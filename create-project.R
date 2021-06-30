library('tidyverse')
library('yaml')
library('here')
library('glue')

# create action functions ----

## generic action function ----
action <- function(
  name,
  run,
  arguments=NULL,
  needs=NULL,
  highly_sensitive=NULL,
  moderately_sensitive=NULL
){

  outputs <- list(
    highly_sensitive = highly_sensitive,
    moderately_sensitive = moderately_sensitive
  )
  outputs[sapply(outputs, is.null)] <- NULL

  action <- list(
    run = paste0(run, " ", paste(arguments, collapse=" ")),
    needs = needs,
    outputs = outputs
  )
  action[sapply(action, is.null)] <- NULL

  action_list <- list(name = action)
  names(action_list) <- name

  action_list
}


# comment <- function(
#   x = "#"
# ){
#   comment <- list(NULL)
#   names(comment) = paste0("# ", x)
#   comment
# }
#comment("blah")

## model action function ----
action_model <- function(
  outcome, timescale
){
  action(
    name = glue("model_{outcome}_{timescale}"),
    run = glue("r:latest analysis/models/model_cox.R"),
    arguments = c(outcome, timescale),
    needs = list("design", "data_selection"),
    highly_sensitive = list(
      data = glue("output/{outcome}/{timescale}/data_cox_split.rds"),
      models = glue("output/{outcome}/{timescale}/model*.rds")
    ),
    moderately_sensitive = list(
      logs = glue("output/{outcome}/{timescale}/log*.txt"),
      glance = glue("output/{outcome}/{timescale}/glance*.csv")
    )
  )
}

## report action function ----
action_report <- function(
  outcome, timescale
){
  action(
    name = glue("report_{outcome}_{timescale}"),
    run = glue("r:latest analysis/models/report_cox.R"),
    arguments = c(outcome, timescale),
    needs = list("design", glue("model_{outcome}_{timescale}")),
    moderately_sensitive = list(
      svg = glue("output/{outcome}/{timescale}/forest*.svg"),
      png = glue("output/{outcome}/{timescale}/forest*.png"),
      csv = glue("output/{outcome}/{timescale}/estimates*.csv")
    )
  )
}



# specify project ----

## defaults ----
defaults_list <- list(
  version = "3.0",
  expectations= list(population_size=100000L)
)

## actions ----
actions_list <- splice(


  action(
    name = "hcw_extract",
    run = "cohortextractor:latest generate_cohort --study-definition study_definition_hcw --output-format feather",
    highly_sensitive = list(
      cohort = "output/input_hcw.feather"
    )
  ),

  action(
    name = "hcw_process",
    run = "r:latest analysis/hcw/process.R",
    needs = list("hcw_extract"),
    highly_sensitive = list(
      data = "output/data/hcw_data_processed.rds",
      datavax = "output/data/hcw_data_vax.rds"
    )
  ),

  action(
    name = "hcw_properties",
    run = "r:latest analysis/process/data_properties.R",
    arguments = c("output/data/hcw_data_processed.rds", "output/data_properties"),
    needs = list("hcw_process"),
    highly_sensitive = list(
      cohort = "output/data_properties/hcw_data_processed*.txt"
    )
  ),

  action(
    name = "hcw_descr",
    run = "r:latest analysis/hcw/descr.R",
    needs = list("hcw_process"),
    moderately_sensitive = list(
      png = "output/hcw/*.png",
      svg = "output/hcw/*.svg",
      html = "output/hcw/*.html",
      csv = "output/hcw/*.csv"
    )
  ),


  action(
    name = "design",
    run = "r:latest analysis/process/design.R",
    moderately_sensitive = list(
      metadata = "output/data/metadata*"
    )
  ),

  action(
    name = "extract",
    run = "cohortextractor:latest generate_cohort --study-definition study_definition --output-format feather",
    highly_sensitive = list(
      cohort = "output/input.feather"
    )
  ),

  action(
    name = "data_process",
    run = "r:latest analysis/process/data_process.R",
    needs = list("extract"),
    highly_sensitive = list(
      cohort = "output/data/data_processed.rds"
    )
  ),

  action(
    name = "data_properties",
    run = "r:latest analysis/process/data_properties.R",
    arguments = c("output/data/data_processed.rds", "output/data_properties"),
    needs = list("data_process"),
    highly_sensitive = list(
      cohort = "output/data_properties/data_processed*.txt"
    )
  ),

  action(
    name = "data_selection",
    run = "r:latest analysis/process/data_selection.R",
    needs = list("data_process"),
    highly_sensitive = list(
      data_allvax = "output/data/data_cohort_allvax.rds",
      data = "output/data/data_cohort.rds"
    ),
    moderately_sensitive = list(
      flow = "output/data/flowchart.csv"
    )
  ),


  action(
    name = "descr_table1",
    run = "r:latest analysis/descriptive/table1.R",
    needs = list("design", "data_selection"),
    moderately_sensitive = list(
      html = "output/descriptive/tables/table1*.html",
      csv = "output/descriptive/tables/table1*.csv"
    )
  ),

  action(
    name = "descr_table1_allvax",
    run = "r:latest analysis/descriptive/table1_allvax.R",
    needs = list("design", "data_selection"),
    moderately_sensitive = list(
      html = "output/descriptive/tables/table1_allvax.html",
      csv = "output/descriptive/tables/table1_allvax.csv"
    )
  ),

  action(
    name = "descr_irr",
    run = "r:latest analysis/descriptive/table_irr.R",
    arguments = c("output/data/data_processed.rds", "output/data_properties"),
    needs = list("design", "data_selection"),
    moderately_sensitive = list(
      html = "output/descriptive/tables/table_irr.html",
      csv = "output/descriptive/tables/table_irr.csv"
    )
  ),

  action(
    name = "descr_km",
    run = "r:latest analysis/descriptive/km.R",
    arguments = c("output/data/data_processed.rds", "output/data_properties"),
    needs = list("design", "data_selection"),
    moderately_sensitive = list(
      png = "output/descriptive/km/plot_survival*.png",
      svg = "output/descriptive/km/plot_survival*.svg"
    )
  ),


  action_model("test", "timesincevax"),
  action_report("test", "timesincevax"),
  action_model("test", "calendar"),
  action_report("test", "calendar"),

  action_model("postest", "timesincevax"),
  action_report("postest", "timesincevax"),
  action_model("postest", "calendar"),
  action_report("postest", "calendar"),

  action_model("emergency", "timesincevax"),
  action_report("emergency", "timesincevax"),
  action_model("emergency", "calendar"),
  action_report("emergency", "calendar"),

  action_model("covidadmitted", "timesincevax"),
  action_report("covidadmitted", "timesincevax"),
  action_model("covidadmitted", "calendar"),
  action_report("covidadmitted", "calendar")
)


project_list <- splice(
  defaults_list,
  list(actions = actions_list)
)


yaml::write_yaml(project_list, file =here("project.yaml"))
