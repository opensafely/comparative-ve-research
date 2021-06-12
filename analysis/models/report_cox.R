
# # # # # # # # # # # # # # # # # # # # #
# This script:
# imports fitted MSMs
# calculates robust CIs taking into account patient-level clustering
# outputs forest plots for the primary vaccine-outcome relationship
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
} else {
  removeobs <- TRUE
  outcome <- args[[1]]
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


## create special log file ----
cat(glue("## script info for {outcome} ##"), "  \n", file = here("output", outcome, glue("log_{outcome}.txt")), append = FALSE)
## function to pass additional log text
logoutput <- function(...){
  cat(..., file = here("output", outcome, glue("log_{outcome}.txt")), sep = "\n  ", append = TRUE)
  cat("\n", file = here("output", outcome, glue("log_{outcome}.txt")), sep = "\n  ", append = TRUE)
}

## import metadata ----
var_labels <- read_rds(here("output", "data", "metadata_labels.rds"))

list_formula <- read_rds(here::here("output", "data", "metadata_formulas.rds"))
list2env(list_formula, globalenv())


  # Import processed data ----

  # import models ----

coxmod0 <- read_rds(here::here("output", outcome, "modelcox0.rds"))
coxmod1 <- read_rds(here::here("output", outcome, "modelcox1.rds"))
coxmod2 <- read_rds(here::here("output", outcome, "modelcox2.rds"))
coxmod3 <- read_rds(here::here("output", outcome, "modelcox3.rds"))

## report models ----

tidypp <- function(model, model_name, ...){
  broom.helpers::tidy_plus_plus(
    model,
    exponentiate=TRUE,
    ...
  ) %>%
  mutate(
    model_name = model_name
  )
}

data_cox_split <- read_rds(here("output", outcome, "data_cox_split.rds"))

tidy0 <- tidypp(coxmod0, "0 Unadjusted")
tidy1 <- tidypp(coxmod1, "1 Time")
tidy2 <- tidypp(coxmod2, "2 Time \n+ demographics")
tidy3 <- tidypp(coxmod3, "3 Time \n+ demographics \n+ clinical")

tidy_summary <- bind_rows(
  tidy0,
  tidy1,
  tidy2,
  tidy3
) %>%
mutate(outcome = outcome)

if(removeobs) rm(coxmod0, coxmod1, coxmod2, coxmod3)

write_csv(tidy_summary, path = here::here("output", outcome, glue::glue("estimates_cox.csv")))

# create forest plot
coxmod_forest_data <- tidy_summary %>%
  filter(str_detect(term, fixed("timesincevax")) | str_detect(term, fixed("vax_az"))) %>%
  mutate(
    term=str_replace(term, pattern=fixed("vax1_az:timesincevax"), ""),
    term=fct_inorder(term),
    term_left = as.numeric(str_extract(term, "^\\d+")),
    term_right = as.numeric(str_extract(term, "\\d+$")),
    term_right = if_else(is.na(term_right), max(term_left)+7, term_right),
    term_midpoint = term_left + (term_right-term_left)/2
  )

coxmod_forest <-
  ggplot(data = coxmod_forest_data) +
  geom_point(aes(y=estimate, x=term_midpoint), position = position_dodge(width = 0.5))+
  geom_linerange(aes(ymin=conf.low, ymax=conf.high, x=term_midpoint), position = position_dodge(width = 0.5))+
  geom_hline(aes(yintercept=1), colour='grey')+
  facet_grid(rows=vars(model_name), switch="y")+
  scale_y_log10(
    breaks=c(0.5, 0.67, 0.80, 1, 1.25, 1.5, 2),
    sec.axis = dup_axis(name="<--  favours Pfizer  /  favours AZ  -->", breaks = c(0.5, 0.67, 0.80, 1, 1.25, 1.5, 2))
  )+
  scale_x_continuous(breaks=unique(coxmod_forest_data$term_left))+
  scale_colour_brewer(type="qual", palette="Set2")+#, guide=guide_legend(reverse = TRUE))+
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

    legend.position = "right"
   ) +
 NULL
coxmod_forest
## save plot
ggsave(filename=here::here("output", outcome, glue::glue("forest_plot_cox.svg")), coxmod_forest, width=20, height=15, units="cm")




