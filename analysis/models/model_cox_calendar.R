
# # # # # # # # # # # # # # # # # # # # #
# This script:
# imports processed data and restricts it to patients in "cohort"
# fits some marginal structural models for vaccine effectiveness, with different adjustment sets
# saves model summaries (tables and figures)
# "tte" = "time-to-event"
#
# The script should be run via an action in the project.yaml
# The script must be accompanied by four arguments,
# 1. the name of the cohort defined in data_define_cohorts.R
# 2. the name of the outcome defined in data_define_cohorts.R
# 4. the stratification variable. Use "all" if no stratification
# # # # # # # # # # # # # # # # # # # # #

# Preliminaries ----


# import command-line arguments ----

args <- commandArgs(trailingOnly=TRUE)


if(length(args)==0){
  # use for interactive testing
  removeobs <- FALSE
  outcome <- "postest"
} else {
  removeobs <- TRUE
  outcome <- args[[1]]
}


## Import libraries ----
library('tidyverse')
library('here')
library('glue')
library('survival')
library('splines')

## Import custom user functions from lib

source(here("analysis", "lib", "utility_functions.R"))
source(here("analysis", "lib", "redaction_functions.R"))
source(here("analysis", "lib", "survival_functions.R"))


# create output directories ----
dir.create(here("output", outcome), showWarnings = FALSE, recursive=TRUE)

## create special log file ----
cat(glue("## script info for {outcome} ##"), "  \n", file = here("output", outcome, glue("log_{outcome}.txt")), append = FALSE)
## function to pass additional log text
logoutput <- function(...){
  cat(..., file = here("output", outcome, glue("log_{outcome}.txt")), sep = "\n  ", append = TRUE)
  cat("\n", file = here("output", outcome, glue("log_{outcome}.txt")), sep = "\n  ", append = TRUE)
}

## import metadata ----
var_labels <- read_rds(here("output", "data", "metadata_labels.rds"))

list_formula <- read_rds(here::here("output", "data", "metadata_formulas.rds"))
list2env(list_formula, globalenv())

# Import matched data ----
data_cohort <- read_rds(here("output", "data", "data_cohort.rds"))

# redo tte variables to indclude censoring date (ie use na.censor=FALSE)
data_tte <- data_cohort %>%
  mutate(

    #composite of death, deregistration and end date
    lastfup_date = pmin(end_date, death_date, dereg_date, na.rm=TRUE),

    # time to last follow up day
    tte_enddate = tte(vax1_date, end_date, end_date),

    # time to last follow up day or death or deregistration
    tte_lastfup = tte(vax1_date, lastfup_date, lastfup_date),

    tte_covidtest =tte(vax1_date, covid_test_date, lastfup_date, na.censor=TRUE),
    ind_covidtest = censor_indicator(covid_test_date, lastfup_date),

    tte_postest = tte(vax1_date, positive_test_date, lastfup_date, na.censor=TRUE),
    ind_postest = censor_indicator(positive_test_date, lastfup_date),

    tte_emergency = tte(vax1_date, emergency_date, lastfup_date, na.censor=TRUE),
    ind_emergency = censor_indicator(emergency_date, lastfup_date),

    tte_covidadmitted = tte(vax1_date, covidadmitted_date, lastfup_date, na.censor=TRUE),
    ind_covidadmitted = censor_indicator(covidadmitted_date, lastfup_date),

    tte_coviddeath = tte(vax1_date, coviddeath_date, lastfup_date, na.censor=TRUE),
    ind_coviddeath = censor_indicator(coviddeath_date, lastfup_date),

    tte_noncoviddeath = tte(vax1_date, noncoviddeath_date, lastfup_date, na.censor=TRUE),
    ind_noncoviddeath = censor_indicator(noncoviddeath_date, lastfup_date),

    tte_death = tte(vax1_date, death_date, lastfup_date, na.censor=TRUE),
    ind_death = censor_indicator(death_date, lastfup_date),

    all = factor("all",levels=c("all")),

  )

data_cox <- data_tte %>%
  mutate(
    tte_outcome = .[[glue::glue("tte_",outcome)]],
    ind_outcome = .[[glue::glue("ind_",outcome)]],
  ) %>%
  mutate( # this step converts logical to integer so that model coefficients print nicely in gtsummary methods
    across(
      where(is.logical),
      ~.x*1L
    )
  ) %>%
  mutate(
    week_region = paste0(vax1_week, "__", region),
    vax1_az = (vax1_type=="az")*1
  ) %>%
  filter(
    !is.na(vax1_date),
    vax1_date<=lastfup_date,
    tte_outcome>0, # necessary for filtering out bad dummy data and removing people who experienced an event on the same day as vaccination
    tte_lastfup>0, # necessary for filtering out bad dummy data and removing people who experienced a censoring event on the same day as vaccination
  )

stopifnot("there is some unvaccinated person-time" = !any(is.na(data_cox$vax1_type)))

### print dataset size ----
logoutput(
  glue("data_cox data size = ", nrow(data_cox)),
  glue("data_cox memory usage = ", format(object.size(data_cox), units="GB", standard="SI", digits=3L))
)

