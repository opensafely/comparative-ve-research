
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

## Import libraries ----
library('tidyverse')
library('survival')
library('splines')
library('parglm')
library('gtsummary')
library('gt')

## Import custom user functions from lib
source(here::here("lib", "utility_functions.R"))
source(here::here("lib", "redaction_functions.R"))
source(here::here("lib", "survival_functions.R"))

# import command-line arguments ----

args <- commandArgs(trailingOnly=TRUE)



if(length(args)==0){
  # use for interactive testing
  removeobs <- FALSE
  cohort <- "over80s"
  outcome <- "postest"
  strata_var <- "all"
} else {
  removeobs <- TRUE
  cohort <- args[[1]]
  outcome <- args[[2]]
  strata_var <- args[[3]]
}

brand <- "compare"

# Import metadata for cohort ----

metadata_cohorts <- read_rds(here::here("output", "data", "metadata_cohorts.rds"))
metadata <- metadata_cohorts[metadata_cohorts[["cohort"]]==cohort, ]


stopifnot("cohort does not exist" = (cohort %in% metadata_cohorts[["cohort"]]))

## define model hyper-parameters and characteristics ----

### model names ----

list2env(metadata, globalenv())


### import outcomes, exposures, and covariate formulae ----
## these are created in data_define_cohorts.R script

list_formula <- read_rds(here::here("output", "data", "list_formula.rds"))
list2env(list_formula, globalenv())


formula_remove_strata_var <- as.formula(paste0(". ~ . - ",strata_var))

# Import processed data ----

data_fixed <- read_rds(here::here("output", cohort, "data", glue::glue("data_wide_fixed.rds")))
data_tte <- read_rds(here::here("output", cohort, "data", glue::glue("data_wide_tte.rds")))


# redo tte variables to indclude censoring date (ie use na.censor=FALSE)
data_tte <- data_tte %>%
  mutate(
    covid_vax_1_date = pmin(covid_vax_az_1_date, covid_vax_pfizer_1_date, na.rm=TRUE), # necessary to standardise dummy data
    vax_brand = case_when(
      covid_vax_1_date==covid_vax_pfizer_1_date ~ "pfizer",
      covid_vax_1_date==covid_vax_az_1_date ~ "az",
      TRUE ~ "unvaccinated"
    ),

    # time to last follow up day
    vax_day = tte(start_date, covid_vax_1_date, lastfup_date),

    tte_lastfup = tte(covid_vax_1_date, lastfup_date, lastfup_date),

    tte_covidtest =tte(covid_vax_1_date, covid_test_1_date, lastfup_date, na.censor=TRUE),
    ind_covidtest = censor_indicator(covid_test_1_date, lastfup_date),

    tte_postest = tte(covid_vax_1_date, positive_test_1_date, lastfup_date, na.censor=TRUE),
    ind_postest = censor_indicator(positive_test_1_date, lastfup_date),

    tte_emergency = tte(covid_vax_1_date, emergency_1_date, lastfup_date, na.censor=TRUE),
    ind_emergency = censor_indicator(emergency_1_date, lastfup_date),

    tte_covidadmitted = tte(covid_vax_1_date, covidadmitted_1_date, lastfup_date, na.censor=TRUE),
    ind_covidadmitted = censor_indicator(covidadmitted_1_date, lastfup_date),

    tte_coviddeath = tte(covid_vax_1_date, coviddeath_date, lastfup_date, na.censor=TRUE),
    ind_coviddeath = censor_indicator(coviddeath_date, lastfup_date),

    tte_noncoviddeath = tte(covid_vax_1_date, noncoviddeath_date, lastfup_date, na.censor=TRUE),
    ind_noncoviddeath = censor_indicator(noncoviddeath_date, lastfup_date),

    tte_death = tte(covid_vax_1_date, death_date, lastfup_date, na.censor=TRUE),
    ind_death = censor_indicator(death_date, lastfup_date),

    all = factor("all",levels=c("all")),

    week = floor((covid_vax_1_date - start_date)/7),

  )

