
## Import libraries ----
library('tidyverse')
library('here')
library('survival')
library('glue')

## Import custom user functions from lib
source(here("analysis", "R", "lib", "utility_functions.R"))
source(here("analysis", "R", "lib", "survival_functions.R"))

# import command-line arguments ----

args <- commandArgs(trailingOnly=TRUE)

if(length(args)==0){
  # use for interactive testing
  removeobs <- FALSE
  sample_size <- 10000
  sample_nonoutcomeprop <- 0.1
  cohort <- "under65s"

} else{
  removeobs <- TRUE
  sample_size <- 200000
  sample_nonoutcomeprop <- 0.1
  cohort <- args[[1]]
}

## create output directories ----
dir.create(here("output", cohort, "data"), showWarnings = FALSE, recursive=TRUE)



# Import processed data ----
data_cohorts <- read_rds(here("output", "data", "data_cohorts.rds"))
metadata_cohorts <- read_rds(here("output", "data", "metadata_cohorts.rds"))
data_processed <- read_rds(here("output", "data", "data_processed.rds"))

stopifnot("cohort does not exist" = (cohort %in% metadata_cohorts[["cohort"]]))

data_cohorts <- data_cohorts[data_cohorts[[cohort]],]

metadata <- metadata_cohorts[metadata_cohorts[["cohort"]]==cohort, ]

data_processed %>%
  select(
    patient_id,
    age,
    sex,
    ethnicity_combined,
    region,
    vax_day,
    covid_vax_1_date,
    vax_type
  ) %>%
  split(.$vax_type) %>%
  iwalk(~write_csv(.x, here("output", glue("data_vax_{.y}_only.csv"))))



