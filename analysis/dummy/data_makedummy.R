
library('tidyverse')
library('here')
library('glue')
library('simstudy')
library('arrow')
source(here("analysis", "lib", "utility_functions.R"))

population_size <- 1000

# import globally defined repo variables from
gbl_vars <- jsonlite::fromJSON(
  txt="./analysis/global-variables.json"
)


index_date <- as.Date(gbl_vars$start_date)
start_date_pfizer <- as.Date(gbl_vars$start_date_pfizer)
start_date_az <- as.Date(gbl_vars$start_date_az)
end_date <- as.Date(gbl_vars$end_date)
#censor_date <- pmin(end_date, dereg_date, death_date, na.rm=TRUE)

pfizer_day <- as.integer(start_date_pfizer - index_date)
az_day <- as.integer(start_date_az - index_date)
end_day <- as.integer(end_date - index_date)

def <-
  defData(varname = "prior_covid_vax_pfizer_day", dist = "uniformInt", formula = "-100; -1", id="patient_id") %>%
  defData(varname = "covid_vax_pfizer_1_day", dist = "uniformInt", formula = "pfizer_day; pfizer_day + 120") %>%
  defData(varname = "covid_vax_pfizer_2_day", dist = "uniformInt", formula = "covid_vax_pfizer_1_day + 80; covid_vax_pfizer_1_day + 100") %>%
  defData(varname = "prior_covid_vax_az_day", dist = "uniformInt", formula = "-100; -1") %>%
  defData(varname = "covid_vax_az_1_day", dist = "uniformInt", formula = "az_day; az_day + 120") %>%
  defData(varname = "covid_vax_az_2_day", dist = "uniformInt", formula = "covid_vax_az_1_day + 80; covid_vax_az_1_day + 100") %>%
  defData(varname = "prior_covid_vax_day", dist = "uniformInt", formula = "-100; -1") %>%
  defData(varname = "covid_vax_1_day", dist = "nonrandom", formula = "pmin(covid_vax_pfizer_1_day, covid_vax_az_1_day)") %>%
  defData(varname = "covid_vax_2_day", dist = "nonrandom", formula = "pmin(covid_vax_pfizer_2_day, covid_vax_az_2_day)") %>%

  defData(varname = "has_follow_up_previous_year", dist = "binary", formula = "0.999") %>%
  defData(varname = "dereg_day", dist = "uniformInt", formula = "1; end_day") %>%

  defData(varname = "age", dist = "normal", formula = 40, variance = 15) %>%
  defData(varname = "sex", dist = "categorical", formula = "0.5; 0.5") %>%
  defData(varname = "bmi", dist = "categorical", formula = "0.7; 0.1; 0.1; 0.1") %>%
  defData(varname = "ethnicity", dist = "categorical", formula = "0.2; 0.2; 0.2; 0.2; 0.2") %>%
  defData(varname = "ethnicity_6_sus", dist = "categorical", formula = "0.2; 0.2; 0.2; 0.2; 0.2") %>%

  defData(varname = "practice_id", dist = "uniformInt", formula = "1; 1000") %>%
  defData(varname = "msoa", dist = "uniformInt", formula = "1; 1000") %>%
  defData(varname = "stp", dist = "uniformInt", formula = "1; 36") %>%
  defData(varname = "region", dist = "uniformInt", formula = "1; 8") %>%
  defData(varname = "imd", dist = "uniformInt", formula = "1; 32000") %>%
  defData(varname = "rural_urban", dist = "uniformInt", formula = "1; 9") %>%

  defData(varname = "prior_positive_test_day", dist = "uniformInt", formula = "-100; -1") %>%
  defData(varname = "prior_primary_care_covid_case_day", dist = "uniformInt", formula = "-100; -1") %>%
  defData(varname = "prior_covidadmitted_day", dist = "uniformInt", formula = "-100; -1") %>%
  defData(varname = "prior_covid_test_day", dist = "uniformInt", formula = "-100; -1") %>%

  defData(varname = "covid_test_day", dist = "uniformInt", formula = "covid_vax_1_day; covid_vax_1_day + 200") %>%

  defData(varname = "positive_test_day", dist = "uniformInt", formula = "covid_vax_1_day; covid_vax_1_day + 200") %>%
  defData(varname = "emergency_day", dist = "uniformInt", formula = "covid_vax_1_day; covid_vax_1_day + 200") %>%
  defData(varname = "covidadmitted_day", dist = "uniformInt", formula = "covid_vax_1_day; covid_vax_1_day + 200") %>%
  defData(varname = "covidadmitted_ccdays", dist = "uniformInt", formula = "0; 1") %>%
  defData(varname = "death_day", dist = "uniformInt", formula = "1; end_day") %>%
  defData(varname = "coviddeath_day", dist = "nonrandom", formula = "if_else(runif(length(death_day))<0.2, death_day, NA_integer_)") %>%

  defData(varname = "chronic_cardiac_disease", dist = "binary", formula = 0.05) %>%
  defData(varname = "heart_failure", dist = "binary", formula = 0.05) %>%
  defData(varname = "other_heart_disease", dist = "binary", formula = 0.05) %>%
  defData(varname = "diabetes", dist = "binary", formula = 0.05) %>%
  defData(varname = "dialysis", dist = "binary", formula = 0.05) %>%
  defData(varname = "chronic_liver_disease", dist = "binary", formula = 0.05) %>%
  defData(varname = "current_copd", dist = "binary", formula = 0.05) %>%
  defData(varname = "LD_incl_DS_and_CP", dist = "binary", formula = 0.05) %>%
  defData(varname = "cystic_fibrosis", dist = "binary", formula = 0.05) %>%
  defData(varname = "other_resp_conditions", dist = "binary", formula = 0.05) %>%
  defData(varname = "lung_cancer", dist = "binary", formula = 0.05) %>%
  defData(varname = "haematological_cancer", dist = "binary", formula = 0.05) %>%
  defData(varname = "cancer_excl_lung_and_haem", dist = "binary", formula = 0.05) %>%
  defData(varname = "chemo_or_radio", dist = "binary", formula = 0.05) %>%
  defData(varname = "solid_organ_transplantation", dist = "binary", formula = 0.05) %>%
  defData(varname = "bone_marrow_transplant", dist = "binary", formula = 0.05) %>%
  defData(varname = "sickle_cell_disease", dist = "binary", formula = 0.05) %>%
  defData(varname = "permanant_immunosuppression", dist = "binary", formula = 0.05) %>%
  defData(varname = "temporary_immunosuppression", dist = "binary", formula = 0.05) %>%
  defData(varname = "asplenia", dist = "binary", formula = 0.05) %>%
  defData(varname = "dmards", dist = "binary", formula = 0.05) %>%
  defData(varname = "dementia", dist = "binary", formula = 0.05) %>%
  defData(varname = "other_neuro_conditions", dist = "binary", formula = 0.05) %>%
  defData(varname = "psychosis_schiz_bipolar", dist = "binary", formula = 0.05) %>%
  defData(varname = "cev_ever", dist = "binary", formula = 0.02) %>%
  defData(varname = "cev", dist = "binary", formula = 0.02)

