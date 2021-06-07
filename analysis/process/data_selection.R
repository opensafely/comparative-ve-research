
# # # # # # # # # # # # # # # # # # # # #
# This script:
# imports processed data
# creates indicator variables for each potential cohort/outcome combination of interest
# creates a metadata df that describes each cohort
# # # # # # # # # # # # # # # # # # # # #

# Preliminaries ----

## Import libraries ----
library('tidyverse')
library('here')
library('glue')

## import command-line arguments ----
args <- commandArgs(trailingOnly=TRUE)

## create output directories ----
dir.create(here("output", "data"), showWarnings = FALSE, recursive=TRUE)

## Import processed data ----

data_processed <- read_rds(here("output", "data", "data_processed.rds"))

data_criteria <- data_processed %>%
  mutate(
    patient_id,
    has_age = !is.na(age),
    has_sex = !is.na(sex),
    has_imd = !is.na(imd),
    has_ethnicity = !is.na(ethnicity_combined),
    has_region = !is.na(region),
    has_follow_up_previous_year,
    no_prior_vaccine = (is.na(prior_covid_vax_date) & is.na(prior_covid_vax_pfizer_date) & is.na(prior_covid_vax_az_date)),
    no_prior_covid = (is.na(prior_positive_test_date) & is.na(prior_primary_care_covid_case_date) & is.na(prior_covidadmitted_date)),
    not_cev = !cev,
    vax1_4janonwards = vax1_date>=as.Date("04-01-2021"),

    include = (
      has_age & has_sex & has_imd & has_ethnicity & has_region &
        has_follow_up_previous_year &
        !unknown_vaccine_brand &
        no_prior_vaccine &
        no_prior_covid &
        not_cev
    ),
  )

data_cohort <- data_criteria %>% filter(include)
write_rds(data_cohort, here("output", "data", "data_cohort.rds"), compress="gz")

data_flowchart <- data_criteria %>%
  transmute(
    c0_all = TRUE,
    c1_1yearfup = c0_all & (has_follow_up_previous_year),
    c2_notmissing = c1_1yearfup & (has_age & has_sex & has_imd & has_ethnicity & has_region),
    c3_notcev = c2_notmissing & not_cev,
    c4_nopriorcovid = c3_notcev & (no_prior_covid),
    c5_nopriorvaccine = c4_nopriorcovid & (no_prior_vaccine),
    c6_knownbrand = c5_nopriorvaccine & (!unknown_vaccine_brand),
    c7_4jan = c6_knownbrand & vax1_4janonwards
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
write_csv(data_flowchart, here("output", "data", "flowchart.csv"))


data_cohort %>%
  select(
    patient_id,
    age,
    sex,
    imd,
    ethnicity_combined,
    region,
    vax1_day,
    vax1_date,
    vax1_type
  ) %>%
  split(.$vax1_type) %>%
  iwalk(~write_csv(.x, here("output", "data", glue("data_vax_{.y}_only_withoutdate.csv"))))



data_cohort %>%
  filter(vax1_4janonwards) %>%
  select(
    patient_id,
    age,
    sex,
    imd,
    ethnicity_combined,
    region,
    vax1_day,
    vax1_date,
    vax1_type
  ) %>%
  split(.$vax1_type) %>%
  iwalk(~write_csv(.x, here("output", "data", glue("data_vax_{.y}_only_withdate.csv"))))


