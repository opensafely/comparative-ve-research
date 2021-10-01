
# # # # # # # # # # # # # # # # # # # # #
# This script:
# imports fitted PLR models
# outputs comparative effects plots
#
# The script must be accompanied by three arguments,
# `outcome` - the dependent variable in the regression model
# `timescale` - either "timesincevax" or "calendar"
# `censor_seconddose` - second at second dose (1) or not (0)
# # # # # # # # # # # # # # # # # # # # #

# Preliminaries ----


# import command-line arguments ----

args <- commandArgs(trailingOnly=TRUE)


if(length(args)==0){
  # use for interactive testing
  removeobs <- FALSE
  outcome <- "postest"
  timescale <- "timesincevax"
  censor_seconddose <- as.integer("1")
} else {
  removeobs <- TRUE
  outcome <- args[[1]]
  timescale <- args[[2]]
  censor_seconddose <- as.integer(args[[3]])

}


## Import libraries ----
library('tidyverse')
library('here')
library('glue')
library('lubridate')
library('survival')
library('splines')
library('gtsummary')


## Import custom user functions from lib

source(here("analysis", "lib", "utility_functions.R"))
source(here("analysis", "lib", "redaction_functions.R"))
source(here("analysis", "lib", "survival_functions.R"))


## import metadata ----
var_labels <- read_rds(here("output", "data", "metadata_labels.rds"))

list_formula <- read_rds(here("output", "data", "metadata_formulas.rds"))
list2env(list_formula, globalenv())

if(censor_seconddose==1){
  postvaxcuts<-postvaxcuts12
  lastfupday<-lastfupday12
} else {
  postvaxcuts <- postvaxcuts20
  if(outcome=="postest") postvaxcuts <- postvaxcuts20_postest
  lastfupday <- lastfupday20
}


  # Import processed data ----

  # import models ----

## report models ----

#data_cox <- read_rds(here("output", "models", outcome, timescale, "modelcox_data.rds"))

tidy_cox <- read_rds(here("output", "models", outcome, timescale, censor_seconddose, "modelcox_tidy.rds"))

if(timescale == "calendar"){
  effectscox <- tidy_cox %>%
    filter(str_detect(term, fixed("vax1_az"))) %>%
    mutate(
      term=str_replace(term, pattern=fixed("vax1_az:timesincevax_pw"), ""),
      term=if_else(label=="vax1_az", paste0(postvaxcuts[1]+1,"-", postvaxcuts[2]), term),
      term=fct_inorder(term),
    )
}

if(timescale=="timesincevax"){
  effectscox <- tidy_cox %>%
    filter(str_detect(term, fixed("timesincevax_pw")) | str_detect(term, fixed("vax1_az"))) %>%
    mutate(
      term=str_replace(term, pattern=fixed("vax1_az:strata(timesincevax_pw)"), ""),
      term=fct_inorder(term),
    )
}

effectscox <- effectscox %>%
  mutate(
    term_left = as.numeric(str_extract(term, "^\\d+"))-1,
    term_right = as.numeric(str_extract(term, "\\d+$"))-1,
    term_right = if_else(is.na(term_right), lastfupday, term_right),
    term_midpoint = term_left + (term_right+1-term_left)/2
  )

write_csv(effectscox, path = here("output", "models", outcome, timescale, censor_seconddose, glue::glue("reportcox_effects.csv")))
write_rds(effectscox, path = here("output", "models", outcome, timescale, censor_seconddose, glue::glue("reportcox_effects.rds")))

plotcox <-
  ggplot(data = effectscox) +
  geom_point(aes(y=exp(estimate), x=term_midpoint, colour=model_name), position = position_dodge(width = 1.8))+
  geom_linerange(aes(ymin=exp(conf.low), ymax=exp(conf.high), x=term_midpoint, colour=model_name), position = position_dodge(width = 1.8))+
  geom_hline(aes(yintercept=1), colour='grey')+
  scale_y_log10(
    breaks=c(0.25, 0.33, 0.5, 0.67, 0.80, 1, 1.25, 1.5, 2, 3, 4),
    sec.axis = dup_axis(name="<--  favours Pfizer  /  favours AZ  -->", breaks = NULL)
  )+
  scale_x_continuous(breaks=unique(effectscox$term_left), limits=c(min(effectscox$term_left), max(effectscox$term_right)+1), expand = c(0, 0))+
  scale_colour_brewer(type="qual", palette="Set2", guide=guide_legend(ncol=1))+
  labs(
    y="Hazard ratio",
    x="Time since first dose",
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
plotcox
## save plot

write_rds(plotcox, path=here("output", "models", outcome, timescale, censor_seconddose, glue("reportcox_effectsplot.rds")))
ggsave(filename=here("output", "models", outcome, timescale, censor_seconddose, glue("reportcox_effectsplot.svg")), plotcox, width=20, height=15, units="cm")
ggsave(filename=here("output", "models", outcome, timescale, censor_seconddose, glue("reportcox_effectsplot.png")), plotcox, width=20, height=15, units="cm")




