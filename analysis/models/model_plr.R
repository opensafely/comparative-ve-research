
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
library('splines')
library('parglm')
library('sandwich')
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
  postvaxcuts <- postvaxcuts20
  if(outcome=="postest") postvaxcuts <- postvaxcuts20_postest
  lastfupday <- lastfupday20
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

    tte_censor = tte(vax1_date-1, censor_date, censor_date, na.censor=TRUE),
    ind_censor = censor_indicator(censor_date, censor_date),

    tte_outcome = tte(vax1_date-1, outcome_date, censor_date, na.censor=TRUE),
    ind_outcome = censor_indicator(outcome_date, censor_date),

    tte_stop = pmin(tte_censor, tte_outcome, na.rm=TRUE),

    sample_outcome = sample_nonoutcomes_n(!is.na(tte_outcome), patient_id, samplesize_nonoutcomes_n),

    sample_weights = sample_weights(!is.na(tte_outcome), sample_outcome),
  ) %>%
  filter(
    # select all patients who experienced the outcome, and a sample of those who don't
    sample_outcome==1L
  )

alltimes <- expand(data_tte, patient_id, times=as.integer(full_seq(c(1, tte_stop),1)))

# one row per day
data_plr <-
  tmerge(
    data1 = data_tte %>% select(everything()),
    data2 = data_tte,
    id = patient_id,

    outcome_status = tdc(tte_outcome),
    censor_status= tdc(tte_censor),

    outcome_event = event(tte_outcome),
    censor_event = event(tte_censor),

    tstart = 0L,
    tstop = tte_stop

  ) %>%
  tmerge(
    data2 = alltimes,
    id = patient_id,
    alltimes = event(times, times)
  )  %>%
  mutate(
    timesincevax_pw = droplevels(timesince_cut(tstop, postvaxcuts)),

    tstart_calendar = tstart + vax1_day - 1,
    tstop_calendar = tstop + vax1_day - 1,

    vax1_az = (vax1_type=="az")*1
  )

### print dataset size and save ----
logoutput(
  glue("data_pt data size = ", nrow(data_plr)),
  glue("data_pt memory usage = ", format(object.size(data_plr), units="GB", standard="SI", digits=3L))
)

write_rds(data_plr, here("output", "models", outcome, timescale, censor_seconddose, "modelplr_data.rds"), compress="gz")

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


formula_outcome <- outcome_event ~ 1

## TODO
# define knots based on event times, not on all follow-up time
#

nsevents <- function(x, events, df){
  # this is the same as the `ns` function,
  # except the knot locations are chosen
  # based on the event times only, not on all person-time
  probs <- seq(0,df)/df
  q <- quantile(x[events==1], probs=probs)
  ns(x, knots=q[-c(1, df+1)], Boundary.knots = q[c(1, df+1)])
}

# nsevents(
#   c(1,2,3,4,5,6,7,8,9,10,1,2,3,4,5,6,7,8,9,10),
#   c(0,0,1,1,1,0,0,0,1,1,0,0,0,0,0,0,0,0,0,1),
#   3
# )
# ns(c(1,2,3,4,5,6,7,8,9,10,1,2,3,4,5,6,7,8,9,10), df=3)

# mimicing timescale / stratification in simple cox models
if(timescale=="calendar"){
  formula_timescale_pw <- . ~ . + ns(tstop_calendar, 3) # spline for timescale only
  formula_timescale_ns <- . ~ . + ns(tstop_calendar, 3) # spline for timescale only
  formula_spacetime <- . ~ . + ns(tstop_calendar, 3)*region # spline for space-time adjustments

  formula_timesincevax_pw <- . ~ . + vax1_az * timesincevax_pw
  formula_timesincevax_ns <- . ~ . + vax1_az * nsevents(tstop, outcome_event, 4)

}
if(timescale=="timesincevax"){
  formula_timescale_pw <- . ~ . + timesincevax_pw # spline for timescale only
  formula_timescale_ns <- . ~ . + nsevents(tstop, outcome_event, 4) # spline for timescale only
  formula_spacetime <- . ~ . + ns(vax1_day, 3)*region # spline for space-time adjustments

  formula_timesincevax_pw <- . ~ . + vax1_az + vax1_az:timesincevax_pw
  formula_timesincevax_ns <- . ~ . + vax1_az + vax1_az:nsevents(tstop, outcome_event, 4)

}


