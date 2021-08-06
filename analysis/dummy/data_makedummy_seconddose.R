
library('tidyverse')
library('arrow')
library('here')
library('glue')

source(here("analysis", "lib", "utility_functions.R"))

remotes::install_github("https://github.com/wjchulme/dd4d")
library('dd4d')


population_size <- 10000

# import globally defined repo variables from
gbl_vars <- jsonlite::fromJSON(
  txt="./analysis/global-variables.json"
)


index_date <- as.Date(gbl_vars$start_date)
start_date_pfizer <- as.Date(gbl_vars$start_date_pfizer)
start_date_az <- as.Date(gbl_vars$start_date_az)
start_date_moderna <- as.Date(gbl_vars$start_date_moderna)
end_date <- as.Date(gbl_vars$end_date)
#censor_date <- pmin(end_date, dereg_date, death_date, na.rm=TRUE)

index_day <- 0
pfizer_day <- as.integer(start_date_pfizer - index_date)
az_day <- as.integer(start_date_az - index_date)
moderna_day <- as.integer(start_date_moderna - index_date)
end_day <- as.integer(end_date - index_date)


known_variables <- c("index_date", "start_date_pfizer", "start_date_az", "start_date_moderna", "end_date", "index_day", "pfizer_day",  "az_day", "moderna_day", "end_day")


sim_list = list(
  covid_vax_pfizer_1_day = bn_node(
    ~as.integer(runif(n=1, pfizer_day, pfizer_day+120)),
  ),
  covid_vax_pfizer_2_day = bn_node(
    ~as.integer(runif(n=1, covid_vax_pfizer_1_day+80, covid_vax_pfizer_1_day+120)),
    missing_rate = ~0.7
  ),
  covid_vax_pfizer_3_day = bn_node(
    ~as.integer(runif(n=1, covid_vax_pfizer_2_day+80, covid_vax_pfizer_2_day+120)),
    missing_rate = ~1
  ),
  covid_vax_az_1_day = bn_node(
    ~as.integer(runif(n=1, az_day, az_day+120)),
  ),
  covid_vax_az_2_day = bn_node(
    ~as.integer(runif(n=1, covid_vax_az_1_day+80, covid_vax_az_1_day+120)),
    missing_rate = ~0.7
  ),
  covid_vax_az_3_day = bn_node(
    ~as.integer(runif(n=1, covid_vax_az_2_day+80, covid_vax_az_2_day+120)),
    missing_rate = ~1
  ),
  covid_vax_moderna_1_day = bn_node(
    ~as.integer(runif(n=1, moderna_day, moderna_day+120)),
  ),
  covid_vax_moderna_2_day = bn_node(
    ~as.integer(runif(n=1, covid_vax_moderna_1_day+80, covid_vax_moderna_1_day+120)),
    missing_rate = ~0.7
  ),
  covid_vax_moderna_3_day = bn_node(
    ~as.integer(runif(n=1, covid_vax_moderna_1_day+80, covid_vax_moderna_1_day+120)),
    missing_rate = ~1
  ),



  covid_vax_any_1_day = bn_node(
    ~pmin(covid_vax_pfizer_1_day, covid_vax_az_1_day, covid_vax_moderna_1_day, na.rm=TRUE),
    needs = c("covid_vax_pfizer_1_day", "covid_vax_az_1_day", "covid_vax_moderna_1_day")
  ),
  covid_vax_any_2_day = bn_node(
    ~pmin(covid_vax_pfizer_2_day, covid_vax_az_2_day, covid_vax_moderna_2_day, na.rm=TRUE),
    needs = c("covid_vax_pfizer_2_day", "covid_vax_az_2_day", "covid_vax_moderna_2_day")
  ),
  covid_vax_any_3_day = bn_node(
    ~pmin(covid_vax_pfizer_3_day, covid_vax_az_3_day, covid_vax_moderna_3_day, na.rm=TRUE),
    needs = c("covid_vax_pfizer_3_day", "covid_vax_az_3_day", "covid_vax_moderna_3_day")
  ),

  # assumes covid_vax_disease is the same as covid_vax_any though in reality there will be slight differences
  covid_vax_disease_1_day = bn_node(
    ~pmin(covid_vax_pfizer_1_day, covid_vax_az_1_day, covid_vax_moderna_1_day, na.rm=TRUE),
  ),
  covid_vax_disease_2_day = bn_node(
    ~pmin(covid_vax_pfizer_2_day, covid_vax_az_2_day, covid_vax_moderna_2_day, na.rm=TRUE),
  ),
  covid_vax_disease_3_day = bn_node(
    ~pmin(covid_vax_pfizer_3_day, covid_vax_az_3_day, covid_vax_moderna_3_day, na.rm=TRUE),
  ),

  dereg_day = bn_node(
    ~as.integer(runif(n=1, covid_vax_any_1_day, covid_vax_any_1_day+120)),
    missing_rate = ~0.99
  ),

  age = bn_node(
    ~as.integer(rnorm(n=1, mean=60, sd=15))
  ),
  sex = bn_node(
    ~rfactor(n=1, levels = c("F", "M"), p = c(0.51, 0.49)),
    missing_rate = ~0.001 # this is shorthand for ~(rbernoulli(n=1, p = 0.2))
  ),

  ethnicity = bn_node(
    ~rfactor(n=1, levels = c(1,2,3,4,5), p = c(0.8, 0.05, 0.05, 0.05, 0.05)),
    missing_rate = ~ 0.25
  ),

  ethnicity_6_sus = bn_node(
    ~rfactor(n=1, levels = c(0,1,2,3,4,5), p = c(0.1, 0.7, 0.05, 0.05, 0.05, 0.05)),
    missing_rate = ~ 0
  ),

  practice_id = bn_node(
    ~as.integer(runif(n=1, 1, 200))
  ),

  region = bn_node(
    variable_formula = ~rfactor(n=1, levels=c(
      "North East",
      "North West",
      "Yorkshire and the Humber",
      "East Midlands",
      "West Midlands",
      "East of England",
      "London",
      "South East",
      "South West"
    ), p = c(0.2, 0.2, 0.3, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05))
  ),

  imd = bn_node(
    ~factor(plyr::round_any(runif(n=1, 1, 32000), 100), levels=seq(0,32000,100)),
    missing_rate = ~0.02
  ),

  death_day = bn_node(
    ~as.integer(runif(n=1, covid_vax_any_1_day, covid_vax_any_1_day+200)),
    missing_rate = ~0.99
  )

)

