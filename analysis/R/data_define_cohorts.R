
# # # # # # # # # # # # # # # # # # # # #
# This script:
# imports processed data
# creates indicator variables for each potential cohort/outcome combination of interest
# creates a metadata df that describes each cohort
# # # # # # # # # # # # # # # # # # # # #

# Preliminaries ----

## Import libraries ----
library('tidyverse')

## create output directories ----
dir.create(here::here("output", "data"), showWarnings = FALSE, recursive=TRUE)

## Import processed data ----

data_all <- read_rds(here::here("output", "data", "data_all.rds"))

data_criteria <- data_all %>%
  transmute(
    patient_id,
    has_age = !is.na(age),
    has_sex = !is.na(sex),
    has_imd = !is.na(imd),
    has_ethnicity = !is.na(ethnicity_combined),
    has_region = !is.na(region),
    has_follow_up_previous_year,
    unknown_vaccine_brand,
    care_home_combined,
    endoflife,
    nopriorcovid = (is.na(prior_positive_test_date) & is.na(prior_primary_care_covid_case_date) & is.na(prior_covidadmitted_date)),

    include = (
      has_age & has_sex & has_imd & has_ethnicity & has_region &
      has_follow_up_previous_year &
      !unknown_vaccine_brand &
      !care_home_combined &
      !endoflife &
      nopriorcovid
    ),

    is_over70s = age>=70 & has_age,
    is_over80s = age>=80 & has_age,
    is_in70s = (age>=70 & age<80) & has_age,
    is_under65s = (age<=64) & has_age,
  )

data_cohorts <- data_criteria %>%
  transmute(
    patient_id,
    over70s = include & is_over70s,
    over80s = include & is_over80s,
    in70s = include & is_in70s,
    under65s = include & is_under65s,
  )


# define different cohorts ----

metadata_cohorts <- tribble(
  ~cohort, ~cohort_descr, #~postvax_cuts, ~knots,
  "over70s", "Aged 70+, non-carehome, no prior infection",
  "over80s", "Aged 80+, non-carehome, no prior infection",
  "in70s", "Aged 70-79, non-carehome, no prior infection",
  "under65s", "Aged <=64, no prior infection",
) %>%
mutate(
  cohort_size = map_int(cohort, ~sum(data_cohorts[[.]]))
)

metadata_cohorts %>% select(cohort, cohort_size) %>% print(n=100)

stopifnot("cohort names should match" = names(data_cohorts)[-1] == metadata_cohorts$cohort)
stopifnot("all cohorts should contain at least 1 patient" = all(metadata_cohorts$cohort_size>0))


## Save processed data ----
write_rds(data_cohorts, here::here("output", "data", "data_cohorts.rds"))
write_rds(metadata_cohorts, here::here("output", "data", "metadata_cohorts.rds"))
write_csv(metadata_cohorts, here::here("output", "data", "metadata_cohorts.csv"))



## create flowchart data ----

for(cohort in metadata_cohorts$cohort){


  data_flowchart <- data_criteria[data_criteria[[paste0("is_",cohort)]], ] %>%
    transmute(
      c0_all = TRUE,
      c1_1yearfup = c0_all & (has_follow_up_previous_year),
      c2_notmissing = c1_1yearfup & (has_age & has_sex & has_imd & has_ethnicity & has_region),
      c3_knownbrand = c2_notmissing & (!unknown_vaccine_brand),
      c4_noncarehome = c3_knownbrand & (!care_home_combined),
      c5_nonendoflife = c4_noncarehome & (!endoflife),
      c6_nopriorcovid = c5_nonendoflife & (nopriorcovid),
    ) %>%
    summarise(
      across(.fns=sum)
    ) %>%
    pivot_longer(
      cols=everything(),
      names_to="criteria",
      values_to="n"
    ) %>%
    mutate(
      n_exclude = lag(n) - n,
      pct_exclude = n_exclude/lag(n),
      pct_all = n / first(n),
      pct_step = n / lag(n),
    )

  write_csv(data_flowchart, here::here("output", "data", glue::glue("flowchart_{cohort}.csv")))

}


# define different outcomes ----

metadata_outcomes <- tribble(
  ~outcome, ~outcome_var, ~outcome_descr,
  "test", "covid_test_1_date", "Covid test",
  "postest", "positive_test_1_date", "Positive test",
  "emergency", "emergency_1_date", "A&E attendance",
  "covidadmitted", "covidadmitted_1_date", "COVID-related admission",
  "coviddeath", "coviddeath_date", "COVID-related death",
  "noncoviddeath", "noncoviddeath_date", "Non-COVID-related death",
  "death", "death_date", "Any death",
  "vaccine", "covid_vax_1_date", "First vaccination date"
)

write_rds(metadata_outcomes, here::here("output", "data", "metadata_outcomes.rds"))

# define exposures and covariates ----

formula_exposure <- . ~ . + timesincevax_pw
#formula_demog <- . ~ . + age + I(age * age) + sex + imd + ethnicity
formula_demog <- . ~ . + poly(age, degree=2, raw=TRUE) + sex + imd + ethnicity_combined
formula_comorbs <- . ~ . +
  bmi +
  heart_failure +
  other_heart_disease +

  dialysis +
  diabetes +
  chronic_liver_disease +

  current_copd +
  #cystic_fibrosis +
  other_resp_conditions +

  lung_cancer +
  haematological_cancer +
  cancer_excl_lung_and_haem +

  #chemo_or_radio +
  #solid_organ_transplantation +
  #bone_marrow_transplant +
  #sickle_cell_disease +
  #permanant_immunosuppression +
  #temporary_immunosuppression +
  #asplenia +
  #dmards +
  any_immunosuppression +

  dementia +
  other_neuro_conditions +

  LD_incl_DS_and_CP +
  psychosis_schiz_bipolar +

  multimorb +

  shielded +

  flu_vaccine +

  efi_cat


formula_region <- . ~ . + region
formula_secular <- . ~ . + ns(tstop, df=4)
formula_secular_region <- . ~ . + ns(tstop, df=4)*region

formula_timedependent <- . ~ . +
  #timesince_probable_covid_pw +
  timesince_postesttdc_pw +
  timesince_suspectedcovid_pw +
  timesince_hospinfectiousdischarge_pw +
  timesince_hospnoninfectiousdischarge_pw


formula_all_rhsvars <- update(1 ~ 1, formula_exposure) %>%
  update(formula_demog) %>%
  update(formula_comorbs) %>%
  update(formula_secular) %>%
  update(formula_secular_region) %>%
  update(formula_timedependent)

postvaxcuts <- c(0, 3, 7, 14, 21, 28)

list_formula <- lst(
  formula_exposure,
  formula_demog,
  formula_comorbs,
  formula_secular,
  formula_secular_region,
  formula_timedependent,
  formula_all_rhsvars,
  postvaxcuts
)

write_rds(list_formula, here::here("output", "data", glue::glue("list_formula.rds")))



## define stratification variables ----

list_strata <- data_all %>%
  mutate(
    all=factor("all")
  ) %>%
  select(
    all, sex
  ) %>%
  lapply(levels)

write_rds(list_strata, here::here("output", "data", glue::glue("list_strata.rds")))
