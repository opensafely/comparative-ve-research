######################################

# This script:
# imports data extracted by the cohort extractor (or dummy data)
# fills in unknown ethnicity from GP records with ethnicity from SUS (secondary care)
# tidies missing values
# standardises some variables (eg convert to factor) and derives some new ones
# organises vaccination date data to "vax X type", "vax X date" (rather than "pfizer X date", "az X date", ...)
######################################




# Import libraries ----
library('tidyverse')
library('lubridate')
library('arrow')
library('here')

source(here("analysis", "lib", "utility_functions.R"))

# import globally defined repo variables from
study_dates <- jsonlite::read_json(
  path=here("output", "data", "metadata_study-dates.json")
)

## load A&E diagnosis column names
diagnosis_codes <- jsonlite::read_json(
  path=here("analysis","lib","diagnosis_groups.json")
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

    start_date = as.Date(study_dates$start_date), # i.e., this is interpreted later as [midnight at the _end of_ the start date] = [midnight at the _start of_ start date + 1], So that for example deaths on start_date+1 occur at t=1, not t=0.
    start_date_pfizer = as.Date(study_dates$start_date_pfizer),
    start_date_az = as.Date(study_dates$start_date_az),
    lastvax_date = as.Date(study_dates$lastvax_date),
    end_date = as.Date(study_dates$end_date),

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

    rural_urban_group = fct_case_when(
      rural_urban %in% c(1,2) ~ "Urban conurbation",
      rural_urban %in% c(3,4) ~ "Urban city or town",
      rural_urban %in% c(5,6,7,8) ~ "Rural town or village",
      TRUE ~ NA_character_
    ),

    multimorb =
      (sev_obesity) +
      (chronic_heart_disease) +
      (chronic_kidney_disease)+
      (diabetes) +
      (chronic_liver_disease)+
      (chronic_resp_disease | asthma)+
      (immunosuppressed | asplenia)+
      (chronic_neuro_disease)#+
      #(learndis)+
      #(sev_mental),
    ,
    multimorb = cut(multimorb, breaks = c(0, 1, 2, Inf), labels=c("0", "1", "2+"), right=FALSE),
    prior_tests_cat = cut(prior_covid_test_frequency, breaks=c(0, 1, 2, 3, Inf), labels=c("0", "1", "2", "3+"), right=FALSE),

    # clinically at-risk group
    cv = immunosuppressed | chronic_kidney_disease | chronic_resp_disease | diabetes | chronic_liver_disease |
      chronic_neuro_disease | chronic_heart_disease | asplenia | learndis | sev_mental,

    prior_covid_infection = !is.na(prior_positive_test_date) | !is.na(prior_covidadmitted_date) | !is.na(prior_primary_care_covid_case_date),

    cause_of_death = fct_case_when(
      !is.na(coviddeath_date) ~ "covid-related",
      !is.na(death_date) ~ "not covid-related",
      TRUE ~ NA_character_
    ),

    emergency_covid_date = pmin(emergency_covid_date, covidadmitted_date, na.rm=TRUE),

    covidadmitted_ccdays = as.integer(as.character(covidadmitted_ccdays)), # covidadmitted_ccdays is a factor, so convert to character then integer
    noncoviddeath_date = if_else(!is.na(death_date) & is.na(coviddeath_date), death_date, as.Date(NA_character_)),
    covidcc_date = if_else(!is.na(covidadmitted_date) & covidadmitted_ccdays>0, covidadmitted_date, as.Date(NA_character_)),

  )


# reshape vaccination data ----

