
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
  outcome <- "test"
  timescale <- "timesincevax"
} else {
  removeobs <- TRUE
  outcome <- args[[1]]
  timescale <- args[[2]]
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
fs::dir_create(here("output", "models", outcome, timescale))

## create special log file ----
cat(glue("## script info for {outcome} ##"), "  \n", file = here("output", "models", outcome, timescale, glue("modelcox_log.txt")), append = FALSE)
## function to pass additional log text
logoutput <- function(...){
  cat(..., file = here("output", "models", outcome, timescale, glue("modelcox_log.txt")), sep = "\n  ", append = TRUE)
  cat("\n", file = here("output", "models", outcome, timescale, glue("modelcox_log.txt")), sep = "\n  ", append = TRUE)
}

## import metadata ----
metadata_outcomes <- read_rds(here("output", "data", "metadata_outcomes.rds"))
outcome_var <- metadata_outcomes$outcome_var[metadata_outcomes$outcome==outcome]


var_labels <- read_rds(here("output", "data", "metadata_labels.rds"))
list_formula <- read_rds(here::here("output", "data", "metadata_formulas.rds"))
list2env(list_formula, globalenv())

# Import data ----
data_cohort <- read_rds(here("output", "data", "data_cohort.rds"))

data_tte <- data_cohort %>%
  mutate(

    outcome_date = .[[glue("{outcome_var}")]],
    censor_date = pmin(end_date, dereg_date, death_date, covid_vax_any_2_date, na.rm=TRUE),

    # assume vaccination occurs at the start of the day, and all other events occur at the end of the day.
    tte_censor = tte(vax1_date-1, censor_date, censor_date, na.censor=TRUE),
    ind_censor = censor_indicator(censor_date, censor_date),

    tte_outcome = tte(vax1_date-1, outcome_date, censor_date, na.censor=TRUE),
    ind_outcome = censor_indicator(outcome_date, censor_date),

    tte_stop = pmin(tte_censor, tte_outcome, na.rm=TRUE),
  )

data_cox0 <- data_tte %>%
  mutate( # this step converts logical to integer so that model coefficients print nicely in gtsummary methods
    across(where(is.logical), ~.x*1L)
  ) %>%
  mutate(
    week_region = paste0(vax1_week, "__", region),
    vax1_az = (vax1_type=="az")*1
  )

stopifnot("there is some unvaccinated person-time" = !any(is.na(data_cox0$vax1_type)))

### print dataset size ----
logoutput(
  glue("data_cox0 data size = ", nrow(data_cox0)),
  glue("data_cox0 memory usage = ", format(object.size(data_cox0), units="GB", standard="SI", digits=3L))
)

# one row per patient per post-vaccination week
postvax_time <- data_cox0 %>%
  select(patient_id) %>%
  uncount(weights = length(postvaxcuts), .id="id_postvax") %>%
  mutate(
    fup_day = postvaxcuts[id_postvax],
    timesincevax_pw = timesince_cut(fup_day+1, postvaxcuts)
  ) %>%
  droplevels() %>%
  select(patient_id, fup_day, timesincevax_pw)


# create dataset that splits follow-up time by
# time since vaccination (using postvaxcuts cutoffs)
data_cox <- tmerge(
  data1 = data_cox0 %>% select(-starts_with("ind_"), -ends_with("_date")),
  data2 = data_cox0,
  id = patient_id,
  tstart = 0L,
  tstop = pmin(tte_censor, tte_outcome, na.rm=TRUE),
  ind_outcome = event(tte_outcome)
) %>%
 tmerge( # create treatment timescale variables
    data1 = .,
    data2 = postvax_time,
    id = patient_id,
    timesincevax_pw = tdc(fup_day, timesincevax_pw)
  )

### print dataset size and save ----
logoutput(
  glue("data_cox data size = ", nrow(data_cox)),
  glue("data_cox memory usage = ", format(object.size(data_cox), units="GB", standard="SI", digits=3L))
)

write_rds(data_cox, here("output", "models", outcome, timescale, "modelcox_data.rds"), compress="gz")



## if using calendar timescale ----
# - az versus pfizer is examined as an interaction term with time since vaccination, which is a time-dependent covariate
# - delayed entry at vaccination date
# - split time into az week 1, az week 2, .... pfizer week1, pfizer week 2, ... using standard interaction term
# - no need to adjust for calender time
if(timescale=="calendar"){
# convert to calendar timescale
  data_cox <- data_cox %>%
  mutate(
    tstart= tstart + vax1_day - 1,
    tstop= tstop + vax1_day - 1,
  )

  formula_vaxonly <- Surv(tstart, tstop, ind_outcome) ~ vax1_az*timesincevax_pw
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
    select(patient_id, vax1_day, tte_stop) %>%
    mutate(
      calendar_day = map2(vax1_day, tte_stop, ~.x:(.y+.x))
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

  data_cox <- data_cox %>%
    tmerge(
      data1 = .,
      data2 = treatment_week,
      id = patient_id,
      calendar_day = tdc(treatment_day, calendar_day)
    )

  formula_vaxonly <- Surv(tstart, tstop, ind_outcome) ~ vax1_az:strata(timesincevax_pw) #as per https://cran.r-project.org/web/packages/survival/vignettes/timedep.pdf
  formula_spacetime <- . ~ . + strata(region) * ns(calendar_day, 3)
}

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

formula0_pw <- formula_vaxonly
formula1_pw <- formula_vaxonly %>% update(formula_spacetime)
formula2_pw <- formula_vaxonly %>% update(formula_spacetime) %>% update(formula_demog)
formula3_pw <- formula_vaxonly %>% update(formula_spacetime) %>% update(formula_demog) %>% update(formula_comorbs)

opt_control <- coxph.control(iter.max = 30)

cox_model <- function(number, formula_cox){
  coxmod <- coxph(
    formula = formula_cox,
    data = data_cox,
    robust = TRUE,
    id = patient_id,
    na.action = "na.fail",
    control = opt_control
  )

  print(warnings())
  logoutput(
    glue("model{number} data size = ", coxmod$n),
    glue("model{number} memory usage = ", format(object.size(coxmod), units="GB", standard="SI", digits=3L)),
    glue("convergence status: ", coxmod$info[["convergence"]])
  )

  tidy <-
    broom.helpers::tidy_plus_plus(
      coxmod,
      exponentiate = FALSE
    ) %>%
    add_column(
      model = number,
      .before=1
    )

  glance <-
    broom::glance(coxmod) %>%
    add_column(
    model = number,
    convergence = coxmod$info[["convergence"]],
    ram = format(object.size(coxmod), units="GB", standard="SI", digits=3L),
    .before = 1
  )

  coxmod$data <- NULL
  write_rds(coxmod, here("output", "models", outcome, timescale, glue("modelcox_model{number}.rds")), compress="gz")


  lst(glance, tidy)
}


summary0 <- cox_model(0, formula0_pw)
summary1 <- cox_model(1, formula1_pw)
summary2 <- cox_model(2, formula2_pw)
summary3 <- cox_model(3, formula3_pw)


# combine results
model_glance <-
  bind_rows(summary0$glance, summary1$glance, summary2$glance, summary3$glance) %>%
  mutate(
    model_name = fct_recode(as.character(model), !!!model_names),
    outcome = outcome
  )
write_csv(model_glance, here::here("output", "models", outcome, timescale, glue("modelcox_glance.csv")))

model_tidy <- bind_rows(summary0$tidy, summary1$tidy, summary2$tidy, summary3$tidy) %>%
  mutate(
    model_name = fct_recode(as.character(model), !!!model_names),
    outcome = outcome
  )
write_csv(model_tidy, here::here("output", "models", outcome, timescale, glue("modelcox_tidy.csv")))
write_rds(model_tidy, here::here("output", "models", outcome, timescale, glue("modelcox_tidy.rds")))

