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

# import globally defined repo variables from
gbl_vars <- jsonlite::fromJSON(
  txt="./analysis/global-variables.json"
)

# output processed data to rds ----

dir.create(here("output", "data"), showWarnings = FALSE, recursive=TRUE)


# process ----

data_extract0 <- read_feather(here("output", "input.feather"))

#convert date-strings to dates
data_extract <- data_extract0 %>%
  mutate(across(
    .cols = ends_with("_date"),
    .fns = as.Date
  )) #%>%
  ## convert 0/1 to TRUE/FALSE
  #mutate(across(
  #  .cols = all_of(c("")),
  #  .fns = ~.==1
  #))



##  SECTION TO SORT OUT BAD DUMMY DATA ----
# this rearranges so events are in date order

data_dates_reordered_long <- data_extract %>%
  select(patient_id, matches("^(.*)_(\\d+)_date")) %>%
  pivot_longer(
    cols = -patient_id,
    names_to = c("event", "index"),
    names_pattern = "^(.*)_(\\d+)_date",
    values_to = "date",
    values_drop_na = TRUE
  ) %>%
  arrange(patient_id, event, date) %>%
  group_by(patient_id, event) %>%
  mutate(
    index = row_number(),
    name = paste0(event,"_",index,"_date")
  ) %>%
  ungroup() %>%
  select(
    patient_id, name, event, index, date
  )

data_dates_reordered_wide <- data_dates_reordered_long %>%
  arrange(name, patient_id) %>%
  pivot_wider(
    id_cols=c(patient_id),
    names_from = name,
    values_from = date
  )

data_extract_reordered <- left_join(
  data_extract %>% select(-matches("^(.*)_(\\d+)_date")),
  data_dates_reordered_wide,
  by="patient_id"
)


data_processed <- data_extract_reordered %>%
  mutate(

    start_date = as.Date(gbl_vars$start_date), # i.e., this is interpreted later as [midnight at the _end of_ the start date] = [midnight at the _start of_ start date + 1], So that for example deaths on start_date+1 occur at t=1, not t=0.
    end_date = as.Date(gbl_vars$end_date),
    censor_date = pmin(end_date, death_date, na.rm=TRUE),

    ageband = cut(
      age,
      breaks=c(-Inf, 18, 30, 40, 50, 60, 65, Inf),
      labels=c("under 18", "18-30", "30s", "40s", "50s", "60-64", "65+"),
      right=FALSE
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


    imd = na_if(imd, "0"),
    imd = fct_case_when(
      imd == 1 ~ "1 most deprived",
      imd == 2 ~ "2",
      imd == 3 ~ "3",
      imd == 4 ~ "4",
      imd == 5 ~ "5 least deprived",
      #TRUE ~ "Unknown",
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
    multimorb = cut(multimorb, breaks = c(0, 1, 2, 3, 4, Inf), labels=c("0", "1", "2", "3", "4+"), right=FALSE),

    cause_of_death = fct_case_when(
      !is.na(coviddeath_date) ~ "covid-related",
      !is.na(death_date) ~ "not covid-related",
      TRUE ~ NA_character_
    ),

    noncoviddeath_date = if_else(!is.na(death_date) & is.na(coviddeath_date), death_date, as.Date(NA_character_))

  ) %>%
  droplevels()

## create one-row-per-event datasets ----
# for vaccination

data_vax <- local({

  data_vax_all <- data_processed %>%
    select(patient_id, matches("covid\\_vax\\_\\d+\\_date")) %>%
    pivot_longer(
      cols = -patient_id,
      names_to = c(NA, "vax_index"),
      names_pattern = "^(.*)_(\\d+)_date",
      values_to = "date",
      values_drop_na = TRUE
    ) %>%
    arrange(patient_id, date)

  data_vax_pf <- data_processed %>%
    select(patient_id, matches("covid\\_vax\\_pfizer\\_\\d+\\_date")) %>%
    pivot_longer(
      cols = -patient_id,
      names_to = c(NA, "vax_pf_index"),
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


  data_vax_all %>%
    left_join(data_vax_pf, by=c("patient_id", "date")) %>%
    left_join(data_vax_az, by=c("patient_id", "date")) %>%
    mutate(
      vaccine_type = fct_case_when(
        !is.na(vax_az_index) & is.na(vax_pf_index) ~ "Ox-AZ",
        is.na(vax_az_index) & !is.na(vax_pf_index) ~ "Pf-BNT",
        is.na(vax_az_index) & is.na(vax_pf_index) ~ "Unknown",
        !is.na(vax_az_index) & !is.na(vax_pf_index) ~ "Both",
        TRUE ~ NA_character_
      )
    ) %>%
    arrange(patient_id, date)

})


write_rds(data_processed, here("output", "data", "data_all.rds"), compress="gz")
write_rds(data_vax, here("output", "data", "data_long_vax_dates.rds"), compress="gz")

