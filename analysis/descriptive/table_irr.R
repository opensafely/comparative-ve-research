
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
library('survival')
library('gt')
library('gtsummary')
library('scales')

## Import custom user functions from lib

source(here::here("analysis", "lib", "utility_functions.R"))
source(here::here("analysis", "lib", "redaction_functions.R"))

args <- commandArgs(trailingOnly=TRUE)
if(length(args)==0){
  # use for interactive testing
  removeobs <- FALSE
} else {
  removeobs <- TRUE
}



## import metadata ----
var_labels <- read_rds(here("output", "data", "metadata_labels.rds"))

list_formula <- read_rds(here("output", "data", "metadata_formulas.rds"))
list2env(list_formula, globalenv())
metadata_outcomes <- read_rds(here("output", "data", "metadata_outcomes.rds"))

## create output directory ----
fs::dir_create(here("output", "descriptive", "tables"))

## Import processed data ----
data_cohort <- read_rds(here("output", "data", "data_cohort.rds"))

# create pt data ----

data_tte <- data_cohort %>%
  transmute(
    patient_id,
    vax1_type,
    end_date,

    censor_date = pmin(vax1_date - 1 + lastfupday, end_date, dereg_date, death_date, covid_vax_any_2_date, na.rm=TRUE),

    # time to last follow up day
    tte_enddate = tte(vax1_date-1, end_date, end_date),

    # time to last follow up day or death or deregistration
    tte_censor = tte(vax1_date-1, censor_date, censor_date),

    tte_test =tte(vax1_date-1, covid_test_date, censor_date, na.censor=TRUE),
    ind_test = censor_indicator(covid_test_date, censor_date),

    tte_postest = tte(vax1_date-1, positive_test_date, censor_date, na.censor=TRUE),
    ind_postest = censor_indicator(positive_test_date, censor_date),

    tte_emergency = tte(vax1_date-1, emergency_date, censor_date, na.censor=TRUE),
    ind_emergency = censor_indicator(emergency_date, censor_date),

    tte_admitted = tte(vax1_date-1, admitted_date, censor_date, na.censor=TRUE),
    ind_admitted = censor_indicator(admitted_date, censor_date),

    tte_covidadmitted = tte(vax1_date-1, covidadmitted_date, censor_date, na.censor=TRUE),
    ind_covidadmitted = censor_indicator(covidadmitted_date, censor_date),

    tte_covidcc = tte(vax1_date-1, covidcc_date, censor_date, na.censor=TRUE),
    ind_covidcc = censor_indicator(covidcc_date, censor_date),

    tte_coviddeath = tte(vax1_date-1, coviddeath_date, censor_date, na.censor=TRUE),
    ind_coviddeath = censor_indicator(coviddeath_date, censor_date),

    tte_noncoviddeath = tte(vax1_date-1, noncoviddeath_date, censor_date, na.censor=TRUE),
    ind_noncoviddeath = censor_indicator(noncoviddeath_date, censor_date),

    tte_death = tte(vax1_date-1, death_date, censor_date, na.censor=TRUE),
    ind_death = censor_indicator(death_date, censor_date),

  ) %>%
  filter(
    # TDOD remove once study def rerun with new dereg date
    tte_censor>0 | is.na(tte_censor)
  )

if(removeobs) rm(data_cohort)


# one row per patient per post-vaccination week
postvax_time <- data_tte %>%
  select(patient_id, tte_censor) %>%
  mutate(
    fup_day = list(postvaxcuts_2week),
    timesincevax = map(fup_day, ~droplevels(timesince_cut_end(.x+1, postvaxcuts_2week)))
  ) %>%
  unnest(c(fup_day, timesincevax))

