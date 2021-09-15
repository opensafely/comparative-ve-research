
# # # # # # # # # # # # # # # # # # # # #
# This script:
# imports processed data and restricts it to patients in "cohort"
# fits some pooled logistic regression models, with different adjustment sets
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
  timescale <- "timesincevax"
  censor_seconddose <- as.integer("0")
  samplesize_nonoutcomes_n <- 5000
} else {
  removeobs <- TRUE
  outcome <- args[[1]]
  timescale <- args[[2]]
  censor_seconddose <- as.integer(args[[3]])
  samplesize_nonoutcomes_n <- as.integer(args[[4]])
}



## Import libraries ----
library('tidyverse')
library('here')
library('glue')
library('survival')
library('mgcv')
library('pammtools')
## Import custom user functions from lib

source(here("analysis", "lib", "utility_functions.R"))
source(here("analysis", "lib", "redaction_functions.R"))
source(here("analysis", "lib", "survival_functions.R"))


# create output directories ----
fs::dir_create(here("output", "models", outcome, timescale, censor_seconddose))

## create special log file ----
cat(glue("## script info for {outcome} ##"), "  \n", file = here("output", "models", outcome, timescale, censor_seconddose, glue("modelplr_log_{outcome}.txt")), append = FALSE)
## function to pass additional log text
logoutput <- function(...){
  cat(..., file = here("output", "models", outcome, timescale, censor_seconddose, glue("modelplr_log_{outcome}.txt")), sep = "\n  ", append = TRUE)
  cat("\n", file = here("output", "models", outcome, timescale, censor_seconddose, glue("modelplr_log_{outcome}.txt")), sep = "\n  ", append = TRUE)
}

## import metadata ----

metadata_outcomes <- read_rds(here("output", "data", "metadata_outcomes.rds"))
outcome_var <- metadata_outcomes$outcome_var[metadata_outcomes$outcome==outcome]

var_labels <- read_rds(here("output", "data", "metadata_labels.rds"))

list_formula <- read_rds(here("output", "data", "metadata_formulas.rds"))
list2env(list_formula, globalenv())

if(censor_seconddose==1){
  postvaxcuts<-postvaxcuts12
  lastfupday<-lastfupday12
} else {
  postvaxcuts<-postvaxcuts20
  lastfupday<-lastfupday20
}

# Import data ----
data_cohort <- read_rds(here("output", "data", "data_cohort.rds"))

# calculate time to event variables
data_tte <- data_cohort %>%
  mutate(
    end_date,
    censor_date = pmin(
      vax1_date - 1 + lastfupday,
      dereg_date,
      death_date,
      if_else(rep(censor_seconddose, n())==1, vax2_date-1, as.Date(Inf)),
      end_date,
      na.rm=TRUE
    ),


    outcome_date = .[[glue("{outcome_var}")]],

    tte_outcome = tte(vax1_date-1, outcome_date, censor_date, na.censor=FALSE),
    ind_outcome = censor_indicator(outcome_date, censor_date),

    sample_outcome = sample_nonoutcomes_n(!is.na(tte_outcome), patient_id, samplesize_nonoutcomes_n),

    sample_weights = sample_weights(!is.na(tte_outcome), sample_outcome),
  ) %>%
  filter(
    # select all patients who experienced the outcome, and a sample of those who don't
    sample_outcome==1L
  )



### print dataset size and save ----
logoutput(
  glue("data_ped data size = ", nrow(data_ped)),
  glue("data_ped memory usage = ", format(object.size(data_ped), units="GB", standard="SI", digits=3L))
)

write_rds(data_ped, here("output", "models", outcome, timescale, censor_seconddose, "modelplr_data.rds"), compress="gz")

## make formulas ----

### model 0 - vaccination + timescale only, no adjustment variables
### model 1 - minimally adjusted vaccination effect model, stratification by region only
### model 2 - minimally adjusted vaccination effect model, baseline demographics only
### model 3 - fully adjusted vaccination effect model, baseline demographics + clinical characteristics

model_names = c(
  "Unadjusted" = "0",
  "Adjusting for time" = "1",
  "Adjusting for time + demographics" = "2",
  "Adjusting for time + demographics + clinical" = "3"
)


formula_outcome <- ped_status ~ 1

# mimicing timescale / stratification in simple cox models
if(timescale=="timesincevax"){
  formula_treatmenttimescale_ns <- . ~ . + vax1_type + s(tend, k=4, by=vax1_type, pc=0)
  formula_spacetime <- . ~ . + s(vax1_day, k=4, by=region) # spline for space-time adjustments
}


## NOTE
# as time-varying splines for both vaccination time and calendar time are included.
# This wrongly allows for estimation of the probability of, eg, the risk of death
# in february for someone vaccinated on 1 march

### natural cubic spline formulae ----
### estimands
formula_vaxonly_ns <- formula_outcome  %>% update(formula_treatmenttimescale_ns)

formula0_ns <- formula_vaxonly_ns
formula1_ns <- formula_vaxonly_ns %>% update(formula_spacetime)
formula2_ns <- formula_vaxonly_ns %>% update(formula_spacetime) %>% update(formula_demog)
formula3_ns <- formula_vaxonly_ns %>% update(formula_spacetime) %>% update(formula_demog) %>% update (formula_comorbs)


## ped ----
data_ped <-
  data_tte %>%
  as_ped(
    Surv(tte_outcome, ind_outcome)~.,
    id = "patient_id",
  )


pedmod0 <- gam(
  ped_status ~ vax1_type + s(tend, k = 4, by = vax1_type) + s(tend, k=4),
  data = data_ped,
  offset = offset,
  family = poisson()
)

pedmod1 <- gam(
  ped_status ~ vax1_type + s(tend, k = 4, by = vax1_type) + s(tend, k = 4) + s(vax1_day, k = 4, by = region),
  data = data_ped,
  offset = offset,
  family = poisson()
)
summary(pedmod1)


