
# # # # # # # # # # # # # # # # # # # # #
# This script:
# takes a cohort name as defined in data_define_cohorts.R, and imported as an Arg
# creates descriptive outputs on patient characteristics by vaccination status at 0, 28, and 56 days.
#
# The script should be run via an action in the project.yaml
# The script must be accompanied by one argument,
# 1. the name of the cohort defined in data_define_cohorts.R
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
metadata_outcomes <- read_rds(here("output", "data", "metadata_outcomes.rds"))

## create output directory ----
fs::dir_create(here("output", "descriptive", "tables"))

## custom functions ----


# # function to extract total plot height minus panel height
# plotHeight <- function(plot, unit){
#   grob <- ggplot2::ggplotGrob(plot)
#   grid::convertHeight(gtable::gtable_height(grob), unitTo=unit, valueOnly=TRUE)
# }
#
# # function to extract total plot width minus panel height
# plotWidth <- function(plot, unit){
#   grob <- ggplot2::ggplotGrob(plot)
#   grid::convertWidth(gtable::gtable_width(grob), unitTo=unit, valueOnly=TRUE)
# }
#
# # function to extract total number of bars plot (strictly this is the number of rows in the build of the plot data)
# plotNbars <- function(plot){
#   length(unique(ggplot2::ggplot_build(plot)$data[[1]]$x))
# }
#
# # function to extract total number of bars plot (strictly this is the number of rows in the build of the plot data)
# plotNfacetrows <- function(plot){
#   length(levels(ggplot2::ggplot_build(plot)$data[[1]]$PANEL))
# }
#
# plotNyscales <- function(plot){
#   length(ggplot2::ggplot_build(plot)$layout$panel_scales_y[[1]]$range$range)
# }
#
#
# # function to extract total number of panels
# plotNpanelrows <- function(plot){
#   length(unique(ggplot2::ggplot_build(plot)$layout$layout$ROW))
# }


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
    start_date,
    end_date,

    # time to last follow up day
    tte_enddate = tte(vax1_date, end_date, end_date),

    # time to last follow up day or death or deregistration
    tte_censor = tte(vax1_date, censor_date, censor_date),

    tte_vaxany2 = tte(vax1_date, covid_vax_any_2_date, censor_date),
    tte_vaxpfizer2 = tte(vax1_date, covid_vax_pfizer_2_date, censor_date),
    tte_vaxaz2 = tte(vax1_date, covid_vax_az_2_date, censor_date),
    tte_vaxmoderna2 = tte(vax1_date, covid_vax_moderna_2_date, censor_date),

    tte_test =tte(vax1_date, covid_test_date, censor_date, na.censor=TRUE),
    ind_test = censor_indicator(covid_test_date, censor_date),

    tte_postest = tte(vax1_date, positive_test_date, censor_date, na.censor=TRUE),
    ind_postest = censor_indicator(positive_test_date, censor_date),

    tte_emergency = tte(vax1_date, emergency_date, censor_date, na.censor=TRUE),
    ind_emergency = censor_indicator(emergency_date, censor_date),

    tte_covidadmitted = tte(vax1_date, covidadmitted_date, censor_date, na.censor=TRUE),
    ind_covidadmitted = censor_indicator(covidadmitted_date, censor_date),

    tte_covidcc = tte(vax1_date, covidcc_date, censor_date, na.censor=TRUE),
    ind_covidcc = censor_indicator(covidcc_date, censor_date),

    tte_coviddeath = tte(vax1_date, coviddeath_date, censor_date, na.censor=TRUE),
    ind_coviddeath = censor_indicator(coviddeath_date, censor_date),

    tte_noncoviddeath = tte(vax1_date, noncoviddeath_date, censor_date, na.censor=TRUE),
    ind_noncoviddeath = censor_indicator(noncoviddeath_date, censor_date),

    tte_death = tte(vax1_date, death_date, censor_date, na.censor=TRUE),
    ind_death = censor_indicator(death_date, censor_date),

    tte_dereg = tte(vax1_date, dereg_date, censor_date, na.censor=TRUE),
    ind_dereg = censor_indicator(dereg_date, censor_date),

    all = factor("all")
  ) %>%
  filter(
    tte_censor>0 | is.na(tte_censor)
  )



 alltimes <- expand(data_tte, patient_id, times=as.integer(full_seq(c(1, tte_enddate),1)))# %>%
#   left_join(
#     data_tte %>% select(patient_id, vax1_day, tte_enddate),
#     by="patient_id"
#   )

