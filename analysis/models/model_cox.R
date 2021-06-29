
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
  timescale <- "timesincevax"
  outcome <- "postest"
} else {
  removeobs <- TRUE
  timescale <- args[[1]]
  outcome <- args[[2]]

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
fs::dir_create(here("output", outcome, timescale))

## create special log file ----
cat(glue("## script info for {outcome} ##"), "  \n", file = here("output", outcome, timescale, glue("log_{outcome}.txt")), append = FALSE)
## function to pass additional log text
logoutput <- function(...){
  cat(..., file = here("output", outcome, timescale, glue("log_{outcome}.txt")), sep = "\n  ", append = TRUE)
  cat("\n", file = here("output", outcome, timescale, glue("log_{outcome}.txt")), sep = "\n  ", append = TRUE)
}

## import metadata ----
var_labels <- read_rds(here("output", "data", "metadata_labels.rds"))

list_formula <- read_rds(here::here("output", "data", "metadata_formulas.rds"))
list2env(list_formula, globalenv())

# Import data ----
data_cohort <- read_rds(here("output", "data", "data_cohort.rds"))

# redo tte variables to indclude censoring date (ie use na.censor=FALSE)
data_tte <- data_cohort %>%
  mutate(

    # time to study end date
    tte_enddate = tte(vax1_date, end_date, end_date),

    # time to last follow up day or death or deregistration
    tte_censor = tte(vax1_date, censor_date, censor_date),

    tte_vaxany2 =tte(vax1_date, covid_vax_any_2_date, censor_date, na.censor=TRUE),
    ind_vaxany2 = censor_indicator(covid_vax_any_2_date, censor_date),

    tte_test =tte(vax1_date, covid_test_date, censor_date, na.censor=TRUE),
    ind_test = censor_indicator(covid_test_date, censor_date),

    tte_postest = tte(vax1_date, positive_test_date, censor_date, na.censor=TRUE),
    ind_postest = censor_indicator(positive_test_date, censor_date),

    tte_emergency = tte(vax1_date, emergency_date, censor_date, na.censor=TRUE),
    ind_emergency = censor_indicator(emergency_date, censor_date),

    tte_covidadmitted = tte(vax1_date, covidadmitted_date, censor_date, na.censor=TRUE),
    ind_covidadmitted = censor_indicator(covidadmitted_date, censor_date),

    tte_covidcc = tte(vax1_date, covidcc_date, censor_date, na.censor=TRUE),
    ind_covidcc = censor_indicator(covidcc_date, censor_date),

    tte_coviddeath = tte(vax1_date, coviddeath_date, censor_date, na.censor=TRUE),
    ind_coviddeath = censor_indicator(coviddeath_date, censor_date),

    tte_noncoviddeath = tte(vax1_date, noncoviddeath_date, censor_date, na.censor=TRUE),
    ind_noncoviddeath = censor_indicator(noncoviddeath_date, censor_date),

    tte_death = tte(vax1_date, death_date, censor_date, na.censor=TRUE),
    ind_death = censor_indicator(death_date, censor_date),

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
    tte_outcome>0 | is.na(tte_outcome), # necessary for filtering out bad dummy data and removing people who experienced an event on the same day as vaccination
    tte_censor>0 | is.na(tte_censor), # necessary for filtering out bad dummy data and removing people who experienced a censoring event on the same day as vaccination
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
  tstop = pmin(tte_censor, tte_outcome, na.rm=TRUE),
  ind_outcome = event(tte_outcome)
) %>%
 tmerge( # create treatment timescale variables
    data1 = .,
    data2 = postvax_time,
    id = patient_id,
    timesincevax = tdc(fup_day, timesincevax)
  )


## if using calendar timescale ----
# - az versus pfizer is examined as an interaction term with time since vaccination, which is a time-dependent covariate
# - delayed entry at vaccination date
# - split time into az week 1, az week 2, .... pfizer week1, pfizer week 2, ... using standard interaction term
# - no need to adjust for calender time
if(timescale=="calendar"){
# convert to calendar timescale
  data_cox_split <- data_cox_split %>%
  mutate(
    tstart= tstart + vax1_day - 1,
    tstop= tstop + vax1_day - 1,
  )

  formula_vaxonly <- Surv(tstart, tstop, ind_outcome) ~ vax1_az*timesincevax
  formula_spacetime <- . ~ . + strata(region)
}

## if using time since vaccination timescale ----
# - az versus pfizer is examined as a time-dependent effect
# - start date is vaccination date
# - post-vax follow-up is already overlapping, so can use az/pfizer : weekly strata
# - need to adjust for calendar time
if(timescale=="timesincevax"){
  # one row per patient per follow-up calendar day
  calendar_time <- data_cox %>%
    select(patient_id, vax1_day, tte_enddate) %>%
    mutate(
      calendar_day = map2(vax1_day, tte_enddate, ~.x:(.y+.x))
    ) %>%
    unnest(c(calendar_day)) %>%
    mutate(
      #calendar_week = paste0("week ", str_pad(floor(calendar_day/7), 2, pad = "0")),
      calendar_week = floor(calendar_day/7),
      treatment_day = calendar_day - vax1_day,
      treatment_week = floor(treatment_day/7)
    )

  # one row per patient per follow-up calendar week
  calendar_week <- calendar_time %>%
    group_by(patient_id, calendar_week) %>%
    filter(first(calendar_day)==calendar_day) %>%
    ungroup()

  # one row per patient per follow-up post-vax week
  treatment_week <- calendar_time %>%
    group_by(patient_id, treatment_week) %>%
    filter(first(treatment_day)==treatment_day) %>%
    ungroup()

  data_cox_split <- data_cox_split %>%
    tmerge(
      data1 = .,
      data2 = treatment_week,
      id = patient_id,
      calendar_day = tdc(treatment_day, calendar_day)
    )

  formula_vaxonly <- Surv(tstart, tstop, ind_outcome) ~ vax1_az:strata(timesincevax) #as per https://cran.r-project.org/web/packages/survival/vignettes/timedep.pdf
  formula_spacetime <- . ~ . + strata(region) + ns(calendar_day, 4)
}


opt_control <- coxph.control(iter.max = 30)

### print dataset size ----
logoutput(
  glue("data_cox_split data size = ", nrow(data_cox_split)),
  glue("data_cox_split memory usage = ", format(object.size(data_cox_split), units="GB", standard="SI", digits=3L))
)

write_rds(data_cox_split, here("output", outcome, timescale, "data_cox_split.rds"))


### model 0 - unadjusted vaccination effect model ----
## no adjustment variables
cat("  \n")
cat("model0 \n")
coxmod0 <- coxph(
  formula = formula_vaxonly,
  data = data_cox_split,
  robust = TRUE,
  id = patient_id,
  na.action = "na.fail",
  control = opt_control
)

print(warnings())
logoutput(
  glue("model0 data size = ", coxmod0$n),
  glue("model0 memory usage = ", format(object.size(coxmod0), units="GB", standard="SI", digits=3L)),
  glue("convergence status: ", coxmod0$info[["convergence"]])
)
write_rds(coxmod0, here::here("output", outcome, timescale, "modelcox0.rds"), compress="gz")
model_glance <- broom::glance(coxmod0) %>% mutate(model=0, convergence = coxmod0$info[["convergence"]])
if(removeobs) rm(coxmod0)


### model 1 - minimally adjusted vaccination effect model, stratification by stp only ----
cat("  \n")
cat("model1 \n")

coxmod1 <- coxph(
  formula = formula_vaxonly %>% update(formula_spacetime),
  data = data_cox_split,
  robust = TRUE,
  id = patient_id,
  na.action = "na.fail",
  control = opt_control
)

print(warnings())
logoutput(
  glue("model1 data size = ", coxmod1$n),
  glue("model1 memory usage = ", format(object.size(coxmod1), units="GB", standard="SI", digits=3L)),
  glue("convergence status: ", coxmod1$info[["convergence"]])
)
write_rds(coxmod1, here::here("output", outcome, timescale, "modelcox1.rds"), compress="gz")
model_glance <- bind_rows(model_glance, broom::glance(coxmod1) %>% mutate(model=1, convergence = coxmod1$info[["convergence"]]))
if(removeobs) rm(coxmod1)




### model 2 - minimally adjusted vaccination effect model, baseline demographics only ----
cat("  \n")
cat("model2 \n")

coxmod2 <- coxph(
  formula = formula_vaxonly %>% update(formula_spacetime) %>% update(formula_demog),
  data = data_cox_split,
  robust = TRUE,
  id = patient_id,
  na.action = "na.fail",
  control = opt_control
)

print(warnings())
logoutput(
  glue("model2 data size = ", coxmod2$n),
  glue("model2 memory usage = ", format(object.size(coxmod2), units="GB", standard="SI", digits=3L)),
  glue("convergence status: ", coxmod2$info[["convergence"]])
)
write_rds(coxmod2, here::here("output", outcome, timescale, "modelcox2.rds"), compress="gz")
model_glance <- bind_rows(model_glance, broom::glance(coxmod2) %>% mutate(model=2, convergence = coxmod2$info[["convergence"]]))
if(removeobs) rm(coxmod2)



### model 3 - fully adjusted vaccination effect model, baseline demographics + clinical characteristics ----
cat("  \n")
cat("model3 \n")

coxmod3 <- coxph(
  formula = formula_vaxonly %>% update(formula_spacetime) %>% update(formula_demog) %>% update(formula_comorbs),
  data = data_cox_split,
  robust = TRUE,
  id = patient_id,
  na.action = "na.fail",
  control = opt_control
)

print(warnings())
logoutput(
  glue("model3 data size = ", coxmod3$n),
  glue("model3 memory usage = ", format(object.size(coxmod3), units="GB", standard="SI", digits=3L)),
  glue("convergence status: ", coxmod3$info[["convergence"]])
)
write_rds(coxmod3, here::here("output", outcome, timescale, "modelcox3.rds"), compress="gz")
model_glance <- bind_rows(model_glance, broom::glance(coxmod3) %>% mutate(model=3, convergence = coxmod3$info[["convergence"]]))
if(removeobs) rm(coxmod3)


## print warnings
print(warnings())
cat("  \n")
print(gc(reset=TRUE))


model_glance <- model_glance %>%
  select(
    model, convergence,
    everything()
  )

write_csv(model_glance, here::here("output", outcome, timescale, glue("glance_{outcome}.csv")))

