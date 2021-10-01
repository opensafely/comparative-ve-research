# # # # # # # # # # # # # # # # # # # # #
# This script looks at emergency attendnace diagnoses
# An ad-hoc script which is NOT part of the main analysis
# # # # # # # # # # # # # # # # # # # # #

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

## create output directory ----
fs::dir_create(here("output", "descriptive", "diagnoses"))

## load A&E diagnosis column names
lookup <- read_rds(here("analysis", "lib", "diagnosis_groups_lookup.rds")) %>%
  mutate(
    diagnosis_col_names =  paste0("emergency_", group, "_date"),
    diagnosis_short = group,
    diagnosis_long = ECDS_GroupCustom,
  ) %>%
  add_row(
    diagnosis_short="unknown",
    diagnosis_long="(Unknown)"
  )

diagnoses <- set_names(lookup$diagnosis_short, lookup$diagnosis_long)

## Import processed data ----

data_cohort <- read_rds(here("output", "data", "data_cohort.rds"))
data_diagnoses <- read_rds(here("output", "data", "data_diagnoses.rds")) %>%
  filter(patient_id %in% data_cohort$patient_id)
rm(data_cohort)



data_diagnoses <- data_diagnoses %>%
  mutate(
    censor_date = pmin(vax1_date - 1 + (7*14), end_date, dereg_date, death_date, covid_vax_any_2_date, na.rm=TRUE),
    tte_emergency = tte(vax1_date-1, emergency_date, censor_date, na.censor=FALSE),
    ind_emergency = censor_indicator(emergency_date, censor_date),
    vax1_week = lubridate::floor_date(vax1_date, unit="week", week_start=1),
    vax1_month = format(vax1_date, "%b-%y"),
    all=""
  )



diag_freq <-
  data_diagnoses %>%
  group_by(vax1_type_descr) %>%
  summarise(
    across(
      matches("emergency_(.)+_date$"),
      list(
        day1 = ~sum(!is.na(.x) & tte_emergency <=1),
        day2 = ~sum(!is.na(.x) & tte_emergency <=2),
        day3 = ~sum(!is.na(.x) & tte_emergency <=3),
        day4 = ~sum(!is.na(.x) & tte_emergency <=4),
        day5 = ~sum(!is.na(.x) & tte_emergency <=5),
        day6 = ~sum(!is.na(.x) & tte_emergency <=6),
        day7 = ~sum(!is.na(.x) & tte_emergency <=7),
        day8 = ~sum(!is.na(.x) & tte_emergency <=8),
        day14 = ~sum(!is.na(.x) & tte_emergency <=14)
      )
    )
  ) %>%
  pivot_longer(
    cols=-vax1_type_descr,
    names_pattern="emergency_(.+)_date_day(\\d+)",
    names_to= c("diagnosis", "day"),
    values_to="n"
  ) %>% mutate(
    diagnosis_short = factor(diagnosis, levels=diagnoses),
    diagnosis_long = fct_recode(diagnosis_short,  !!!diagnoses)
  )

vax_freq <-
  data_diagnoses %>%
  count(vax1_type_descr, name="n_vax") %>%
  add_count(wt=n_vax, name="n_total") %>%
  mutate(
    pct_vax=n_vax/n_total
  )


freqs <- diag_freq %>%
  left_join(vax_freq, by="vax1_type_descr") %>%
  mutate(
    n=if_else(between(n,1,5), 3L, n), # rounding
    pct=n/n_vax,
    day=as.numeric(day)
  )


## plot diagnosis frequencies ----
#
# get_freqs <- function(day){
#
#   data_wide <- data_diagnoses %>%
#     filter(tte_emergency<=day & ind_emergency==1) %>%
#     mutate(
#       emergency_diagnosis_list=str_split(emergency_diagnosis, "; "),
#       dummy_val=1L
#     ) %>%
#     unnest_longer(col="emergency_diagnosis_list") %>%
#     pivot_wider(
#       id_cols=-emergency_diagnosis_list,
#       names_from=emergency_diagnosis_list,
#       names_prefix = "diag_",
#       values_from=dummy_val,
#       values_fill=0L
#     )
#
#
#   diag_freq <-
#     data_wide %>%
#     group_by(vax1_type_descr) %>%
#     select(starts_with("diag_")) %>%
#     summarise(
#       across(
#         starts_with("diag_"),
#         .fns=list(n=sum, pct=mean),
#         .names="{.col}.{.fn}",
#         na.rm=TRUE
#       )
#     ) %>%
#     pivot_longer(
#       cols=starts_with("diag_"),
#       names_prefix="diag_",
#       names_to=c("diagnosis", ".value"),
#       names_sep="\\."
#     ) %>%
#     mutate(
#       diagnosis_short = factor(diagnosis, levels=diagnoses),
#       diagnosis_long = fct_recode(diagnosis_short,  !!!diagnoses)
#     ) %>%
#     arrange(vax1_type_descr, diagnosis_long)
#
#   vax_freq <-
#     data_wide %>%
#     count(vax1_type_descr, name="n_vax") %>%
#     add_count(wt=n_vax, name="n_total") %>%
#     mutate(
#       pct_vax=n_vax/n_total
#     )
#
#
#   freq <- diag_freq %>%
#     left_join(vax_freq, by="vax1_type_descr") %>%
#     mutate(day = day)
#
#   freq
# }
#
#
# freqs <- bind_rows(
#   get_freqs(1),
#   get_freqs(2),
#   get_freqs(3),
#   get_freqs(4),
#   get_freqs(5),
#   get_freqs(6),
#   get_freqs(7),
#   get_freqs(8),
#   get_freqs(14)
# )

