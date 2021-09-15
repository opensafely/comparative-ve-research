
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
library('gt')
library('gtsummary')

## create output directory ----
dir.create(here("output", "matching"), showWarnings = FALSE, recursive=TRUE)


## import command-line arguments ----
args <- commandArgs(trailingOnly=TRUE)

if(length(args)==0){
  matchtype <- "withoutdate"
} else {
  matchtype <- args[[1]]
}


## import metadata ----
var_labels <- read_rds(here("output", "data", "metadata_labels.rds"))

## create output directories ----
dir.create(here("output", "data"), showWarnings = FALSE, recursive=TRUE)



## Import processed data ----
data_cohort <- read_rds(here("output", "data", "data_cohort.rds"))
if(matchtype=="withdate"){
  data_cohort <- data_cohort %>% filter(vax1_4janonwards)
}

data_match_lookup <- read_csv(
  here("output", "data", glue("matched_combined_{matchtype}.csv")),
  col_types = cols_only(

    # identifiers
    patient_id = col_integer(),
    set_id = col_integer()#,
    #match_counts = col_integer()
  )
)

data_matches <-
  data_cohort %>%
  left_join(data_match_lookup, by="patient_id") %>%
  mutate(
    set_id = case_when(
      is.na(set_id) ~ 0L,
      TRUE ~ set_id
    ),
    matched = set_id!=0
  )

write_rds(data_matches, here("output", "data", glue("data_matches_{matchtype}.rds")), compress="gz")

data_matches %>%
  group_by(matched, vax1_type) %>%
  summarise(
    n=n()
  )


## covariate balance ----

data_matches %>%
  # filter(
  #   matched
  # ) %>%
  mutate(
    matchgroup = case_when(
      matched & vax1_type =="pfizer" ~ "Matched, pfizer",
      matched & vax1_type =="az" ~ "Matched, AZ",
      !matched & vax1_type =="pfizer" ~ "unmatched, pfizer",
      !matched & vax1_type =="az" ~ "Unmatched, AZ",
      TRUE ~ NA_character_
    )
  ) %>%
  select(
    matchgroup,
    vax1_day,
    names(var_labels),
  ) %>%
  tbl_summary(
    by=matchgroup,
    missing = "ifany",
    label = unname(var_labels),
  ) %>%
  as_gt() %>%
  gtsave(
    filename = glue("matching_balance_{matchtype}.html"),
    path=here("output", "matching")
  )


