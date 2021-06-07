
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
library('lubridate')
library('survival')
library('gt')
library('gtsummary')

## Import custom user functions from lib

source(here::here("lib", "utility_functions.R"))
source(here::here("lib", "redaction_functions.R"))
source(here::here("lib", "survival_functions.R"))

## import command-line arguments ----

args <- commandArgs(trailingOnly=TRUE)


if(length(args)==0){
  # use for interactive testing
  cohort <- "over80s"
} else {
  # use for actions
  cohort <- args[[1]]
}

## import global vars ----
gbl_vars <- jsonlite::fromJSON(
  txt="./analysis/global-variables.json"
)
#list2env(gbl_vars, globalenv())


### import outcomes, exposures, and covariate formulae ----
## these are created in data_define_cohorts.R script

list_formula <- read_rds(here::here("output", "data", "list_formula.rds"))
list2env(list_formula, globalenv())


postvaxcuts <- c(0, 7, 14, 21, 28)


## Import processed data ----


data_fixed <- read_rds(here::here("output", cohort, "data", glue::glue("data_wide_fixed.rds")))
#data_cp <- read_rds(here::here("output", cohort, "data", glue::glue("data_cp.rds")))
data_pt <- read_rds(here::here("output", cohort, "data", glue::glue("data_pt.rds")))

# create snapshot data ----

## choose snapshot times ----
snapshot_days <- c(0, 28, 56)

## create snapshop format dataset ----
# ie, one row per person per snapshot date
data_ss <- data_pt %>%
  filter(tstart %in% snapshot_days) %>%
  mutate(snapshot_day = tstart) %>%
  arrange(snapshot_day, patient_id) %>%
  left_join(data_fixed, by = "patient_id")


# create tables ----


data_tab <- data_ss %>%
  mutate(
    date = factor(as.Date(gbl_vars$start_date) + snapshot_day),
    snapshot_day = paste0("day ", snapshot_day),
    vaxany_status=fct_case_when(
      timesincevaxany1<=0 ~ "Unvaccinated",
      timesincevaxany1>0 ~ "Vaccinated",
      TRUE ~ NA_character_
    ),

    ageband = cut(
      age,
      breaks=c(-Inf, 70, 75, 80, 85, 90, 95, Inf),
      labels=c("under 70", "70-74", "75-79", "80-84", "85-89", "90-94", "95+"),
      right=FALSE
    ),

    postest_status = postest_status==1,
    covidadmitted_status = covidadmitted_status==1,
    coviddeath_status = coviddeath_status==1,
    death_status = death_status==1,
    Participants = "1"

  ) %>%
  droplevels()# %>%
 # mutate(across(
 #   .cols = where(is.logical),
 #   .fns = ~if_else(.x, "yes", "no")
 # ))



