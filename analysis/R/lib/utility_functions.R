

specify_decimal <- function(x, k, trim=FALSE) {

  fmtd <- format(round(x, k), nsmall = k)
  if (trim) {fmtd <- trimws(fmtd)}
  return(fmtd)
}

print_est1bracket <- function(x, b, round=1){
  paste0(specify_decimal(x, round), " (", specify_decimal(b, round), ")")
}

print_est2bracket <- function(x, b1, b2, round=1){
  paste0(specify_decimal(x, round), " (", specify_decimal(b1, round), ", ", specify_decimal(b2, round), ")")
}

print_2bracket <- function(b1, b2, round=1){
  paste0("(", specify_decimal(b1, round), ", ", specify_decimal(b2, round), ")")
}

print_pval <- function(pval, k=3){
  ifelse(pval < 1/(10^k), paste0("p<", 1/(10^k)), paste0("p=", specify_decimal(pval, k = 3)))
}


fct_case_when <- function(...) {
  # uses dplyr::case_when but converts the output to a factor,
  # with factors ordered as they appear in the case_when's  ... argument
  args <- as.list(match.call())
  levels <- sapply(args[-1], function(f) f[[3]])  # extract RHS of formula
  levels <- levels[!is.na(levels)]
  factor(dplyr::case_when(...), levels=levels)
}



censor <- function(event_date, censor_date, na.censor=TRUE){
  # censors event_date to on or before censor_date
  # if na.censor = TRUE then returns NA if event_date>censor_date, otherwise returns min(event_date, censor_date)
  if (na.censor)
    dplyr::if_else(event_date>censor_date, as.Date(NA_character_), as.Date(event_date))
  else
    dplyr::if_else(event_date>censor_date, as.Date(censor_date), as.Date(event_date))
}

censor_indicator <- function(event_date, censor_date){
  # returns 0 if event_date is censored by censor_date, or if event_date is NA. Otherwise 1
  dplyr::if_else((event_date>censor_date) | is.na(event_date), FALSE, TRUE)
}

tte <- function(origin_date, event_date, censor_date, na.censor=FALSE){
  # returns time-to-event date or time to censor date, which is earlier

  if (na.censor)
    time <- event_date-origin_date
  else
    time <- pmin(event_date-origin_date, censor_date-origin_date, na.rm=TRUE)
    as.numeric(time)
}



round_tte <- function(time, width=7){
  # group follow-up time to be in periods of size `width`
  # eg, convert to weekly instead of dail with width=7
  # follow-up time of zero is always mapped to zero
  # then first period is mapped to `1`, second period is mapped to `2`, etc
  ceiling(time/width)
}





postvax_cut <- function(event_time, time, breaks, prelabel="pre", prefix=""){

  # this function defines post-vaccination time-periods at `time`,
  # for a vaccination occurring at time `event_time`
  # delimited by `breaks`

  # note, intervals are open on the left and closed on the right
  # so at the exact time point the vaccination occurred, it will be classed as "pre-dose".

  event_time <- as.numeric(event_time)
  event_time <- if_else(!is.na(event_time), event_time, Inf)

  diff <- time - event_time
  breaks_aug <- unique(c(-Inf, breaks, Inf))
  labels0 <- cut(c(breaks, Inf), breaks_aug)
  labels <- paste0(prefix, c(prelabel, as.character(labels0[-1])))
  period <- cut(diff, breaks=breaks_aug, labels=labels, include.lowest=TRUE)


  period
}





# define post-vaccination time periods for piece-wise constant hazards (ie time-varying effects / time-varying coefficients)
# eg c(0, 10, 21) will create 4 periods
# pre-vaccination, [0, 10), [10, 21), and [21, inf)
# can use eg c(3, 10, 21) to treat first 3 days post-vaccination the same as pre-vaccination
# note that the exact vaccination date is set to the first "pre-vax" period,
# because in survival analysis, intervals are open-left and closed-right.


timesince_cut <- function(time_since, breaks, prelabel="pre", prefix=""){

  # this function defines post-vaccination time-periods at `time_since`,
  # delimited by `breaks`

  # note, intervals are open on the left and closed on the right
  # so at the exact time point the vaccination occurred, it will be classed as "pre-dose".

  time_since <- as.numeric(time_since)
  time_since <- if_else(!is.na(time_since), time_since, Inf)

  breaks_aug <- unique(c(-Inf, breaks, Inf))

  lab_left <- breaks+1
  lab_right <- lead(breaks)
  label <- paste0(lab_left, "-", lab_right)
  label <- str_replace(label,"-NA", "+")
  labels <- paste0(prefix, c(prelabel, label))

  #labels0 <- cut(c(breaks, Inf), breaks_aug)
  #labels <- paste0(prefix, c(prelabel, as.character(labels0[-1])))
  period <- cut(time_since, breaks=breaks_aug, labels=labels, include.lowest=TRUE)

  period
}


