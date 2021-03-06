# # # # # # # # # # # # # # # # # # # # #
# This script plots event rates by calendar time under follow up
# # # # # # # # # # # # # # # # # # # # #

# Preliminaries ----

## Import libraries ----
library('tidyverse')
library('here')
library('glue')

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

## import metadata ----
var_labels <- read_rds(here("output", "data", "metadata_labels.rds"))
metadata_outcomes <- read_rds(here("output", "data", "metadata_outcomes.rds"))

lastfupday <- 140

## create output directory ----
fs::dir_create(here("output", "descriptive", "eventdate"))

data_cohort <- read_rds(here::here("output", "data", "data_cohort.rds"))

data_tte <- data_cohort %>%
  transmute(
    patient_id,
    vax1_date,
    vax1_day,
    vax1_type,
    vax1_type_descr,
    region,

    end_date,
    censor_date = pmin(
      vax1_date - 1 + lastfupday,
      dereg_date,
      death_date,
      end_date,
      na.rm=TRUE
    ),

    # time to last follow up day
    tte_enddate = tte(vax1_date-1, end_date, end_date),

    # time to last follow up day or death or deregistration
    tte_censor = tte(vax1_date-1, censor_date, censor_date),

    tte_vax1 = tte(vax1_date-1, vax1_date, censor_date),
    ind_vax1 = censor_indicator(vax1_date, censor_date),

    tte_postest = tte(vax1_date-1, positive_test_date, censor_date, na.censor=TRUE),
    ind_postest = censor_indicator(positive_test_date, censor_date),

    tte_covidemergency = tte(vax1_date-1, emergency_covid_date, censor_date, na.censor=TRUE),
    ind_covidemergency = censor_indicator(emergency_covid_date, censor_date),

    tte_covidadmitted = tte(vax1_date-1, covidadmitted_date, censor_date, na.censor=TRUE),
    ind_covidadmitted = censor_indicator(covidadmitted_date, censor_date),

  )

alltimes <- expand(data_tte, patient_id, times=as.integer(full_seq(c(1, tte_censor),1)))

data_pt <- tmerge(
  data1 = data_tte,
  data2 = data_tte,
  id = patient_id,
  tstart = 0L,
  tstop = tte_censor,
  vax1 = event(tte_vax1),
  postest = event(tte_postest),
  covidemergency = event(tte_covidemergency),
  covidadmitted = event(tte_covidadmitted),

  status_vax1 = tdc(tte_vax1),
  status_postest = tdc(tte_postest),
  status_covidemergency = tdc(tte_covidemergency),
  status_covidadmitted = tdc(tte_covidadmitted),
  status_censor = tdc(tte_censor)
) %>%
  tmerge( # add row for each day
    data1 = .,
    data2 = alltimes,
    id = patient_id,
    alltimes = event(times, times)
  ) %>%
  filter(
    status_censor==0 # not strictly necessary as tstop=tte_censor above
  ) %>%
  mutate(
    date = as.Date(vax1_date)+tstart,
    date_week = lubridate::floor_date(date, unit="week", week_start=1)
  )


rm(data_tte)
rm(data_cohort)

data_by_day <-
  data_pt %>%
  group_by(date_week,vax1_type_descr) %>%
  summarise(
    #vax1 = mean(vax1),
    #underfup = n(),
    postest=weighted.mean(postest, 1-status_postest),
    covidemergency=weighted.mean(covidemergency, 1-status_covidemergency),
    covidadmitted=weighted.mean(covidadmitted, 1-status_covidadmitted),

  ) %>%
  pivot_longer(
    cols=c(postest, covidemergency,covidadmitted),
    names_to="outcome",
    values_to="rate"
  ) %>%
  left_join(
    metadata_outcomes, by="outcome"
  ) %>%
  mutate(
    outcome_descr=fct_inorder(outcome_descr),
    outcome_descr_wrap=fct_inorder(str_wrap(outcome_descr,15))
  ) %>%
  group_by(outcome_descr,vax1_type_descr) %>%
  mutate(
    rate_end=lead(rate)
  )


event_rates <-
  data_by_day %>%
  ggplot()+
  geom_hline(aes(yintercept=0), colour='black')+
 # geom_step(aes(x=date_week, y=rate, colour=vax1_type_descr), size=1)+
  geom_segment(aes(x=date_week, y=rate, xend=date_week+7, yend=rate, colour=vax1_type_descr), size=1)+
  geom_segment(aes(x=date_week+7, y=rate, xend=date_week+7, yend=rate_end, colour=vax1_type_descr), size=0.5)+
  facet_grid(rows=vars(outcome_descr_wrap), switch="y", scales = "free_y")+
  scale_x_date(
    breaks = seq(min(data_by_day$date_week), max(data_by_day$date_week)+15,by=28),
    limits = c(lubridate::floor_date(min(data_by_day$date_week), "1 month"), NA),
    labels = scales::label_date("%d/%m"),
    expand = expansion(add=3),
    sec.axis = sec_axis(
      trans = ~as.Date(.),
      breaks=as.Date(seq(floor_date(min(data_by_day$date_week), "month"), ceiling_date(max(data_by_day$date_week), "month"),by="month")),
      labels = scales::label_date("%b %y")
    )
  )+
  scale_y_continuous(expand=expansion(mult=c(0,0.05)), labels=scales::label_number(0.01, scale=1000))+
  scale_colour_brewer(type="qual", palette="Set1")+
  labs(
    x="Date",
    y="Incidence per 1000 people",
    colour=NULL
  )+
  theme_minimal()+
  theme(
    legend.position = c(0.95,0.16),
    legend.justification = c(1,0),
    strip.placement = "outside",
    strip.text.y.left = element_text(angle = 0),
    axis.text.x.top = element_text(hjust=0),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    axis.ticks.x = element_line(colour = 'black')
  )