tab_summary <- data_tab %>% transmute(
  ageband, sex, imd, region, ethnicity_combined,
  bmi,
  heart_failure,
  other_heart_disease,

  dialysis,
  diabetes,
  chronic_liver_disease,

  current_copd,
  #cystic_fibrosis,
  other_resp_conditions,

  lung_cancer,
  haematological_cancer,
  cancer_excl_lung_and_haem,

  #chemo_or_radio,
  #solid_organ_transplantation,
  #bone_marrow_transplant,
  #sickle_cell_disease,
  #permanant_immunosuppression,
  #temporary_immunosuppression,
  #asplenia,
  #dmards,
  any_immunosuppression,

  dementia,
  other_neuro_conditions,
  LD_incl_DS_and_CP,
  psychosis_schiz_bipolar,

  multimorb,

  shielded,

  flu_vaccine,

  efi_cat,

  snapshot_day, vaxany_status
) %>%
group_split(snapshot_day) %>%
map(
  ~tbl_summary(
    .x %>% mutate(vaxany_status=droplevels(vaxany_status)) %>% select(-snapshot_day),
    by=vaxany_status,
    label=list(
      ageband ~ "Age",
      sex ~ "Sex",
      imd ~ "IMD",
      region ~ "Region",
      ethnicity_combined ~ "Ethnicity",

      bmi ~ "Body Mass Index",

      heart_failure ~ "Heart failure",
      other_heart_disease ~ "Other heart disease",

      dialysis ~ "Dialysis",
      diabetes ~ "Diabetes",
      chronic_liver_disease ~ "Chronic liver disease",

      current_copd ~ "COPD",
      #cystic_fibrosis ~ "Cystic fibrosis",
      other_resp_conditions ~ "Other respiratory conditions",

      lung_cancer ~ "Lung Cancer",
      haematological_cancer ~ "Haematological cancer",
      cancer_excl_lung_and_haem ~ "Cancer excl. lung, haemo",

      #chemo_or_radio ~ "Chemo- or radio-therapy",
      #solid_organ_transplantation ~ "Solid organ transplant",
      #bone_marrow_transplant ~ "Bone marrow transplant",
      #sickle_cell_disease ~ "Sickle Cell Disease",
      #permanant_immunosuppression ~ "Permanent immunosuppression",
      #temporary_immunosuppression ~ "Temporary Immunosuppression",
      #asplenia ~ "Asplenia",
      #dmards ~ "DMARDS",

      any_immunosuppression ~ "Immunosuppressed",

      dementia ~ "Dementia",
      other_neuro_conditions ~ "Other neurological conditions",

      LD_incl_DS_and_CP ~ "Learning disabilities",
      psychosis_schiz_bipolar ~ "Serious mental illness",

      multimorb ~ "Morbidity count",

      shielded ~ "Shielding criteria met",

      flu_vaccine ~ "Flu vaccine in previous 5 years",

      efi_cat ~ "Frailty"

    )
  ) %>%
  modify_footnote(starts_with("stat_") ~ NA)
) %>%
tbl_merge(tab_spanner=c("Day 0", "Day 28", "Day 56"))


## create output directories ----
dir.create(here::here("output", cohort, "descr", "tables"), showWarnings = FALSE, recursive=TRUE)

#gt::gtsave(as_gt(tab_summary), here::here("output", cohort, "descr", "tables", "table1.png"))
#gt::gtsave(as_gt(tab_summary), here::here("output", cohort, "descr", "tables", "table1.rtf"))
gtsave(as_gt(tab_summary), here::here("output", cohort, "descr", "tables", "table1.html"))



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

rrCI_exact <- function(n, pt, ref_n, ref_pt, group, accuracy=0.001){

  # use exact methods if incidence is very low for immediate post-vaccine outcomes

  rate <- n/pt
  ref_rate <- ref_n/ref_pt
  rr <- rate/ref_rate

  ll = ref_pt/pt * (n/(ref_n+1)) * 1/qf(2*(ref_n+1), 2*n, p = 0.05/2, lower.tail = FALSE)
  ul = ref_pt/pt * ((n+1)/ref_n) * qf(2*(n+1), 2*ref_n, p = 0.05/2, lower.tail = FALSE)

  if_else(
    group==levels(group)[1],
    NA_character_,
    paste0("(", scales::number_format(accuracy=accuracy)(ll), "-", scales::number_format(accuracy=accuracy)(ul), ")")
  )

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

  if_else(
    dat2$x==first(dat2$x),
    NA_character_,
    paste0("(", scales::number_format(accuracy=accuracy)(dat2$conf.low), "-", scales::number_format(accuracy=accuracy)(dat2$conf.high), ")")
  )
}

