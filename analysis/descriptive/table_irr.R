
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


## import global vars ----
gbl_vars <- jsonlite::fromJSON(
  txt="./analysis/global-variables.json"
)
#list2env(gbl_vars, globalenv())


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
    start_date,
    end_date,

    # time to last follow up day
    tte_enddate = tte(vax1_date, end_date, end_date),

    # time to last follow up day or death or deregistration
    tte_censor = tte(vax1_date, censor_date, censor_date),

    tte_test =tte(vax1_date, covid_test_date, censor_date, na.censor=TRUE),
    ind_test = censor_indicator(covid_test_date, censor_date),

    tte_postest = tte(vax1_date, positive_test_date, censor_date, na.censor=TRUE),
    ind_postest = censor_indicator(positive_test_date, censor_date),

    tte_emergency = tte(vax1_date, emergency_date, censor_date, na.censor=TRUE),
    ind_emergency = censor_indicator(emergency_date, censor_date),

    tte_covidadmitted = tte(vax1_date, covidadmitted_date, censor_date, na.censor=TRUE),
    ind_covidadmitted = censor_indicator(covidadmitted_date, censor_date),

    tte_covidcc = tte(vax1_date, covidcc_date, censor_date, na.censor=TRUE),
    ind_covidcc = censor_indicator(covidcc_date, censor_date),

    tte_coviddeath = tte(vax1_date, coviddeath_date, censor_date, na.censor=TRUE),
    ind_coviddeath = censor_indicator(coviddeath_date, censor_date),

    tte_noncoviddeath = tte(vax1_date, noncoviddeath_date, censor_date, na.censor=TRUE),
    ind_noncoviddeath = censor_indicator(noncoviddeath_date, censor_date),

    tte_death = tte(vax1_date, death_date, censor_date, na.censor=TRUE),
    ind_death = censor_indicator(death_date, censor_date),

    all = factor("all")
  ) %>%
  filter(
    tte_censor>0 | is.na(tte_censor)
  )

if(removeobs) rm(data_cohort)


# one row per patient per post-vaccination week
postvax_time <- data_tte %>%
  select(patient_id, tte_censor) %>%
  mutate(
    fup_day = list(postvaxcuts),
    timesincevax = map(fup_day, ~droplevels(timesince_cut(.x+0.5, postvaxcuts, "blah")))
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
  covidadmitted = event(tte_covidadmitted),
  covidcc = event(tte_covidcc),
  coviddeath = event(tte_coviddeath),
  noncoviddeath = event(tte_noncoviddeath),
  death = event(tte_death),


  status_test = tdc(tte_test),
  status_postest = tdc(tte_postest),
  status_emergency = tdc(tte_emergency),
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


rrCI_normal <- function(n, pt, ref_n, ref_pt, group, accuracy=0.001){
  rate <- n/pt
  ref_rate <- ref_n/ref_pt
  rr <- rate/ref_rate
  log_rr <- log(rr)
  selog_rr <- sqrt((1/n)+(1/ref_n))
  log_ll <- log_rr - qnorm(0.975)*selog_rr
  log_ul <- log_rr + qnorm(0.975)*selog_rr
  ll <- exp(log_ll)
  ul <- exp(log_ul)

  if_else(
    group==levels(group)[1],
    NA_character_,
    paste0("(", scales::number_format(accuracy=accuracy)(ll), "-", scales::number_format(accuracy=accuracy)(ul), ")")
  )
}

rrCI_exact <- function(n, pt, ref_n, ref_pt, accuracy=0.001){

  # use exact methods if incidence is very low for immediate post-vaccine outcomes

  rate <- n/pt
  ref_rate <- ref_n/ref_pt
  rr <- rate/ref_rate

  ll = ref_pt/pt * (n/(ref_n+1)) * 1/qf(2*(ref_n+1), 2*n, p = 0.05/2, lower.tail = FALSE)
  ul = ref_pt/pt * ((n+1)/ref_n) * qf(2*(n+1), 2*ref_n, p = 0.05/2, lower.tail = FALSE)

  paste0("(", scales::number_format(accuracy=accuracy)(ll), "-", scales::number_format(accuracy=accuracy)(ul), ")")

}

# get confidence intervals for rate ratio using unadjusted poisson GLM
# uses gtsummary not broom::tidy to make it easier to paste onto original data

rrCI_glm <- function(n, pt, x, accuracy=0.001){

  dat<-tibble(n=n, pt=pt, x=x)

  poismod <- glm(
    formula = n ~ x + offset(log(pt*365.25)),
    family=poisson,
    data=dat
  )

  gtmodel <- tbl_regression(poismod, exponentiate=TRUE)$table_body %>%
    filter(reference_row %in% FALSE) %>%
    select(label, conf.low, conf.high)

  dat2 <- left_join(dat, gtmodel, by=c("x"="label"))

  paste0("(", scales::number_format(accuracy=accuracy)(dat2$conf.low), "-", scales::number_format(accuracy=accuracy)(dat2$conf.high), ")")

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
  temp4 <- pt_summary(data_cox_split, "covidadmitted")
  temp5 <- pt_summary(data_cox_split, "covidcc")
  temp6 <- pt_summary(data_cox_split, "coviddeath")
  temp7 <- pt_summary(data_cox_split, "noncoviddeath")
  temp8 <- pt_summary(data_cox_split, "death")
  bind_rows(
    temp1, temp2, temp3, temp4,
    temp5, temp6, temp7, temp8
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

gtsave(tab_summary, here("output", "descriptive", "tables", "table_irr.html"))


## note:
# the follow poisson model gives the same results eg for postest
# poismod <- glm(
#   formula = postest_n ~ timesincevax_pw + offset(log(postest_yearsatrisk*365.25)),
#   family=poisson,
#   data=pt_summary(data_pt, "timesincevaxany1", postvaxcuts)
# )

# same but with person-time data
# poismod2 <- glm(
#   formula = postest ~ timesincevax_pw ,
#   family=poisson,
#   data=data_pt %>% mutate(timesincevax_pw = timesince_cut(timesincevaxany1, postvaxcuts, "Unvaccinated")) %>% filter(postest_status==0, death_status==0, dereg_status==0)
# )

# and the following pyears call gives the same results
# pyears(
#  Surv(time=tstart, time2=tstop, event=postest) ~ timesincevaxany1,
#  data=data_pt %>% filter(postest_status==0),
#  data.frame = TRUE
# )