plot_freq <- function(day){
  dayy <- day

  freqs_day <- freqs %>%
    filter(day==dayy)

  plot_freqs <-
    freqs_day %>%
    mutate(
      day_name = glue("Proportion of attendance diagnoses\nafter {dayy} days"),
      n=if_else(vax1_type_descr==first(vax1_type_descr), n, -n),
      pct=if_else(vax1_type_descr==first(vax1_type_descr), pct, -pct),
      vax1_type_descr = paste0(vax1_type_descr, " (N = ", n_vax, ")")
    ) %>%
    ggplot()+
    geom_bar(aes(x=pct, y=fct_rev(diagnosis_long), fill=vax1_type_descr), width=freqs_day$pct_vax, stat = "identity")+
    geom_vline(aes(xintercept=0), colour = "black")+
    scale_fill_brewer(type="qual", palette="Set1")+
    scale_y_discrete(position = "right")+
    scale_x_continuous(labels = abs)+
    labs(
      y=NULL,
      x="Proportion",
      fill=NULL,
      title = glue("Post-vaccination emergency attendances after {dayy} days"),
      subtitle= "There may be multiple diagnoses per attendance"
    )+
    theme_minimal()+
    theme(
      panel.grid.major.y = element_blank(),
      panel.grid.minor.y = element_blank(),
      #panel.grid.minor.x = element_blank(),
      axis.line.x.bottom = element_line(),
      plot.title.position = "plot",
      legend.position = "bottom"

    )
  plot_freqs

}


ggsave(plot_freq(1), filename=here("output", "descriptive", "diagnoses", "plot_diagnosis_freq1.png"))
ggsave(plot_freq(2), filename=here("output", "descriptive", "diagnoses", "plot_diagnosis_freq2.png"))
ggsave(plot_freq(3), filename=here("output", "descriptive", "diagnoses", "plot_diagnosis_freq3.png"))
ggsave(plot_freq(4), filename=here("output", "descriptive", "diagnoses", "plot_diagnosis_freq4.png"))
ggsave(plot_freq(5), filename=here("output", "descriptive", "diagnoses", "plot_diagnosis_freq5.png"))
ggsave(plot_freq(6), filename=here("output", "descriptive", "diagnoses", "plot_diagnosis_freq6.png"))
ggsave(plot_freq(7), filename=here("output", "descriptive", "diagnoses", "plot_diagnosis_freq7.png"))
ggsave(plot_freq(8), filename=here("output", "descriptive", "diagnoses", "plot_diagnosis_freq8.png"))
ggsave(plot_freq(14), filename=here("output", "descriptive", "diagnoses", "plot_diagnosis_freq14.png"))


## plot diagnosis-specific survival-curves ----

ceiling_any <- function(x, to=1){
  # round to nearest 100 millionth to avoid floating point errors
  ceiling(plyr::round_any(x/to, 1/100000000))*to
}

survobj <- function(.data, diagnosis, group, threshold){

  dat <- .data %>%
    mutate(
      event_date = .[[glue("emergency_{diagnosis}_date")]],
      .time = tte(vax1_date-1, event_date, censor_date, na.censor=FALSE),
      .indicator = censor_indicator(event_date, censor_date),
    )

  unique_times <- unique(c(dat[[".time"]]))

  dat_surv <- dat %>%
    group_by(across(all_of(c("vax1_type_descr", group)))) %>%
    transmute(
      .time, .indicator
    )

  dat_surv1 <- dat_surv %>%
    nest() %>%
    mutate(
      n_events = map_int(data, ~sum(.x$.indicator, na.rm=TRUE)),
      surv_obj = map(data, ~{
        survfit(Surv(.time, .indicator) ~ 1, data = .x, conf.type="log-log")
      }),
      surv_obj_tidy = map(surv_obj, ~tidy_surv(.x, addtimezero = TRUE)),
    ) %>%
    select("vax1_type_descr", all_of(group), n_events, surv_obj_tidy) %>%
    unnest(surv_obj_tidy)

  dat_surv_rounded <- dat_surv1 %>%
    mutate(
      surv = ceiling_any(surv, 1/floor(max(n.risk, na.rm=TRUE)/(threshold+1))),
      surv.ll = ceiling_any(surv.ll, 1/floor(max(n.risk, na.rm=TRUE)/(threshold+1))),
      surv.ul = ceiling_any(surv.ul, 1/floor(max(n.risk, na.rm=TRUE)/(threshold+1))),
    )
  dat_surv_rounded
}

