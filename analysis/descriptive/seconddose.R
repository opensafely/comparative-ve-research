# # # # # # # # # # # # # # # # # # # # #
# This script plots time to second dose, censoring by the different study outcomes
# It's basically the same as the KM plots in the `km.R` script, but presents the data a bit differently, and looks for cross-brand second doses
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

## import metadata ----
var_labels <- read_rds(here("output", "data", "metadata_labels.rds"))

list_formula <- read_rds(here("output", "data", "metadata_formulas.rds"))
list2env(list_formula, globalenv())
lastfupday <- lastfupday20

metadata_outcomes <- read_rds(here("output", "data", "metadata_outcomes.rds"))



## create output directory ----
fs::dir_create(here("output", "descriptive", "seconddose"))

threshold <- 5

ceiling_any <- function(x, to=1){
  # round to nearest 100 millionth to avoid floating point errors
  ceiling(plyr::round_any(x/to, 1/100000000))*to
}

data_cohort <- read_rds(here::here("output", "data", "data_cohort.rds"))


data_tte <-
  data_cohort %>%
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
    vaxmoderna2_date = if_else(vax1_type=="moderna", vax2_date, as.Date(NA)),
)

data_tab <- data_tte %>%
  mutate(
    vax2_type_descr =if_else((vax2_day-vax1_day)<=20*7, vax2_type_descr, factor(NA_character_)),
    vaxmatch = as.character(vax2_type_descr) == as.character(vax1_type_descr)
  )

dose_tab <- redacted_summary_catcat(
  data_tab$vaxmatch, data_tab$vax1_type_descr,
  .missing_name="no second dose at 20 weeks",
  .redacted_name="REDACTED",
  redaction_threshold=5L,
  redaction_accuracy=1L,
  .total_name=NULL
) %>%
  select(
    `First dose`=.level2,
    `Matching second dose`=.level1,
    everything()
  )

write_csv(dose_tab, here("output","descriptive","seconddose", "seconddose.csv"))

seconddose <- function(outcome){

  outcome_var <- metadata_outcomes$outcome_var[metadata_outcomes$outcome==outcome]

  data_outcome <-
    data_tte %>%
    mutate(

      outcome_date = .[[glue("{outcome_var}")]],
      # assume vaccination occurs at the start of the day, and all other events occur at the end of the day.
      # so use vax1_date - 1
      censor_date = pmin(
        vax1_date - 1 + lastfupday,
        dereg_date,
        death_date,
        outcome_date,
        end_date,
        na.rm=TRUE
      ),
      tte_censor = tte(vax1_date-1, censor_date, censor_date),

      tte_vaxpfizer2 = tte(vax1_date-1, vaxpfizer2_date-1, censor_date),
      ind_vaxpfizer2 = censor_indicator(vaxpfizer2_date-1, censor_date),

      tte_vaxaz2 = tte(vax1_date-1, vaxaz2_date-1, censor_date),
      ind_vaxaz2 = censor_indicator(vaxaz2_date-1, censor_date),

      tte_vaxmoderna2 = tte(vax1_date-1, vaxmoderna2_date-1, censor_date),
      ind_vaxmoderna2 = censor_indicator(vaxmoderna2_date-1, censor_date),
    )


  survaz <- survfit(Surv(tte_vaxaz2, ind_vaxaz2) ~ vax1_type_descr, data = data_outcome, conf.type="log-log")
  survpfizer <- survfit(Surv(tte_vaxpfizer2, ind_vaxpfizer2) ~ vax1_type_descr, data = data_outcome, conf.type="log-log")
  survmoderna <- survfit(Surv(tte_vaxmoderna2, ind_vaxmoderna2) ~ vax1_type_descr, data = data_outcome, conf.type="log-log")

  survpfizertidy <- broom::tidy(survpfizer) %>% mutate(vax2_type_descr = "BNT162b2")
  survaztidy <- broom::tidy(survaz) %>% mutate(vax2_type_descr = "ChAdOx1")
  survmodernatidy <- broom::tidy(survmoderna) %>% mutate(vax2_type_descr = "Moderna")

  survtidy <- bind_rows(survpfizertidy, survaztidy, survmodernatidy) %>%
    group_by(strata, vax2_type_descr) %>%
    mutate(
      outcome =  outcome,
      vax1_type_descr = str_remove(strata, fixed("vax1_type_descr=")),
      surv = ceiling_any(estimate, 1/floor(max(n.risk, na.rm=TRUE)/(threshold+1))),
      surv.ll = ceiling_any(conf.low, 1/floor(max(n.risk, na.rm=TRUE)/(threshold+1))),
      surv.ul = ceiling_any(conf.high, 1/floor(max(n.risk, na.rm=TRUE)/(threshold+1))),
      surv.ll = if_else(std.error==0, surv, surv.ll),
      surv.ul = if_else(std.error==0, surv, surv.ul),
    ) %>%
    ungroup() %>%
    add_row(
      outcome = outcome,
      vax1_type_descr = rep(unique(.$vax1_type_descr), times=3),
      vax2_type_descr = rep(unique(.$vax2_type_descr), each=2),
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
      vax1_type_descr = paste0("First dose ", vax1_type_descr)
    ) %>%
    ggplot(
      aes(group=paste(vax1_type_descr, vax2_type_descr), colour=vax2_type_descr, fill=vax2_type_descr)
    ) +
    geom_step(aes(x=time, y=1-surv))+
    geom_rect(aes(xmin=time, xmax=leadtime, ymin=1-surv.ll, ymax=1-surv.ul), alpha=0.1, colour="transparent")+
    geom_hline(aes(yintercept=0), colour='black')+
    facet_wrap(vars(vax1_type_descr), strip.position="top", ncol=1)+
    scale_colour_brewer(type="qual", palette="Set1", na.value="grey")+
    scale_fill_brewer(type="qual", palette="Set1", guide="none", na.value="grey")+
    scale_x_continuous(breaks = seq(0,lastfupday,14), expand=expansion(mult=c(0)))+
    scale_y_continuous(limits=c(0,1), expand = expansion(mult=c(0)))+
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
  write_rds(surv_plot, here("output", "descriptive", "seconddose", glue("plot_seconddose_{outcome}.rds")))
  ggsave(surv_plot, filename=glue("plot_seconddose_{outcome}.png"), path=here("output", "descriptive", "seconddose"))
  ggsave(surv_plot, filename=glue("plot_seconddose_{outcome}.pdf"), path=here("output", "descriptive", "seconddose"))

  survtidy
}


