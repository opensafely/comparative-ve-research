
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

data_cohort <- read_rds(here("output", "data", "data_cohort.rds"))

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
  iwalk(~write_csv(.x, here("output", "data", glue("data_vax_{.y}_withoutdate.csv"))))



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
  iwalk(~write_csv(.x, here("output", "data", glue("data_vax_{.y}_withdate.csv"))))


