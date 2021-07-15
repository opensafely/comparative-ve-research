
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


## Import custom user functions from lib

source(here("analysis", "lib", "utility_functions.R"))
source(here("analysis", "lib", "redaction_functions.R"))
source(here("analysis", "lib", "survival_functions.R"))


## import metadata ----
var_labels <- read_rds(here("output", "data", "metadata_labels.rds"))

list_formula <- read_rds(here::here("output", "data", "metadata_formulas.rds"))
list2env(list_formula, globalenv())


  # Import processed data ----

  # import models ----

coxmod0 <- read_rds(here::here("output", outcome, timescale, "modelcox0.rds"))
coxmod1 <- read_rds(here::here("output", outcome, timescale, "modelcox1.rds"))
coxmod2 <- read_rds(here::here("output", outcome, timescale, "modelcox2.rds"))
coxmod3 <- read_rds(here::here("output", outcome, timescale, "modelcox3.rds"))

## report models ----

tidypp <- function(model, model_name, ...){
  broom.helpers::tidy_plus_plus(
    model,
    exponentiate=TRUE,
    ...
  ) %>%
  add_column(
    model_name = model_name,
    .before=1
  )
}

data_cox_split <- read_rds(here("output", outcome, timescale, "data_cox_split.rds"))

tidy0 <- tidypp(coxmod0, "0 unadjusted")
tidy1 <- tidypp(coxmod1, "1 adjusting for time")
tidy2 <- tidypp(coxmod2, "2 adjusting for time + demographics")
tidy3 <- tidypp(coxmod3, "3 adjusting for time + demographics + clinical")

tidy_summary <- bind_rows(
  tidy0,
  tidy1,
  tidy2,
  tidy3
) %>%
add_column(outcome = outcome, .before=1)

if(removeobs) rm(coxmod0, coxmod1, coxmod2, coxmod3)

write_csv(tidy_summary, path = here::here("output", outcome, timescale, glue::glue("estimates_cox.csv")))


if(timescale == "calendar"){
  coxmod_effect_data <- tidy_summary %>%
    filter(str_detect(term, fixed("vax1_az"))) %>%
    mutate(
      term=str_replace(term, pattern=fixed("vax1_az:timesincevax"), ""),
      term=if_else(label=="vax1_az", paste0(postvaxcuts[1]+1,"-", postvaxcuts[2]), term),
      term=fct_inorder(term),
    )
}

if(timescale=="timesincevax"){
  coxmod_effect_data <- tidy_summary %>%
    filter(str_detect(term, fixed("timesincevax")) | str_detect(term, fixed("vax1_az"))) %>%
    mutate(
      term=str_replace(term, pattern=fixed("vax1_az:strata(timesincevax)"), ""),
      term=fct_inorder(term),
    )
}

coxmod_effect_data <- coxmod_effect_data %>%
  mutate(
    term_left = as.numeric(str_extract(term, "^\\d+"))-1,
    term_right = as.numeric(str_extract(term, "\\d+$"))-1,
    term_right = if_else(is.na(term_right), max(term_left)+6, term_right),
    term_midpoint = term_left + (term_right+1-term_left)/2
  )

coxmod_effect <-
  ggplot(data = coxmod_effect_data) +
  geom_point(aes(y=estimate, x=term_midpoint, colour=model_name), position = position_dodge(width = 1.8))+
  geom_linerange(aes(ymin=conf.low, ymax=conf.high, x=term_midpoint, colour=model_name), position = position_dodge(width = 1.8))+
  geom_hline(aes(yintercept=1), colour='grey')+
  scale_y_log10(
    breaks=c(0.25, 0.33, 0.5, 0.67, 0.80, 1, 1.25, 1.5, 2, 3, 4),
    sec.axis = dup_axis(name="<--  favours Pfizer  /  favours AZ  -->", breaks = NULL)
  )+
  scale_x_continuous(breaks=unique(coxmod_effect_data$term_left), limits=c(min(coxmod_effect_data$term_left), max(coxmod_effect_data$term_right)+1), expand = c(0, 0))+
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
coxmod_effect
## save plot

write_rds(coxmod_effect, path=here::here("output", outcome, timescale, glue::glue("forest_plot_cox.rds")))
ggsave(filename=here::here("output", outcome, timescale, glue::glue("forest_plot_cox.svg")), coxmod_effect, width=20, height=15, units="cm")
ggsave(filename=here::here("output", outcome, timescale, glue::glue("forest_plot_cox.png")), coxmod_effect, width=20, height=15, units="cm")




