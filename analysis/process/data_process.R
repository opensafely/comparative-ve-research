######################################

# This script:
# imports data extracted by the cohort extractor
# fills in unknown ethnicity from GP records with ethnicity from SUS (secondary care)
# tidies missing values
# re-orders date variables so no negative time differences (only actually does anything for dummy data)
# standardises some variables (eg convert to factor) and derives some new ones
# saves processed one-row-per-patient dataset
# saves one-row-per-patient dataset for vaccines and for hospital admissions

######################################




# Import libraries ----
library('tidyverse')
library('lubridate')
library('arrow')
library('here')

source(here("analysis", "lib", "utility_functions.R"))

# import globally defined repo variables from
gbl_vars <- jsonlite::fromJSON(
  txt="./analysis/global-variables.json"
)

## load A&E diagnosis column names
diagnosis_codes <- jsonlite::fromJSON(
  txt="./analysis/lib/diagnosis_groups.json"
)
diagnosis_col_names <- paste0("emergency_", names(diagnosis_codes), "_date")
diagnosis_short <- str_remove(str_remove(diagnosis_col_names, "emergency_"), "_date")

# output processed data to rds ----

fs::dir_create(here("output", "data"))


# process ----

# use externally created dummy data if not running in the server
# check variables are as they should be
if(Sys.getenv("OPENSAFELY_BACKEND") %in% c("", "expectations")){

  # ideally in future this will check column existence and types from metadata,
  # rather than from a cohort-extractor-generated dummy data

  data_studydef_dummy <- read_feather(here("output", "input.feather")) %>%
    # because date types are not returned consistently by cohort extractor
    mutate(across(ends_with("_date"), ~ as.Date(.))) %>%
    # because of a bug in cohort extractor -- remove once pulled new version
    mutate(patient_id = as.integer(patient_id))

  data_custom_dummy <- read_feather(here("dummydata", "dummyinput.feather"))

  not_in_studydef <- names(data_custom_dummy)[!( names(data_custom_dummy) %in% names(data_studydef_dummy) )]
  not_in_custom  <- names(data_studydef_dummy)[!( names(data_studydef_dummy) %in% names(data_custom_dummy) )]


  if(length(not_in_custom)!=0) stop(
    paste(
      "These variables are in studydef but not in custom: ",
      paste(not_in_custom, collapse=", ")
    )
  )

  if(length(not_in_studydef)!=0) stop(
    paste(
      "These variables are in custom but not in studydef: ",
      paste(not_in_studydef, collapse=", ")
    )
  )

  # reorder columns
  data_studydef_dummy <- data_studydef_dummy[,names(data_custom_dummy)]

  unmatched_types <- cbind(
    map_chr(data_studydef_dummy, ~paste(class(.), collapse=", ")),
    map_chr(data_custom_dummy, ~paste(class(.), collapse=", "))
  )[ (map_chr(data_studydef_dummy, ~paste(class(.), collapse=", ")) != map_chr(data_custom_dummy, ~paste(class(.), collapse=", ")) ), ] %>%
    as.data.frame() %>% rownames_to_column()


  if(nrow(unmatched_types)>0) stop(
    #unmatched_types
    "inconsistent typing in studydef : dummy dataset\n",
    apply(unmatched_types, 1, function(row) paste(paste(row, collapse=" : "), "\n"))
  )

  data_extract <- data_custom_dummy
} else {
  data_extract <- read_feather(here("output", "input.feather")) %>%
    #because date types are not returned consistently by cohort extractor
    mutate(across(ends_with("_date"),  as.Date))
}


