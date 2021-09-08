

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

list_formula <- read_rds(here("output", "data", "metadata_formulas.rds"))
list2env(list_formula, globalenv())
lastfupday <- lastfupday20

## create output directory ----
fs::dir_create(here("output", "descriptive", "seconddose"))



ceiling_any <- function(x, to=1){
  # round to nearest 100 millionth to avoid floating point errors
  ceiling(plyr::round_any(x/to, 1/100000000))*to
}

data_cohort <- read_rds(here::here("output", "data", "data_cohort.rds")) %>%
  mutate(

    patient_id,
    vax1_type,
    vax1_day,
    vax2_type,
    vax2_day,
    end_date,

    vax1_type_descr,
    vax2_type_descr,

    vaxpfizer2_date = if_else(vax1_type=="pfizer", vax2_date, as.Date(NA)),
    vaxaz2_date = if_else(vax1_type=="az", vax2_date, as.Date(NA)),

    # assume vaccination occurs at the start of the day, and all other events occur at the end of the day.
    # so use vax1_date - 1
    censor_date = pmin(
      vax1_date - 1 + lastfupday,
      dereg_date,
      death_date,
      end_date,
      na.rm=TRUE
    ),
    tte_censor = tte(vax1_date-1, censor_date, censor_date),

    tte_vaxpfizer2 = tte(vax1_date-1, vaxpfizer2_date, censor_date),
    ind_vaxpfizer2 = censor_indicator(vaxpfizer2_date, censor_date),

    tte_vaxaz2 = tte(vax1_date-1, vaxaz2_date, censor_date),
    ind_vaxaz2 = censor_indicator(vaxaz2_date, censor_date),
  )

threshold <- 5

survaz <- survfit(Surv(tte_vaxaz2, ind_vaxaz2) ~ vax1_type_descr, data = data_cohort, conf.type="log-log")
survpfizer <- survfit(Surv(tte_vaxpfizer2, ind_vaxpfizer2) ~ vax1_type_descr, data = data_cohort, conf.type="log-log")

survpfizertidy <- broom::tidy(survpfizer) %>% mutate(vax2_type_descr = "BNT162b2")
survaztidy <- broom::tidy(survaz) %>% mutate(vax2_type_descr = "ChAdOx1")

survtidy <- bind_rows(survpfizertidy, survaztidy) %>%
  group_by(strata, vax2_type_descr) %>%
  mutate(
    vax1_type_descr = str_remove(strata, fixed("vax1_type_descr=")),
    surv = ceiling_any(estimate, 1/floor(max(n.risk, na.rm=TRUE)/(threshold+1))),
    surv.ll = ceiling_any(conf.low, 1/floor(max(n.risk, na.rm=TRUE)/(threshold+1))),
    surv.ul = ceiling_any(conf.high, 1/floor(max(n.risk, na.rm=TRUE)/(threshold+1))),
    surv.ll = if_else(std.error==0, surv, surv.ll),
    surv.ul = if_else(std.error==0, surv, surv.ul),
  ) %>%
  ungroup() %>%
  add_row(
    vax1_type_descr = rep(unique(.$vax1_type_descr), times=2),
    vax2_type_descr = rep(unique(.$vax1_type_descr), each=2),
    time=0,
    surv=1,
    surv.ll=1,
    surv.ul=1,
    std.error=0,
  ) %>%
  arrange(vax1_type_descr, vax2_type_descr, time) %>%
  group_by(vax1_type_descr, vax2_type_descr) %>%
  mutate(leadtime= lead(time)) %>%
  ungroup()


surv_plot <- survtidy %>%
  mutate(
    vax2_type_descr = paste0("First dose ", vax2_type_descr)
  ) %>%
  ggplot(
    aes(group=paste(vax1_type_descr, vax2_type_descr), colour=vax1_type_descr, fill=vax1_type_descr)
  ) +
  geom_step(aes(x=time, y=1-surv))+
  geom_rect(aes(xmin=time, xmax=leadtime, ymin=1-surv.ll, ymax=1-surv.ul), alpha=0.1, colour="transparent")+
  geom_hline(aes(yintercept=0), colour='black')+
  facet_wrap(vars(vax2_type_descr), strip.position="top", ncol=1)+
  scale_colour_brewer(type="qual", palette="Set1", na.value="grey")+
  scale_fill_brewer(type="qual", palette="Set1", guide="none", na.value="grey")+
  scale_x_continuous(breaks = seq(0,lastfupday,14), expand=expansion(mult=c(0,0.01)))+
  scale_y_continuous(expand = expansion(mult=c(0,0.01)))+
  coord_cartesian(xlim=c(0, lastfupday) ,ylim=c(0,NA))+
  labs(
    x="Days since vaccination",
    y="Proportion with second dose",
    colour="Second dose",
    title=NULL
  )+
  theme_minimal()+
  theme(
    legend.position = c(0.05,0.95),
    legend.justification = c(0,1),
    panel.grid.minor.x = element_blank(),
    axis.ticks.x = element_line(colour = 'black'),
    axis.line.x = element_line(colour = "black"),
    axis.line.y = element_line(colour = "black"),
    strip.placement="outside",

  )

surv_plot

write_rds(surv_plot, here("output", "descriptive", "seconddose", "plot_seconddose.rds"))
ggsave(surv_plot, filename="plot_seconddose.png", path=here("output", "descriptive", "seconddose"))

