
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
formula_demog <- . ~ . + poly(age, degree=2, raw=TRUE) + sex + imd_Q5 + ethnicity_combined
formula_comorbs <- . ~ . +
  bmi +
  prior_covid_infection +
  #heart_failure +
  #other_heart_disease +

  #dialysis +
  #diabetes +
  #chronic_liver_disease +

  #current_copd +
  #cystic_fibrosis +
  #other_resp_conditions +

  #lung_cancer +
  #haematological_cancer +
  #cancer_excl_lung_and_haem +

  #chemo_or_radio +
  #solid_organ_transplantation +
  #bone_marrow_transplant +
  #sickle_cell_disease +
  #permanant_immunosuppression +
  #temporary_immunosuppression +
  #asplenia +
  #dmards +
  #any_immunosuppression +

  #other_neuro_conditions +

  #LD_incl_DS_and_CP +
  psychosis_schiz_bipolar +

  multimorb

formula_region <- . ~ . + region
formula_secular <- . ~ . + ns(tstop, df=4)
formula_secular_region <- . ~ . + ns(tstop, df=4)*region


formula_all_rhsvars <- update(1 ~ 1, formula_exposure) %>%
  update(formula_demog) %>%
  update(formula_comorbs) %>%
  update(formula_secular) %>%
  update(formula_secular_region)

postvaxcuts <- c(0, 7, 14, 21, 28, 35)

list_formula <- lst(
  formula_exposure,
  formula_demog,
  formula_comorbs,
  formula_secular,
  formula_secular_region,
  formula_all_rhsvars,
  postvaxcuts
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
  stp ~ "STP",
  vax1_day ~ "Day of vaccination",

  bmi ~ "Body Mass Index",

  heart_failure ~ "Heart failure",
  other_heart_disease ~ "Other heart disease",

  dialysis ~ "Dialysis",
  diabetes ~ "Diabetes",
  chronic_liver_disease ~ "Chronic liver disease",

  current_copd ~ "COPD",
  #cystic_fibrosis ~ "Cystic fibrosis",
  other_resp_conditions ~ "Other respiratory conditions",

  lung_cancer ~ "Lung Cancer",
  haematological_cancer ~ "Haematological cancer",
  cancer_excl_lung_and_haem ~ "Cancer excl. lung, haemo",

  #chemo_or_radio ~ "Chemo- or radio-therapy",
  #solid_organ_transplantation ~ "Solid organ transplant",
  #bone_marrow_transplant ~ "Bone marrow transplant",
  #sickle_cell_disease ~ "Sickle Cell Disease",
  #permanant_immunosuppression ~ "Permanent immunosuppression",
  #temporary_immunosuppression ~ "Temporary Immunosuppression",
  #asplenia ~ "Asplenia",
  #dmards ~ "DMARDS",

  any_immunosuppression ~ "Immunosuppressed",

  other_neuro_conditions ~ "Other neurological conditions",

  LD_incl_DS_and_CP ~ "Learning disabilities",
  psychosis_schiz_bipolar ~ "Serious mental illness",

  multimorb ~ "Morbidity count",

  prior_covid_infection ~ "Prior SARS-CoV-2 infection"

) %>%
  set_names(., map_chr(., all.vars))

write_rds(var_labels, here("output", "data", "metadata_labels.rds"))