data_processed <- data_extract %>%
  mutate(

    start_date = as.Date(gbl_vars$start_date), # i.e., this is interpreted later as [midnight at the _end of_ the start date] = [midnight at the _start of_ start date + 1], So that for example deaths on start_date+1 occur at t=1, not t=0.
    start_date_pfizer = as.Date(gbl_vars$start_date_pfizer),
    start_date_az = as.Date(gbl_vars$start_date_az),
    lastvax_date = as.Date(gbl_vars$lastvax_date),
    end_date = as.Date(gbl_vars$end_date),

    ageband = cut(
      age,
      breaks=c(-Inf, 18, 30, 40, 50, 60, 65, Inf),
      labels=c("under 18", "18-30", "30s", "40s", "50s", "60-64", "65+"),
      right=FALSE
    ),

    sex = fct_case_when(
      sex == "F" ~ "Female",
      sex == "M" ~ "Male",
      #sex == "I" ~ "Inter-sex",
      #sex == "U" ~ "Unknown",
      TRUE ~ NA_character_
    ),

    ethnicity_combined = if_else(is.na(ethnicity), ethnicity_6_sus, ethnicity),

    ethnicity_combined = fct_case_when(
      ethnicity_combined == "1" ~ "White",
      ethnicity_combined == "4" ~ "Black",
      ethnicity_combined == "3" ~ "South Asian",
      ethnicity_combined == "2" ~ "Mixed",
      ethnicity_combined == "5" ~ "Other",
      #TRUE ~ "Unknown",
      TRUE ~ NA_character_

    ),

    region = fct_collapse(
      region,
      `East of England` = "East",
      `London` = "London",
      `Midlands` = c("West Midlands", "East Midlands"),
      `North East and Yorkshire` = c("Yorkshire and The Humber", "North East"),
      `North West` = "North West",
      `South East` = "South East",
      `South West` = "South West"
    ),

    imd = as.integer(as.character(imd)), # imd is a factor, so convert to character then integer to get underlying values
    imd = if_else(imd<=0, NA_integer_, imd),
    imd_Q5 = fct_case_when(
      (imd >=1) & (imd < 32844*1/5) ~ "1 most deprived",
      (imd >= 32844*1/5) & (imd < 32844*2/5) ~ "2",
      (imd >= 32844*2/5) & (imd < 32844*3/5) ~ "3",
      (imd >= 32844*3/5) & (imd < 32844*4/5) ~ "4",
      (imd >= 32844*4/5) ~ "5 least deprived",
      TRUE ~ NA_character_
    ),

    any_immunosuppression = (permanant_immunosuppression | asplenia | dmards | solid_organ_transplantation | sickle_cell_disease | temporary_immunosuppression | bone_marrow_transplant | chemo_or_radio),

    multimorb =
      (bmi %in% c("Obese II (35-39.9)", "Obese III (40+)")) +
      (chronic_cardiac_disease | heart_failure | other_heart_disease) +
      (dialysis) +
      (diabetes) +
      (chronic_liver_disease)+
      (current_copd | other_resp_conditions)+
      (lung_cancer | haematological_cancer | cancer_excl_lung_and_haem)+
      (any_immunosuppression)+
      (dementia | other_neuro_conditions)+
      (LD_incl_DS_and_CP)+
      (psychosis_schiz_bipolar),
    multimorb = cut(multimorb, breaks = c(0, 1, 2, 3, Inf), labels=c("0", "1", "2", "3+"), right=FALSE),

    prior_covid_infection = !is.na(prior_positive_test_date) | !is.na(prior_covidadmitted_date) | !is.na(prior_primary_care_covid_case_date),

    vax1_type = case_when(
      pmin(covid_vax_az_1_date, as.Date("2030-01-01"), na.rm=TRUE) <= pmin(covid_vax_pfizer_1_date, covid_vax_moderna_1_date, as.Date("2030-01-01"), na.rm=TRUE) ~ "az",
      pmin(covid_vax_pfizer_1_date, as.Date("2030-01-01"), na.rm=TRUE) <= pmin(covid_vax_pfizer_1_date, covid_vax_moderna_1_date, as.Date("2030-01-01"), na.rm=TRUE) ~ "pfizer",
      pmin(covid_vax_moderna_1_date, as.Date("2030-01-01"), na.rm=TRUE) <= pmin(covid_vax_pfizer_1_date, covid_vax_az_1_date, as.Date("2030-01-01"), na.rm=TRUE) ~ "moderna",
      TRUE ~ NA_character_
    ),

    vax1_type_descr = fct_case_when(
      vax1_type == "pfizer" ~ "BNT162b2",
      vax1_type == "az" ~ "ChAdOx1",
      vax1_type == "moderna" ~ "Moderna",
      TRUE ~ NA_character_
    ),

    vax1_date = pmin(covid_vax_pfizer_1_date, covid_vax_az_1_date, covid_vax_moderna_1_date, na.rm=TRUE),
    vax1_day = as.integer(floor((vax1_date - start_date_az))+1), # day 0 is the day before "start_date"
    vax1_week = as.integer(floor((vax1_date - start_date_az)/7)+1), # week 1 is days 1-7.

    cause_of_death = fct_case_when(
      !is.na(coviddeath_date) ~ "covid-related",
      !is.na(death_date) ~ "not covid-related",
      TRUE ~ NA_character_
    ),

    covidadmitted_ccdays = as.integer(as.character(covidadmitted_ccdays)), # covidadmitted_ccdays is a factor, so convert to character then integer
    noncoviddeath_date = if_else(!is.na(death_date) & is.na(coviddeath_date), death_date, as.Date(NA_character_)),
    covidcc_date = if_else(!is.na(covidadmitted_date) & covidadmitted_ccdays>0, covidadmitted_date, as.Date(NA_character_))

  ) %>%
  rowwise(patient_id) %>%
  mutate(
    emergency_diagnosis = paste(diagnosis_short[!is.na(c_across(all_of(diagnosis_col_names)))], collapse="; "),
    emergency_diagnosis = if_else(is.na(emergency_date) , "(no admission)", emergency_diagnosis),
    emergency_diagnosis = if_else(!is.na(emergency_date) & emergency_diagnosis %in% c("", NA), "unknown", emergency_diagnosis),

    emergency_unknown_date = if_else(!is.na(emergency_date) & emergency_diagnosis=="unknown", emergency_date, as.Date(NA))
  ) %>%
  ungroup()

