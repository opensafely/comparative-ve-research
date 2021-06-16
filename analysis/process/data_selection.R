
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
    #has_follow_up_previous_year,
    no_prior_vaccine = is.na(covid_vax_any_0_date),
    not_cev = !cev,
    vax1_4janonwards = vax1_date>=start_date_az,

    include = (
      has_age & has_sex & has_imd & has_ethnicity & has_region &
        #has_follow_up_previous_year &
        #no_unclear_brand &
        no_prior_vaccine &
        not_cev
    ),
  )

data_cohort_allvax <- data_criteria %>% filter(include)
write_rds(data_cohort_allvax, here("output", "data", "data_cohort_allvax.rds"), compress="gz")
data_cohort <- data_criteria %>% filter(include & vax1_4janonwards)
write_rds(data_cohort, here("output", "data", "data_cohort.rds"), compress="gz")

data_flowchart <- data_criteria %>%
  transmute(
    c0_all = TRUE,
    #c1_1yearfup = c0_all & (has_follow_up_previous_year),
    c1_notmissing = c0_all & (has_age & has_sex & has_imd & has_ethnicity & has_region),
    c2_notcev = c1_notmissing & not_cev,
    c3_nopriorvaccine = c2_notcev & (no_prior_vaccine),
    c4_4jan = c3_nopriorvaccine & vax1_4janonwards
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
