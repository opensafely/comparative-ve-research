

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

if(Sys.getenv("OPENSAFELY_BACKEND") %in% c("", "expectations")){
  redact_threshold <- 2
} else{
  redact_threshold <- 5
}


## create output directory ----
fs::dir_create(here("output", "seconddose", "plots"))

## custom functions ----

# function to extract total plot height minus panel height
plotHeight <- function(plot, unit){
  grob <- ggplotGrob(plot)
  grid::convertHeight(gtable::gtable_height(grob), unitTo=unit, valueOnly=TRUE)
}

# function to extract total plot width minus panel height
plotWidth <- function(plot, unit){
  grob <- ggplotGrob(plot)
  grid::convertWidth(gtable::gtable_width(grob), unitTo=unit, valueOnly=TRUE)
}

# function to extract total number of bars plot (strictly this is the number of rows in the build of the plot data)
plotNbars <- function(plot){
  length(ggplot_build(plot)$data[[1]]$x)
}

# function to extract total number of panels
plotNpanels <- function(plot){
  length(levels(ggplot_build(plot)$data[[1]]$PANEL))
}

## Import processed data ----

data_cohort <- read_rds(here::here("output", "data", "seconddose_data_processed.rds"))

data_tte <- data_cohort %>%
  transmute(
    patient_id,

    end_date = as.Date("2021-04-05"),

    covid_vax_1_date = pmax(as.Date("2020-12-01"), covid_vax_1_date),
    covid_vax_2_date = pmax(as.Date("2020-12-01"), covid_vax_2_date),

    covid_vax_1_type,
    covid_vax_2_type,

    vax1_type_descr,

    censor_date = pmin(end_date, dereg_date, death_date, na.rm=TRUE),

    # time to last follow up day
    tte_enddate = tte(covid_vax_1_date-1, end_date, end_date),

    # time to last follow up day or death or deregistration
    tte_censor = tte(covid_vax_1_date-1, censor_date, censor_date),

    tte_vaxany2 = tte(covid_vax_1_date-1, covid_vax_2_date, censor_date),
    ind_vaxany2 = censor_indicator(covid_vax_2_date, censor_date),

    ageband,
    sex,
    ethnicity_combined,
    imd_Q5,
    all=""
  )




