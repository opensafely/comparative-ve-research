
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
source(here("analysis", "lib", "redaction_functions.R"))

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
data_cohort <- read_rds(here("output", "data", "data_cohort_allvax.rds")) %>%
  mutate(
    censor_date12 = pmin(vax1_date - 1 + lastfupday12, end_date, dereg_date, death_date, vax2_date, na.rm=TRUE),
    censor_date20 = pmin(vax1_date - 1 + lastfupday20, end_date, dereg_date, death_date, vax2_date, na.rm=TRUE),
    tte_censor12 = tte(vax1_date-1, censor_date12, censor_date12, na.censor=TRUE),
    tte_censor20 = tte(vax1_date-1, censor_date20, censor_date20, na.censor=TRUE),
    fu_days12 = tte_censor12,
    fu_days20 = tte_censor20,
    N=1
  )

var_labels <- splice(list(N= N ~ "Total N"), var_labels, list(cev = cev ~ "Clinically Extremely Vulnerable"))

## baseline variables
tab_summary_baseline <- data_cohort %>%
  select(
    all_of(names(var_labels)),
    -age, -stp, -vax1_type, -fu_days12, -fu_days20
  ) %>%
  tbl_summary(
    by = vax1_type_descr,
    label=unname(var_labels[names(.)]),
    statistic = list(N = "{N}"),
    missing = "ifany"
  ) %>%
  modify_footnote(starts_with("stat_") ~ NA) %>%
  modify_header(stat_by = "**{level}**") %>%
  bold_labels()

tab_summary_baseline_redacted <- redact_tblsummary(tab_summary_baseline, 5, "[REDACTED]")


write_csv(tab_summary_baseline_redacted$table_body, here("output", "descriptive", "tables", "table1_allvax.csv"))
write_csv(tab_summary_baseline_redacted$df_by, here("output", "descriptive", "tables", "table1_allvax_by.csv"))
gtsave(as_gt(tab_summary_baseline_redacted), here("output", "descriptive", "tables", "table1_allvax.html"))

