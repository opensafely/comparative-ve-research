
# # # # # # # # # # # # # # # # # # # # #
# This script:
# creates metadata for aspects of the study design
# # # # # # # # # # # # # # # # # # # # #

# Preliminaries ----

## Import libraries ----
library('tidyverse')
library('here')
## create output directories ----
fs::dir_create(here("output", "data"))

## Import processed data ----

# define different outcomes ----

metadata_outcomes <- tribble(
  ~outcome, ~outcome_var, ~outcome_descr,
  "test", "covid_test_date", "SARS-CoV-2 test",
  "postest", "positive_test_date", "Positive SARS-CoV-2 test",
  "emergency", "emergency_date", "A&E attendance",
  "admitted", "admitted_date", "Unplanned hospitalisation",
  "covidadmitted", "covidadmitted_date", "COVID-19 hospitalisation",
  "covidcc", "covidcc_date", "COVID-19 critical care",
  "coviddeath", "coviddeath_date", "COVID-19 death",
  "noncoviddeath", "noncoviddeath_date", "Non-COVID-19 death",
  "death", "death_date", "Any death",
)

write_rds(metadata_outcomes, here("output", "data", "metadata_outcomes.rds"))

# define exposures and covariates ----

formula_exposure <- . ~ . + timesincevax_pw
#formula_demog <- . ~ . + age + I(age * age) + sex + imd + ethnicity
formula_demog <- . ~ . + poly(age, degree=2, raw=TRUE) + sex + imd_Q5 + ethnicity_combined + rural_urban_group
formula_comorbs <- . ~ . +
  prior_covid_infection +
  multimorb +
  learndis +
  sev_mental

formula_region <- . ~ . + region
formula_secular <- . ~ . + ns(tstop, df=4)
formula_secular_region <- . ~ . + ns(tstop, df=4)*region


formula_all_rhsvars <- update(1 ~ 1, formula_exposure) %>%
  update(formula_demog) %>%
  update(formula_comorbs) %>%
  update(formula_secular) %>%
  update(formula_secular_region)

postvaxcuts <- c(0, 7, 14, 21, 28, 35, 42, 70)
postvaxcuts_2week <- c(0, 14, 28, 42, 70, 84, 98)

lastfupday <- 14*7


list_formula <- lst(
  formula_exposure,
  formula_demog,
  formula_comorbs,
  formula_secular,
  formula_secular_region,
  formula_all_rhsvars,
  postvaxcuts,
  postvaxcuts_2week,
  lastfupday
)

write_rds(list_formula, here("output", "data", "metadata_formulas.rds"))


## variable labels
var_labels <- list(
  vax1_type ~ "Vaccine type",
  vax1_type_descr ~ "Vaccine type",
  age ~ "Age",
  ageband ~ "Age",
  sex ~ "Sex",
  ethnicity_combined ~ "Ethnicity",
  imd_Q5 ~ "IMD",
  region ~ "Region",
  rural_urban_group ~ "Rural/urban category",
  stp ~ "STP",
  vax1_day ~ "Day of vaccination",

  sev_obesity ~ "Body Mass Index > 40 kg/m^2",

  chronic_heart_disease ~ "Chronic heart disease",
  chronic_kidney_disease ~ "Chronic kidney disease",
  diabetes ~ "Diabetes",
  chronic_liver_disease ~ "Chronic liver disease",
  chronic_resp_disease ~ "Chronic respiratory disease",
  chronic_neuro_disease ~ "Chronic neurological disease",
  immunosuppressed ~ "Immunosuppressed",
  asplenia ~ "Asplenia or poor spleen function",

  learndis ~ "Learning disabilities",
  sev_mental ~ "Serious mental illness",

  multimorb ~ "Morbidity count",

  prior_covid_infection ~ "Prior SARS-CoV-2 infection"

) %>%
  set_names(., map_chr(., all.vars))

write_rds(var_labels, here("output", "data", "metadata_labels.rds"))

