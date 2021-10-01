
# # # # # # # # # # # # # # # # # # # # #
# This script creates a table 1 of baseline characteristics by vaccine type
# # # # # # # # # # # # # # # # # # # # #

# Preliminaries ----

## Import libraries ----
library('tidyverse')
library('here')
library('glue')
library('gt')
library('gtsummary')

## Import custom user functions from lib

source(here("analysis", "lib", "utility_functions.R"))
source(here("analysis", "lib", "redaction_functions.R"))

## create output directories ----
fs::dir_create(here("output", "descriptive", "tables"))


## import metadata ----
var_labels <- read_rds(here("output", "data", "metadata_labels.rds"))

list_formula <- read_rds(here("output", "data", "metadata_formulas.rds"))
list2env(list_formula, globalenv())
lastfupday <- lastfupday20

## Import processed data ----
data_cohort <- read_rds(here("output", "data", "data_cohort.rds")) %>%
  mutate(
    censor_date12 = pmin(vax1_date - 1 + lastfupday12, end_date, dereg_date, death_date, na.rm=TRUE),
    censor_date20 = pmin(vax1_date - 1 + lastfupday20, end_date, dereg_date, death_date, na.rm=TRUE),
    tte_censor12 = tte(vax1_date-1, censor_date12, censor_date12, na.censor=TRUE),
    tte_censor20 = tte(vax1_date-1, censor_date20, censor_date20, na.censor=TRUE),
    fu_days12 = tte_censor12,
    fu_days20 = tte_censor20,
    N=1,
  )

var_labels <-splice(N = N  ~ "Total N", var_labels)


## baseline variables
tab_summary_baseline <- data_cohort %>%
  select(
    all_of(names(var_labels)),
    -age, -stp, -vax1_type, -fu_days12, -fu_days20
  ) %>%
  tbl_summary(
    by = vax1_type_descr,
    label=unname(var_labels[names(.)]),
    statistic = list(N = "{N}")
  )  %>%
  modify_footnote(starts_with("stat_") ~ NA) %>%
  modify_header(stat_by = "**{level}**") %>%
  bold_labels()



tab_summary_baseline_redacted <- redact_tblsummary(tab_summary_baseline, 5, "[REDACTED]")
#gt_summary_baseline_redacted <- as_gt(tab_summary_baseline_redacted)
#flex_summary_baseline_redacted <- as_flex_table(tab_summary_baseline_redacted)

raw_stats <- tab_summary_baseline_redacted$meta_data %>%
  select(var_label, df_stats) %>%
  unnest(df_stats)

write_csv(tab_summary_baseline_redacted$table_body, here("output", "descriptive", "tables", "table1.csv"))
write_csv(tab_summary_baseline_redacted$df_by, here("output", "descriptive", "tables", "table1_by.csv"))
gtsave(as_gt(tab_summary_baseline_redacted), here("output", "descriptive", "tables", "table1.html"))


tab_summary_region <- data_cohort %>%
  select(
    region, stp, vax1_type_descr
  ) %>%
  tbl_summary(
    by = vax1_type_descr,
    label=unname(var_labels[names(.)])
  )  %>%
  modify_footnote(starts_with("stat_") ~ NA) %>%
  modify_header(stat_by = "**{level}**") %>%
  bold_labels()


tab_summary_region_redacted <- redact_tblsummary(tab_summary_region, 5, "[REDACTED]")

write_csv(tab_summary_region_redacted$table_body, here("output", "descriptive", "tables", "table1_regions.csv"))
write_csv(tab_summary_region_redacted$df_by, here("output", "descriptive", "tables", "table1_regions_by.csv"))
gtsave(as_gt(tab_summary_region_redacted), here("output", "descriptive", "tables", "table1_regions.html"))






if(FALSE){


  table1 <-
    table1_body %>%
    group_by(variable) %>%
    mutate(
      label = if_else(row_number()==1, label, str_c("   ", label)),
    ) %>%
    mutate(
      across(
        starts_with("stat_"),
        ~if_else(is.na(.x) & row_number()==1, "", .x)
      )
    ) %>%
    ungroup() %>%
    mutate(
      order = cumsum(lag(variable, 1, first(variable))!=variable)
    ) %>%
    select(
      variable, var_label, label, starts_with("stat_"), order
    ) %>%
    rename(!!!set_names(table1_by$by_col, table1_by$by_chr))


  table1 %>%
    gt() %>%
    fmt_html(columns = "label") %>%
    tab_style(
      style = list(
        cell_fill(color = "gray96")
      ),
      locations = cells_body(
        rows = order%%2 == 0
      )
    ) %>%
    tab_style(
      style = list(
        cell_text(weight = "bold")
      ),
      locations = cells_column_labels(everything())
    ) %>%
    cols_label(
      label=md("Characteristic")
    ) %>%
    cols_hide(c("variable", "var_label", "order"))
}
