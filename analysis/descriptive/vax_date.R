

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

## create output directory ----
fs::dir_create(here("output", "descriptive", "vaxdate"))

data_cohort <- read_rds(here::here("output", "data", "data_cohort.rds"))

cumulvax <- data_cohort %>%
  group_by(vax1_type_descr, vax1_date) %>%
  summarise(
    n=n()
  ) %>%
  group_by(vax1_type_descr) %>%
  arrange(vax1_date) %>%
  mutate(
    cumuln = cumsum(n)
  )


plot_stack <-
  ggplot(cumulvax)+
  geom_area(
    aes(
      x=vax1_date, y=cumuln,
      group=vax1_type_descr,
      fill=vax1_type_descr
    ),
    alpha=0.5
  )+
  scale_x_date(
    breaks = seq(min(cumulvax$vax1_date),max(cumulvax$vax1_date)+1,by=14),
    limits = c(lubridate::floor_date((min(cumulvax$vax1_date)), "1 month"), NA),
    labels = scales::date_format("%d/%m"),
    expand = expansion(0),
    sec.axis = sec_axis(
      trans = ~as.Date(.),
      breaks=as.Date(seq(floor_date(min(cumulvax$vax1_date), "month"), ceiling_date(max(cumulvax$vax1_date), "month"),by="month")),
      labels = scales::date_format("%b %y")
    )
  )+
  scale_fill_brewer(type="qual", palette="Set1")+
  labs(
    x="Date",
    y="Vaccination status",
    colour=NULL,
    fill=NULL,
    alpha=NULL
  ) +
  theme_minimal()+
  theme(legend.position = "bottom")


plot_step <-
  ggplot(cumulvax)+
  geom_step(
    aes(
      x=vax1_date, y=cumuln,
      group=vax1_type_descr,
      colour=vax1_type_descr
    )
  )+
  scale_x_date(
    breaks = seq(min(cumulvax$vax1_date),max(cumulvax$vax1_date)+1,by=14),
    limits = c(lubridate::floor_date((min(cumulvax$vax1_date)), "1 month"), NA),
    labels = scales::date_format("%d/%m"),
    expand = expansion(0),
    sec.axis = sec_axis(
      trans = ~as.Date(.),
      breaks=as.Date(seq(floor_date(min(cumulvax$vax1_date), "month"), ceiling_date(max(cumulvax$vax1_date), "month"),by="month")),
      labels = scales::date_format("%b %y")
    )
  )+
  scale_colour_brewer(type="qual", palette="Set1")+
  labs(
    x="Date",
    y="Vaccination status",
    colour=NULL,
    fill=NULL,
    alpha=NULL
  ) +
  theme_minimal()+
  theme(
    axis.text.x.top=element_text(hjust=0),
    legend.position = "bottom"
  )


ggsave(plot_step, filename="plot_vaxdate_step.png", path=here("output", "descriptive", "vaxdate"))
ggsave(plot_stack, filename="plot_vaxdate_stack.png", path=here("output", "descriptive", "vaxdate"))