dummy_data_raw <- genData(population_size, def, id = "patient_id")

defm <-
  defMiss(varname = "prior_covid_vax_pfizer_day", formula = 0.999) %>%
  defMiss(varname = "covid_vax_pfizer_1_day", formula = "covid_vax_az_1_day<covid_vax_pfizer_1_day") %>%
  defMiss(varname = "covid_vax_pfizer_2_day", formula = "if_else(covid_vax_az_1_day<covid_vax_pfizer_1_day, 1, 0.2)") %>%
  defMiss(varname = "prior_covid_vax_az_day", formula = 0.999) %>%
  defMiss(varname = "covid_vax_az_1_day", formula = "covid_vax_az_1_day>=covid_vax_pfizer_1_day") %>%
  defMiss(varname = "covid_vax_az_2_day", formula = "if_else(covid_vax_az_1_day>=covid_vax_pfizer_1_day, 1, 0.2)") %>%
  defMiss(varname = "prior_covid_vax_day", formula = 0.999) %>%
  defMiss(varname = "covid_vax_2_day", formula = 0.2) %>%
  defMiss(varname = "dereg_day", formula = 0.95) %>%

  defMiss(varname = "sex", formula = 0.001) %>%
  defMiss(varname = "ethnicity", formula = 0.25) %>%
  defMiss(varname = "ethnicity_6_sus", formula = 0.2) %>%
  defMiss(varname = "prior_positive_test_day", formula = 0.95) %>%
  defMiss(varname = "prior_primary_care_covid_case_day", formula = 0.95) %>%
  defMiss(varname = "prior_covidadmitted_day", formula = 0.98) %>%
  defMiss(varname = "prior_covid_test_day", formula = 0.50) %>%

  defMiss(varname = "covid_test_day", formula = 0.40) %>%
  defMiss(varname = "positive_test_day", formula = 0.90) %>%
  defMiss(varname = "emergency_day", formula = 0.90) %>%
  defMiss(varname = "covidadmitted_day", formula = 0.94) %>%
  defMiss(varname = "covidadmitted_ccdays", formula = "if_else(is.na(covidadmitted_day), 1, 0)") %>%
  defMiss(varname = "death_day", formula = 0.99) %>%
  defMiss(varname = "coviddeath_day", formula = "if_else(is.na(death_day), 1, 0)")



missmatt <- genMiss(dummy_data_raw, defm, idvars = "patient_id")

dummy_data_withmissing <- genObs(dummy_data_raw, missmatt, idvars = "patient_id")

dummy_data_processed <- dummy_data_withmissing %>%
  mutate(across(ends_with("_day"), ~ as.character(index_date + .))) %>%
  rename_with(~str_replace(., "_day", "_date"), ends_with("_day")) %>%
  mutate(
    age = as.integer(round(age, 0)),
    sex = fct_case_when(
      sex == 1 ~ "Female",
      sex == 2 ~ "Male",
      TRUE ~ NA_character_
    ),
    bmi = fct_case_when(
      bmi == 1 ~ "Not obese",
      bmi == 2 ~ "Obese I (30-34.9)",
      bmi == 3 ~ "Obese II (35-39.9)",
      bmi == 4 ~ "Obese III (40+)",
      TRUE ~ NA_character_
    ),

    imd = factor(plyr::round_any(imd, 100)),

    region = fct_case_when(
      region == 1 ~ "North East",
      region == 2 ~ "North West",
      region == 3 ~ "Yorkshire and the Humber",
      region == 4 ~ "East Midlands",
      region == 5 ~ "West Midlands",
      region == 6 ~ "East of England",
      region == 7 ~ "London",
      region == 8 ~ "South East",
      region == 9 ~ "South West",
      TRUE ~ NA_character_
    ),

    ethnicity = factor(ethnicity),
    ethnicity_6_sus = factor(ethnicity_6_sus),
    msoa = factor(msoa),
    stp = factor(stp),
    rural_urban = factor(rural_urban),


  )


write_feather(dummy_data_processed, sink = here("dummydata", "dummyinput.feather"))
