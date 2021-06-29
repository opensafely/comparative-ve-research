

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

# output processed data to rds ----

dir.create(here("output", "data"), showWarnings = FALSE, recursive=TRUE)


# import data ----
data_extract0 <- read_feather(here("output", "input_hcw.feather"))

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


data_processed <- data_extract %>%
  mutate(

    start_date = as.Date(gbl_vars$start_date), # i.e., this is interpreted later as [midnight at the _end of_ the start date] = [midnight at the _start of_ start date + 1], So that for example deaths on start_date+1 occur at t=1, not t=0.
    start_date_pfizer = as.Date(gbl_vars$start_date_pfizer),
    start_date_az = as.Date(gbl_vars$start_date_az),
    end_date = as.Date(gbl_vars$end_date),

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

    # vax1_type = fct_case_when(
    #   covid_vax_any_1_date == covid_vax_pfizer_1_date ~ "pfizer",
    #   covid_vax_any_1_date == covid_vax_az_1_date ~ "az",
    #   covid_vax_any_1_date == covid_vax_moderna_1_date ~ "moderna",
    #   is.na(covid_vax_any_1_date) & !is.na(covid_vax_disease_1_date) ~ "unknown",
    #   is.na(covid_vax_disease_1_date) ~ "unvaccinated",
    #   TRUE ~ NA_character_
    # ),
    #
    # vax2_type = fct_case_when(
    #   covid_vax_any_2_date == covid_vax_pfizer_2_date ~ "pfizer",
    #   covid_vax_any_2_date == covid_vax_az_2_date ~ "az",
    #   covid_vax_any_2_date == covid_vax_moderna_2_date ~ "moderna",
    #   is.na(covid_vax_any_2_date) & !is.na(covid_vax_disease_2_date) ~ "unknown",
    #   is.na(covid_vax_disease_2_date) ~ "no second dose",
    #   TRUE ~ NA_character_
    # ),

    vax1_date = covid_vax_any_1_date,
    vax1_day = as.integer(floor((vax1_date - start_date))+1),
    vax1_week = as.integer(floor((vax1_date - start_date)/7)+1),

    cause_of_death = fct_case_when(
      !is.na(coviddeath_date) ~ "covid-related",
      !is.na(death_date) ~ "not covid-related",
      TRUE ~ NA_character_
    ),
    noncoviddeath_date = if_else(!is.na(death_date) & is.na(coviddeath_date), death_date, as.Date(NA_character_)),

  ) %>%
  droplevels()

## create one-row-per-event datasets ----
# for vaccination

data_vax <- local({

  data_vax_disease <- data_processed %>%
    select(patient_id, matches("covid\\_vax\\_disease\\_\\d+\\_date")) %>%
    pivot_longer(
      cols = -patient_id,
      names_to = c(NA, "vax_disease_index"),
      names_pattern = "^(.*)_(\\d+)_date",
      values_to = "date",
      values_drop_na = TRUE
    ) %>%
    select(patient_id, date, vax_disease_index) %>%
    arrange(patient_id, date)

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


  data_vax <- data_vax_disease %>%
    full_join(data_vax_pfizer, by=c("patient_id", "date")) %>%
    full_join(data_vax_az, by=c("patient_id", "date")) %>%
    full_join(data_vax_moderna, by=c("patient_id", "date")) %>%
    mutate(
      vaccine_type = fct_case_when(
        !is.na(vax_az_index) & is.na(vax_pfizer_index) & is.na(vax_moderna_index) ~ "az",
        is.na(vax_az_index) & !is.na(vax_pfizer_index) & is.na(vax_moderna_index) ~ "pfizer",
        is.na(vax_az_index) & is.na(vax_pfizer_index) & !is.na(vax_moderna_index) ~ "moderna",
        !is.na(vax_az_index) + !is.na(vax_pfizer_index) + !is.na(vax_moderna_index) > 1 ~ "unclear",
        #(is.na(vax_az_index) + is.na(vax_pfizer_index) + is.na(vax_moderna_index))==3  ~ "unknown",
        TRUE ~ NA_character_
      )
    ) %>%
    arrange(patient_id, date)

  data_vax

})


write_rds(data_processed, here("output", "data", "hcw_data_processed.rds"), compress="gz")
write_rds(data_vax, here("output", "data", "hcw_data_vax.rds"), compress="gz")