# one row per patient per post-vaccination week
postvax_time <- data_cox %>%
  select(patient_id) %>%
  mutate(
    fup_day = list(postvaxcuts),
    timesincevax = map(fup_day, ~droplevels(timesince_cut(.x+0.5, postvaxcuts, "blah")))
  ) %>%
  unnest(c(fup_day, timesincevax))

# create dataset that splits follow-up time by
# time since vaccination (using postvaxcuts cutoffs)
data_cox_split <- tmerge(
  data1 = data_cox %>% select(-starts_with("ind_"), -ends_with("_date")),
  data2 = data_cox,
  id = patient_id,
  tstart = 0L,
  tstop = pmin(tte_lastfup, tte_outcome, na.rm=TRUE),
  ind_outcome = event(tte_outcome)
) %>%
 tmerge( # create treatment timescale variables
    data1 = .,
    data2 = postvax_time,
    id = patient_id,
    timesincevax = tdc(fup_day, timesincevax)
  ) %>%
  mutate( # convert to calendar timescale
    tstart= tstart + vax1_day - 1,
    tstop= tstop + vax1_day - 1,
  )


### print dataset size ----
logoutput(
  glue("data_cox_split data size = ", nrow(data_cox_split)),
  glue("data_cox_split memory usage = ", format(object.size(data_cox_split), units="GB", standard="SI", digits=3L))
)

write_rds(data_cox_split, here("output", outcome, "data_cox_split.rds"))

# Time-dependent Cox models ----

# calculate calendar week (this is the date of vaccination (x) + follow-up time (t), then rounded)
# tt_week <- function(x, t, ...){
#   day <- x + t
#
# }

# print(table(data_cox_split$timesincevax, outcome = data_cox_sub_split$ind_outcome,  az= data_cox_sub_split$vax_az))
# # why does this not work? using timesincevax as a timevarying coefficient. Is it just a dummy data thing?
# coxmod00 <- coxph(
#   formula = Surv(tstart, tstop, ind_outcome) ~ vax_az + timesincevax,
#   data = data_cox_sub_split,
#   id = patient_id
# )

formula_vaxonly <- Surv(tstart, tstop, ind_outcome) ~ vax1_az:timesincevax
#formula_vaxonly <- Surv(tstart, tstop, ind_outcome) ~ vax1_az:strata(timesincevax) #as per https://cran.r-project.org/web/packages/survival/vignettes/timedep.pdf

formula_spacetime <- . ~ . + strata(stp)


### model 0 - unadjusted vaccination effect model ----
## no adjustment variables
cat("  \n")
cat("model0 \n")
coxmod0 <- coxph(
  formula = formula_vaxonly,
  data = data_cox_split,
  robust = TRUE,
  id = patient_id,
  na.action = "na.fail"
)


logoutput(
  glue("model0 data size = ", coxmod0$n),
  glue("model0 memory usage = ", format(object.size(coxmod0), units="GB", standard="SI", digits=3L))
)
write_rds(coxmod0, here::here("output", outcome, "modelcox0.rds"), compress="gz")
if(removeobs) rm(coxmod0)


### model 1 - minimally adjusted vaccination effect model, stratification by stp only ----
cat("  \n")
cat("model1 \n")

coxmod1 <- coxph(
  formula = formula_vaxonly %>% update(formula_spacetime),
  data = data_cox_split,
  robust = TRUE,
  id = patient_id,
  na.action = "na.fail"
)

logoutput(
  glue("model1 data size = ", coxmod1$n),
  glue("model1 memory usage = ", format(object.size(coxmod1), units="GB", standard="SI", digits=3L))
)
write_rds(coxmod1, here::here("output", outcome, "modelcox1.rds"), compress="gz")
if(removeobs) rm(coxmod1)




### model 2 - minimally adjusted vaccination effect model, baseline demographics only ----
cat("  \n")
cat("model2 \n")

coxmod2 <- coxph(
  formula = formula_vaxonly %>% update(formula_spacetime) %>% update(formula_demog),
  data = data_cox_split,
  robust = TRUE,
  id = patient_id,
  na.action = "na.fail"
)

logoutput(
  glue("model2 data size = ", coxmod2$n),
  glue("model2 memory usage = ", format(object.size(coxmod2), units="GB", standard="SI", digits=3L))
)
write_rds(coxmod2, here::here("output", outcome, "modelcox2.rds"), compress="gz")
if(removeobs) rm(coxmod2)



### model 3 - fully adjusted vaccination effect model, baseline demographics + clinical characteristics ----
cat("  \n")
cat("model3 \n")

coxmod3 <- coxph(
  formula = formula_vaxonly %>% update(formula_spacetime) %>% update(formula_demog) %>% update(formula_comorbs),
  data = data_cox_split,
  robust = TRUE,
  id = patient_id,
  na.action = "na.fail"
)

logoutput(
  glue("model3 data size = ", coxmod3$n),
  glue("model3 memory usage = ", format(object.size(coxmod3), units="GB", standard="SI", digits=3L))
)
write_rds(coxmod3, here::here("output", outcome, "modelcox3.rds"), compress="gz")
if(removeobs) rm(coxmod3)




## print warnings
print(warnings())
cat("  \n")
print(gc(reset=TRUE))


