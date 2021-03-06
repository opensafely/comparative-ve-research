# # # # # # # # # # # # # # # # # # # # #
# This script creates a Kaplan-Meier plots for the study outcomes
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

metadata_outcomes <- read_rds(here("output", "data", "metadata_outcomes.rds"))

list_formula <- read_rds(here("output", "data", "metadata_formulas.rds"))
list2env(list_formula, globalenv())

lastfupday <- lastfupday20

## create output directory ----
fs::dir_create(here("output", "descriptive", "tables"))

## custom functions ----

ceiling_any <- function(x, to=1){
  # round to nearest 100 millionth to avoid floating point errors
  ceiling(plyr::round_any(x/to, 1/100000000))*to
}


## define theme ----

plot_theme <-
  theme_minimal()+
  theme(
    legend.position = "left",
    panel.border=element_rect(colour='black', fill=NA),
    strip.text.y.right = element_text(angle = 0),
    axis.line.x = element_line(colour = "black"),
    axis.text.x = element_text(angle = 70, vjust = 1, hjust=1),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    axis.ticks.x = element_line(colour = 'black')
  )


## Import processed data ----

data_cohort <- read_rds(here::here("output", "data", "data_cohort.rds"))


data_tte <- data_cohort %>%
  transmute(
    patient_id,
    vax1_type,
    vax1_day,
    end_date,

    vax1_type_descr,

    # assume vaccination occurs at the start of the day, and all other events occur at the end of the day.
    # so use vax1_date - 1

    censor_date = pmin(
      vax1_date - 1 + lastfupday,
      dereg_date,
      death_date,
      end_date,
      na.rm=TRUE
    ),

    # time to last follow up day
    tte_enddate = tte(vax1_date-1, vax1_date+lastfupday20, vax1_date+lastfupday20),

    # time to last follow up day or death or deregistration
    tte_censor = tte(vax1_date-1, censor_date, censor_date),

    tte_vaxany2 = tte(vax1_date-1, vax2_date, censor_date),
    ind_vaxany2 = censor_indicator(vax2_date, censor_date),

    tte_test =tte(vax1_date-1, covid_test_date, censor_date, na.censor=FALSE),
    ind_test = censor_indicator(covid_test_date, censor_date),

    tte_postest = tte(vax1_date-1, positive_test_date, censor_date, na.censor=FALSE),
    ind_postest = censor_indicator(positive_test_date, censor_date),

    tte_emergency = tte(vax1_date-1, emergency_date, censor_date, na.censor=FALSE),
    ind_emergency = censor_indicator(emergency_date, censor_date),

    tte_covidemergency = tte(vax1_date-1, emergency_covid_date, censor_date, na.censor=FALSE),
    ind_covidemergency = censor_indicator(emergency_covid_date, censor_date),

    tte_admitted = tte(vax1_date-1, admitted_date, censor_date, na.censor=FALSE),
    ind_admitted = censor_indicator(admitted_date, censor_date),

    tte_covidadmitted = tte(vax1_date-1, covidadmitted_date, censor_date, na.censor=FALSE),
    ind_covidadmitted = censor_indicator(covidadmitted_date, censor_date),

    tte_covidcc = tte(vax1_date-1, covidcc_date, censor_date, na.censor=FALSE),
    ind_covidcc = censor_indicator(covidcc_date, censor_date),

    tte_coviddeath = tte(vax1_date-1, coviddeath_date, censor_date, na.censor=FALSE),
    ind_coviddeath = censor_indicator(coviddeath_date, censor_date),

    tte_noncoviddeath = tte(vax1_date-1, noncoviddeath_date, censor_date, na.censor=FALSE),
    ind_noncoviddeath = censor_indicator(noncoviddeath_date, censor_date),

    tte_death = tte(vax1_date-1, death_date, censor_date, na.censor=FALSE),
    ind_death = censor_indicator(death_date, censor_date),

    tte_dereg = tte(vax1_date-1, dereg_date, censor_date, na.censor=FALSE),
    ind_dereg = censor_indicator(dereg_date, censor_date),

  ) %>%
  droplevels()


