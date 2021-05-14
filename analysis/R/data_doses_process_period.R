


## flexsurvspline won't work properly without matched controls, since the timescale is calendar time with vaccination as a time-yvarying covariate,
## rather than the timescale being time-post vaccination
# flexmod <- flexsurvspline(
#   Surv(tstart, tstop, postest) ~ vax + age + sex + cluster(patient_id),
#   data=data_survready,
#   k = 2,
#   scale = "hazard",
#   timescale = "identity"
# )


data_survreadyperiod <- survSplit(
  Surv(tstart, tstop, postest) ~ .,
  data=data_survready,
  cut=seq(14,800,14),
  start="tstart",
  episode = "period"
)




data_survreadyperiodvax <- survSplit(
  Surv(tstart, tstop, vax) ~ .,
  data=data_survready,
  cut=c(10, 21, Inf),
  start="tstart",
  episode = "period"
)


## ALTERNATIVE USING TMERGE ---
## NEED TO CONVERT TO LONG FORM, SORT BY DATE, THEN CONVERT BACK TO WIDE TO RE-SORT NONSENSE DUMMY DATA

data_tte <- data_vaccinated %>%
  transmute(
    patient_id,
    start_date,
    end_date,
    censor_date,
    # postvac_positive_test_date_SGSS_censored = censor(postvac_positive_test_date_SGSS, censor_date, na.censor=FALSE),
    # postvac_primary_care_covid_case_censored = censor(postvac_primary_care_covid_case, censor_date, na.censor=FALSE),
    # postvac_admitted_date_censored = censor(postvac_admitted_date, censor_date, na.censor=FALSE),
    # coviddeath_date_censored = censor(coviddeath_date, censor_date, na.censor=FALSE),
    # death_date_censored = censor(death_date, censor_date, na.censor=FALSE),

    st_censor = tte(start_date, censor_date, censor_date),

    st_vacc1 = tte(start_date, covid_vacc_1_date, censor_date, na.censor=TRUE),
    st_vacc2 = tte(start_date, covid_vacc_2_date, censor_date, na.censor=TRUE),
    st_vacc3 = tte(start_date, covid_vacc_3_date, censor_date, na.censor=TRUE),
    st_vacc4 = tte(start_date, covid_vacc_4_date, censor_date, na.censor=TRUE),

    st_pos1 = tte(start_date, post_vaccine_positive_test_date, censor_date, na.censor=TRUE),
    death = tte(start_date, death_date, censor_date, na.censor=TRUE),

  )



data_tte_long <- data_tte %>%
  pivot_longer(
    cols=starts_with("st_vacc"),
    values_to = "vacc_date",
  ) %>%
  arrange(patient_id, vacc_date) %>%
  select(-name) %>%
  group_by(patient_id) %>%
  mutate(index = row_number())


data_tte_wide <- data_tte_long %>%
  pivot_wider(
    id_cols=-vacc_date,
    names_from=index,
    names_prefix = "st_vacc",
    values_from = vacc_date
  )


data_survreadymerge <- tmerge(
  data1=data_baseline,
  data2=data_tte_wide,
  id=patient_id,
  vacc = tdc(st_vacc1),
  vacc = tdc(st_vacc2),
  vacc = tdc(st_vacc3),
  vacc = tdc(st_vacc4),
  postest = event(st_pos1),
  death = event(death),
  tstop = st_censor
)







# output processed data to rds ----

dir.create(here::here("output", "data"), showWarnings = FALSE, recursive=TRUE)

write_rds(data_vaccinated, here::here("output", "data", "data_vaccinated.rds"))




## get long dates ----

data_admissions <- data_vaccinated %>%
  select(patient_id, matches("admitted\\_\\d+\\_date"), matches("discharged\\_\\d+\\_date")) %>%
  pivot_longer(
    cols = -patient_id,
    names_to = c(".value", NA),
    names_pattern = "^(.*)_(.*)_date",
    values_drop_na = TRUE
  )