pt_summary <- function(data, fup, timesince, postvaxcuts, baseline){

  unredacted <- data %>%
  mutate(
    timesincevax = data[[timesince]],
    fup = data[[fup]],
    timesincevax_pw = timesince_cut(timesincevax, postvaxcuts, baseline),
  ) %>%
  filter(fup==1) %>%
  group_by(timesincevax_pw) %>%
  summarise(
    postest_yearsatrisk=sum(postest_status==0)/365.25,
    postest_n=sum(postest),
    postest_rate=postest_n/postest_yearsatrisk,

    covidadmitted_yearsatrisk=sum(covidadmitted_status==0)/365.25,
    covidadmitted_n=sum(covidadmitted),
    covidadmitted_rate=covidadmitted_n/covidadmitted_yearsatrisk,

    coviddeath_yearsatrisk=sum(coviddeath_status==0)/365.25,
    coviddeath_n=sum(coviddeath),
    coviddeath_rate=coviddeath_n/coviddeath_yearsatrisk,

    noncoviddeath_yearsatrisk=sum(noncoviddeath_status==0)/365.25,
    noncoviddeath_n=sum(noncoviddeath),
    noncoviddeath_rate=noncoviddeath_n/noncoviddeath_yearsatrisk,

    # death_yearsatrisk=sum(death_status==0)/365.25,
    # death_n=sum(death),
    # death_rate=death_n/death_yearsatrisk,
  ) %>%
  ungroup() %>%
  mutate(
    postest_rr=postest_rate/first(postest_rate),
    covidadmitted_rr=covidadmitted_rate/first(covidadmitted_rate),
    coviddeath_rr=coviddeath_rate/first(coviddeath_rate),
    noncoviddeath_rr=noncoviddeath_rate/first(noncoviddeath_rate),

    postest_rrCI = rrCI_exact(postest_n, postest_yearsatrisk, first(postest_n), first(postest_yearsatrisk), timesincevax_pw, 0.01),
    covidadmitted_rrCI = rrCI_exact(covidadmitted_n, covidadmitted_yearsatrisk, first(covidadmitted_n), first(covidadmitted_yearsatrisk),  timesincevax_pw, 0.01),
    coviddeath_rrCI = rrCI_exact(coviddeath_n, coviddeath_yearsatrisk, first(coviddeath_n), first(coviddeath_yearsatrisk),  timesincevax_pw, 0.01),
    noncoviddeath_rrCI = rrCI_exact(noncoviddeath_n, noncoviddeath_yearsatrisk, first(noncoviddeath_n), first(noncoviddeath_yearsatrisk), timesincevax_pw, 0.01),
  )

  redacted <- unredacted %>%
    mutate(
      postest_rate = redactor2(postest_n, 5, postest_rate),
      covidadmitted_rate = redactor2(covidadmitted_n, 5, covidadmitted_rate),
      coviddeath_rate = redactor2(coviddeath_n, 5, coviddeath_rate),
      noncoviddeath_rate = redactor2(noncoviddeath_n, 5, noncoviddeath_rate),
      #death_rate = redactor2(death_n, 5, death_rate),

      postest_rr = redactor2(postest_n, 5, postest_rr),
      covidadmitted_rr = redactor2(covidadmitted_n, 5, covidadmitted_rr),
      coviddeath_rr = redactor2(coviddeath_n, 5, coviddeath_rr),
      noncoviddeath_rr = redactor2(noncoviddeath_n, 5, noncoviddeath_rr),
      #death_rr = redactor2(death_n, 5, death_rr)

      postest_rrCI = redactor2(postest_n, 5, postest_rrCI),
      covidadmitted_rrCI = redactor2(covidadmitted_n, 5, covidadmitted_rrCI),
      coviddeath_rrCI = redactor2(coviddeath_n, 5, coviddeath_rrCI),
      noncoviddeath_rrCI = redactor2(noncoviddeath_n, 5, noncoviddeath_rrCI),

      postest_n = redactor2(postest_n, 5),
      covidadmitted_n = redactor2(covidadmitted_n, 5),
      coviddeath_n = redactor2(coviddeath_n, 5),
      noncoviddeath_n = redactor2(noncoviddeath_n, 5),
      #death_n = redactor2(death_n, 5)
    )

  redacted
}

data_pt_fup <- data_pt %>%
mutate(
  fup_any = (death_status==0 & dereg_status==0),
  fup_pfizer = (death_status==0 & dereg_status==0 & vaxaz1_status==0),
  fup_az = (death_status==0 & dereg_status==0 & vaxpfizer1_status==0 & tstart>=27),
  all=0
)


data_summary_any <-
  bind_rows(
    pt_summary(data_pt_fup, "fup_any", "timesincevaxany1", postvaxcuts, "Unvaccinated"),
    pt_summary(data_pt_fup, "fup_any", "all", postvaxcuts, "Total") %>% mutate(across(.cols=ends_with("_rr"), .fns = ~ NA_real_)),
  ) %>%
  mutate(brand ="Any")

