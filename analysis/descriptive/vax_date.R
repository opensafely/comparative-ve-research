

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
  ungroup() %>%
  add_row(
    vax1_type_descr = unique(.$vax1_type_descr),
    vax1_date = min(.$vax1_date) - 1,
    n=0,
    .before=1
  ) %>%
  group_by(vax1_type_descr) %>%
  mutate(
    cumuln = cumsum(n)
  ) %>%
  arrange(vax1_type_descr, vax1_date)


plot_stack <-
  ggplot(cumulvax)+
  geom_bar(
    aes(
      x=vax1_date+0.5,
      y=cumuln,
      group=vax1_type_descr,
      fill=vax1_type_descr
    ),
    alpha=0.5,
    position=position_stack(),
    stat="identity",
    width=1
  )+
  scale_x_date(
    breaks = seq(min(cumulvax$vax1_date),max(cumulvax$vax1_date)+1,by=14)+1,
    limits = c(lubridate::floor_date(min(cumulvax$vax1_date), "1 month"), NA),
    labels = scales::label_date("%d/%m"),
    expand = expansion(add=1),
    sec.axis = sec_axis(
      trans = ~as.Date(.),
      breaks=as.Date(seq(floor_date(min(cumulvax$vax1_date), "month"), ceiling_date(max(cumulvax$vax1_date), "month"),by="month")),
      labels = scales::label_date("%B %y")
    )
  )+
  scale_y_continuous(
    labels = scales::label_number(accuracy = 1, big.mark=","),
    expand = expansion(c(0, NA))
  )+
  scale_fill_brewer(type="qual", palette="Set1")+
  labs(
    x="Date",
    y="Vaccinated, n",
    colour=NULL,
    fill=NULL,
    alpha=NULL
  ) +
  theme_minimal()+
  theme(
    axis.line.x.bottom = element_line(),
    axis.text.x.top=element_text(hjust=0),
    axis.ticks.x=element_line(),
    legend.position = c(0.3,0.8),
    legend.justification = c(1,0)
  )


plot_step <-
  ggplot(cumulvax)+
  geom_step(
    aes(
      x=vax1_date+1, y=cumuln,
      group=vax1_type_descr,
      colour=vax1_type_descr
    ),
    direction = "vh",
    size=1
  )+
  scale_x_date(
    breaks = seq(min(cumulvax$vax1_date),max(cumulvax$vax1_date)+1,by=14)+1,
    limits = c(lubridate::floor_date((min(cumulvax$vax1_date)), "1 month"), NA),
    labels = scales::label_date("%d/%m"),
    expand = expansion(add=1),
    sec.axis = sec_axis(
      trans = ~as.Date(.),
      breaks=as.Date(seq(floor_date(min(cumulvax$vax1_date), "month"), ceiling_date(max(cumulvax$vax1_date), "month"),by="month")),
      labels = scales::label_date("%B %y")
    )
  )+
  scale_y_continuous(
    labels = scales::label_number(accuracy = 1, big.mark=","),
    expand = expansion(c(0, NA))
  )+
  scale_colour_brewer(type="qual", palette="Set1")+
  labs(
    x="Date",
    y="Vaccinated, n",
    colour=NULL,
    fill=NULL,
    alpha=NULL
  ) +
  theme_minimal()+
  theme(
    axis.line.x.bottom = element_line(),
    axis.text.x.top=element_text(hjust=0),
    axis.ticks.x=element_line(),
    legend.position = c(0.3,0.8),
    legend.justification = c(1,0)
  )


write_rds(plot_step, here("output", "descriptive", "vaxdate", "plot_vaxdate_step.rds"))
write_rds(plot_stack, here("output", "descriptive", "vaxdate", "plot_vaxdate_stack.rds"))

ggsave(plot_step, filename="plot_vaxdate_step.png", path=here("output", "descriptive", "vaxdate"))
ggsave(plot_stack, filename="plot_vaxdate_stack.png", path=here("output", "descriptive", "vaxdate"))