## NOTE
# calendar-time PLR models are still probably wrong!
# as time-varying splines for both vaccination time and calendar time are included.
# This wrongly allows for estimation of the probability of, eg, the risk of death
# in february for someone vaccinated on 1 march

### piecewise formulae ----
### estimand
formula_vaxonly_pw <- formula_outcome  %>% update(formula_timesincevax_pw) %>% update(formula_timescale_pw)

formula0_pw <- formula_vaxonly_pw
formula1_pw <- formula_vaxonly_pw %>% update(formula_spacetime)
formula2_pw <- formula_vaxonly_pw %>% update(formula_spacetime) %>% update(formula_demog)
formula3_pw <- formula_vaxonly_pw %>% update(formula_spacetime) %>% update(formula_demog) %>% update (formula_comorbs)

### natural cubic spline formulae ----
### estimands
formula_vaxonly_ns <- formula_outcome  %>% update(formula_timesincevax_ns) %>% update(formula_timescale_ns)

formula0_ns <- formula_vaxonly_ns
formula1_ns <- formula_vaxonly_ns %>% update(formula_spacetime)
formula2_ns <- formula_vaxonly_ns %>% update(formula_spacetime) %>% update(formula_demog)
formula3_ns <- formula_vaxonly_ns %>% update(formula_spacetime) %>% update(formula_demog) %>% update (formula_comorbs)


## optimisation options ----
parglmparams <- parglm.control(
  method = "LINPACK",
  nthreads = 8,
  maxit = 40 # default = 25
)

plr_process <- function(plrmod, number, cluster, splinetype){

  print(warnings())
  logoutput(
    glue("model{number} data size = ", plrmod$n),
    glue("model{number} memory usage = ", format(object.size(plrmod), units="GB", standard="SI", digits=3L)),
    glue("convergence status: ", plrmod$converged)
  )

  glance <-
    glance_plr(plrmod) %>%
    add_column(
      model = number,
      convergence = plrmod$converged,
      ram = format(object.size(plrmod), units="GB", standard="SI", digits=3L),
      .before=1
    )
  #write_rds(glance, here("output", "models", outcome, timescale, glue("modelplr_glance{number}{splinetype}.rds")), compress="gz")

  tidy <- broom.helpers::tidy_plus_plus(
    plrmod,
    tidy_fun = tidy_plr,
    exponentiate = FALSE,
    cluster = cluster
  ) %>%
  add_column(
    model=number,
    .before=1
  )
  #write_rds(tidy, here("output", "models", outcome, timescale, glue("modelplr_tidy{number}{splinetype}.rds")), compress="gz")

  vcov <- vcovCL(plrmod, cluster = cluster, type = "HC0")
  write_rds(vcov, here("output", "models", outcome, timescale, censor_seconddose, glue("modelplr_vcov{number}{splinetype}.rds")), compress="gz")

  plrmod$data <- NULL
  write_rds(plrmod, here("output", "models", outcome, timescale, censor_seconddose, glue("modelplr_model{number}{splinetype}.rds")), compress="gz")

  lst(glance, tidy)
}


## piecewise estimands ----

# NOTE model fitting and model processing aren't fully wrapped in a function because
# sandwich::vcovCL doesn't handle formulae properly!

## vaccination + timescale only, no adjustment variables
plrmod0 <- parglm(
  formula = formula0_pw,
  data = data_plr,
  weights = sample_weights,
  family = binomial,
  control = parglmparams,
  na.action = "na.fail",
  model = FALSE
)
summary0 <- plr_process(
  plrmod0, 0,
  data_plr$patient_id, "pw"
)
if(removeobs){remove(plrmod0)}


## model 1 - minimally adjusted vaccination effect model, stratification by region only
plrmod1 <- parglm(
  formula = formula1_pw,
  data = data_plr,
  weights = sample_weights,
  family = binomial,
  control = parglmparams,
  na.action = "na.fail",
  model = FALSE
)
summary1 <- plr_process(
  plrmod1, 1,
  data_plr$patient_id, "pw"
)
if(removeobs){remove(plrmod1)}