data_vax <- data_vaccinated %>%
  select(patient_id, matches("covid\\_vacc\\_\\d+\\_date")) %>%
  pivot_longer(
    cols = -patient_id,
    names_to = c("event", NA),
    names_pattern = "^(.*)_(.*)_date",
    values_to = "date",
    values_drop_na = TRUE
  ) %>%
  arrange(patient_id, date) #%>%
# group_by(patient_id) %>%
# mutate(
#   vax_number = row_number(),
#   postvax_date = map2(
#     date,
#     lead(date),
#     ~{
#       x <- .x + postvax_period
#       if(!is.na(.y))  x <- x[x < .y]
#       x
#     }
#   ),
#   postvax_days = map(
#     postvax_date,
#     ~{postvax_period[seq_along(.x)]}
#   ),
#   vax_period_index  = map(postvax_date, seq_along),
# ) %>%
# unnest(c(date, postvax_date, postvax_days, vax_period_index) )


data_vax_pf <- data_vaccinated %>%
  select(patient_id, matches("covid\\_vacc\\_pfizer\\_\\d+\\_date")) %>%
  pivot_longer(
    cols = -patient_id,
    names_to = c("event", NA),
    names_pattern = "^(.*)_(.*)_date",
    values_to = "date",
    values_drop_na = TRUE
  ) %>%
  arrange(patient_id, date)


data_vax_ox <- data_vaccinated %>%
  select(patient_id, matches("covid\\_vacc\\_oxford\\_\\d+\\_date")) %>%
  pivot_longer(
    cols = -patient_id,
    names_to = c("event", NA),
    names_pattern = "^(.*)_(.*)_date",
    values_to = "date",
    values_drop_na = TRUE
  ) %>%
  arrange(patient_id, date)





data_events_long <- local({

  # event type "0" is time-dependent covariates
  # event type "1" is outcomes

  temp_vax <- data_vax %>%
    distinct(patient_id, .keep_all=TRUE) %>%
    mutate(
      event="vax",
      event_type = "0",
    )

  temp_vax_tdc <- bind_rows(
    temp_vax %>% mutate(date=date, postvaxperiod="(0, 10]"),
    temp_vax %>% mutate(date=date+10, postvaxperiod="(10, 21]"),
    temp_vax %>% mutate(date=date+21, postvaxperiod="(21, Inf)")
  ) %>%
    arrange(patient_id, date)

  temp_postest <- data_vaccinated %>%
    filter(!is.na(post_vaccine_positive_test_date)) %>%
    transmute(
      patient_id,
      date = post_vaccine_positive_test_date,
      event = "postest",
      event_type = "1"
    )

  temp_death <- data_vaccinated %>%
    filter(!is.na(death_date)) %>%
    transmute(
      patient_id,
      date = death_date,
      event = "death",
      event_type = "1"
    )

  temp_censor = data_vaccinated %>%
    transmute(
      patient_id,
      date = censor_date,
      event = "censor",
      event_type = "1"
    )

  bind_rows(
    temp_vax_tdc, temp_postest, temp_death, temp_censor
  ) %>%
    arrange(patient_id, date, desc(event_type)) #arrange by patient id, then date, then event type ensuring "outcomes" go first

})


data_survready0 <- data_events_long %>%
  group_by(patient_id) %>%
  transmute(
    patient_id,
    time = as.numeric(tte(as.Date(vars_list$start_date), date, as.Date(vars_list$end_date))),
    tstart = lag(time, 1, 0),
    tstop = time,
    vax = cumsum(lag(event=="vax",1,FALSE))*1,
    postest = cumsum(event=="postest")*1,
    death = (event=="death")*1,
    same = tstart>=tstop
  ) %>%
  filter(tstop != lag(tstop,1,0)) %>% #if censor date and death date is the same, remove censor_date
  filter(cumsum(postest) <= 1) #remove any observations after first positive test #CHANGE THIS FOR DIFFERENT OUTCOMES