data_pt <- tmerge(
  data1 = data_tte,
  data2 = data_tte,
  id = patient_id,

  tstart = 0L,
  tstop = tte_enddate, # use enddate not lastfup because it's useful for status over time plots

 # alltimes = event(times, times),

  vaxany2_status = tdc(tte_vaxany2),
  vaxpfizer2_status = tdc(tte_vaxpfizer2),
  vaxaz2_status = tdc(tte_vaxaz2),
  vaxmoderna2_status = tdc(tte_vaxmoderna2),

  test_status = tdc(tte_test),
  postest_status = tdc(tte_postest),
  emergency_status = tdc(tte_emergency),
  covidadmitted_status = tdc(tte_covidadmitted),
  covidcc_status = tdc(tte_covidcc),
  coviddeath_status = tdc(tte_coviddeath),
  noncoviddeath_status = tdc(tte_noncoviddeath),
  death_status = tdc(tte_death),
  dereg_status= tdc(tte_dereg),
  censor_status = tdc(tte_censor),

  vaxany2 = event(tte_vaxany2),
  vaxpfizer2 = event(tte_vaxpfizer2),
  vaxaz2 = event(tte_vaxaz2),
  vaxmoderna2 = event(tte_vaxmoderna2),
  test = event(tte_test),
  postest = event(tte_postest),
  emergency = event(tte_emergency),
  covidadmitted = event(tte_covidadmitted),
  covidcc = event(tte_covidcc),
  coviddeath = event(tte_coviddeath),
  noncoviddeath = event(tte_noncoviddeath),
  death = event(tte_death),
  dereg = event(tte_dereg),
  censor = event(tte_censor)

) %>%
tmerge(
  data1 = .,
  data2 = alltimes,
  id = patient_id,
  alltimes = event(times, times)
)


data_pt <- data_pt %>% select(
  patient_id,
  tstart, tstop,

  vaxany2_status,
  vaxpfizer2_status,
  vaxaz2_status,
  vaxmoderna2_status,

  test_status,
  postest_status,
  covidadmitted_status,
  covidcc_status,
  coviddeath_status,
  noncoviddeath_status,
  death_status,
  dereg_status,
  censor_status,

  vaxany2,
  vaxpfizer2,
  vaxaz2,
  vaxmoderna2,
  test,
  postest,
  covidadmitted,
  covidcc,
  coviddeath,
  noncoviddeath,
  death,
  dereg,
  censor
)

# create plots ----
data_by_day <-
  data_pt %>%
  left_join(
    data_cohort %>% transmute(
      patient_id,
      start_date,
      all = "all",
      sex,
      imd,
      ethnicity_combined,
      region,
      ageband,
      vax1_type
    ),
    by = "patient_id"
  ) %>%
  mutate(
    day = tstop,
    date = as.Date(start_date) + day -1,
    week = lubridate::floor_date(date, unit="week", week_start=2), #week commencing tuesday (since index date is a tuesday)
    #date = week,

    vaxany_status = fct_case_when(
      vaxany2_status==0 & death_status==0 & dereg_status==0 ~ "First dose",
      vaxany2_status==1 ~ "Second dose",
      death_status==1 | dereg_status==1 ~ "Died/deregistered",
      TRUE ~ NA_character_
    ),

    vaxbrand_status = fct_case_when(
      vax1_type=="pfizer" ~ "BNT162b2\ndose 1",
      vax1_type=="az" ~ "ChAdOx1\ndose 1",
      vaxpfizer2_status==1  ~ "BNT162b2\ndose 2",
      vaxaz2_status==1  ~ "ChAdOx1\ndose 2",
      TRUE ~ NA_character_
    ),
  )

plot_brand_counts <- function(var, var_descr){

  data1 <- data_by_day %>%
    mutate(
      variable = data_by_day[[var]]
    ) %>%
    filter(dereg_status==0) %>%
    group_by(date, variable, vaxbrand_status, censor_status, .drop=FALSE) %>%
    summarise(
      n = n(),
    ) %>%
    group_by(date, variable) %>%
    mutate(
      n_per_10000 = (n/sum(n))*10000
    ) %>%
    ungroup() %>%
    arrange(date, variable, vaxbrand_status, censor_status) %>%
    mutate(
      censor_status = if_else(censor_status %in% 1, "Died / deregistered", "At-risk"),
      group= factor(
        paste0(censor_status,":",vaxbrand_status),
        levels= map_chr(
          cross2(c("At-risk", "Died / deregistered"), levels(vaxbrand_status)),
          paste, sep = ":", collapse = ":"
        )
      )
    )

  colorspace::lighten("#d95f02", 0.25)

  plot <- data1 %>%
    ggplot() +
    geom_area(aes(x=date, y=n_per_10000,
                  group=group,
                  fill=vaxbrand_status,
                  alpha=censor_status
    )
    )+
    facet_grid(rows=vars(variable))+
    scale_x_date(date_breaks = "1 week", labels = scales::date_format("%Y-%m-%d"))+
    scale_fill_manual(values=c("#d95f02", "#7570b3","#FC7D42",  "#9590D3"))+#, "#1b9e77",  "#4BBA93"))+
    scale_alpha_manual(values=c(0.8,0.1), breaks=c(0.1))+
    labs(
      x="Date",
      y="Status per 10,000 people",
      colour=NULL,
      fill=NULL,
      alpha=NULL
    ) +
    plot_theme+
    theme(legend.position = "bottom")

  plot
}