data_summary_pfizer <-
  bind_rows(
    pt_summary(data_pt_fup, "fup_pfizer", "timesincevaxpfizer1", postvaxcuts, "Unvaccinated"),
    pt_summary(data_pt_fup, "fup_pfizer", "all", postvaxcuts, "Total") %>% mutate(across(.cols=ends_with("_rr"), .fns = ~ NA_real_)),
  ) %>%
  mutate(brand ="BNT162b2")

data_summary_az <-
  bind_rows(
    pt_summary(data_pt_fup, "fup_az", "timesincevaxaz1", postvaxcuts, "Unvaccinated"),
    pt_summary(data_pt_fup, "fup_az", "all", postvaxcuts, "Total") %>% mutate(across(.cols=ends_with("_rr"), .fns = ~ NA_real_)),
  ) %>%
  mutate(brand ="ChAdOx1")


data_summary <- bind_rows(
  data_summary_any,
  data_summary_pfizer,
  data_summary_az
) %>%
mutate(
  postest_q = format_ratio(postest_n,postest_yearsatrisk),
  covidadmitted_q = format_ratio(covidadmitted_n,covidadmitted_yearsatrisk),
  coviddeath_q = format_ratio(coviddeath_n,coviddeath_yearsatrisk),
  noncoviddeath_q = format_ratio(noncoviddeath_n,noncoviddeath_yearsatrisk),
) %>%
select(brand, starts_with("timesince"), ends_with(c("_q","_rr", "_rrCI")))


tab_summary <- data_summary %>%
  gt(
    groupname_col = "brand",
  ) %>%
   cols_label(
     brand = "Vaccine brand",
     timesincevax_pw = "Time since first dose",


     postest_q = "Events / person-years",
     covidadmitted_q = "Events / person-years",
     coviddeath_q = "Events / person-years",
     noncoviddeath_q = "Events / person-years",
     #death_q = "Events per person-years at risk",

     # postest_yearsatrisk = "Person-years at risk",
     # covidadmitted_yearsatrisk = "Person-years at risk",
     # coviddeath_yearsatrisk = "Person-years at risk",
     # noncoviddeath_yearsatrisk = "Person-years at risk",
     # #death_yearsatrisk = "Person-years at risk",
     #
     # postest_n = "Events",
     # covidadmitted_n = "Events",
     # coviddeath_n = "Events",
     # noncoviddeath_n = "Events",
     # #death_n = "Events",
     #
     # postest_rate = "Rate/year",
     # covidadmitted_rate = "Rate/year",
     # coviddeath_rate = "Rate/year",
     # noncoviddeath_rate = "Rate/year",
     # #death_rate = "Rate/year"

     postest_rr = "Rate ratio",
     covidadmitted_rr = "Rate ratio",
     coviddeath_rr = "Rate ratio",
     noncoviddeath_rr = "Rate ratio",

     postest_rrCI = "95% CI",
     covidadmitted_rrCI = "95% CI",
     coviddeath_rrCI = "95% CI",
     noncoviddeath_rrCI = "95% CI"
   ) %>%
  tab_spanner(
    label = "Positive test",
    columns = starts_with("postest")
  ) %>%
  tab_spanner(
    label = "COVID-related admission",
    columns = starts_with("covidadmitted")
  ) %>%
  tab_spanner(
    label = "COVID-related death",
    columns = starts_with("coviddeath")
  ) %>%
  tab_spanner(
    label = "Non-COVID-related death",
    columns = starts_with("noncoviddeath")
  ) %>%
  # tab_spanner(
  #   label = "Any death",
  #   columns = starts_with("death")
  # ) %>%
  # fmt_number(
  #   columns = ends_with(c("yearsatrisk")),
  #   decimals = 0
  # ) %>%
  fmt_number(
    columns = ends_with(c("rr")),
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
    columns = "timesincevax_pw"
  )

gtsave(tab_summary, here::here("output", cohort, "descr", "tables", "table_pt.html"))


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

