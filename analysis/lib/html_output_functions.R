
## gt output of tables ----

### categorical ----

gt_cat <- function(
  summary_cat,
  var_name="",
  pct_deminals = 1
){

  summary_cat %>%
    select(-c(redacted)) %>%
    gt() %>%
    fmt_percent(
      columns = ends_with(c("pct", "pct_nonmiss")),
      decimals = pct_deminals
    ) %>%
    fmt_missing(
      everything(),
      missing_text="--"
    ) %>%
    tab_spanner(
      label = "non-missing",
      columns = vars("n_nonmiss", "pct_nonmiss")
    ) %>%
    cols_label(
      .level=var_name,
      n = "N",
      n_nonmiss = "N",
      pct = "%",
      pct_nonmiss = "%",
    ) %>%
    cols_align(
      align = "left",
      columns = vars(.level)
    )
}


### categorical*ctegorical ----

gt_catcat <- function(
  summary_catcat,
  var1_name="",
  var2_name="",
  title = NULL,
  source_note = NULL,
  pct_decimals = 1
){

  summary_wide <- summary_catcat %>%
    arrange(.level2) %>%
    pivot_wider(
      id_cols=c(.level1),
      values_from=c(n, pct),
      names_from=.level2,
      names_glue="{.level2}__{.value}"
    )

  col_selector <- levels(summary_catcat$.level2)

  old_names <- summary_wide %>% select(-.level1) %>% names()

  col_renamer <- old_names %>%
    set_names(
      . %>%
        #str_replace("__n", str_c("__","N")) %>%
        str_replace("__pct", str_c("__","%"))
    )

  gt_table <- summary_wide %>%
    rename(!!!col_renamer) %>%
    select(.level1, starts_with(paste0(col_selector, "__"))) %>%
    # select step needed because https://github.com/tidyverse/tidyr/issues/839#issuecomment-622073209 -- need
    # use until `gather` option for tab_spanner_delim works
    gt() %>%
    tab_spanner_delim(delim="__", gather=TRUE) %>%
    # gather doesn't work!
    fmt_percent(
      columns = ends_with(c("%")),
      decimals = pct_decimals
    ) %>%
    fmt_missing(everything(),
                missing_text="-"
    ) %>%
    cols_label(
      .level1=var1_name
    ) %>%
    cols_align(
      align = "left",
      columns = vars(.level1)
    )

    if(!is.null(title)){
      gt_table <- tab_header(gt_table, title = title)
    }

    if(!is.null(source_note)){
      gt_table <- tab_source_note(gt_table, source_note = source_note)
    }

  gt_table
  ## TODO, add labels, change column headers, redaction label
}



### numeric ----

gt_num <- function(
  summary_num,
  variable_name="",
  num_decimals=1,
  pct_decimals=1
){

  summary_num %>%
    select(-c(n_miss, pct_miss, redacted)) %>%
    gt() %>%
    fmt_percent(
      columns = ends_with(c("pct_nonmiss", "pct_miss")),
      decimals = pct_deminals
    ) %>%
    fmt_number(
      columns = vars("mean", "sd", "min", "p10", "p25", "p50", "p75", "p90", "max"),
      decimals = num_decimals
    ) %>%
    fmt_missing(
      everything(),
      missing_text="--"
    ) %>%
    tab_spanner(
      label = "non-missing",
      columns = vars("n_nonmiss", "pct_nonmiss")
    ) %>%
    tab_spanner(
      label = "percentiles",
      columns = vars("min", "p10", "p25", "p50", "p75", "p90", "max")
    ) %>%
    cols_label(
      n = "N",
      n_nonmiss = "N",
      pct_nonmiss = "%",
      mean = "mean",
      sd = "SD",
      min = "min",
      unique = "unique values"
    )
}


### numeric*categorical ----

gt_catnum <- function(
  summary_catnum,
  variable_cat="",
  variable_num="",
  num_decimals=1,
  pct_decimals=1
){

  summary_catnum %>%
    select(-c(n_miss, pct_miss, redacted)) %>%
    gt(groupname_col=variable_num) %>%
    fmt_percent(
      columns = ends_with(c("pct_nonmiss", "pct_miss")),
      decimals = pct_deminals
    ) %>%
    fmt_number(
      columns = vars("mean", "sd", "min", "p10", "p25", "p50", "p75", "p90", "max"),
      decimals = num_decimals
    ) %>%
    fmt_missing(
      everything(),
      missing_text="--"
    ) %>%
    tab_spanner(
      label = "non-missing",
      columns = vars("n_nonmiss", "pct_nonmiss")
    ) %>%
    tab_spanner(
      label = "percentiles",
      columns = vars("min", "p10", "p25", "p50", "p75", "p90", "max")
    ) %>%
    cols_label(
      .variable_cat=variable_cat,
      n = "N",
      n_nonmiss = "N",
      pct_nonmiss = "%",
      mean = "mean",
      sd = "SD",
      min = "min",
      unique = "unique values"
    ) %>%
    cols_align(
      align = "left",
      columns = vars(.variable_cat)
    )
}

