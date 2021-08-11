
# # # # # # # # # # # # # # # # # # # # #
# This script:
# imports fitted MSMs
# calculates robust CIs taking into account patient-level clustering
# outputs effect plots for the primary vaccine-outcome relationship
# outputs plots showing model-estimated spatio-temporal trends
#
# The script should only be run via an action in the project.yaml only
# The script must be accompanied by four arguments: cohort, outcome, brand, and stratum
# # # # # # # # # # # # # # # # # # # # #

# Preliminaries ----


# import command-line arguments ----

args <- commandArgs(trailingOnly=TRUE)


if(length(args)==0){
  # use for interactive testing
  removeobs <- FALSE
  outcome <- "postest"
  timescale <- "timesincevax"
} else {
  removeobs <- TRUE
  outcome <- args[[1]]
  timescale <- args[[2]]

}


## Import libraries ----
library('tidyverse')
library('here')
library('glue')
library('lubridate')
library('survival')
library('splines')
library('gtsummary')
library("sandwich")
library("lmtest")



## Import custom user functions from lib

source(here("analysis", "lib", "utility_functions.R"))
source(here("analysis", "lib", "redaction_functions.R"))
source(here("analysis", "lib", "survival_functions.R"))


## import metadata ----
var_labels <- read_rds(here("output", "data", "metadata_labels.rds"))

list_formula <- read_rds(here("output", "data", "metadata_formulas.rds"))
list2env(list_formula, globalenv())

# redo formulae from model script ----

formula_outcome <- outcome_event ~ 1

# mimicing timescale / stratification in simple cox models
if(timescale=="calendar"){
  formula_timescale <- . ~ . + ns(tstop_calendar, 3) # spline for timescale only
  formula_spacetime <- . ~ . + ns(tstop_calendar, 3)*region # spline for space-time adjustments
}
if(timescale=="timesincevax"){
  formula_timescale <- . ~ . +  ns(tstop, 3) # spline for timescale only
  formula_spacetime <- . ~ . + ns(tstop_calendar, 3)*region # spline for space-time adjustments
}


### piecewise formulae ----
### estimand
formula_timesincevax_pw <- . ~ . + vax1_az*timesincevax_pw
formula_vaxonly_pw <- formula_outcome  %>% update(formula_timesincevax_pw) %>% update(formula_timescale)

formula0_pw <- formula_vaxonly_pw
formula1_pw <- formula_vaxonly_pw %>% update(formula_spacetime)
formula2_pw <- formula_vaxonly_pw %>% update(formula_spacetime) %>% update(formula_demog)
formula3_pw <- formula_vaxonly_pw %>% update(formula_spacetime) %>% update(formula_demog) %>% update (formula_comorbs)

### natural cubic spline formulae ----
### estimands
formula_timesincevax_ns <- . ~ . + vax1_az*ns(tstop, 3)
formula_vaxonly_ns <- formula_outcome  %>% update(formula_timesincevax_ns) %>% update(formula_timescale)

formula0_ns <- formula_vaxonly_ns
formula1_ns <- formula_vaxonly_ns %>% update(formula_spacetime)
formula2_ns <- formula_vaxonly_ns %>% update(formula_spacetime) %>% update(formula_demog)
formula3_ns <- formula_vaxonly_ns %>% update(formula_spacetime) %>% update(formula_demog) %>% update (formula_comorbs)

# Import processed data ----

data_plr <- read_rds(here("output", "models", outcome, timescale, "modelplr_data.rds"))

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
# import peicewise models ----
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

## report models ----


tidy_plr_pw <- read_rds(here("output", "models", outcome, timescale, "modelplr_tidy_pw.rds"))

effectsplr <- tidy_plr_pw %>%
  filter(str_detect(term, fixed("vax1_az"))) %>%
  mutate(
    pw=str_replace(term, pattern=fixed("vax1_az:timesincevax_pw"), ""),
    pw=if_else(label=="vax1_az", paste0(postvaxcuts[1]+1,"-", postvaxcuts[2]), pw),
    pw=fct_inorder(pw),
    term_left = as.numeric(str_extract(pw, "^\\d+"))-1,
    term_right = as.numeric(str_extract(pw, "\\d+$"))-1,
    term_right = if_else(is.na(term_right), max(term_left, na.rm=TRUE)+6, term_right),
    term_midpoint = term_left + (term_right+1-term_left)/2
  )

write_rds(effectsplr, path = here("output", "models", outcome, timescale, glue::glue("reportplr_effects_pw.rds")))
write_csv(effectsplr, path = here("output", "models", outcome, timescale, glue::glue("reportplr_effects_pw.csv")))