surv_list <- vector("list", length(diagnoses))
names(surv_list) <- diagnoses

for(diagnosis in names(surv_list)){
  surv_list[[diagnosis]] <-
    survobj(data_diagnoses, diagnosis, "vax1_month", 0) %>%
    mutate(diagnosis = diagnosis)
}

surv_long_month <- bind_rows(surv_list) %>%
  mutate(
    diagnosis_short = factor(diagnosis, levels=diagnoses),
    diagnosis_long = fct_recode(diagnosis,  !!!diagnoses),
    diagnosis_wrap = fct_relabel(diagnosis_long, ~str_wrap(., 15)),
  )

surv_plot_month <-
  surv_long_month %>%
  filter(time <= 14) %>%
  ggplot(aes(group=vax1_type_descr, colour=vax1_type_descr, fill=vax1_type_descr)) +
  geom_step(aes(x=time, y=surv))+
  geom_rect(aes(xmin=time, xmax=leadtime, ymin=surv.ll, ymax=surv.ul), alpha=0.1, colour="transparent")+
  facet_grid(rows=vars(diagnosis_wrap), cols=vars(vax1_month))+
  scale_color_brewer(type="qual", palette="Set1", na.value="grey")+
  scale_fill_brewer(type="qual", palette="Set1", guide="none", na.value="grey")+
  scale_y_continuous(expand = expansion(mult=c(0,0.01)))+
  coord_cartesian(xlim=c(0, NA))+
  labs(
    x="Days since vaccination",
    y="1 - emergency attendance rate",
    colour=NULL,
    fill=NULL,
    title=NULL
  )+
  theme_minimal(base_size=9)+
  theme(
    legend.position = "bottom",
    axis.line.x = element_line(colour = "black"),
    panel.grid.minor.x = element_blank(),
    strip.text.y = element_text(angle = 0)
  )

ggsave(
  surv_plot_month,
  filename=here("output", "descriptive", "diagnoses", "plot_diagnosis_surv_by_month.png"),
  units="cm", width=15, height=30
)




surv_list <- vector("list", length(diagnoses))
names(surv_list) <- diagnoses

for(diagnosis in names(surv_list)){
  surv_list[[diagnosis]] <-
    survobj(data_diagnoses, diagnosis, "all", 0) %>%
    mutate(diagnosis = diagnosis)
}

surv_long <- bind_rows(surv_list) %>%
  mutate(
    diagnosis_short = factor(diagnosis, levels=diagnoses),
    diagnosis_long = fct_recode(diagnosis,  !!!diagnoses),
    diagnosis_wrap = fct_relabel(diagnosis_long, ~str_wrap(., 15)),
  )

surv_plot <-
  surv_long %>%
  filter(time <= 14) %>%
  ggplot(aes(group=vax1_type_descr, colour=vax1_type_descr, fill=vax1_type_descr)) +
  geom_step(aes(x=time, y=surv))+
  geom_rect(aes(xmin=time, xmax=leadtime, ymin=surv.ll, ymax=surv.ul), alpha=0.1, colour="transparent")+
  facet_wrap(vars(diagnosis_wrap))+
  scale_color_brewer(type="qual", palette="Set1", na.value="grey")+
  scale_fill_brewer(type="qual", palette="Set1", guide="none", na.value="grey")+
  scale_y_continuous(expand = expansion(mult=c(0,0.01)))+
  coord_cartesian(xlim=c(0, NA))+
  labs(
    x="Days since vaccination",
    y="1 - emergency attendance rate",
    colour=NULL,
    fill=NULL,
    title=NULL
  )+
  theme_minimal(base_size=9)+
  theme(
    legend.position = "bottom",
    axis.line.x = element_line(colour = "black"),
    panel.grid.minor.x = element_blank(),
    strip.text.y = element_text(angle = 0)
  )

ggsave(
  surv_plot,
  filename=here("output", "descriptive", "diagnoses", "plot_diagnosis_surv.png"),
  units="cm", width=15, height=15
)