data_cox <- data_fixed %>%
  left_join(data_tte, by="patient_id") %>%
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
    week_region = paste0(week, "__", region),
    vax_az = (vax_brand=="az")*1
  ) %>%
  filter(
    !is.na(covid_vax_1_date),
    covid_vax_1_date<=lastfup_date,
    tte_outcome>0, # necessary for filtering out bad dummy data,
    tte_lastfup>0, # necessary for filtering out bad dummy data,
  )

stopifnot("there is some unvaccinated person-time" = !any(data_cox$vax_brand=="unvaccinated"))

### print dataset size ----
cat(glue::glue("data_cox data size = ", nrow(data_cox)), "\n  ")
cat(glue::glue("memory usage = ", format(object.size(data_cox), units="GB", standard="SI", digits=3L)), "\n  ")

##  Create big loop over all categories

strata <- read_rds(here::here("output", "data", "list_strata.rds"))[[strata_var]]

for(stratum in strata){

  cat("  \n")
  cat(stratum, "  \n")
  cat("  \n")

  # create output directories ----
  dir.create(here::here("output", cohort, outcome, brand, strata_var, stratum), showWarnings = FALSE, recursive=TRUE)


  # subset data
  data_cox_sub <- data_cox %>% filter(.[[strata_var]] == stratum)


  calendar_time <- data_cox_sub %>%
    select(patient_id, vax_day, tte_enddate) %>%
    mutate(
      calendar_day = map2(vax_day, tte_enddate, ~.x:.y)
    ) %>%
    unnest(c(calendar_day)) %>%
    mutate(
      calendar_week = paste0("week ", str_pad(floor(calendar_day/7), 2, pad = "0")),
      fup_day = calendar_day - vax_day
    )


  calendar_week <- calendar_time %>%
    group_by(patient_id, calendar_week) %>%
    filter(first(calendar_day)==calendar_day) %>%
    ungroup()

  postvax_time <- data_cox_sub %>%
    select(patient_id) %>%
    mutate(
      fup_day = list(postvaxcuts),
      timesincevax = map(fup_day, ~droplevels(timesince_cut(.x+0.5, postvaxcuts, "blah")))
    ) %>%
    unnest(c(fup_day, timesincevax))

  # create dataset that splits follow-up time by:
  # - time since vaccination (using postvaxcuts cutoffs)
  # - calendar week
  data_cox_sub_split <- tmerge(
      data1 = data_cox_sub %>% select(-starts_with("ind_"), -ends_with("_date")),
      data2 = data_cox_sub,
      id = patient_id,
      tstart = 0L,
      tstop = pmin(tte_lastfup, tte_outcome, na.rm=TRUE),
      ind_outcome = event(tte_outcome)
      #calendar_week = tdc(fup_day, calendar_week)
    ) %>%
    tmerge(
      data1 = .,
      data2 = calendar_week,
      id = patient_id,
      calendar_week = tdc(fup_day, calendar_week)
    ) %>%
    tmerge(
      data1 = .,
      data2 = postvax_time,
      id = patient_id,
      timesincevax = tdc(fup_day, timesincevax)
    ) %>%
    mutate(
      week_region = paste0(calendar_week, "__", region),
    )

  # Time-dependent Cox models ----

  # calculate calendar week (this is the date of vaccination (x) + follow-up time (t), then rounded)
  tt_week <- function(x, t, ...){
    day <- x + t

  }

  # print(table(data_cox_sub_split$timesincevax, outcome = data_cox_sub_split$ind_outcome,  az= data_cox_sub_split$vax_az))
  # # why does this not work? using timesincevax as a timevarying coefficient. Is it just a dummy data thing?
  # coxmod00 <- coxph(
  #   formula = Surv(tstart, tstop, ind_outcome) ~ vax_az + timesincevax,
  #   data = data_cox_sub_split,
  #   id = patient_id
  # )


  #formula_vaxonly <- Surv(tstart, tstop, ind_outcome) ~ vax_az  + vax_az:timesincevax + timesincevax
  formula_vaxonly <- Surv(tstart, tstop, ind_outcome) ~ vax_az:strata(timesincevax)

  formula_spacetime <- . ~ . + calendar_week + strata(region) + calendar_week:region

  ### model 0 - unadjusted vaccination effect model ----
  ## no adjustment variables
  cat("  \n")
  cat("coxmod0 \n")
  coxmod0 <- coxph(
    formula = formula_vaxonly %>% update(formula_remove_strata_var),
    data = data_cox_sub_split,
    robust = TRUE,
    #tt = tt_week,
    id = patient_id
  )

  cat(glue::glue("coxmod0 data size = ", coxmod0$n), "\n")
  cat(glue::glue("memory usage = ", format(object.size(coxmod0), units="GB", standard="SI", digits=3L)), "\n")
  write_rds(coxmod0, here::here("output", cohort, outcome, brand, strata_var, stratum, "modelcox0.rds"), compress="gz")
  if(removeobs) rm(coxmod0)



  ### model 1 - minimally adjusted vaccination effect model, baseline demographics only ----
  cat("  \n")
  cat("coxmod1 \n")

  coxmod1 <- coxph(
    formula = formula_vaxonly %>% update(formula_spacetime) %>% update(formula_remove_strata_var),
    data = data_cox_sub_split,
    robust = TRUE,
    #tt = tt_week,
    id = patient_id
  )

  cat(glue::glue("coxmod1 data size = ", coxmod1$n), "\n")
  cat(glue::glue("memory usage = ", format(object.size(coxmod1), units="GB", standard="SI", digits=3L)), "\n")
  write_rds(coxmod1, here::here("output", cohort, outcome, brand, strata_var, stratum, "modelcox1.rds"), compress="gz")
  if(removeobs) rm(coxmod1)




  ### model 2 - minimally adjusted vaccination effect model, baseline demographics only ----
  cat("  \n")
  cat("coxmod2 \n")

  coxmod2 <- coxph(
    formula = formula_vaxonly %>% update(formula_spacetime) %>% update(formula_demog) %>% update(formula_remove_strata_var),
    data = data_cox_sub_split,
    robust = TRUE,
    #tt = tt_week,
    id = patient_id
  )

  cat(glue::glue("coxmod2 data size = ", coxmod2$n), "\n")
  cat(glue::glue("memory usage = ", format(object.size(coxmod2), units="GB", standard="SI", digits=3L)), "\n")
  write_rds(coxmod2, here::here("output", cohort, outcome, brand, strata_var, stratum, "modelcox2.rds"), compress="gz")
  if(removeobs) rm(coxmod2)



  ### model 3 - baseline, demographics, comorbs adjusted vaccination effect model ----
  # cat("  \n")
  # cat("coxmod3 \n")
  #
  # coxmod3 <- coxph(
  #   formula = formula_vaxonly %>% update(formula_spacetime) %>% update(formula_demog) %>% update(formula_comorbs) %>% update(formula_remove_strata_var),
  #   data = data_cox_sub_split,
  #   robust = TRUE,
  #   #tt = tt_week,
  #   id = patient_id
  # )
  #
  # cat(glue::glue("coxmod3 data size = ", coxmod3$n), "\n")
  # cat(glue::glue("memory usage = ", format(object.size(coxmod3), units="GB", standard="SI", digits=3L)), "\n")
  # write_rds(coxmod3, here::here("output", cohort, outcome, brand, strata_var, stratum, "modelcox3.rds"), compress="gz")
  # if(removeobs) rm(coxmod3)
  #
  #

  ## print warnings
  print(warnings())
  cat("  \n")
  print(gc(reset=TRUE))
}