write_rds(event_rates, here("output", "descriptive", "eventdate", "eventdate_step.rds"))
ggsave(event_rates, filename="plot_eventdate_step.png", path=here("output", "descriptive", "eventdate"))
ggsave(event_rates, filename="plot_eventdate_step.svg", path=here("output", "descriptive", "eventdate"))
ggsave(event_rates, filename="plot_eventdate_step.pdf", path=here("output", "descriptive", "eventdate"))




data_by_day_region <-
  data_pt %>%
  group_by(date_week,region,vax1_type_descr) %>%
  summarise(
    #vax1 = mean(vax1),
    #underfup = n(),
    postest=weighted.mean(postest, 1-status_postest),
    covidemergency=weighted.mean(covidemergency, 1-status_covidemergency),
    covidadmitted=weighted.mean(covidadmitted, 1-status_covidadmitted),

  ) %>%
  pivot_longer(
    cols=c(postest, covidemergency,covidadmitted),
    names_to="outcome",
    values_to="rate"
  ) %>%
  left_join(
    metadata_outcomes, by="outcome"
  ) %>%
  mutate(
    outcome_descr=fct_inorder(outcome_descr),
    outcome_descr_wrap=fct_inorder(str_wrap(outcome_descr,15))
  ) %>%
  group_by(outcome_descr,region,vax1_type_descr) %>%
  mutate(
    rate_end=lead(rate)
  )

plot_outcome <- function(outcome){
  outcomee <- outcome

    data_by_day_region %>%
    bind_rows(data_by_day %>% mutate(region="England")) %>%
    ungroup() %>%
    filter(outcome==outcomee) %>%
    mutate(region=fct_inorder(region)) %>%
    ggplot()+
    geom_hline(aes(yintercept=0), colour='black')+
    #geom_step(aes(x=date_week, y=rate, colour=region), size=1)+
    #geom_line(aes(x=date_week+3.5, y=rate, colour=region), size=1)+
    geom_segment(aes(x=date_week, y=rate, xend=date_week+7, yend=rate, colour=vax1_type_descr), size=1)+
    geom_segment(aes(x=date_week+7, y=rate, xend=date_week+7, yend=rate_end, colour=vax1_type_descr), size=0.2)+
    facet_wrap(vars(region), scales = "fixed", ncol=2, dir="v")+
    scale_x_date(
      breaks = seq(min(data_by_day$date_week), max(data_by_day$date_week)+15,by=7*4),
      limits = c(lubridate::floor_date(min(data_by_day$date_week), "1 month"), NA),
      labels = scales::label_date("%d/%m"),
      expand = expansion(add=3),
      sec.axis = sec_axis(
        trans = ~as.Date(.),
        breaks=as.Date(seq(floor_date(min(data_by_day$date_week), "month"), ceiling_date(max(data_by_day$date_week), "month"),by="month")),
        labels = scales::label_date("%b %y")
      )
    )+
    scale_y_continuous(expand=expansion(mult=c(0,0.05)), labels=scales::label_number(0.01, scale=1000))+
    scale_colour_brewer(type="qual", palette="Set1")+
    labs(
      x="Date",
      y="Incidence per 1000 people",
      colour=NULL
    )+
    theme_minimal()+
    theme(
      legend.position = c(0.97,0.97),
      legend.justification = c(1,1),
      strip.placement = "outside",
      strip.text.y.left = element_text(angle = 0, hjust=1),
      axis.text.x.top = element_text(hjust=0),
      panel.grid.major.x = element_blank(),
      panel.grid.minor.x = element_blank(),
      axis.ticks.x = element_line(colour = 'black')
    )

}

plot_postest <- plot_outcome("postest")
plot_covidemergency <- plot_outcome("covidemergency")
plot_covidadmitted <- plot_outcome("covidadmitted")

ggsave(plot_postest, filename="plot_region_postest_step.png", path=here("output", "descriptive", "eventdate"))
ggsave(plot_postest, filename="plot_region_postest_step.svg", path=here("output", "descriptive", "eventdate"))
ggsave(plot_postest, filename="plot_region_postest_step.pdf", path=here("output", "descriptive", "eventdate"))

ggsave(plot_covidemergency, filename="plot_region_covidemergency_step.png", path=here("output", "descriptive", "eventdate"))
ggsave(plot_covidemergency, filename="plot_region_covidemergency_step.svg", path=here("output", "descriptive", "eventdate"))
ggsave(plot_covidemergency, filename="plot_region_covidemergency_step.pdf", path=here("output", "descriptive", "eventdate"))

ggsave(plot_covidadmitted, filename="plot_region_covidadmitted_step.png", path=here("output", "descriptive", "eventdate"))
ggsave(plot_covidadmitted, filename="plot_region_covidadmitted_step.svg", path=here("output", "descriptive", "eventdate"))
ggsave(plot_covidadmitted, filename="plot_region_covidadmitted_step.pdf", path=here("output", "descriptive", "eventdate"))

