
# # # # # # # # # # # # # # # # # # # # #
# This script:
# imports processed data
# filters out people who are excluded from the main analysis
# outputs inclusion/exclusions flowchart data
# # # # # # # # # # # # # # # # # # # # #

# Preliminaries ----

## Import libraries ----
library('tidyverse')
library('here')
library('glue')

source(here("analysis", "lib", "utility_functions.R"))

## import command-line arguments ----
args <- commandArgs(trailingOnly=TRUE)

## create output directories ----
fs::dir_create(here("output", "data"))


## Import processed data ----

data_processed <- read_rds(here("output", "data", "data_processed.rds"))

data_criteria <- data_processed %>%
  mutate(
    patient_id,
    has_age = !is.na(age),
    has_sex = !is.na(sex) & !(sex %in% c("I", "U")),
    has_imd = !is.na(imd),
    has_ethnicity = !is.na(ethnicity_combined),
    has_region = !is.na(region),
    has_rural = !is.na(rural_urban_group),
    not_cev = !cev,
    #knownvaxdate = vax1_date>=as.Date("2020-03-01"), # not currently used because these are excluded in study definition
    vax1_beforelastvaxdate = vax1_date <= lastvax_date,
    vax1_afterstartdate = vax1_date >= start_date_az,
    vax1_azpfizer = vax1_type %in% c("az", "pfizer"),

    include = (
      has_age & has_sex & has_imd & has_ethnicity & has_region & has_rural &
        #has_follow_up_previous_year &
        #no_unclear_brand &
        not_cev &
        #knownvaxdate &
        vax1_beforelastvaxdate &
        vax1_afterstartdate &
        vax1_azpfizer
    ),
  )

data_cohort_allvax <- data_criteria %>%
  filter(
    vax1_azpfizer & vax1_afterstartdate & vax1_beforelastvaxdate
  ) %>% droplevels()
write_rds(data_cohort_allvax, here("output", "data", "data_cohort_allvax.rds"), compress="gz")
data_cohort <- data_criteria %>% filter(include) %>% droplevels()
write_rds(data_cohort, here("output", "data", "data_cohort.rds"), compress="gz")

data_flowchart <- data_criteria %>%
  transmute(
    c0_all = vax1_azpfizer & vax1_afterstartdate & vax1_beforelastvaxdate,
    #c1_1yearfup = c0_all & (has_follow_up_previous_year),
    c1_notmissing = c0_all & (has_age & has_sex & has_imd & has_ethnicity & has_region & has_rural),
    c2_notcev = c1_notmissing & not_cev
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
    crit = str_extract(criteria, "^c\\d+"),
    criteria = fct_case_when(
      crit == "c0" ~ "HCWs aged 18-64\n  receiving first dose of BNT162b2 or ChAdOx1\n  between 4 January and 28 February 2021",
      crit == "c1" ~ "  with no missing demographic information",
      crit == "c2" ~ "  who are not clinically extremely vulnerable",
      #crit == "c3" ~ "  with vaccination on or before recruitment end date",
      #crit == "c4" ~ "  with vaccination on or after recruitment start date",
      #crit == "c5" ~ "  with Pfizer/BNT or Oxford/AZ vaccine",
      TRUE ~ NA_character_
    )
  )
write_csv(data_flowchart, here("output", "data", "flowchart.csv"))