plotplr <-
  ggplot(data = effectsplr) +
  geom_point(aes(y=exp(estimate), x=term_midpoint, colour=model_name), position = position_dodge(width = 1.8))+
  geom_linerange(aes(ymin=exp(conf.low), ymax=exp(conf.high), x=term_midpoint, colour=model_name), position = position_dodge(width = 1.8))+
  geom_hline(aes(yintercept=1), colour='grey')+
  scale_y_log10(
    breaks=c(0.25, 0.33, 0.5, 0.67, 0.80, 1, 1.25, 1.5, 2, 3, 4),
    sec.axis = dup_axis(name="<--  favours Pfizer  /  favours AZ  -->", breaks = NULL)
  )+
  scale_x_continuous(breaks=unique(effectsplr$term_left), limits=c(min(effectsplr$term_left), max(effectsplr$term_right)+1), expand = c(0, 0))+
  scale_colour_brewer(type="qual", palette="Set2", guide=guide_legend(ncol=1))+
  labs(
    y="Hazard ratio",
    x="Days since first dose",
    colour=NULL,
    title=glue::glue("AZ versus Pfizer, by time since first-dose")
  ) +
  theme_bw()+
  theme(
    panel.border = element_blank(),
    axis.line.y = element_line(colour = "black"),

    panel.grid.minor.x = element_blank(),
    panel.grid.minor.y = element_blank(),
    strip.background = element_blank(),
    strip.placement = "outside",
    strip.text.y.left = element_text(angle = 0),

    panel.spacing = unit(0.8, "lines"),

    plot.title = element_text(hjust = 0),
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.caption = element_text(hjust = 0, face= "italic"),

    legend.position = "bottom"
  ) +
  NULL
plotplr

## save plot

write_rds(plotplr, path=here("output", "models", outcome, timescale, glue("reportplr_effectsplot_pw.rds")))
ggsave(filename=here("output", "models", outcome, timescale, glue("reportplr_effectsplot_pw.svg")), plotplr, width=20, height=15, units="cm")
ggsave(filename=here("output", "models", outcome, timescale, glue("reportplr_effectsplot_pw.png")), plotplr, width=20, height=15, units="cm")

## risk-adjusted survival curves ----


plrmod0 <- read_rds(here("output", "models", outcome, timescale, glue("modelplr_model0pw.rds")))
plrmod1 <- read_rds(here("output", "models", outcome, timescale, glue("modelplr_model1pw.rds")))
plrmod2 <- read_rds(here("output", "models", outcome, timescale, glue("modelplr_model2pw.rds")))
plrmod3 <- read_rds(here("output", "models", outcome, timescale, glue("modelplr_model3pw.rds")))

survival_az <- data_plr %>%
  mutate(vax1_az=1L) %>%
  transmute(
    patient_id,
    tstop,
    tstop_calendar,
    vax1_az,
    sample_weights,
    outcome_prob0=predict(plrmod0, newdata=., type="response"),
    outcome_prob1=predict(plrmod1, newdata=., type="response"),
    outcome_prob2=predict(plrmod1, newdata=., type="response"),
    outcome_prob3=predict(plrmod3, newdata=., type="response"),
  )

survival_pfizer <- data_plr %>%
  mutate(vax1_az=0L) %>%
  transmute(
    patient_id,
    tstop,
    tstop_calendar,
    vax1_az,
    sample_weights,
    outcome_prob0=predict(plrmod0, newdata=., type="response"),
    outcome_prob1=predict(plrmod1, newdata=., type="response"),
    outcome_prob2=predict(plrmod1, newdata=., type="response"),
    outcome_prob3=predict(plrmod3, newdata=., type="response"),
  )

if(removeobs) rm(plrmod0, plrmod1, plrmod2, plrmod3)