bn <- bn_create(sim_list, known_variables = known_variables)

bn_plot(bn)
bn_plot(bn, connected_only=TRUE)


dummydata <-bn_simulate(bn, pop_size = population_size, keep_all = FALSE, .id="patient_id")

dummydata_processed <- dummydata %>%
  mutate(
    # remove vaccination dates occurring after an earlier vaccination of a different brand
    covid_vax_pfizer_1_day = if_else(covid_vax_pfizer_1_day<=pmin(Inf, covid_vax_az_1_day, covid_vax_moderna_1_day, na.rm=TRUE), covid_vax_pfizer_1_day, NA_integer_),
    covid_vax_pfizer_2_day = if_else(covid_vax_pfizer_1_day<=pmin(Inf, covid_vax_az_1_day, covid_vax_moderna_1_day, na.rm=TRUE), covid_vax_pfizer_2_day, NA_integer_),

    covid_vax_az_1_day = if_else(covid_vax_az_1_day<pmin(Inf, covid_vax_pfizer_1_day, covid_vax_moderna_1_day, na.rm=TRUE), covid_vax_az_1_day, NA_integer_),
    covid_vax_az_2_day = if_else(covid_vax_az_1_day<pmin(Inf, covid_vax_pfizer_1_day, covid_vax_moderna_1_day, na.rm=TRUE), covid_vax_az_2_day, NA_integer_),

    covid_vax_moderna_1_day = if_else(covid_vax_moderna_1_day<pmin(Inf, covid_vax_pfizer_1_day, covid_vax_az_1_day, na.rm=TRUE), covid_vax_moderna_1_day, NA_integer_),
    covid_vax_moderna_2_day = if_else(covid_vax_moderna_1_day<pmin(Inf, covid_vax_pfizer_1_day, covid_vax_az_1_day, na.rm=TRUE), covid_vax_moderna_2_day, NA_integer_),
  ) %>%
  #convert logical to integer as study defs output 0/1 not TRUE/FALSE
  #mutate(across(where(is.logical), ~ as.integer(.))) %>%
  #convert integer days to dates since index date and rename vars
  mutate(across(ends_with("_day"), ~ as.Date(as.character(index_date + .)))) %>%
  rename_with(~str_replace(., "_day", "_date"), ends_with("_day"))



write_feather(dummydata_processed, sink = here("dummydata", "dummyinput_seconddose.feather"))
