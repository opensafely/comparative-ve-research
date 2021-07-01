
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

# create output directory
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

data_summary <- data_hcw %>%
  transmute(
    ageband,
    sex = case_when(
      sex=="M" ~ "Male",
      sex=="F" ~ "Female",
      sex!="" ~ "Other",
      TRUE ~ NA_character_
    ),
    imd_Q5,
    ethnicity_combined,
    region,
    vax_doses = cut(vax_doses, c(0,1,2,3, Inf), include.lowest=TRUE, right=FALSE, labels = c("0", "1", "2", "3+")),
    vax1_type,
    vax_any_record = !is.na(covid_vax_any_1_date),
    vax_disease_record = !is.na(covid_vax_disease_1_date),
    vax_date1_mismatch = case_when(
      (covid_vax_any_1_date != covid_vax_disease_1_date) ~ TRUE,
      (is.na(covid_vax_any_1_date) != is.na(covid_vax_disease_1_date)) ~ TRUE,
      TRUE ~ FALSE
    )
  )


tab_summary <- data_summary %>%
  tbl_summary() %>%
  modify_footnote(starts_with("stat_") ~ NA)

tab_summary$inputs$data <- NULL

tab_csv <- tab_summary$table_body
names(tab_csv) <- tab_summary$table_header$label
tab_csv <- tab_csv[, (!tab_summary$table_header$hide | tab_summary$table_header$label=="variable")]

## save output ----
gtsave(as_gt(tab_summary), here::here("output", "hcw", "table1.html"))
write_csv(tab_csv, here::here("output", "hcw", "table1.csv"))




tab_summary_vax <- data_summary %>%
  tbl_summary(
    by=vax_any_record
  ) %>%
  modify_footnote(starts_with("stat_") ~ NA)

tab_summary_vax$inputs$data <- NULL

tab_vax_csv <- tab_summary_vax$table_body
names(tab_vax_csv) <- tab_summary_vax$table_header$label
tab_vax_csv <- tab_vax_csv[, (!tab_summary_vax$table_header$hide | tab_summary_vax$table_header$label=="variable")]

## save output ----
gtsave(as_gt(tab_summary_vax), here::here("output", "hcw", "table1_vax.html"))
write_csv(tab_vax_csv, here::here("output", "hcw", "table1_vax.csv"))

### vaccination date histogram ----

plot_vax1date <- data_vax_knownbrand %>%
  filter(vax_index<=3) %>%
  mutate(
    date = pmax(date, as.Date("2020-12-01")) # change default "missing" date to Dec 2020 to make histogram easier to read
  ) %>%
  ggplot() +
  geom_histogram(aes(x=date, fill=vaccine_type, alpha=is.na(vax_disease_index)), position = "identity", binwidth=7) +
  facet_grid(cols=vars(vax_index), rows=vars(vaccine_type), scales="free_y")+
  theme_bw()

ggsave(filename=here::here("output", "hcw", glue::glue("vax1date.svg")), plot_vax1date, width=15, height=20, units="cm")
ggsave(filename=here::here("output", "hcw", glue::glue("vax1date.png")), plot_vax1date, width=15, height=20, units="cm")