curves <- bind_rows(survival_az, survival_pfizer) %>%
#marginalise over all patients
group_by(vax1_az, tstop) %>%
  summarise(
    outcome_prob0=weighted.mean(outcome_prob0, sample_weights),
    outcome_prob1=weighted.mean(outcome_prob1, sample_weights),
    outcome_prob2=weighted.mean(outcome_prob2, sample_weights),
    outcome_prob3=weighted.mean(outcome_prob3, sample_weights),
  ) %>%
  pivot_longer(
    cols=starts_with("outcome_prob"),
    names_to="model",
    names_pattern="outcome_prob(\\d+$)",
    values_to="outcome_prob"
  ) %>%
  arrange(model, vax1_az, tstop) %>%
  group_by(model, vax1_az) %>%
  mutate(
    survival = cumprod(1-outcome_prob),
    haz = (lag(survival,n=1,default=1)-survival)/survival
  ) %>%
  ungroup() %>%
  add_row(
    model = rep(c("0", "1", "2", "3"), each=2),
    vax1_az = rep(c(0L, 1L), times=4),
    tstop=0,
    outcome_prob =0,
    survival = 1,
    haz = 0
  ) %>%
  mutate(
    model = as.integer(model),
    vax1_az_descr = if_else(vax1_az==1, "ChAdOx1", "BNT162b2"),
  ) %>%
  left_join(
    tidy_plr_pw %>% group_by(model_name, model) %>% summarise() %>% ungroup(), by="model"
  ) %>%
  arrange(model, vax1_az, tstop)

cml_inc <- ggplot(curves %>% filter(model=="3"))+
  geom_step(aes(x=tstop, y=1-survival, group=vax1_az_descr, colour=vax1_az_descr))+
  scale_x_continuous(
    breaks = seq(0,7*52,by=14),
    expand = expansion(0)
  )+
  scale_y_continuous(
    expand = expansion(0)
  )+
  scale_colour_brewer(type="qual", palette="Set2")+
  labs(
    x="Days since first dose",
    y="Cumulative risk",
    colour=NULL
  )+
  theme_bw()+
  theme(
    legend.position=c(0.05,.95),
    legend.justification = c(0,1),
    axis.text.x.top=element_text(hjust=0)
  )

write_rds(curves, here("output", "models", outcome, timescale, glue("reportplr_cmlinccurves_pw.rds")), compress="gz")

ggsave(filename=here("output", "models", outcome, timescale, glue("reportplr_cmlincplot_pw.svg")), cml_inc, width=20, height=15, units="cm")
ggsave(filename=here("output", "models", outcome, timescale, glue("reportplr_cmlincplot_pw.png")), cml_inc, width=20, height=15, units="cm")





# # # # # # # # # # # # # # # # # # # # # # # # # # # #
# import spline models ----
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

tidy_plr_ns <- read_rds(here("output", "models", outcome, timescale, glue("modelplr_tidy_ns.rds")))

plrmod0 <- read_rds(here("output", "models", outcome, timescale, glue("modelplr_model0ns.rds")))
plrmod1 <- read_rds(here("output", "models", outcome, timescale, glue("modelplr_model1ns.rds")))
plrmod2 <- read_rds(here("output", "models", outcome, timescale, glue("modelplr_model2ns.rds")))
plrmod3 <- read_rds(here("output", "models", outcome, timescale, glue("modelplr_model3ns.rds")))

vcov0 <- read_rds(here("output", "models", outcome, timescale, glue("modelplr_vcov0ns.rds")))
vcov1 <- read_rds(here("output", "models", outcome, timescale, glue("modelplr_vcov1ns.rds")))
vcov2 <- read_rds(here("output", "models", outcome, timescale, glue("modelplr_vcov2ns.rds")))
vcov3 <- read_rds(here("output", "models", outcome, timescale, glue("modelplr_vcov3ns.rds")))


get_HRspline <- function(.data, model, vcov, df){
  ## function to get AZ/pfizer hazard ratio spline over time since first dose

  tstop <- .data$tstop
  spline <- ns(.data$tstop, df=df)

  mat0 <- model.matrix(model, data = mutate(.data, vax1_az=0))
  mat1 <- model.matrix(model, data = mutate(.data, vax1_az=1))

  tstop_distinct <- unique(tstop)

  distinctX0 <- mat0[match(tstop_distinct, tstop),]
  distinctX1 <- mat1[match(tstop_distinct, tstop),]

  term_index <- str_detect(names(coef(model)), fixed("ns(tstop,")) | str_detect(names(coef(model)), fixed("vax1_az"))

  partialX0 <- distinctX0[,term_index]
  partialX1 <- distinctX1[,term_index]

  diffX <- partialX1-partialX0

  partialbeta <- coef(model)[term_index]
  partialV <- vcov[term_index, term_index]

  tibble(
    tstop = tstop_distinct,
    loghr = unname((diffX %*% partialbeta)[,1]),
    se = sqrt( rowSums(diffX * (diffX %*% partialV)) ),
    loghr.ul = loghr + se * qnorm(0.025),
    loghr.ll = loghr - se * qnorm(0.025)
  )

}