# plot_brand_counts("all", "")
# data1 <- data_by_day %>%
#   mutate(
#     variable = data_by_day[["all"]]
#   ) %>%
#   filter(dereg_status==0) %>%
#   group_by(date, variable, vaxbrand_status, censor_status, .drop=FALSE) %>%
#   summarise(
#     n = n(),
#   ) %>%
#   group_by(date, variable) %>%
#   mutate(
#     n_per_10000 = (n/sum(n))*10000
#   ) %>%
#   ungroup() %>%
#   arrange(date, variable, vaxbrand_status, censor_status) %>%
#   mutate(
#     censor_status= if_else(is.na(censor_status) | censor_status==0, "Alive", "Dead"),
#       group= factor(
#       paste0(censor_status,":",vaxbrand_status),
#       levels= map_chr(
#         cross2(c("Alive","Dead"), levels(vaxbrand_status)),
#         paste, sep = ":", collapse = ":"
#       )
#     )
#   )

## cumulative event status ----

plot_event_counts <- function(var, var_descr){

  data1 <- data_by_day %>%
    mutate(
      variable = data_by_day[[var]]
    ) %>%
    group_by(date, outcome_status, variable, lag_vaxany_status_onedose) %>%
    summarise(
      n_events = n()
    ) %>%
    group_by(date, variable, lag_vaxany_status_onedose) %>%
    mutate(
      n = (n_events/sum(n_events))*10000
    ) %>%
    ungroup()

  plot <- data1 %>%
    filter(outcome_status !="No events") %>%
    droplevels() %>%
    ggplot() +
    geom_area(aes(x=date, y=n, group=outcome_status, fill=outcome_status), alpha=0.5)+
    facet_grid(rows=vars(variable), cols=vars(lag_vaxany_status_onedose))+
    scale_x_date(date_breaks = "1 week", labels = scales::date_format("%m-%d"))+
    scale_fill_brewer(palette="Dark2")+
    labs(
      x=NULL,
      y="Events per 10,000 people",
      fill=NULL,
      title = "Outcome status over time",
      subtitle = var_descr
    ) +
    plot_theme+
    theme(legend.position = "bottom")+
    guides(fill = guide_legend(nrow = 2))

  plot
}

## event rates ----


plot_event_rates <- function(var, var_descr){

  data1 <- data_by_day %>%
    mutate(
      variable = data_by_day[[var]]
    ) %>%
    filter(!death_status) %>%
    group_by(date, variable, lag_vaxany_status_onedose) %>%
    summarise(
      n= n(),
      death_rate = (sum(death)/n())*10000,
      coviddeath_rate = (sum(coviddeath)/n())*10000,
      covidadmitted_rate = (sum(covidadmitted)/n())*10000,
      postest_rate = (sum(postest)/n())*10000
    ) %>%
    pivot_longer(
      cols=c(-n, -date, -variable, -lag_vaxany_status_onedose),
      names_to = "outcome",
      values_to = "rate"
    ) %>%
    mutate(
      outcome = factor(
        outcome,
        levels=c("postest_rate", "covidadmitted_rate", "coviddeath_rate", "death_rate"),
        labels=c("Positive test", "COVID-19 hospitalisation", "COVID-19 death", "Any death"))
    )


  plot <- data1 %>%
    ggplot() +
    geom_line(aes(x=date, y=rate, group=outcome, colour=outcome))+
    facet_grid(rows=vars(variable), cols=vars(lag_vaxany_status_onedose))+
    scale_x_date(date_breaks = "1 week", labels = scales::date_format("%m-%d"))+
    scale_color_brewer(palette="Dark2")+
    labs(
      x=NULL,
      y="Event rate per week per 10,000 people",
      colour=NULL#,
      #title = "Outcome rates over time",
      #subtitle = var_descr
    ) +
    plot_theme+
    guides(colour = guide_legend(nrow = 2))+
    theme(legend.position = "bottom")

  plot

}

