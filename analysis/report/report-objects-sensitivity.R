# load libraries ----

library('tidyverse')
library('here')
library('glue')
library('lubridate')
library('gt')
library('patchwork')
library('scales')
source(here("analysis", "lib", "utility_functions.R"))


metadata_outcomes <- read_rds(here("output", "data", "metadata_outcomes.rds"))

list_formula <- read_rds(here("output", "data", "metadata_formulas.rds"))
list2env(list_formula, globalenv())
lastfupday <- lastfupday20

## create directory ----

fs::dir_create(here("output", "report", "objects", "sensitivity", "exclude_prior_infection"))

## baseline information ----
### model plots information -----

outcomes <-
  c(
    "postest",
    "covidemergency",
    "covidadmitted"
  ) %>%
  set_names(., .)

# cumulative incidence
cmlinc_ns <-
  map_dfr(
    outcomes,
    ~read_rds(here("output", "models", .x, "timesincevax", "0", "1", glue("reportplr_adjustedsurvival_ns.rds"))),
    .id="outcome"
  ) %>%
  left_join(metadata_outcomes, by="outcome") %>%
  mutate(
    inc_format = label_number(0.1, scale=1000)(1-survival),
    inc_CI = paste0("(" , label_number(0.1, scale=1000)(1-survival.ul), ", ", label_number(0.1, scale=1000)(1-survival.ll), ")")
  )

write_csv(cmlinc_ns, here("output", "report", "objects", "sensitivity", "exclude_prior_infection", "cmlinc_ns.csv"))

cmlinc_pw <-
  map_dfr(
    outcomes,
    ~read_rds(here("output", "models", .x, "timesincevax", "0", "1", glue("reportplr_adjustedsurvival_pw.rds"))),
    .id="outcome"
  ) %>%
  left_join(metadata_outcomes, by="outcome") %>%
  mutate(
    inc_format = label_number(0.1, scale=1000)(1-survival),
    inc_CI = paste0("(" , label_number(0.1, scale=1000)(1-survival.ul), ", ", label_number(0.1, scale=1000)(1-survival.ll), ")")
  )

write_csv(cmlinc_pw, here("output", "report", "objects", "sensitivity", "exclude_prior_infection", "cmlinc_pw.csv"))


# difference in cumulative incidence

riskdiff_ns <-
  map_dfr(
    outcomes,
    ~read_rds(here("output", "models", .x, "timesincevax", "0",  "1", glue("reportplr_adjusteddiff_ns.rds"))),
    .id="outcome"
  ) %>%
  left_join(metadata_outcomes, by="outcome") %>%
  mutate(
    diff_format = label_number(0.01, scale=1000)(diff),
    diff_CI = paste0("(" , label_number(0.01, scale=1000)(diff.ll), ", ", label_number(0.01, scale=1000)(diff.ul), ")")
  )

write_csv(riskdiff_ns, here("output", "report", "objects", "sensitivity", "exclude_prior_infection", "riskdiff_ns.csv"))

riskdiff_pw <-
  map_dfr(
    outcomes,
    ~read_rds(here("output", "models", .x, "timesincevax", "0",  "1", glue("reportplr_adjusteddiff_pw.rds"))),
    .id="outcome"
  ) %>%
  left_join(metadata_outcomes, by="outcome") %>%
  mutate(
    diff_format = label_number(0.01, scale=1000)(diff),
    diff_CI = paste0("(" , label_number(0.01, scale=1000)(diff.ll), ", ", label_number(0.01, scale=1000)(diff.ul), ")")
  )

write_csv(riskdiff_pw, here("output", "report", "objects", "sensitivity", "exclude_prior_infection", "riskdiff_pw.csv"))

# hazard
hazard_ns <-
  map_dfr(
    outcomes,
    ~read_rds(here("output", "models", .x, "timesincevax", "0", "1", glue("reportplr_effects_ns.rds"))),
    .id="outcome"
  ) %>%
  left_join(metadata_outcomes, by="outcome")

write_csv(hazard_ns, here("output", "report", "objects", "sensitivity", "exclude_prior_infection", "hazard_ns.csv"))

hazard_pw <-
  map_dfr(
    outcomes,
    ~read_rds(here("output", "models", .x, "timesincevax", "0", "1", glue("reportplr_effects_pw.rds"))),
    .id="outcome"
  ) %>%
  left_join(metadata_outcomes, by="outcome")

write_csv(hazard_pw, here("output", "report", "objects", "sensitivity", "exclude_prior_infection", "hazard_pw.csv"))