timesince2_cut <- function(time_since1, time_since2, breaks, prelabel="pre-vax"){
  #wrapper for timesince_cut than puts postvax1 and postvax2 together

  stopifnot("time_since1 should be greater than time_since2" = time_since1>=time_since2)

  vax1_status <- timesince_cut(time_since1, breaks=breaks, prelabel=" SHOULD NOT APPEAR 1", prefix="Dose 1 ")
  vax2_status <- timesince_cut(time_since2, breaks=breaks, prelabel=" SHOULD NOT APPEAR 2", prefix="Dose 2 ")

  levels <- c(prelabel, levels(vax1_status[time_since1>0]), levels(vax2_status[time_since2>0]))

  fct <- case_when(
    time_since1 == 0 ~ as.character(prelabel),
    time_since1 > 0 & time_since2 == 0 ~ as.character(vax1_status),
    time_since2 > 0 ~ as.character(vax2_status)
  )

  fct <- factor(fct, levels=levels) %>% droplevels()

  fct

}




tidy_parglm <- function(x, conf.int = FALSE, conf.level = .95,
                        exponentiate = FALSE, ...) {

  # nicked from https://github.com/tidymodels/broom/blob/443ebd995760c6674f122d75ceb2e6b82f055439/R/stats-glm-tidiers.R#L12
  # and adapted for parglm glm objects

  ret <- as_tibble(summary(x)$coefficients, rownames = "term")
  colnames(ret) <- c("term", "estimate", "std.error", "statistic", "p.value")

  # summary(x)$coefficients misses rank deficient rows (i.e. coefs that summary.lm() sets to NA)
  # catch them here and add them back

  coefs <- tibble::enframe(stats::coef(x), name = "term", value = "estimate")
  ret <- left_join(coefs, ret, by = c("term", "estimate"))

  if (conf.int) {
    ci <- confint.default(x, level = conf.level) # not ideal -- change for more robust conf intervals! - see tidy_plr below
    ci <- as_tibble(ci, rownames = "term")
    names(ci) <- c("term", "conf.low", "conf.high")

    ret <- dplyr::left_join(ret, ci, by = "term")
  }

  if (exponentiate) {
    ret <- exponentiate(ret)
  }

  ret
}



tidy_plr <- function(model, conf.int=TRUE, conf.level=0.95, exponentiate=FALSE, cluster){
  # create tidy dataframe for coefficients of pooled logistic regression
  mod_tidy <- tidy_parglm(model, conf.int=conf.int, conf.level=conf.level, exponentiate=exponentiate)
  robustSEs <- coeftest(model, vcov. = vcovCL(model, cluster = cluster, type = "HC0")) %>% broom::tidy()
  robustCIs <- coefci(model, vcov. = vcovCL(model, cluster = cluster, type = "HC0")) %>% as_tibble(rownames="term")
  robust <- inner_join(robustSEs, robustCIs, by="term")

  robust %>%
    rename(
      conf.low=`2.5 %`,
      conf.high=`97.5 %`
    ) %>%
    mutate(
      or = exp(estimate),
      or.ll = exp(conf.low),
      or.ul = exp(conf.high),
    )

}



tidy_custom.glm  <- function(model, conf.int=TRUE, conf.level=0.95, exponentiate=FALSE, cluster){
  # create tidy dataframe for coefficients of pooled logistic regression
  #mod_tidy <- tidy_parglm(model, conf.int=conf.int, conf.level=conf.level, exponentiate=exponentiate)
  robustSEs <- coeftest(model, vcov. = vcovCL(model, cluster = cluster, type = "HC0")) %>% broom::tidy()
  robustCIs <- coefci(model, vcov. = vcovCL(model, cluster = cluster, type = "HC0")) %>% as_tibble(rownames="term")
  robust <- inner_join(robustSEs, robustCIs, by="term")

  output <- robust %>%
    rename(
      conf.low=`2.5 %`,
      conf.high=`97.5 %`
    )

  if(exponentiate){
    output <- output %>%
      mutate(
        estimate = exp(estimate),
        conf.low = exp(conf.low),
        conf.high = exp(conf.high),
      )
  }

  output
}