data_vax <- local({

  # data_vax_all <- data_processed %>%
  #   select(patient_id, matches("covid\\_vax\\_\\d+\\_date")) %>%
  #   pivot_longer(
  #     cols = -patient_id,
  #     names_to = c(NA, "vax_index"),
  #     names_pattern = "^(.*)_(\\d+)_date",
  #     values_to = "date",
  #     values_drop_na = TRUE
  #   ) %>%
  #   arrange(patient_id, date)

  data_vax_pfizer <- data_processed %>%
    select(patient_id, matches("covid\\_vax\\_pfizer\\_\\d+\\_date")) %>%
    pivot_longer(
      cols = -patient_id,
      names_to = c(NA, "vax_pfizer_index"),
      names_pattern = "^(.*)_(\\d+)_date",
      values_to = "date",
      values_drop_na = TRUE
    ) %>%
    arrange(patient_id, date)

  data_vax_az <- data_processed %>%
    select(patient_id, matches("covid\\_vax\\_az\\_\\d+\\_date")) %>%
    pivot_longer(
      cols = -patient_id,
      names_to = c(NA, "vax_az_index"),
      names_pattern = "^(.*)_(\\d+)_date",
      values_to = "date",
      values_drop_na = TRUE
    ) %>%
    arrange(patient_id, date)

  data_vax_moderna <- data_processed %>%
    select(patient_id, matches("covid\\_vax\\_moderna\\_\\d+\\_date")) %>%
    pivot_longer(
      cols = -patient_id,
      names_to = c(NA, "vax_moderna_index"),
      names_pattern = "^(.*)_(\\d+)_date",
      values_to = "date",
      values_drop_na = TRUE
    ) %>%
    arrange(patient_id, date)


  data_vax <-
    data_vax_pfizer %>%
    full_join(data_vax_az, by=c("patient_id", "date")) %>%
    full_join(data_vax_moderna, by=c("patient_id", "date")) %>%
    mutate(
      type = fct_case_when(
        (!is.na(vax_az_index)) & is.na(vax_pfizer_index) & is.na(vax_moderna_index) ~ "az",
        is.na(vax_az_index) & (!is.na(vax_pfizer_index)) & is.na(vax_moderna_index) ~ "pfizer",
        is.na(vax_az_index) & is.na(vax_pfizer_index) & (!is.na(vax_moderna_index)) ~ "moderna",
        (!is.na(vax_az_index)) + (!is.na(vax_pfizer_index)) + (!is.na(vax_moderna_index)) > 1 ~ "duplicate",
        TRUE ~ NA_character_
      )
    ) %>%
    arrange(patient_id, date) %>%
    group_by(patient_id) %>%
    mutate(
      vax_index=row_number()
    ) %>%
    ungroup()

  data_vax

})

data_vax_wide = data_vax %>%
  pivot_wider(
    id_cols= patient_id,
    names_from = c("vax_index"),
    values_from = c("date", "type"),
    names_glue = "covid_vax_{vax_index}_{.value}"
  )

data_processed <- data_processed %>%
  left_join(data_vax_wide, by ="patient_id") %>%
  mutate(
    vax1_type = covid_vax_1_type,
    vax2_type = covid_vax_2_type,

    vax1_type_descr = fct_case_when(
      vax1_type == "pfizer" ~ "BNT162b2",
      vax1_type == "az" ~ "ChAdOx1",
      vax1_type == "moderna" ~ "Moderna",
      TRUE ~ NA_character_
    ),
    vax2_type_descr = fct_case_when(
      vax2_type == "pfizer" ~ "BNT162b2",
      vax2_type == "az" ~ "ChAdOx1",
      vax2_type == "moderna" ~ "Moderna",
      TRUE ~ NA_character_
    ),

    vax1_date = covid_vax_1_date,
    vax2_date = covid_vax_2_date,
    vax1_day = as.integer(floor((vax1_date - start_date_az))+1), # day 0 is the day before "start_date"
    vax2_day = as.integer(floor((vax2_date - start_date_az))+1), # day 0 is the day before "start_date"
    vax1_week = as.integer(floor((vax1_date - start_date_az)/7)+1), # week 1 is days 1-7.
    vax2_week = as.integer(floor((vax2_date - start_date_az)/7)+1), # week 1 is days 1-7.
) %>%
select(
  -starts_with("covid_vax_"),
  -any_of(diagnosis_col_names[diagnosis_col_names!="emergency_covid_date"]) # remove non-covid a&e
)


write_rds(data_processed, here("output", "data", "data_processed.rds"), compress="gz")