### model 2 - minimally adjusted vaccination effect model, baseline demographics only
plrmod2 <- parglm(
  formula = formula2_pw,
  data = data_plr,
  weights = sample_weights,
  family = binomial,
  control = parglmparams,
  na.action = "na.fail",
  model = FALSE
)
summary2 <- plr_process(
  plrmod2, 2,
  data_plr$patient_id, "pw"
)
if(removeobs){remove(plrmod2)}

### model 3 - fully adjusted vaccination effect model, baseline demographics + clinical characteristics
plrmod3 <- parglm(
  formula = formula3_pw,
  data = data_plr,
  weights = sample_weights,
  family = binomial,
  control = parglmparams,
  na.action = "na.fail",
  model = FALSE
)
summary3 <- plr_process(
  plrmod3, 3,
  data_plr$patient_id, "pw"
)
if(removeobs){remove(plrmod3)}


### combine results ----
model_glance <- bind_rows(summary0$glance, summary1$glance, summary2$glance, summary3$glance) %>%
  mutate(
    model_name = fct_recode(as.character(model), !!!model_names),
    outcome = outcome
  )
write_csv(model_glance, here::here("output", "models", outcome, timescale, censor_seconddose, glue("modelplr_glance_pw.csv")))

model_tidy <- bind_rows(summary0$tidy, summary1$tidy, summary2$tidy, summary3$tidy) %>%
  mutate(
    model_name = fct_recode(as.character(model), !!!model_names),
    outcome = outcome
  )
write_csv(model_tidy, here::here("output", "models", outcome, timescale, censor_seconddose, glue("modelplr_tidy_pw.csv")))
write_rds(model_tidy, here::here("output", "models", outcome, timescale, censor_seconddose, glue("modelplr_tidy_pw.rds")))

## continuous estimands ----


plrmod0 <- parglm(
  formula = formula0_ns,
  data = data_plr,
  weights = sample_weights,
  family = binomial,
  control = parglmparams,
  na.action = "na.fail",
  model = FALSE
)
summary0 <- plr_process(
  plrmod0, 0,
  data_plr$patient_id, "ns"
)
if(removeobs){remove(plrmod0)}

plrmod1 <- parglm(
  formula = formula1_ns,
  data = data_plr,
  weights = sample_weights,
  family = binomial,
  control = parglmparams,
  na.action = "na.fail",
  model = FALSE
)
summary1 <- plr_process(
  plrmod1, 1,
  data_plr$patient_id, "ns"
)
if(removeobs){remove(plrmod1)}

plrmod2 <- parglm(
  formula = formula2_ns,
  data = data_plr,
  weights = sample_weights,
  family = binomial,
  control = parglmparams,
  na.action = "na.fail",
  model = FALSE
)
summary2 <- plr_process(
  plrmod2, 2,
  data_plr$patient_id, "ns"
)
if(removeobs){remove(plrmod2)}

plrmod3 <- parglm(
  formula = formula3_ns,
  data = data_plr,
  weights = sample_weights,
  family = binomial,
  control = parglmparams,
  na.action = "na.fail",
  model = FALSE
)
summary3 <- plr_process(
  plrmod3, 3,
  data_plr$patient_id, "ns"
)
if(removeobs){remove(plrmod3)}


### combine results ----
model_glance <- bind_rows(summary0$glance, summary1$glance, summary2$glance, summary3$glance) %>%
  mutate(
    model_name = fct_recode(as.character(model), !!!model_names),
    outcome = outcome
  )
write_csv(model_glance, here::here("output", "models", outcome, timescale, censor_seconddose, glue("modelplr_glance_ns.csv")))

model_tidy <- bind_rows(summary0$tidy, summary1$tidy, summary2$tidy, summary3$tidy) %>%
  mutate(
    model_name = fct_recode(as.character(model), !!!model_names),
    outcome = outcome
  )
write_csv(model_tidy, here::here("output", "models", outcome, timescale, censor_seconddose, glue("modelplr_tidy_ns.csv")))
write_rds(model_tidy, here::here("output", "models", outcome, timescale, censor_seconddose, glue("modelplr_tidy_ns.rds")))

## print warnings ----
print(warnings())
cat("  \n")
print(gc(reset=TRUE))



