


library('tidyverse')
library('here')
library('readxl')
library('jsonlite')


diagnosis_codes <- read_xlsx(here("analysis", "lib", "diagnosis_groups.xlsx"))


diagnosis_groups <-
  diagnosis_codes %>%
  rename(group = ECDS_GroupCustomShort) %>%
  mutate(
    group = if_else(is.na(group), "na", group)
  ) %>%
  group_by(ECDS_GroupCustom, group) %>%
  summarise(
    codelist = list(SNOMED_Code)
  ) %>%
  ungroup()

diagnosis_groups %>%
  select(group, codelist) %>%
  {set_names(.$codelist, .$group)} %>% # convert tibble to list in a slightly awkward way
  write_json(
    path = here("analysis", "lib", "diagnosis_groups.json"),
#    flatten = TRUE
  )