vars_df <- tribble(
  ~var, ~var_descr,
  "all", "",
  "sex", "Sex",
  "imd", "IMD",
  "ageband", "Age",
  "ethnicity_combined", "Ethnicity",
) %>% mutate(
  device="svg",
  units = "cm",
)

# save data to combine across cohorts later
write_rds(
  plot_brand_counts("all", "")$data,
  path=here::here("output", "descriptive", "plots", paste0("vaxcounts12.rds")), compress="gz"
)

vars_df %>%
  transmute(
    plot = pmap(lst(var, var_descr), plot_brand_counts),
    plot = patchwork::align_patches(plot),
    filename = paste0("brandcounts_",var,".svg"),
    path=here::here("output", cohort, "descriptive", "plots"),
    panelwidth = 15,
    panelheight = 7,
    #width = pmap_dbl(list(plot, units, panelwidth), function(plot, units, panelwidth){plotWidth(plot, units) + panelwidth}),
    units="cm",
    width = 25,
    height = pmap_dbl(list(plot, units, panelheight), function(plot, units, panelheight){plotHeight(plot, units) + plotNpanelrows(plot)*panelheight}),
  ) %>%
  mutate(
    pmap(list(
      filename=filename,
      plot=plot,
      path=path,
      width=width, height=height, units=units, limitsize=FALSE, scale=0.8
    ),
    ggsave),
  )

#
# vars_df %>%
#   transmute(
#     plot = pmap(lst(var, var_descr), plot_event_counts),
#     plot = patchwork::align_patches(plot),
#     filename = paste0("eventcounts_",var,".svg"),
#     path=here::here("output", cohort, "descr", "plots"),
#     panelwidth = 15,
#     panelheight = 7,
#     units="cm",
#     #width = pmap_dbl(list(plot, units, panelwidth), function(plot, units, panelwidth){plotWidth(plot, units) + panelwidth}),
#     width = 25,
#     height = pmap_dbl(list(plot, units, panelheight), function(plot, units, panelheight){plotHeight(plot, units) + plotNpanelrows(plot)*panelheight}),
#   ) %>%
#   mutate(
#     pmap(list(
#       filename=filename,
#       path=path,
#       plot=plot,
#       width=width, height=height, units=units, limitsize=FALSE, scale=0.8
#     ),
#     ggsave)
#   )
#
#
#
#
# vars_df %>%
#   transmute(
#     plot = pmap(lst(var, var_descr), plot_event_rates),
#     plot = patchwork::align_patches(plot),
#     filename = paste0("eventrates_",var,".svg"),
#     path=here::here("output", cohort, "descr", "plots"),
#     panelwidth = 15,
#     panelheight = 7,
#     units="cm",
#     #width = pmap_dbl(list(plot, units, panelwidth), function(plot, units, panelwidth){plotWidth(plot, units) + panelwidth}),
#     width = 25,
#     height = pmap_dbl(list(plot, units, panelheight), function(plot, units, panelheight){plotHeight(plot, units) + plotNpanelrows(plot)*panelheight}),
#   ) %>%
#   mutate(
#     pmap(list(
#       filename=filename,
#       path=path,
#       plot=plot,
#       width=width, height=height, units=units, limitsize=FALSE, scale=0.8
#     ),
#     ggsave)
#   )


## end-date status ----
tab_end_status <- data_pt %>%
  filter(lastfup == 1) %>%
  summarise(
    n = n(),
    alive_unvax = sum(vaxany_status==0 & death_status==0),
    vaxany = sum(vaxany_status>0 & death_status==0),
    vaxpfizer = sum(vaxpfizer_status>0 & death_status==0),
    vaxaz = sum(vaxaz_status>0 & death_status==0),
    vaxpfizer_pct = vaxpfizer / vaxany,
    vaxaz_pct = vaxaz / vaxany,
    dead_unvax = sum(vaxany_status==0 & death==1),
    dereg_unvax = sum(vaxany_status==0 & dereg==1),

    pt_days = sum(tstop),
    pt_years = sum(tstop)/365.25,

    pt_days_vax = sum(tstop)-sum(pmin(vaxanyday1, tstop, na.rm=TRUE)),
    pt_years_vax = (sum(tstop)-sum(pmin(vaxanyday1, tstop, na.rm=TRUE)))/365.25,

    pt_pct_vax = pt_days_vax / pt_days,

    fup_min = min(tstop),
    fup_q1 = quantile(tstop, 0.25),
    fup_median = median(tstop),
    fup_q3 = quantile(tstop, 0.75),
    max_fup = max(tstop),
  )

write_csv(tab_end_status, here::here("output", cohort, "descriptive", "tables", "end_status.csv"))