plot_2dose <- function(var, var_descr, weekly){

  # weekly <- TRUE
  # var <- "ageband"
  # var_descr <- "Age group"

  resolution <- ifelse(weekly, "weekly", "daily")

  data_only2dose <-
    data_tte %>%
    filter(
      # allow 18 weeks to see 2nd vaccination otherwise censor
      covid_vax_1_date < end_date,
      !(is.na(covid_vax_2_date) | (covid_vax_2_date-covid_vax_1_date > 18*7))
    ) %>%
    mutate(
      temp_var = fct_explicit_na(.[[var]]),
    ) %>%
    droplevels()

  if(weekly){
    data_freq <-
      data_only2dose %>%
      mutate(
        #round date to nearest week, starting on tuesday
        covid_vax_1_date=floor_date(covid_vax_1_date, unit="week", week_start=2),
        covid_vax_2_date=floor_date(covid_vax_2_date, unit="week", week_start=2),
      ) %>%
      group_by(covid_vax_1_date, covid_vax_2_date, vax1_type_descr, temp_var) %>%
      count()
  } else{
  data_freq <-
    data_only2dose %>%
    group_by(covid_vax_1_date, covid_vax_2_date, vax1_type_descr, temp_var) %>%
    count()
  }

  # data_freq %>%
  #   ggplot()+
  #   geom_tile(aes(x=covid_vax_1_date, covid_vax_2_date, fill=n))+
  #   geom_abline(slope=c(1), intercept=7*c(0,6,12,18))+
  #   facet_grid(rows=vars(temp_var), cols=vars(vax1_type_descr))+
    #   coord_fixed() +
  #   theme_bw()
  #

  tile <- data_freq %>%
    filter(!is.na(covid_vax_2_date)) %>%
    ggplot()+
    geom_abline(slope=-1, intercept=seq.Date(as.Date("2020-12-01"), as.Date("2021-08-01"), by="month"), colour="lightgrey", alpha=0.2)+
    geom_tile(aes(x=covid_vax_1_date, covid_vax_2_date-covid_vax_1_date, fill=n), colour="transparent", alpha=0.7)+
    scale_x_date(
      limits=as.Date(c("2020-12-01","2021-05-01")),
      date_breaks="months",
      date_labels="%b",
      #sec.axis = dup_axis()
    )+
    scale_y_continuous(limits=c(14,18*7), breaks=seq(0,365,14))+
    scale_fill_gradientn(
      colours=c("transparent", "aliceblue", "aliceblue", "darkblue"),
      values=scales::rescale(c(0,1,redact_threshold,max(data_freq$n, na.rm=TRUE))),
      na.value = "grey50"
    )+
    facet_grid(
      rows=vars(temp_var),
      cols=vars(vax1_type_descr)
    )+
    labs(
      x="First dose date",
      y="Days to second dose",
      fill="Count"
    )+
    coord_fixed() +
    theme_minimal(base_size = 14)+
    theme(
      legend.position = "bottom",

      strip.text.y.right = element_text(angle = 0),
      axis.line.x = element_line(colour = "black"),
      axis.text.x.bottom = element_text(angle = 70, vjust = 1, hjust=1),
      axis.text.x.top = element_text(angle = 70, vjust = 0, hjust=0),
      panel.grid.minor = element_blank(),
      axis.ticks.x = element_line(colour = 'black'),
      legend.text = element_text(angle = 70, vjust = 1, hjust=1)
    )

  ggsave(
    plot = tile,
    units = "cm",
    width= 20,
    height = plotHeight(tile, "cm") + (plotNpanels(tile)/3)*4,
    limitsize = FALSE,
    filename = glue("plot_tile_{resolution}_{var}.png"),
    path = here("output", "seconddose", "plots")
  )


  binwidth <- ifelse(weekly, 7, 1)

  histogram <- data_only2dose %>%
    ggplot()+
    geom_histogram(
      aes(x=as.numeric(covid_vax_2_date-covid_vax_1_date)),
      binwidth=binwidth,
      boundary=0,
      closed="right"
    ) +
    geom_rect(
      aes(xmin=-Inf, xmax=Inf,ymin=1, ymax=6), fill="mistyrose", colour="transparent"
    ) +
    facet_grid(
      rows = vars(temp_var),
      cols=vars(vax1_type_descr)
    )+
    scale_x_continuous(breaks=seq(0, 52*7, 14))+
    scale_y_continuous(expand=expansion(c(0,NA)))+
    labs(
      x="Days to second dose",
      y="Count"
    )+
    theme_minimal(base_size = 14)+
    theme(
      strip.text.y.right = element_text(angle = 0),
      axis.line.x = element_line(colour = "black"),
      axis.ticks.x = element_line(colour = 'black')
    )


  ggsave(
    plot = histogram,
    units = "cm",
    height = plotHeight(histogram, "cm") + (plotNpanels(histogram)/3)*4,
    width= 20,
    limitsize = FALSE,
    filename = glue("plot_histogram_{resolution}_{var}.png"),
    path = here("output", "seconddose", "plots")
  )

}



# vars_df <- tribble(
#   ~var, ~var_descr,
#   "all", "",
#   "sex", "Sex",
#   "imd", "IMD",
#   "ageband", "Age",
#   "ethnicity_combined", "Ethnicity",
# )

plot_2dose("all", "Overall", TRUE)
plot_2dose("sex", "Sex", TRUE)
plot_2dose("imd_Q5", "IMD", TRUE)
plot_2dose("ageband", "Age", TRUE)
plot_2dose("ethnicity_combined", "Ethnicity", TRUE)

plot_2dose("all", "Overall", FALSE)
plot_2dose("sex", "Sex", FALSE)
plot_2dose("imd_Q5", "IMD", FALSE)
plot_2dose("ageband", "Age", FALSE)
plot_2dose("ethnicity_combined", "Ethnicity", FALSE)
