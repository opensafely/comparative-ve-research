# load libraries ----

library('tidyverse')
library('here')
library('glue')
library('lubridate')
library('gt')
library('patchwork')
library('scales')
source(here("analysis", "lib", "utility_functions.R"))


data_cohort <- read_rds(here("output", "data", "data_cohort.rds"))

metadata_outcomes <- read_rds(here("output", "data", "metadata_outcomes.rds"))

list_formula <- read_rds(here("output", "data", "metadata_formulas.rds"))
list2env(list_formula, globalenv())
lastfupday <- lastfupday20

## create directory ----

fs::dir_create(here("output", "report", "objects"))

## baseline information ----

data_cohort <-
  data_cohort %>%
  mutate(
    censor_date = pmin(vax1_date - 1 + lastfupday, end_date, dereg_date, death_date, na.rm=TRUE),
    tte_censor = tte(vax1_date-1, censor_date, censor_date, na.censor=TRUE),
    tte_seconddose = tte(vax1_date-1, vax2_date-1, censor_date, na.censor=TRUE),

    postest = censor_indicator(positive_test_date, censor_date),
    emergency = censor_indicator(emergency_date, censor_date),
    covidemergency = censor_indicator(emergency_covid_date, censor_date),
    admitted = censor_indicator(admitted_date, censor_date),
    covidadmitted = censor_indicator(covidadmitted_date, censor_date),
    covidcc = censor_indicator(covidcc_date, censor_date),
    coviddeath = censor_indicator(coviddeath_date, censor_date),
    death = censor_indicator(death_date, censor_date),

    seconddose = censor_indicator(vax2_date-1, censor_date)
  )

baseline <-
  data_cohort %>%
  summarise(
    n = n(),
    age_median = median(age),
    age_Q1 = quantile(age, 0.25),
    age_Q3 = quantile(age, 0.75),
    female = mean(sex=="Female"),
    fu_years = sum(tte_censor)/365.25,
    fu_median = median(tte_censor),
    priorinfection = mean(prior_covid_infection),
    seconddose_12week = mean(replace_na(tte_seconddose<=12*7, FALSE)),

    postest = sum(postest),
    covidemergency = sum(covidemergency),
    emergency = sum(emergency),
    admitted = sum(admitted),
    covidadmitted = sum(covidadmitted),
    coviddeath = if_else(sum(coviddeath)>5, as.integer(sum(coviddeath)), NA_integer_),
    death = if_else(sum(death)>5, as.integer(sum(death)), NA_integer_),
    seconddose = sum(seconddose),
  )

baseline_az <-
  data_cohort %>%
  filter(vax1_type=="az") %>%
  summarise(
    n = n(),
    age_median = median(age),
    age_Q1 = quantile(age, 0.25),
    age_Q3 = quantile(age, 0.75),
    female = mean(sex=="Female"),
    fu_years = sum(tte_censor)/365.25,
    fu_median = median(tte_censor),
    priorinfection = mean(prior_covid_infection),
    median_vaxday = first(start_date_az) + floor(median(vax1_day)) -1,
    seconddose_12week = mean(replace_na(tte_seconddose<=12*7, FALSE)),

    postest = sum(postest),
    covidemergency = sum(covidemergency),
    emergency = sum(emergency),
    admitted = sum(admitted),
    covidadmitted = sum(covidadmitted),
    coviddeath = if_else(sum(coviddeath)>5, as.integer(sum(coviddeath)), NA_integer_),
    death = if_else(sum(death)>5, as.integer(sum(death)), NA_integer_),
    seconddose = sum(seconddose),

  )

baseline_pfizer <-
  data_cohort %>%
  filter(vax1_type=="pfizer") %>%
  summarise(
    n = n(),
    age_median = median(age),
    age_Q1 = quantile(age, 0.25),
    age_Q3 = quantile(age, 0.75),
    female = mean(sex=="Female"),
    fu_years = sum(tte_censor)/365.25,
    fu_median = median(tte_censor),
    priorinfection = mean(prior_covid_infection),
    median_vaxday = first(start_date_az) + floor(median(vax1_day)) - 1,
    seconddose_12week = mean(replace_na(tte_seconddose<=12*7, FALSE)),

    postest = sum(postest),
    covidemergency = sum(covidemergency),
    emergency = sum(emergency),
    admitted = sum(admitted),
    covidadmitted = sum(covidadmitted),
    coviddeath = if_else(sum(coviddeath)>5, as.integer(sum(coviddeath)), NA_integer_),
    death = if_else(sum(death)>5, as.integer(sum(death)), NA_integer_),
    seconddose = sum(seconddose),
  )


write_csv(baseline, here("output", "report", "objects", "baseline.csv"))
write_csv(baseline_az, here("output", "report", "objects", "baseline_az.csv"))
write_csv(baseline_pfizer, here("output", "report", "objects", "baseline_pfizer.csv"))


### descriptive tables ----

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
    ~read_rds(here("output", "models", .x, "timesincevax", "0", glue("reportplr_adjustedsurvival_ns.rds"))),
    .id="outcome"
  ) %>%
  left_join(metadata_outcomes, by="outcome")

write_csv(cmlinc_ns, here("output", "report", "objects", "cmlinc_ns.csv"))

cmlinc_pw <-
  map_dfr(
    outcomes,
    ~read_rds(here("output", "models", .x, "timesincevax", "0", glue("reportplr_adjustedsurvival_pw.rds"))),
    .id="outcome"
  ) %>%
  left_join(metadata_outcomes, by="outcome")

write_csv(cmlinc_pw, here("output", "report", "objects", "cmlinc_pw.csv"))


# difference in cumulative incidence

riskdiff_ns <-
  map_dfr(
    outcomes,
    ~read_rds(here("output", "models", .x, "timesincevax", "0", glue("reportplr_adjusteddiff_ns.rds"))),
    .id="outcome"
  ) %>%
  left_join(metadata_outcomes, by="outcome") %>%
  mutate(
    diff_format = label_number(0.01, scale=1000)(diff),
    diff_CI = paste0("(" , label_number(0.01, scale=1000)(diff.ll), ", ", label_number(0.01, scale=1000)(diff.ul), ")")
  )

write_csv(riskdiff_ns, here("output", "report", "objects", "riskdiff_ns.csv"))

riskdiff_pw <-
  map_dfr(
    outcomes,
    ~read_rds(here("output", "models", .x, "timesincevax", "0", glue("reportplr_adjusteddiff_pw.rds"))),
    .id="outcome"
  ) %>%
  left_join(metadata_outcomes, by="outcome") %>%
  mutate(
    diff_format = label_number(0.01, scale=1000)(diff),
    diff_CI = paste0("(" , label_number(0.01, scale=1000)(diff.ll), ", ", label_number(0.01, scale=1000)(diff.ul), ")")
  )

write_csv(riskdiff_pw, here("output", "report", "objects", "riskdiff_pw.csv"))

# hazard
hazard_ns <-
  map_dfr(
    outcomes,
    ~read_rds(here("output", "models", .x, "timesincevax", "0", glue("reportplr_effects_ns.rds"))),
    .id="outcome"
  ) %>%
  left_join(metadata_outcomes, by="outcome")

write_csv(hazard_ns, here("output", "report", "objects", "hazard_ns.csv"))

hazard_pw <-
  map_dfr(
    outcomes,
    ~read_rds(here("output", "models", .x, "timesincevax", "0", glue("reportplr_effects_pw.rds"))),
    .id="outcome"
  ) %>%
  left_join(metadata_outcomes, by="outcome")

write_csv(hazard_pw, here("output", "report", "objects", "hazard_pw.csv"))