data_diagnoses <-
  data_processed %>%
  select(
    patient_id,
    vax1_day,
    vax1_date,
    vax1_type,
    vax1_type_descr,
    end_date, dereg_date, death_date,
    covid_vax_any_2_date,
    starts_with("emergency_"),
    emergency_diagnosis
  )

data_processed <-
  data_processed %>%
  select(-all_of(diagnosis_col_names)) %>%
  droplevels()

## create one-row-per-event datasets ----
# for vaccination
#
# data_vax <- local({
#
#   data_vax_disease <- data_processed %>%
#     select(patient_id, matches("covid\\_vax\\_disease\\d+\\_date")) %>%
#     pivot_longer(
#       cols = -patient_id,
#       names_to = c(NA, "vax_index"),
#       names_pattern = "^(.*)_(\\d+)_date",
#       values_to = "date",
#       values_drop_na = TRUE
#     ) %>%
#     arrange(patient_id, date)
#
#   data_vax_pf <- data_processed %>%
#     select(patient_id, matches("covid\\_vax\\_pfizer\\_\\d+\\_date")) %>%
#     pivot_longer(
#       cols = -patient_id,
#       names_to = c(NA, "vax_pf_index"),
#       names_pattern = "^(.*)_(\\d+)_date",
#       values_to = "date",
#       values_drop_na = TRUE
#     ) %>%
#     arrange(patient_id, date)
#
#   data_vax_az <- data_processed %>%
#     select(patient_id, matches("covid\\_vax\\_az\\_\\d+\\_date")) %>%
#     pivot_longer(
#       cols = -patient_id,
#       names_to = c(NA, "vax_az_index"),
#       names_pattern = "^(.*)_(\\d+)_date",
#       values_to = "date",
#       values_drop_na = TRUE
#     ) %>%
#     arrange(patient_id, date)
#
#   data_vax_moderna <- data_processed %>%
#     select(patient_id, matches("covid\\_vax\\_moderna\\_\\d+\\_date")) %>%
#     pivot_longer(
#       cols = -patient_id,
#       names_to = c(NA, "vax_az_index"),
#       names_pattern = "^(.*)_(\\d+)_date",
#       values_to = "date",
#       values_drop_na = TRUE
#     ) %>%
#     arrange(patient_id, date)
#
#
#   data_vax_disease %>%
#     left_join(data_vax_pf, by=c("patient_id", "date")) %>%
#     left_join(data_vax_az, by=c("patient_id", "date")) %>%
#     left_join(data_vax_moderna, by=c("patient_id", "date")) %>%
#     mutate(
#       vaccine_type = fct_case_when(
#         !is.na(vax_az_index) & is.na(vax_pf_index) & is.na(vax_moderna_index) ~ "Ox-AZ",
#         is.na(vax_az_index) & !is.na(vax_pf_index) & is.na(vax_moderna_index) ~ "Pf-BNT",
#         is.na(vax_az_index) & is.na(vax_pf_index) & !is.na(vax_moderna_index) ~ "Moderna",
#         (is.na(vax_az_index) + is.na(vax_pf_index) + is.na(vax_moderna_index)) >1 ~ "Unknown",
#         !is.na(vax_az_index) & !is.na(vax_pf_index) ~ "Both",
#         TRUE ~ NA_character_
#       )
#     ) %>%
#     arrange(patient_id, date)
#
# })


write_rds(data_diagnoses, here("output", "data", "data_diagnoses.rds"), compress="gz")

write_rds(data_processed, here("output", "data", "data_processed.rds"), compress="gz")