effectsplr <-
  bind_rows(
    get_HRspline(data_plr, plrmod0, vcov0, df=3) %>% mutate(model=0),
    get_HRspline(data_plr, plrmod1, vcov1, df=3) %>% mutate(model=1),
    get_HRspline(data_plr, plrmod2, vcov2, df=3) %>% mutate(model=2),
    get_HRspline(data_plr, plrmod3, vcov3, df=3) %>% mutate(model=3)
  ) %>%
  select(model, everything()) %>%
  mutate(
    hr=exp(loghr),
    hr.ll=exp(loghr.ll),
    hr.ul=exp(loghr.ul),
  ) %>%
  left_join(
    tidy_plr_ns %>% group_by(model_name, model) %>% summarise() %>% ungroup(), by="model"
  )


plotplr <-
  ggplot(effectsplr)+
  geom_hline(aes(yintercept=1), colour='grey')+
  geom_line(aes(x=tstop-1, y=hr, colour=model_name))+
  geom_ribbon(aes(x=tstop-1, ymin=hr.ll, ymax=hr.ul, fill=model_name), alpha=0.2, colour="transparent")+
  scale_x_continuous(
    breaks = seq(0,7*52,by=14),
    expand = expansion(0)
  )+
  scale_y_log10(
    breaks=c(0.25, 0.33, 0.5, 0.67, 0.80, 1, 1.25, 1.5, 2, 3, 4),
    sec.axis = dup_axis(name="<--  favours Pfizer  /  favours AZ  -->", breaks = NULL)
  )+
  scale_colour_brewer(type="qual", palette="Set2", guide=guide_legend(ncol=1))+
  scale_fill_brewer(type="qual", palette="Set2", guide="none")+
  labs(
    x = "Days since first dose",
    y = "Hazard ratio",
    colour = NULL, fill=NULL
  )+
  theme_bw()+
  theme(
    panel.border = element_blank(),
    axis.line.y = element_line(colour = "black"),
    panel.grid.minor.y = element_blank(),
    legend.position = "bottom"
  ) +
  NULL


write_rds(plotplr, path=here("output", "models", outcome, timescale, glue("reportplr_effectsplot_ns.rds")))
ggsave(filename=here("output", "models", outcome, timescale, glue("reportplr_effectsplot_ns.svg")), plotplr, width=20, height=15, units="cm")
ggsave(filename=here("output", "models", outcome, timescale, glue("reportplr_effectsplot_ns.png")), plotplr, width=20, height=15, units="cm")


## risk-adjusted survival curves ----

# no CIs / standard errors because difficult todo!

#vcovCL0 <- read_rds(here("output", "models", outcome, timescale, glue("modelplr_vcov0_ns.csv")))
#vcovCL1 <- read_rds(here("output", "models", outcome, timescale, glue("modelplr_vcov1_ns.csv")))
#vcovCL2 <- read_rds(here("output", "models", outcome, timescale, glue("modelplr_vcov2_ns.csv")))
#vcovCL3 <- read_rds(here("output", "models", outcome, timescale, glue("modelplr_vcov3_ns.csv")))

#plr.predict(plrmod0, vcovCL0, mutate(data_plr, vax1_az=1L))

survival_az <- data_plr %>%
  mutate(vax1_az=1L) %>%
  transmute(
    patient_id,
    tstop,
    tstop_calendar,
    vax1_az,
    sample_weights,
    outcome_prob0=predict(plrmod0, newdata=., type="response"),
    outcome_prob1=predict(plrmod1, newdata=., type="response"),
    outcome_prob2=predict(plrmod2, newdata=., type="response"),
    outcome_prob3=predict(plrmod3, newdata=., type="response"),
  )


survival_pfizer <- data_plr %>%
  mutate(vax1_az=0L) %>%
  transmute(
    patient_id,
    tstop,
    tstop_calendar,
    vax1_az,
    sample_weights,
    outcome_prob0=predict(plrmod0, newdata=., type="response"),
    outcome_prob1=predict(plrmod1, newdata=., type="response"),
    outcome_prob2=predict(plrmod2, newdata=., type="response"),
    outcome_prob3=predict(plrmod3, newdata=., type="response"),
  )

if(removeobs) rm(plrmod0, plrmod1, plrmod2, plrmod3)