# create dataset that splits follow-up time by
# time since vaccination (using postvaxcuts cutoffs)
data_cox_split <- tmerge(
  data1 = data_tte %>% select(-starts_with("ind_"), -ends_with("_date")),
  data2 = data_tte,
  id = patient_id,
  tstart = 0L,
  tstop = tte_censor,
  test = event(tte_test),
  postest = event(tte_postest),
  emergency = event(tte_emergency),
  admitted = event(tte_admitted),
  covidadmitted = event(tte_covidadmitted),
  covidcc = event(tte_covidcc),
  coviddeath = event(tte_coviddeath),
  noncoviddeath = event(tte_noncoviddeath),
  death = event(tte_death),


  status_test = tdc(tte_test),
  status_postest = tdc(tte_postest),
  status_emergency = tdc(tte_emergency),
  status_admitted = tdc(tte_admitted),
  status_covidadmitted = tdc(tte_covidadmitted),
  status_covidcc = tdc(tte_covidcc),
  status_coviddeath = tdc(tte_coviddeath),
  status_noncoviddeath = tdc(tte_noncoviddeath),
  status_death = tdc(tte_death)

) %>%
  tmerge( # create treatment timescale variables
    data1 = .,
    data2 = postvax_time,
    id = patient_id,
    timesincevax = tdc(fup_day, timesincevax)
  ) %>%
  mutate(
    pt = tstop - tstart
  )

## create person-time table ----

format_ratio = function(numer,denom, width=7){
  paste0(
    replace_na(scales::comma_format(accuracy=1)(numer), "--"),
    " /",
    str_pad(replace_na(scales::comma_format(accuracy=1)(denom),"--"), width=width, pad=" ")
  )
}



pt_summary <- function(data, event){

  #data=data_cox_split
  #event = "test"


  unredacted <- data %>%
    mutate(
      timesincevax,
      status_event = .[[paste0("status_", event)]],
      ind_event = .[[event]],
      event = event
    ) %>%
    group_by(vax1_type, event, timesincevax) %>%
    summarise(
      yearsatrisk=sum(pt*(1-status_event))/365.25,
      n=sum(ind_event),
      rate=n/yearsatrisk
    ) %>%
    ungroup()

  unredacted_all <- data %>%
    mutate(
      status_event = .[[paste0("status_", event)]],
      ind_event = .[[event]],
      event = event
    ) %>%
    group_by(vax1_type, event) %>%
    summarise(
      yearsatrisk=sum(pt*(1-status_event))/365.25,
      n=sum(ind_event),
      rate=n/yearsatrisk
    ) %>%
    ungroup()

  unredacted_add_all <-
    bind_rows(
      unredacted,
      unredacted_all
    ) %>%
    mutate(
      timesincevax=forcats::fct_explicit_na(timesincevax, na_level="All")
    )


  unredacted_wide <-
    unredacted_add_all %>%
    pivot_wider(
      id_cols =c(event, timesincevax),
      names_from = vax1_type,
      values_from = c(yearsatrisk, n, rate),
      names_glue = "{vax1_type}_{.value}"
    ) %>%
    select(
      event, timesincevax, starts_with("pfizer"), starts_with("az")
    ) %>%
    mutate(
      rr = az_rate / pfizer_rate,
      rrE = scales::label_number(accuracy=0.01, trim=FALSE)(rr),
      rrCI = rrCI_exact(az_n, az_yearsatrisk, pfizer_n, pfizer_yearsatrisk, 0.01),
    )

  redacted <- unredacted_wide %>%
    mutate(
      pfizer_rate = redactor2(pfizer_n, 5, pfizer_rate),
      #pfizer_q = redactor2(pfizer_n, 5, pfizer_q),

      az_rate = redactor2(az_n, 5, az_rate),
      #az_q = redactor2(az_n, 5, az_q),

      rr = redactor2(pmin(az_n, pfizer_n), 5, rr),
      rrE = redactor2(pmin(az_n, pfizer_n), 5, rrE),
      rrCI = redactor2(pmin(az_n, pfizer_n), 5, rrCI),

      pfizer_n = redactor2(pfizer_n, 5),
      az_n = redactor2(az_n, 5),

      pfizer_q = format_ratio(pfizer_n, pfizer_yearsatrisk),
      az_q = format_ratio(az_n, az_yearsatrisk),
    )
}


