
# # # # # # # # # # # # # # # # # # # # #
# This script:
# imports fitted PLR models
# calculates robust CIs taking into account patient-level clustering
# outputs effect plots for the primary vaccine-outcome relationship
#
# The script should only be run via an action in the project.yaml only
# The script must be accompanied by the following arguments: outcome, timescale, censor_seconddose
# # # # # # # # # # # # # # # # # # # # #

# Preliminaries ----


# import command-line arguments ----

args <- commandArgs(trailingOnly=TRUE)


if(length(args)==0){
  # use for interactive testing
  removeobs <- FALSE
  outcome <- "postest"
  timescale <- "timesincevax"
  censor_seconddose <- as.integer("0")
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

if(censor_seconddose==1){
  postvaxcuts<-postvaxcuts12
  lastfupday<-lastfupday12
} else {
  postvaxcuts <- postvaxcuts20
  if(outcome=="postest") postvaxcuts <- postvaxcuts20_postest
  lastfupday <- lastfupday20
}


# redo formulae from modelling script ----

formula_outcome <- outcome_event ~ 1


nsevents <- function(x, events, df){
  # this is the same as the `ns` function,
  # except the knot locations are chosen
  # based on the event times only, not on all person-time
  probs <- seq(0,df)/df
  q <- quantile(x[events==1], probs=probs)
  ns(x, knots=q[-c(1, df+1)], Boundary.knots = q[c(1, df+1)])
}

# mimicing timescale / stratification in simple cox models
if(timescale=="calendar"){
  formula_timescale_pw <- . ~ . + ns(tstop_calendar, 4) # spline for timescale only
  formula_timescale_ns <- . ~ . + ns(tstop_calendar, 4) # spline for timescale only
  formula_spacetime <- . ~ . + ns(tstop_calendar, 4)*region # spline for space-time adjustments

  formula_timesincevax_pw <- . ~ . + vax1_az * timesincevax_pw
  formula_timesincevax_ns <- . ~ . + vax1_az * nsevents(tstop, outcome_event, 4)

}
if(timescale=="timesincevax"){
  formula_timescale_pw <- . ~ . + timesincevax_pw # spline for timescale only
  formula_timescale_ns <- . ~ . + nsevents(tstop, outcome_event, 4) # spline for timescale only
  formula_spacetime <- . ~ . + ns(vax1_day, 4)*region # spline for space-time adjustments

  formula_timesincevax_pw <- . ~ . + vax1_az + vax1_az:timesincevax_pw
  formula_timesincevax_ns <- . ~ . + vax1_az + vax1_az:nsevents(tstop, outcome_event, 4)

}


## NOTE
# calendar-time PLR models are still probably wrong!
# as time-varying splines for both vaccination time and calendar time are included.
# This wrongly allows for estimation of the probability of, eg, the risk of death
# in february for someone vaccinated on 1 march

### piecewise formulae ----
### estimand
formula_vaxonly_pw <- formula_outcome  %>% update(formula_timesincevax_pw) %>% update(formula_timescale_pw)

formula0_pw <- formula_vaxonly_pw
formula1_pw <- formula_vaxonly_pw %>% update(formula_spacetime)
formula2_pw <- formula_vaxonly_pw %>% update(formula_spacetime) %>% update(formula_demog)
formula3_pw <- formula_vaxonly_pw %>% update(formula_spacetime) %>% update(formula_demog) %>% update (formula_comorbs)

### natural cubic spline formulae ----
### estimands
formula_vaxonly_ns <- formula_outcome  %>% update(formula_timesincevax_ns) %>% update(formula_timescale_ns)

formula0_ns <- formula_vaxonly_ns
formula1_ns <- formula_vaxonly_ns %>% update(formula_spacetime)
formula2_ns <- formula_vaxonly_ns %>% update(formula_spacetime) %>% update(formula_demog)
formula3_ns <- formula_vaxonly_ns %>% update(formula_spacetime) %>% update(formula_demog) %>% update (formula_comorbs)


## functions for variance estimation ----


## risk-adjusted survival curves ----

cmlinc_variance <- function(model, vcov, newdata, id, time, weights){

  # calculate variance of adjusted survival / adjusted cumulative incidence
  # needs model object, cluster-vcov, input data, model weights, and indices for patient and time

  if(missing(newdata)){ newdata <- model$model }
  tt <- terms(model) # this helpfully grabs the correct spline basis from the model, rather than recalculating based on `newdata`
  Terms <- delete.response(tt)
  m.mat <- model.matrix(Terms, data=newdata)
  m.coef <- model$coef

  N <- nrow(m.mat)
  K <- length(m.coef)

  # log-odds, nu_t, at time t
  nu <- m.coef %*% t(m.mat) # t_i x 1
  # part of partial derivative
  pdc <- (exp(nu)/((1+exp(nu))^2)) # t_i x 1
  # summand for partial derivative of P_t(theta_t | X_t), for each time t and term k

  #summand <- crossprod(diag(as.vector(pdc)), m.mat)    # t_i  x k
  summand <- matrix(0, nrow=N, ncol=K)
  for (k in seq_len(K)){
    summand[,k] <- m.mat[,k] * as.vector(pdc)
  }

  # cumulative sum of summand, by patient_id  # t_i x k
  cmlsum <- matrix(0, nrow=N, ncol=K)
  for (k in seq_len(K)){
    cmlsum[,k] <- ave(summand[,k], id, FUN=cumsum)
  }

  ## multiply by model weights (weights are normalised here so we can use `sum` later, not `weighted.mean`)
  normweights <- weights / ave(weights, time, FUN=sum) # t_i x 1

  #wgtcmlsum <- crossprod(diag(normweights), cmlsum ) # t_i x k
  wgtcmlsum <- matrix(0, nrow=N, ncol=K)
  for (k in seq_len(K)){
    wgtcmlsum[,k] <- cmlsum[,k] * normweights
  }

  # partial derivative of cumulative incidence at t
  partial_derivative <- rowsum(wgtcmlsum, time)

  variance <- rowSums(crossprod(t(partial_derivative), vcov) * partial_derivative) # t x 1

  variance
}

#test<-cmlinc_variance(plrmod3, vcov3, mutate(data_plr, vax1_az=1L), data_plr$patient_id, data_plr$tstop, data_plr$sample_weights)


## risk-adjusted survival curves ----

riskdiff_variance <- function(model, vcov, newdata0, newdata1, id, time, weights){

  # calculate variance of adjusted survival / adjusted cumulative incidence
  # needs model object, cluster-vcov, input data, model weights, and indices for patient and time

  tt <- terms(model) # this helpfully grabs the correct spline basis from the model, rather than recalculating based on `newdata`
  Terms <- delete.response(tt)
  m.mat0 <- model.matrix(Terms, data=newdata0)
  m.mat1 <- model.matrix(Terms, data=newdata1)
  m.coef <- model$coef

  N <- nrow(m.mat0)
  K <- length(m.coef)

  # log-odds, nu_t, at time t
  nu0 <- m.coef %*% t(m.mat0) # t_i x 1
  nu1 <- m.coef %*% t(m.mat1) # t_i x 1
  # part of partial derivative
  pdc0 <- (exp(nu0)/((1+exp(nu0))^2)) # t_i x 1
  pdc1 <- (exp(nu1)/((1+exp(nu1))^2)) # t_i x 1
  # summand for partial derivative of P_t(theta_t | X_t), for each time t and term k

  #summand <- crossprod(diag(as.vector(pdc0)), m.mat0)    # t_i  x k
  summand0 <- matrix(0, nrow=N, ncol=K)
  for (k in seq_len(K)){
    summand0[,k] <- m.mat0[,k] * as.vector(pdc0)
  }
  summand1 <- matrix(0, nrow=N, ncol=K)
  for (k in seq_len(K)){
    summand1[,k] <- m.mat1[,k] * as.vector(pdc1)
  }

  # cumulative sum of summand, by patient_id  # t_i x k
  cmlsum <- matrix(0, nrow=N, ncol=K)
  for (k in seq_len(K)){
    cmlsum[,k] <- ave(summand1[,k] - summand0[,k], id, FUN=cumsum)
  }

  ## multiply by model weights (weights are normalised here so we can use `sum` later, not `weighted.mean`)
  normweights <- weights / ave(weights, time, FUN=sum) # t_i x 1

  #wgtcmlsum <- crossprod(diag(normweights), cmlsum ) # t_i x k
  wgtcmlsum <- matrix(0, nrow=N, ncol=K)
  for (k in seq_len(K)){
    wgtcmlsum[,k] <- cmlsum[,k] * normweights
  }

  # partial derivative of cumulative incidence at t
  partial_derivative <- rowsum(wgtcmlsum, time)

  variance <- rowSums(crossprod(t(partial_derivative), vcov) * partial_derivative) # t x 1

  variance
}

#test<-riskdiff_variance(plrmod3, vcov3, mutate(data_plr, vax1_az=0L), mutate(data_plr, vax1_az=1L), data_plr$patient_id, data_plr$tstop, data_plr$sample_weights)


## function for retrieving time-dpeendnet hazard ratio ----





### function for retrieving time-dependent hazard ratio ----

get_HR <- function(.data, model, vcov, term_index){
  ## function to get AZ/pfizer hazard ratio spline over time since first dose

  tstop <- .data$tstop

  tt <- terms(model) # this helpfully grabs the correct spline basis from the model, rather than recalculating based on `.data`
  Terms <- delete.response(tt)
  mat0 <- model.matrix(Terms, data=mutate(.data, vax1_az=0))
  mat1 <- model.matrix(Terms, data=mutate(.data, vax1_az=1))

  tstop_distinct <- unique(tstop)

  # take a single row for each follow up time, and only select columns relevant for time-dependent vaccine effect
  partialX0 <- mat0[match(tstop_distinct, tstop), term_index]
  partialX1 <- mat1[match(tstop_distinct, tstop), term_index]

  # calculate difference between vaccine types on linear scale
  diffX <- partialX1-partialX0

  # get vaccine relevant  estimates
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

# Import processed data ----

data_plr <- read_rds(here("output", "models", outcome, timescale, censor_seconddose, "modelplr_data.rds"))



## report peicewise models ----
# tidy_plr_pw <- read_rds(here("output", "models", outcome, timescale, censor_seconddose, "modelplr_tidy_pw.rds"))
# tidy_plr_pwc <- read_rds(here("output", "models", outcome, "calendar", censor_seconddose, "modelplr_tidy_pw.rds"))
#
# effectsplr <- tidy_plr_pw %>%
#   filter(str_detect(term, fixed("vax1_az"))) %>%
#   group_by(model) %>%
#   mutate(
#     pw=str_replace(term, pattern=fixed("vax1_az:timesincevax_pw"), ""),
#     pw=if_else(label=="vax1_az", paste0(postvaxcuts[1]+1,"-", postvaxcuts[2]), pw),
#     pw=fct_inorder(pw),
#     term_left = as.numeric(str_extract(pw, "^\\d+"))-1,
#     term_right = as.numeric(str_extract(pw, "\\d+$"))-1,
#     term_right = if_else(is.na(term_right), lastfupday, term_right),
#     term_midpoint = term_left + (term_right+1-term_left)/2
#   ) %>%
#   ungroup()
#
# write_rds(effectsplr, path = here("output", "models", outcome, timescale, censor_seconddose, glue("reportplr_effects_pw.rds")))
# write_csv(effectsplr, path = here("output", "models", outcome, timescale, censor_seconddose, glue("reportplr_effects_pw.csv")))
#
# plotplr <-
#   ggplot(data = effectsplr) +
#   geom_point(aes(y=exp(estimate), x=term_midpoint, colour=model_name), position = position_dodge(width = 1.8))+
#   geom_linerange(aes(ymin=exp(conf.low), ymax=exp(conf.high), x=term_midpoint, colour=model_name), position = position_dodge(width = 1.8))+
#   geom_hline(aes(yintercept=1), colour='grey')+
#   scale_y_log10(
#     breaks=c(0.25, 0.33, 0.5, 0.67, 0.80, 1, 1.25, 1.5, 2, 3, 4),
#     sec.axis = dup_axis(name="<--  favours Pfizer  /  favours AZ  -->", breaks = NULL)
#   )+
#   scale_x_continuous(breaks=unique(effectsplr$term_left), limits=c(min(effectsplr$term_left), max(effectsplr$term_right)+1), expand = c(0, 0))+
#   scale_colour_brewer(type="qual", palette="Set1", guide=guide_legend(ncol=1))+
#   labs(
#     y="Hazard ratio",
#     x="Days since first dose",
#     colour=NULL,
#     title=glue::glue("AZ versus Pfizer, by time since first-dose")
#   ) +
#   theme_bw()+
#   theme(
#     panel.border = element_blank(),
#     axis.line.y = element_line(colour = "black"),
#
#     panel.grid.minor.x = element_blank(),
#     panel.grid.minor.y = element_blank(),
#     strip.background = element_blank(),
#     strip.placement = "outside",
#     strip.text.y.left = element_text(angle = 0),
#
#     panel.spacing = unit(0.8, "lines"),
#
#     plot.title = element_text(hjust = 0),
#     plot.title.position = "plot",
#     plot.caption.position = "plot",
#     plot.caption = element_text(hjust = 0, face= "italic"),
#
#     legend.position = "bottom"
#   ) +
#   NULL
# plotplr
#
# ## save plot
#
# write_rds(plotplr, path=here("output", "models", outcome, timescale, censor_seconddose, glue("reportplr_effectsplot_pw.rds")))
# ggsave(filename=here("output", "models", outcome, timescale, censor_seconddose, glue("reportplr_effectsplot_pw.svg")), plotplr, width=20, height=15, units="cm")
# ggsave(filename=here("output", "models", outcome, timescale, censor_seconddose, glue("reportplr_effectsplot_pw.png")), plotplr, width=20, height=15, units="cm")
#
#



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# save hazard ratios, cumulative incidence and difference in cumulative incidence ----
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

#"timesincevax", "ns(tstop,"
# "pw", "ns"

report_estimates <- function(modeltype, timestr){

  modeltype="pw"
 timestr="timesincevax"

  tidy_plr <- read_rds(here("output", "models", outcome, timescale, censor_seconddose, glue("modelplr_tidy_{modeltype}.rds")))

  # effectsplr <- tidy_plr_pw %>%
  #   filter(str_detect(term, fixed("vax1_az"))) %>%
  #   group_by(model) %>%
  #   mutate(
  #     pw=str_replace(term, pattern=fixed("vax1_az:timesincevax"), ""),
  #     pw=if_else(label=="vax1_az", paste0(postvaxcuts[1]+1,"-", postvaxcuts[2]), pw),
  #     pw=fct_inorder(pw),
  #     term_left = as.numeric(str_extract(pw, "^\\d+"))-1,
  #     term_right = as.numeric(str_extract(pw, "\\d+$"))-1,
  #     term_right = if_else(is.na(term_right), lastfupday, term_right),
  #     term_midpoint = term_left + (term_right+1-term_left)/2
  #   ) %>%
  #   ungroup()



  ### imort models ----

  plrmod0 <- read_rds(here("output", "models", outcome, timescale, censor_seconddose, glue("modelplr_model0{modeltype}.rds")))
  plrmod1 <- read_rds(here("output", "models", outcome, timescale, censor_seconddose, glue("modelplr_model1{modeltype}.rds")))
  plrmod2 <- read_rds(here("output", "models", outcome, timescale, censor_seconddose, glue("modelplr_model2{modeltype}.rds")))
  plrmod3 <- read_rds(here("output", "models", outcome, timescale, censor_seconddose, glue("modelplr_model3{modeltype}.rds")))

  vcov0 <- read_rds(here("output", "models", outcome, timescale, censor_seconddose, glue("modelplr_vcov0{modeltype}.rds")))
  vcov1 <- read_rds(here("output", "models", outcome, timescale, censor_seconddose, glue("modelplr_vcov1{modeltype}.rds")))
  vcov2 <- read_rds(here("output", "models", outcome, timescale, censor_seconddose, glue("modelplr_vcov2{modeltype}.rds")))
  vcov3 <- read_rds(here("output", "models", outcome, timescale, censor_seconddose, glue("modelplr_vcov3{modeltype}.rds")))

  term_index0 <- str_detect(names(coef(plrmod0)), fixed(timestr)) | str_detect(names(coef(plrmod0)), fixed("vax1_az"))
  term_index1 <- str_detect(names(coef(plrmod1)), fixed(timestr)) | str_detect(names(coef(plrmod1)), fixed("vax1_az"))
  term_index2 <- str_detect(names(coef(plrmod2)), fixed(timestr)) | str_detect(names(coef(plrmod2)), fixed("vax1_az"))
  term_index3 <- str_detect(names(coef(plrmod3)), fixed(timestr)) | str_detect(names(coef(plrmod3)), fixed("vax1_az"))

  ### combine time-dependent HR results ----

  effectsplr <-
    bind_rows(
      get_HR(data_plr, plrmod0, vcov0, term_index=term_index0) %>% mutate(model=0),
      get_HR(data_plr, plrmod1, vcov1, term_index=term_index1) %>% mutate(model=1),
      get_HR(data_plr, plrmod2, vcov2, term_index=term_index2) %>% mutate(model=2),
      get_HR(data_plr, plrmod3, vcov3, term_index=term_index3) %>% mutate(model=3),
    ) %>%
    select(model, everything()) %>%
    group_by(model) %>%
    mutate(
      lag_tstop=lag(tstop, 1, 0),
      hr=exp(loghr),
      hr.ll=exp(loghr.ll),
      hr.ul=exp(loghr.ul),
    ) %>%
    ungroup() %>%
    left_join(
      tidy_plr %>% group_by(model_name, model) %>% summarise() %>% ungroup(), by="model"
    )

  write_rds(effectsplr, path=here("output", "models", outcome, timescale, censor_seconddose, glue("reportplr_effects_{modeltype}.rds")))


  ### print estimates at midpoints of cuts
  cuts <-
    tibble(
    left = postvaxcuts[-length(postvaxcuts)],
    right = postvaxcuts[-1],
    midpoint = left + ((right - left ) / 2),
    midpoint_rounded = as.integer(midpoint),
  )

  effectsplr_pw <- effectsplr %>%
    filter(tstop %in% cuts$midpoint_rounded) %>%
    left_join(cuts, by=c("tstop"="midpoint_rounded"))


  write_rds(effectsplr_pw, path = here("output", "models", outcome, timescale, censor_seconddose, glue("reportplr_effects_{modeltype}_midpoint.rds")))
  write_csv(effectsplr_pw, path = here("output", "models", outcome, timescale, censor_seconddose, glue("reportplr_effects_{modeltype}_midpoint.csv")))

  plotplr_pw <-
    ggplot(data = effectsplr_pw) +
    geom_point(aes(y=exp(loghr), x=midpoint, colour=model_name), position = position_dodge(width = 1.8))+
    geom_linerange(aes(ymin=exp(loghr.ll), ymax=exp(loghr.ul), x=midpoint, colour=model_name), position = position_dodge(width = 1.8))+
    geom_hline(aes(yintercept=1), colour='grey')+
    scale_y_log10(
      breaks=c(0.25, 0.33, 0.5, 0.67, 0.80, 1, 1.25, 1.5, 2, 3, 4),
      sec.axis = dup_axis(name="<--  favours Pfizer  /  favours AZ  -->", breaks = NULL)
    )+
    scale_x_continuous(breaks=unique(effectsplr_pw$left), limits=c(min(effectsplr_pw$left), max(effectsplr_pw$right)+1), expand = c(0, 0))+
    scale_colour_brewer(type="qual", palette="Set1", guide=guide_legend(ncol=1))+
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


  write_rds(plotplr_pw, path=here("output", "models", outcome, timescale, censor_seconddose, glue("reportplr_effectsplot_{modeltype}_midpoint.rds")))
  ggsave(filename=here("output", "models", outcome, timescale, censor_seconddose, glue("reportplr_effectsplot_{modeltype}_midpoint.svg")), plotplr_pw, width=20, height=15, units="cm")
  ggsave(filename=here("output", "models", outcome, timescale, censor_seconddose, glue("reportplr_effectsplot_{modeltype}_midpoint.png")), plotplr_pw, width=20, height=15, units="cm")


  ### plot HR ----

  plotplr <-
    ggplot(effectsplr)+
    geom_hline(aes(yintercept=1), colour='grey')+
    geom_step(aes(x=lag_tstop, y=hr, colour=model_name))+
    geom_rect(aes(xmin=lag_tstop, xmax=tstop, ymin=hr.ll, ymax=hr.ul, fill=model_name), alpha=0.1, colour="transparent")+
    scale_x_continuous(
      breaks = seq(0,7*52,by=14),
      expand = expansion(0)
    )+
    scale_y_log10(
      breaks=c(0.25, 0.33, 0.5, 0.67, 0.80, 1, 1.25, 1.5, 2, 3, 4),
      sec.axis = dup_axis(name="<--  favours Pfizer  /  favours AZ  -->", breaks = NULL)
    )+
    scale_colour_brewer(type="qual", palette="Set1", guide=guide_legend(ncol=1))+
    scale_fill_brewer(type="qual", palette="Set1", guide="none")+
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


  write_rds(plotplr, path=here("output", "models", outcome, timescale, censor_seconddose, glue("reportplr_effectsplot_{modeltype}.rds")))
  ggsave(filename=here("output", "models", outcome, timescale, censor_seconddose, glue("reportplr_effectsplot_{modeltype}.svg")), plotplr, width=20, height=15, units="cm")
  ggsave(filename=here("output", "models", outcome, timescale, censor_seconddose, glue("reportplr_effectsplot_{modeltype}.png")), plotplr, width=20, height=15, units="cm")


  ### marginalised cumulative incidence ----


  ## function for maginalisation ----
  ccf <-  function(data, vax1_az){

    # g-formula to get marginalised/adjusted incidence / survival curves

    vaxtype <- vax1_az

    ccf <- data_plr %>%
      mutate(vax1_az=vaxtype) %>%
      select(
        patient_id,
        tstop,
        tstop_calendar,
        vax1_az,
        sample_weights,
        all_of(all.vars(formula(plrmod3)))
      ) %>%
      mutate(
        prob0 = predict(plrmod0, newdata=., type="response"),
        prob1 = predict(plrmod1, newdata=., type="response"),
        prob2 = predict(plrmod2, newdata=., type="response"),
        prob3 = predict(plrmod3, newdata=., type="response")
      ) %>%
      arrange(tstop)

    curves <- ccf %>%
      #marginalise over all patients
      group_by(tstop) %>%
      summarise(
        prob0 = weighted.mean(prob0, sample_weights),
        prob1 = weighted.mean(prob1, sample_weights),
        prob2 = weighted.mean(prob2, sample_weights),
        prob3 = weighted.mean(prob3, sample_weights),
      ) %>%
      ungroup() %>%
      mutate(
        mean.survival0 = cumprod(1-prob0),
        mean.survival1 = cumprod(1-prob1),
        mean.survival2 = cumprod(1-prob2),
        mean.survival3 = cumprod(1-prob3),
        mean.survivalse0 = sqrt(cmlinc_variance(plrmod0, vcov0, ccf, ccf$patient_id, ccf$tstop, ccf$sample_weights)),
        mean.survivalse1 = sqrt(cmlinc_variance(plrmod1, vcov1, ccf, ccf$patient_id, ccf$tstop, ccf$sample_weights)),
        mean.survivalse2 = sqrt(cmlinc_variance(plrmod2, vcov2, ccf, ccf$patient_id, ccf$tstop, ccf$sample_weights)),
        mean.survivalse3 = sqrt(cmlinc_variance(plrmod3, vcov3, ccf, ccf$patient_id, ccf$tstop, ccf$sample_weights))
      ) %>%
      select(-starts_with("prob")) %>%
      pivot_longer(
        cols=c(starts_with("mean.")),
        names_to=c(".value", "model"),
        names_pattern="mean.(\\w+)(\\d+$)"
      ) %>%
      arrange(model, tstop) %>%
      group_by(model) %>%
      mutate(
        survival.ll = pmax(0, survival+qnorm(0.025)*survivalse) - pmax(0, survival+qnorm(0.975)*survivalse - 1),
        survival.ul = pmin(1, survival+qnorm(0.975)*survivalse) + pmin(0, survival+qnorm(0.025)*survivalse),
        haz = (lag(survival,n=1,default=1)-survival)/survival
      ) %>%
      ungroup() %>%
      add_row(
        model = c("0", "1", "2", "3"),
        tstop = 0,
        survivalse = 0,
        survival = 1,
        survival.ll = 1,
        survival.ul = 1,
        haz = 0
      ) %>%
      arrange(model, tstop) %>%
      group_by(model) %>%
      mutate(
        lead_tstop=lead(tstop),
        vax1_az = vaxtype
      ) %>%
      ungroup() %>%
      arrange(model, tstop)

    curves

  }


  survival_pfizer <- ccf(data_plr, vax1_az=0)
  survival_az <- ccf(data_plr, vax1_az=1)


  cmlinc_curves <-
    bind_rows(survival_pfizer, survival_az) %>%
    arrange(vax1_az, outcome, model, tstop) %>%
    mutate(
      model = as.integer(model),
      vax1_az_descr = if_else(vax1_az==1, "ChAdOx1", "BNT162b2"),
    ) %>%
    left_join(
      tidy_plr %>% group_by(model_name, model) %>% summarise() %>% ungroup(), by="model"
    )

  diff_curves <-
    cmlinc_curves %>%
    group_by(model, tstop) %>%
    mutate(
      diff = (1-survival) - first((1-survival)),
    ) %>%
    filter(vax1_az==1) %>%
    ungroup() %>%
    mutate(
      diff.se = sqrt(c(
        c(0, riskdiff_variance(plrmod0, vcov0, mutate(data_plr, vax1_az=0L), mutate(data_plr, vax1_az=1L), data_plr$patient_id, data_plr$tstop, data_plr$sample_weights)),
        c(0, riskdiff_variance(plrmod1, vcov1, mutate(data_plr, vax1_az=0L), mutate(data_plr, vax1_az=1L), data_plr$patient_id, data_plr$tstop, data_plr$sample_weights)),
        c(0, riskdiff_variance(plrmod2, vcov2, mutate(data_plr, vax1_az=0L), mutate(data_plr, vax1_az=1L), data_plr$patient_id, data_plr$tstop, data_plr$sample_weights)),
        c(0, riskdiff_variance(plrmod3, vcov3, mutate(data_plr, vax1_az=0L), mutate(data_plr, vax1_az=1L), data_plr$patient_id, data_plr$tstop, data_plr$sample_weights)),
        NULL
      ))
    ) %>%
    mutate(
      diff.ll = diff+qnorm(0.025)*diff.se,
      diff.ul = diff+qnorm(0.975)*diff.se,
    )

  if(removeobs) rm(plrmod0, plrmod1, plrmod2, plrmod3)


  cmlinc_plot <- ggplot(cmlinc_curves %>% filter(model=="3"))+
    geom_step(aes(x=tstop, y=survival, group=vax1_az_descr, colour=vax1_az_descr))+
    geom_rect(aes(xmin=tstop, xmax=lead_tstop, ymin=survival.ll, ymax=survival.ul, group=vax1_az_descr, fill=vax1_az_descr), alpha=0.1)+
    scale_x_continuous(
      breaks = seq(0,7*52,by=14),
      expand = expansion(0)
    )+
    scale_y_continuous(
      expand = expansion(0)
    )+
    scale_colour_brewer(type="qual", palette="Set1")+
    scale_fill_brewer(type="qual", palette="Set1", guide="none")+
    labs(
      x="Days since first dose",
      y="Adjusted survival",
      colour=NULL,
      fill=NULL
    )+
    theme_bw()+
    theme(
      legend.position=c(.05,.05),
      legend.justification = c(0,0),
      axis.text.x.top=element_text(hjust=0)
    )

  write_rds(cmlinc_curves, here("output", "models", outcome, timescale, censor_seconddose, glue("reportplr_adjustedsurvival_{modeltype}.rds")), compress="gz")

  ggsave(filename=here("output", "models", outcome, timescale, censor_seconddose, glue("reportplr_adjustedsurvival_{modeltype}.svg")), cmlinc_plot, width=20, height=15, units="cm")
  ggsave(filename=here("output", "models", outcome, timescale, censor_seconddose, glue("reportplr_adjustedsurvival_{modeltype}.png")), cmlinc_plot, width=20, height=15, units="cm")


  diff_plot <- ggplot(diff_curves %>% filter(model=="3"))+
    geom_step(aes(x=tstop, y=diff))+
    geom_rect(aes(xmin=tstop, xmax=lead_tstop, ymin=diff.ll, ymax=diff.ul), alpha=0.1)+
    scale_x_continuous(
      breaks = seq(0,7*52,by=14),
      expand = expansion(0)
    )+
    scale_y_continuous(
      expand = expansion(0)
    )+
    scale_colour_brewer(type="qual", palette="Set1")+
    scale_fill_brewer(type="qual", palette="Set1", guide="none")+
    labs(
      x="Days since first dose",
      y="Risk difference",
      colour=NULL,
      fill=NULL
    )+
    theme_bw()+
    theme(
      legend.position=c(.05,.05),
      legend.justification = c(0,0),
      axis.text.x.top=element_text(hjust=0)
    )

  write_rds(diff_curves, here("output", "models", outcome, timescale, censor_seconddose, glue("reportplr_adjusteddiff_{modeltype}.rds")), compress="gz")

  ggsave(filename=here("output", "models", outcome, timescale, censor_seconddose, glue("reportplr_adjusteddiff_{modeltype}.svg")), diff_plot, width=20, height=15, units="cm")
  ggsave(filename=here("output", "models", outcome, timescale, censor_seconddose, glue("reportplr_adjusteddiff_{modeltype}.png")), diff_plot, width=20, height=15, units="cm")


}

report_estimates("ns", "ns(tstop,")
report_estimates("pw", "timesincevax")