curves <- bind_rows(survival_az, survival_pfizer) %>%
  #marginalise over all patients
  group_by(vax1_az, tstop) %>%
  summarise(
    outcome_prob0=weighted.mean(outcome_prob0, sample_weights),
    outcome_prob1=weighted.mean(outcome_prob1, sample_weights),
    outcome_prob2=weighted.mean(outcome_prob2, sample_weights),
    outcome_prob3=weighted.mean(outcome_prob3, sample_weights),
  ) %>%
  pivot_longer(
    cols=starts_with("outcome_prob"),
    names_to="model",
    names_pattern="outcome_prob(\\d+$)",
    values_to="outcome_prob"
  ) %>%
  arrange(model, vax1_az, tstop) %>%
  group_by(model, vax1_az) %>%
  mutate(
    survival = cumprod(1-outcome_prob),
    haz = (lag(survival,n=1,default=1)-survival)/survival
  ) %>%
  ungroup() %>%
  add_row(
    model = rep(c("0", "1", "2", "3"), each=2),
    vax1_az = rep(c(0L, 1L), times=4),
    tstop=0,
    outcome_prob =0,
    survival = 1,
    haz = 0
  ) %>%
  mutate(
    model = as.integer(model),
    vax1_az_descr = if_else(vax1_az==1, "ChAdOx1", "BNT162b2"),
  ) %>%
  left_join(
    tidy_plr_ns %>% group_by(model_name, model) %>% summarise() %>% ungroup(), by="model"
  ) %>%
  arrange(model, vax1_az, tstop)



cml_inc <- ggplot(curves %>% filter(model=="3"))+
  geom_step(aes(x=tstop, y=1-survival, group=vax1_az_descr, colour=vax1_az_descr))+
  scale_x_continuous(
    breaks = seq(0,7*52,by=14),
    expand = expansion(0)
  )+
  scale_y_continuous(
    expand = expansion(0)
  )+
  scale_colour_brewer(type="qual", palette="Set2")+
  labs(
    x="Days since first dose",
    y="Cumulative risk",
    colour=NULL
  )+
  theme_bw()+
  theme(
    legend.position=c(0.05,.95),
    legend.justification = c(0,1),
    axis.text.x.top=element_text(hjust=0)
  )

write_rds(curves, here("output", "models", outcome, timescale, glue("reportplr_cmlinccurves_ns.rds")), compress="gz")

ggsave(filename=here("output", "models", outcome, timescale, glue("reportplr_cmlincplot_ns.svg")), cml_inc, width=20, height=15, units="cm")
ggsave(filename=here("output", "models", outcome, timescale, glue("reportplr_cmlincplot_ns.png")), cml_inc, width=20, height=15, units="cm")


## hazard ratios derived from survival curves

curves_hr <- curves %>%
  group_by(model, model_name, tstop) %>%
  summarise(
    vax1_az = vax1_az,
    hr = haz/first(haz)
  ) %>%
  ungroup() %>%
  filter(vax1_az != 0)


plotplr <-
  ggplot(data = curves_hr) +
  geom_line(aes(y=hr, x=tstop, colour=model_name))+
  geom_hline(aes(yintercept=1), colour='grey')+
  scale_y_log10(
    breaks=c(0.25, 0.33, 0.5, 0.67, 0.80, 1, 1.25, 1.5, 2, 3, 4),
    sec.axis = dup_axis(name="<--  favours Pfizer  /  favours AZ  -->", breaks = NULL)
  )+
  scale_x_continuous(
    breaks = seq(0,7*52,by=14),
     expand = expansion(0)
  )+
  scale_colour_brewer(type="qual", palette="Set2", guide=guide_legend(ncol=1))+
  labs(
    y="Hazard ratio",
    x="Days since first dose",
    colour=NULL,
    title=glue::glue("AZ versus Pfizer, by time since first-dose")
  ) +
  theme_bw()+
  theme(
    panel.border = element_blank(),
    axis.line.y = element_line(colour = "black"),

    panel.grid.minor.x = element_blank(),
    panel.grid.minor.y = element_blank(),
    strip.background = element_blank(),
    strip.placement = "outside",
    strip.text.y.left = element_text(angle = 0),

    panel.spacing = unit(0.8, "lines"),

    plot.title = element_text(hjust = 0),
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.caption = element_text(hjust = 0, face= "italic"),

    legend.position = "bottom"
  ) +
  NULL

write_rds(plotplr, path=here("output", "models", outcome, timescale, glue("reportplr_effectsplot2_ns.rds")))
ggsave(filename=here("output", "models", outcome, timescale, glue("reportplr_effectsplot2_ns.svg")), plotplr, width=20, height=15, units="cm")
ggsave(filename=here("output", "models", outcome, timescale, glue("reportplr_effectsplot2_ns.png")), plotplr, width=20, height=15, units="cm")