survobj <- function(.data, time, indicator, group_vars, threshold){

  dat_filtered <- .data %>%
    mutate(
      .time = .data[[time]],
      .indicator = .data[[indicator]]
    ) %>%
    filter(
      !is.na(.time),
      .time>0
    )

  unique_times <- unique(c(dat_filtered[[time]]))

  dat_surv <- dat_filtered %>%
    group_by(across(all_of(group_vars))) %>%
    transmute(
      .time = .data[[time]],
      .indicator = .data[[indicator]]
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
    select(group_vars, n_events, surv_obj_tidy) %>%
    unnest(surv_obj_tidy)

  dat_surv_rounded <- dat_surv1 %>%
    mutate(
      # Use ceiling not round. This is slightly biased upwards,
      # but means there's no disclosure risk at the boundaries (0 and 1) where masking would otherwise be threshold/2
      surv = ceiling_any(surv, 1/floor(max(n.risk, na.rm=TRUE)/(threshold+1))),
      surv.ll = ceiling_any(surv.ll, 1/floor(max(n.risk, na.rm=TRUE)/(threshold+1))),
      surv.ul = ceiling_any(surv.ul, 1/floor(max(n.risk, na.rm=TRUE)/(threshold+1))),
    )
  dat_surv_rounded
  #dat_surv1
}

get_colour_scales <- function(colour_type = "qual"){

  if(colour_type == "qual"){
    list(
      scale_color_brewer(type="qual", palette="Set1", na.value="grey"),
      scale_fill_brewer(type="qual", palette="Set1", guide="none", na.value="grey")
      #ggthemes::scale_color_colorblind(),
      #ggthemes::scale_fill_colorblind(guide=FALSE),
      #rcartocolor::scale_color_carto_d(palette = "Safe"),
      #rcartocolor::scale_fill_carto_d(palette = "Safe", guide=FALSE),
      #ggsci::scale_color_simpsons(),
      #ggsci::scale_fill_simpsons(guide=FALSE)
    )
  } else if(colour_type == "cont"){
    list(
      viridis::scale_color_viridis(discrete = FALSE, na.value="grey"),
      viridis::scale_fill_viridis(discrete = FALSE, guide = FALSE, na.value="grey")
    )
  } else if(colour_type == "ordinal"){
    list(
      viridis::scale_color_viridis(discrete = TRUE, option="D", na.value="grey"),
      viridis::scale_fill_viridis(discrete = TRUE, guide = FALSE, option="D", na.value="grey")
    )
  } else if(colour_type == "ordinal5"){
    list(
      scale_color_manual(values=viridisLite::viridis(n=5), na.value="grey"),
      scale_fill_manual(guide = FALSE, values=viridisLite::viridis(n=5), na.value="grey")
    )
  } else
    stop("colour_type '", colour_type, "' not supported -- must be 'qual', 'cont', or 'ordinal'")
}


ggplot_surv <- function(.surv_data, colour_var, colour_name, colour_type="qual", ci=FALSE, title=""){

  lines <- list(geom_step(aes(x=time, y=surv)))
  if(ci){
    lines <- append(lines, list(geom_rect(aes(xmin=time, xmax=leadtime, ymin=surv.ll, ymax=surv.ul), alpha=0.1, colour="transparent")))
  }

  surv_plot <- .surv_data %>%
    ggplot(aes_string(group=colour_var, colour=colour_var, fill=colour_var)) +
    lines+
    get_colour_scales(colour_type)+
    scale_x_continuous(breaks = seq(0,600,7))+
    scale_y_continuous(expand = expansion(mult=c(0,0.01)))+
    coord_cartesian(xlim=c(0, NA))+
    labs(
      x="Days since vaccination",
      y="Event-free rate",
      colour=colour_name,
      title=NULL
    )+
    theme_minimal(base_size=9)+
    theme(
      axis.line.x = element_line(colour = "black"),
      panel.grid.minor.x = element_blank()
    )

  surv_plot
}



metadata_variables <- tribble(
  ~variable, ~variable_name, ~colour_type,
  "vax1_type_descr", NULL, "qual",
  #"ageband", "Age", "qual",
)


metadata_outcomes <- tribble(
  ~outcome, ~outcome_name,
  #"seconddose", "Second dose",
  "vaxany2", "Second dose",
  "test", "SARS-CoV-2 test",
  "postest", "Positive test",
  "emergency", "A&E attendance",
  "covidemergency", "COVID-19 A&E attendance",
  "admitted", "Unpanned admission",
  "covidadmitted", "COVID-19 admission",
  "covidcc", "COVID-19 critical care",
  "coviddeath", "COVID-19 death",
  "death", "All-cause death"
)

metadata_crossed <- crossing(metadata_variables, metadata_outcomes)

# test_data <- data_vaccinated %>%
#  filter(age<=18, tte_postest>0) %>%
#  select(tte_postest, ind_postest, ethnicity)
# test_surv <- survobj(test_data, "tte_postest", "ind_postest", "ethnicity")
#
# ggplot_surv(test_surv, "ethnicity", "ethnicity", "qual", FALSE, TRUE)

plot_combinations <- metadata_crossed %>%
  mutate(
    survobj = pmap(
      list(variable, outcome),
      function(variable, outcome){
        survobj(data_tte, paste0("tte_", outcome), paste0("ind_", outcome), group_vars=c(variable), threshold=5)
      }
    ),
    plot_surv = pmap(
      list(survobj, variable, variable_name, colour_type, ci=FALSE, outcome_name),
      ggplot_surv
    ),
    plot_surv_ci = pmap(
      list(survobj, variable, variable_name, colour_type, ci=TRUE, outcome_name),
      ggplot_surv
    ),
  )


 plot_combinations$plot_surv_ci[[4]]
 #plot_combinations$plot_surv[[4]]
 #plot_combinations$survobj[[4]]

fs::dir_create(here("output", "descriptive", "km"))

# save individual plots
plot_combinations %>%
  transmute(
    plot=plot_surv,
    units = "cm",
    height = 10,
    width = 15,
    limitsize=FALSE,
    filename = str_c("plot_survival_", outcome, ".png"),
    path = here("output", "descriptive", "km"),
  ) %>%
  pwalk(ggsave) %>%
  mutate(filename = str_replace(filename, ".png", ".svg")) %>%
  pwalk(ggsave) %>%
  transmute(
    x = plot,
    path = file.path(path, str_replace(filename, ".svg", ".rds")),
    compress="gz"
  ) %>%
  pwalk(write_rds)


plot_combinations %>%
  transmute(
    plot=plot_surv_ci,
    units = "cm",
    height = 10,
    width = 15,
    limitsize=FALSE,
    filename = str_c("plot_survival_ci_", outcome, ".png"),
    path = here("output", "descriptive", "km"),
  ) %>%
  pwalk(ggsave) %>%
  mutate(filename = str_replace(filename, ".png", ".svg")) %>%
  pwalk(ggsave) %>%
  transmute(
    x = plot,
    path = file.path(path, str_replace(filename, ".svg", ".rds")),
    compress="gz"
  ) %>%
  pwalk(write_rds)

