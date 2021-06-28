
# # # # # # # # # # # # # # # # # # # # #
# This script:
# takes a cohort name as defined in data_define_cohorts.R, and imported as an Arg
# creates descriptive outputs on patient characteristics by vaccination status at 0, 28, and 56 days.
#
# The script should be run via an action in the project.yaml
# The script must be accompanied by one argument,
# 1. the name of the cohort defined in data_define_cohorts.R
# # # # # # # # # # # # # # # # # # # # #

# Preliminaries ----

## Import libraries ----
library('tidyverse')
library('here')
library('glue')
library('gt')
library('gtsummary')

## Import custom user functions from lib

source(here("analysis", "lib", "utility_functions.R"))

## import command-line arguments ----
args <- commandArgs(trailingOnly=TRUE)
if(length(args)==0){
  # use for interactive testing
  removeobs <- FALSE
} else {
  removeobs <- TRUE
}

## import global vars ----
gbl_vars <- jsonlite::fromJSON(
  txt="./analysis/global-variables.json"
)
#list2env(gbl_vars, globalenv())

# output directory

fs::dir_create(here("output", "hcw"))


## Import processed data ----
data_hcw <- read_rds(here("output", "data", "hcw_data_processed.rds"))
data_vax <- read_rds(here("output", "data", "hcw_data_vax.rds"))


data_vax_knownbrand <- data_vax %>%
  filter(!is.na(vaccine_type)) %>%
  group_by(patient_id) %>%
  mutate(vax_index = row_number()) %>%
  ungroup()

data_hcw <-
  left_join(
    data_hcw,
    data_vax_knownbrand %>%
      group_by(patient_id) %>%
      summarise(
        vax_doses = n(),
        vax1_type = nth(vaccine_type, 1),
        vax2_type = nth(vaccine_type, 2, default= "no second dose"),
        vax3_type = nth(vaccine_type, 3, default= "no third dose"),
      ) %>% ungroup(),
    by='patient_id'
  )

tab_summary_baseline <- data_hcw %>%
  transmute(
    ageband,
    sex,
    imd_Q5,
    ethnicity_combined,
    region,
    vax_doses,
    vax1_type,
    any_vax_record = !is.na(covid_vax_any_1_date)
  ) %>%
  tbl_summary() %>%
  modify_footnote(starts_with("stat_") ~ NA)

tab_summary_baseline$inputs$data <- NULL
tab_summary_baseline$table_header

tab_csv <- tab_summary_baseline$table_body
names(tab_csv) <- tab_summary_baseline$table_header$label
tab_csv <- tab_csv[, (!tab_summary_baseline$table_header$hide | tab_summary_baseline$table_header$label=="variable")]

## create output directories ----
gtsave(as_gt(tab_summary_baseline), here::here("output", "hcw", "table1.html"))
write_csv(tab_csv, here::here("output", "hcw", "table1.csv"))


### vaccination date histogram ----

plot_vax1date <- data_vax_knownbrand %>%
  filter(vax_index==1) %>%
  mutate(
    date = pmax(date, as.Date("2020-02-01")) # change default "missing" date to Feb 2020 to make histogram easier to read
  ) %>%
  ggplot() +
  geom_histogram(aes(x=date, fill=vaccine_type), position = "identity",  alpha=0.3) +
  theme_bw()

ggsave(filename=here::here("output", "hcw", glue::glue("vax1date.svg")), plot_vax1date, width=20, height=15, units="cm")
ggsave(filename=here::here("output", "hcw", glue::glue("vax1date.png")), plot_vax1date, width=20, height=15, units="cm")