data_summary <- local({
  temp1 <- pt_summary(data_cox_split, "test")
  temp2 <- pt_summary(data_cox_split, "postest")
  temp3 <- pt_summary(data_cox_split, "emergency")
  temp4 <- pt_summary(data_cox_split, "admitted")
  temp5 <- pt_summary(data_cox_split, "covidadmitted")
  temp6 <- pt_summary(data_cox_split, "covidcc")
  temp7 <- pt_summary(data_cox_split, "coviddeath")
  temp8 <- pt_summary(data_cox_split, "noncoviddeath")
  temp9 <- pt_summary(data_cox_split, "death")
  bind_rows(
    temp1, temp2, temp3, temp4,
    temp5, temp6, temp7, temp8,
    temp9
  )
}) %>%
left_join(
  metadata_outcomes %>% select(outcome, outcome_descr),
  by=c("event"="outcome")
)

write_csv(data_summary, here("output", "descriptive", "tables", "table_irr.csv"))

tab_summary <- data_summary %>%
  select(-event, -ends_with("_n"), -ends_with("_yearsatrisk"), -rrE) %>%
  gt(
    groupname_col = "outcome_descr",
  ) %>%
  cols_label(
    outcome_descr = "Outcome",
    timesincevax = "Time since first dose",

    pfizer_q = "Events / person-years",
    az_q   = "Events / person-years",

    pfizer_rate = "Rate/year",
    az_rate = "Incidence",
    rr = "Incidence rate ratio",

    rrCI = "95% CI"
  ) %>%
  tab_spanner(
    label = "BNT162b2",
    columns = starts_with("pfizer")
  ) %>%
  tab_spanner(
    label = "ChAdOx1",
    columns = starts_with("az")
  ) %>%
  fmt_number(
    columns = ends_with(c("rr", "_rate")),
    decimals = 2
  ) %>%
  fmt_missing(
    everything(),
    missing_text="--"
  ) %>%
  cols_align(
    align = "right",
    columns = everything()
  ) %>%
  cols_align(
    align = "left",
    columns = "timesincevax"
  )

write_rds(tab_summary, here("output", "descriptive", "tables", "table_irr.rds"))
gtsave(tab_summary, here("output", "descriptive", "tables", "table_irr.html"))


tab_summary_simple <-
  data_summary %>%
  filter(
    event %in% c(
      "postest",
      "emergency",
      "covidadmitted",
      "coviddeath",
      "death"
    )
  ) %>%
  transmute(
    outcome_descr, timesincevax,
    pfizer_q,
    pfizer_rate_fmt = if_else(pfizer_rate<0.001, "<0.001", number_format(0.001)(pfizer_rate)),
    pfizer_rate_fmt = if_else(pfizer_rate==0, "0", pfizer_rate_fmt),
    az_q,
    az_rate_fmt = if_else(az_rate<0.001, "<0.001", number_format(0.001)(az_rate)),
    az_rate_fmt = if_else(az_rate==0, "0", az_rate_fmt),
  ) %>%
  gt(
    groupname_col = "outcome_descr",
  ) %>%
  cols_label(
    outcome_descr = "Outcome",
    timesincevax = "Time since first dose",

    pfizer_q = "BNT162b2\nEvents / person-years",
    pfizer_rate_fmt = "BNT162b2\nIncidence",

    az_q   = "ChAdOx1\nEvents / person-years",
    az_rate_fmt = "ChAdOx1\nIncidence",
  ) %>%
  fmt_missing(
    everything(),
    missing_text="--"
  ) %>%
  cols_align(
    align = "right",
    columns = everything()
  ) %>%
  cols_align(
    align = "left",
    columns = "timesincevax"
  )

write_rds(tab_summary_simple, here("output", "descriptive", "tables", "table_irr_simple.rds"))
gtsave(tab_summary_simple, here("output", "descriptive", "tables", "table_irr_simple.html"))