survtidy_postest <- seconddose("postest")
survtidy_covidemergency <- seconddose("covidemergency")
survtidy_covidadmitted <- seconddose("covidadmitted")
survtidy_death <- seconddose("death")

survtidyall <-
  bind_rows(
    survtidy_postest,
    survtidy_covidemergency,
    survtidy_covidadmitted,
    #survtidy_death
  ) %>%
  left_join(metadata_outcomes, by="outcome") %>%
  mutate(
    outcome_descr = fct_inorder(outcome_descr)
  )


surv_plot_samebrand <- survtidyall %>%
  filter(
    vax1_type_descr == vax2_type_descr
  ) %>%
  ggplot(
    aes(group=vax1_type_descr, colour=vax1_type_descr, fill=vax1_type_descr),
  ) +
  geom_hline(aes(yintercept=0), colour='black')+
  geom_hline(aes(yintercept=1), colour='black')+
  geom_step(aes(x=time, y=1-surv))+
  geom_rect(aes(xmin=time, xmax=leadtime, ymin=1-surv.ll, ymax=1-surv.ul), alpha=0.1, colour="transparent")+
  facet_wrap(vars(outcome_descr), ncol=1)+
  scale_colour_brewer(type="qual", palette="Set1", na.value="grey")+
  scale_fill_brewer(type="qual", palette="Set1", guide="none", na.value="grey")+
  scale_x_continuous(breaks = seq(0,lastfupday,14), expand=expansion(mult=c(0)))+
  scale_y_continuous(expand = expansion(mult=c(0)), limits=c(0,1))+
  coord_cartesian(xlim=c(0, lastfupday) ,ylim=c(0,NA))+
  labs(
    x="Days since vaccination",
    y="Proportion with second dose\n(matching first dose)",
    colour=NULL,
    title=NULL
  )+
  theme_minimal()+
  theme(
    legend.position = c(0.05,0.95),
    legend.justification = c(0,1),
    panel.grid.minor.x = element_blank(),
    axis.ticks.x = element_line(colour = 'black'),
    strip.placement="outside",
    #strip.text.y = element_text(angle=0)
  )


write_rds(surv_plot_samebrand, here("output", "descriptive", "seconddose", glue("plot_seconddose_samebrand.rds")))
ggsave(surv_plot_samebrand, filename=glue("plot_seconddose_samebrand.png"), path=here("output", "descriptive", "seconddose"))
ggsave(surv_plot_samebrand, filename=glue("plot_seconddose_samebrand.pdf"), path=here("output", "descriptive", "seconddose"))


surv_plot_diffbrand <- survtidyall %>%
  filter(
    vax1_type_descr!=vax2_type_descr
  ) %>%
  mutate(
    vax1_type_descr = paste("First dose", vax1_type_descr)
  ) %>%
  ggplot(
    aes(group=paste(vax1_type_descr, vax2_type_descr), colour=vax2_type_descr, fill=vax2_type_descr),
  ) +
  geom_hline(aes(yintercept=0), colour='black')+
  geom_step(aes(x=time, y=1-surv))+
  geom_rect(aes(xmin=time, xmax=leadtime, ymin=1-surv.ll, ymax=1-surv.ul), alpha=0.1, colour="transparent")+
  facet_grid(
    rows=vars(outcome_descr),
    cols=vars(vax1_type_descr),
    scales="free_y"
  )+
  scale_colour_brewer(type="qual", palette="Set1", na.value="grey")+
  scale_fill_brewer(type="qual", palette="Set1", guide="none", na.value="grey")+
  scale_x_continuous(breaks = seq(0,lastfupday,14), expand=expansion(mult=c(0)))+
  scale_y_continuous(expand = expansion(mult=c(0)), limits=c(0,NA))+
  coord_cartesian(xlim=c(0, lastfupday) ,ylim=c(0,NA))+
  labs(
    x="Days since vaccination",
    y="Proportion with second dose",
    colour="Second dose",
    fill=NULL,
    title=NULL
  )+
  theme_minimal()+
  theme(
    legend.position = c(0.05,0.95),
    legend.justification = c(0,1),
    panel.grid.minor.x = element_blank(),
    axis.ticks.x = element_line(colour = 'black'),
    strip.placement="outside",
    #strip.text.y = element_text(angle=0)
  )+
  NULL


write_rds(surv_plot_diffbrand, here("output", "descriptive", "seconddose", glue("plot_seconddose_diffbrand.rds")))
ggsave(surv_plot_diffbrand, filename=glue("plot_seconddose_diffbrand.png"), path=here("output", "descriptive", "seconddose"))
ggsave(surv_plot_diffbrand, filename=glue("plot_seconddose_diffbrand.pdf"), path=here("output", "descriptive", "seconddose"))
