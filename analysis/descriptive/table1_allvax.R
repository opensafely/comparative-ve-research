
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


## import metadata ----
var_labels <- read_rds(here("output", "data", "metadata_labels.rds"))

list_formula <- read_rds(here::here("output", "data", "metadata_formulas.rds"))
list2env(list_formula, globalenv())


## Import processed data ----
data_cohort <- read_rds(here("output", "data", "data_cohort_allvax.rds"))


## baseline variables
data_baseline <- data_cohort %>%
  select(
    all_of(names(var_labels)),
    vax1_4janonwards,
    -age
  )
if(removeobs) rm(data_cohort)

tab_summary_baseline <- data_baseline %>%
  tbl_summary(
    by = vax1_4janonwards,
    label=unname(var_labels[names(data_baseline)])
  )  %>%
  modify_footnote(starts_with("stat_") ~ NA)

tab_summary_baseline$inputs$data <- NULL

## create output directories ----
dir.create(here::here("output", "descriptive", "tables"), showWarnings = FALSE, recursive=TRUE)
gtsave(as_gt(tab_summary_baseline), here::here("output", "descriptive", "tables", "table1_allvax.html"))
write_csv(tab_summary_baseline$table_body, here::here("output", "descriptive", "tables", "table1_allvax.csv"))
