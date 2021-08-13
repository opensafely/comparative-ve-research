

# Preliminaries ----

## Import libraries ----
library('tidyverse')
library('here')
library('glue')
library('survival')

## Import custom user functions from lib
source(here::here("analysis", "lib", "utility_functions.R"))
source(here::here("analysis", "lib", "redaction_functions.R"))
source(here::here("analysis", "lib", "survival_functions.R"))



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

## load A&E diagnosis column names
diagnosis_codes <- jsonlite::fromJSON(
  txt="./analysis/lib/diagnosis_groups.json"
)
diagnosis_col_names <- paste0("emergency_", names(diagnosis_codes), "_date")
diagnosis_short <- str_remove(str_remove(diagnosis_col_names, "emergency_"), "_date")


## Import processed data ----

data_cohort <- read_rds(here::here("output", "data", "data_cohort.rds"))

data_diagnosis <- data_cohort %>%
  transmute(
    patient_id,
    vax1_type,
    vax1_type_descr,
    vax1_day,
    end_date,

    emergency_diagnosis,

    # assume vaccination occurs at the start of the day, and all other events occur at the end of the day.
    # so use vax1_date - 1

    censor_date = pmin(vax1_date - 1 + (7*14), end_date, dereg_date, death_date, covid_vax_any_2_date, na.rm=TRUE),

    # time to last follow up day
    tte_enddate = tte(vax1_date-1, end_date, end_date),

    # time to last follow up day or death or deregistration
    tte_censor = tte(vax1_date-1, censor_date, censor_date),

    tte_test =tte(vax1_date-1, covid_test_date, censor_date, na.censor=FALSE),
    ind_test = censor_indicator(covid_test_date, censor_date),

    tte_postest = tte(vax1_date-1, positive_test_date, censor_date, na.censor=FALSE),
    ind_postest = censor_indicator(positive_test_date, censor_date),

    tte_emergency = tte(vax1_date-1, emergency_date, censor_date, na.censor=FALSE),
    ind_emergency = censor_indicator(emergency_date, censor_date),
  )



get_freqs <- function(day){

  data_wide <- data_diagnosis %>%
    filter(tte_emergency<=day & ind_emergency==1) %>%
    mutate(
      emergency_diagnosis_list=str_split(emergency_diagnosis, "; "),
      dummy_val=1L
    ) %>%
    unnest_longer(col="emergency_diagnosis_list") %>%
    pivot_wider(
      id_cols=-emergency_diagnosis_list,
      names_from=emergency_diagnosis_list,
      names_prefix = "diag_",
      values_from=dummy_val,
      values_fill=0L
    )


  diag_freq <-
    data_wide %>%
    group_by(vax1_type_descr) %>%
    select(starts_with("diag_")) %>%
    summarise(
      across(
        starts_with("diag_"),
        .fns=list(n=sum, pct=mean),
        .names="{.col}.{.fn}",
        na.rm=TRUE
      )
    ) %>%
    pivot_longer(
      cols=starts_with("diag_"),
      names_prefix="diag_",
      names_to=c("diagnosis", ".value"),
      names_sep="\\."
    ) %>%
    mutate(
      diagnosis=factor(diagnosis, levels=diagnosis_short)
    ) %>%
    arrange(vax1_type_descr, diagnosis)

  vax_freq <-
    data_wide %>%
    count(vax1_type_descr, name="n_vax") %>%
    add_count(wt=n_vax, name="n_total") %>%
    mutate(
      pct_vax=n_vax/n_total
    )


  freq <- diag_freq %>% left_join(vax_freq, by="vax1_type_descr")

  freq
}


freqs7 <- get_freqs(7)


plot7 <- freqs7 %>%
  mutate(
    n=if_else(vax1_type_descr==first(vax1_type_descr), n, -n),
    pct=if_else(vax1_type_descr==first(vax1_type_descr), pct, -pct),
    vax1_type_descr = paste0(vax1_type_descr, " (", n_vax, ")")
  ) %>%
  ggplot()+
  geom_bar(aes(x=pct, y=diagnosis, fill=vax1_type_descr), width=freqs7$pct_vax, stat = "identity")+
  #scale_y_discrete(breaks=)
  scale_x_continuous(breaks=seq(-1,1,0.1), labels = abs(seq(-1,1,0.1)))+
  labs(
    y="Diagnosis",
    x="Proportion\n(there may be multiple diagnoses per attendance)",
    fill=NULL
  )+
  theme_minimal()+
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank(),
    panel.grid.minor.x = element_blank(),
    axis.line.x.bottom = element_line(),
  )
plot7


fs::dir_create(here("output", "descriptive", "diagnoses"))

ggsave(plot7, filename=here("output", "descriptive", "diagnoses", "diagnosis_freq7.png"))

