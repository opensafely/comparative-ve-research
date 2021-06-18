library('tidyverse')
library('dagitty')
library('ggdag')





vax_dag <- dagify(
  # age ~ .,
  # sex ~ .,
  # ethnicity ~.,
  # imd ~ .,
  # region ~ .,
  # rural_urban ~ .,
  comorbs ~ age + sex + ethnicity + imd,
  occupation ~ age + sex + ethnicity + imd,
  at_risk ~ comorbs,
  exposure_risk ~ age + sex + region + comorbs + occupation,
  prior_infection ~ age + sex + ethnicity + comorbs + exposure_risk + comorbs,
  vax_type ~ age + sex + region + comorbs + at_risk,
  infection ~ vax_type + age + sex + ethnicity + region + comorbs + at_risk + exposure_risk,

  exposure = "vax_type",
  outcome = "infection"
  )

dagitty::is.dagitty(vax_dag)

ggdag(vax_dag, text_col="black", node=FALSE)+
  theme_void()
