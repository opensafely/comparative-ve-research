
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

## create output directories ----
fs::dir_create(here("output", "descriptive", "tables"))


## import metadata ----
var_labels <- read_rds(here("output", "data", "metadata_labels.rds"))

list_formula <- read_rds(here("output", "data", "metadata_formulas.rds"))
list2env(list_formula, globalenv())
lastfupday <- lastfupday20

## Import processed data ----
data_cohort <- read_rds(here("output", "data", "data_cohort.rds")) %>%
  mutate(
    censor_date12 = pmin(vax1_date - 1 + lastfupday12, end_date, dereg_date, death_date, na.rm=TRUE),
    censor_date20 = pmin(vax1_date - 1 + lastfupday20, end_date, dereg_date, death_date, na.rm=TRUE),
    tte_censor12 = tte(vax1_date-1, censor_date12, censor_date12, na.censor=TRUE),
    tte_censor20 = tte(vax1_date-1, censor_date20, censor_date20, na.censor=TRUE),
    fu_days12 = tte_censor12,
    fu_days20 = tte_censor20,
  )


## baseline variables
tab_summary_baseline <- data_cohort %>%
  select(
    all_of(names(var_labels)),
    -age, -stp, -vax1_type,
  ) %>%
  tbl_summary(
    by = vax1_type_descr,
    label=unname(var_labels[names(.)])
  )  %>%
  modify_footnote(starts_with("stat_") ~ NA)

tab_summary_baseline$inputs$data <- NULL

tab_csv <- tab_summary_baseline$table_body
names(tab_csv) <- tab_summary_baseline$table_header$label
tab_csv <- tab_csv[, (!tab_summary_baseline$table_header$hide | tab_summary_baseline$table_header$label=="variable")]

write_rds(tab_summary_baseline, here("output", "descriptive", "tables", "table1.rds"))
gtsave(as_gt(tab_summary_baseline), here("output", "descriptive", "tables", "table1.html"))
write_csv(tab_csv, here("output", "descriptive", "tables", "table1.csv"))




tab_summary_region <- data_cohort %>%
  select(
    region, stp, vax1_type
  ) %>%
  tbl_summary(
    by = vax1_type,
    label=unname(var_labels[names(.)])
  )  %>%
  modify_footnote(starts_with("stat_") ~ NA)

tab_summary_region$inputs$data <- NULL

tab_region_csv <- tab_summary_region$table_body
names(tab_region_csv) <- tab_summary_region$table_header$label
tab_region_csv <- tab_region_csv[, (!tab_summary_region$table_header$hide | tab_summary_region$table_header$label=="variable")]

gtsave(as_gt(tab_summary_region), here("output", "descriptive", "tables", "table1_regions.html"))
write_csv(tab_csv, here("output", "descriptive", "tables", "table1_regions.csv"))

