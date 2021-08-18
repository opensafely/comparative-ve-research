library('tidyverse')
library('yaml')
library('here')
library('glue')

# create action functions ----

## create comment function ----
comment <- function(...){
  list_comments <- list(...)
  comments <- map(list_comments, ~paste0("## ", ., " ##"))
  comments
}


## create function to convert comment "actions" in a yaml string into proper comments
convert_comment_actions <-function(yaml.txt){
  yaml.txt %>%
    str_replace_all("\\\n(\\s*)\\'\\'\\:(\\s*)\\'", "\n\\1")  %>%
    #str_replace_all("\\\n(\\s*)\\'", "\n\\1") %>%
    str_replace_all("([^\\'])\\\n(\\s*)\\#\\#", "\\1\n\n\\2\\#\\#") %>%
    str_replace_all("\\#\\#\\'\\\n", "\n")
}
as.yaml(splice(a="c", b="'c'", comment("fff")))
convert_comment_actions(as.yaml(splice(a="c", b="'c'", comment("fff"))))


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
    run = paste(c(run, arguments), collapse=" "),
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
action_model<- function(
  outcome, timescale, modeltype, samplesize_nonoutcomes_n=NULL
){
  action(
    name = glue("model_{outcome}_{timescale}_{modeltype}"),
    run = glue("r:latest analysis/models/model_{modeltype}.R"),
    arguments = c(outcome, timescale, samplesize_nonoutcomes_n),
    needs = list("design", "data_selection"),
    highly_sensitive = list(
      rds = glue("output/models/{outcome}/{timescale}/model{modeltype}*.rds")
    ),
    moderately_sensitive = list(
      txt = glue("output/models/{outcome}/{timescale}/model{modeltype}*.txt"),
      csv = glue("output/models/{outcome}/{timescale}/model{modeltype}*.csv")
    )
  )
}


## report action function ----
action_report <- function(
  outcome, timescale, modeltype
){
  action(
    name = glue("report_{outcome}_{timescale}_{modeltype}"),
    run = glue("r:latest analysis/models/report_{modeltype}.R"),
    arguments = c(outcome, timescale),
    needs = list("design", glue("model_{outcome}_{timescale}_{modeltype}")),
    highly_sensitive = list(
      rds = glue("output/models/{outcome}/{timescale}/report{modeltype}_*.rds")
    ),
    moderately_sensitive = list(
      csv = glue("output/models/{outcome}/{timescale}/report{modeltype}_*.csv"),
      svg = glue("output/models/{outcome}/{timescale}/report{modeltype}_*.svg"),
      png = glue("output/models/{outcome}/{timescale}/report{modeltype}_*.png")
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

  comment("# # # # # # # # # # # # # # # # # # #",
          "DO NOT EDIT project.yaml DIRECTLY",
          "This file is created by create-project.R",
          "Edit and run create-project.R to update the project.yaml",
          "# # # # # # # # # # # # # # # # # # #"
          ),


  comment("# # # # # # # # # # # # # # # # # # #", "Temp second dose info", "# # # # # # # # # # # # # # # # # # #"),
  action(
    name = "seconddose_extract",
    run = "cohortextractor:latest generate_cohort --study-definition study_definition_2dose --output-format feather",
    highly_sensitive = list(
      cohort = "output/input_2dose.feather"
    )
  ),

  action(
    name = "seconddose_process",
    run = "r:latest analysis/seconddose/process.R",
    needs = list("seconddose_extract"),
    highly_sensitive = list(
      data = "output/data/seconddose_data_processed.rds"
    )
  ),

  action(
    name = "seconddose_graphs",
    run = "r:latest analysis/seconddose/graphs.R",
    needs = list("seconddose_process"),
    moderately_sensitive = list(
      data = "output/seconddose/plots/plot*.png"
    )
  ),


  comment("# # # # # # # # # # # # # # # # # # #", "HCW characteristics", "# # # # # # # # # # # # # # # # # # #"),

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
    moderately_sensitive = list(
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


  comment("# # # # # # # # # # # # # # # # # # #", "Extract and process", "# # # # # # # # # # # # # # # # # # #"),

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
      processed = "output/data/data_processed.rds",
      diagnoses = "output/data/data_disagnoses.rds"
    )
  ),

  action(
    name = "data_properties",
    run = "r:latest analysis/process/data_properties.R",
    arguments = c("output/data/data_processed.rds", "output/data_properties"),
    needs = list("data_process"),
    moderately_sensitive = list(
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

  comment("# # # # # # # # # # # # # # # # # # #", "Descriptive stats", "# # # # # # # # # # # # # # # # # # #"),

  action(
    name = "descr_table1",
    run = "r:latest analysis/descriptive/table1.R",
    needs = list("design", "data_selection"),
    highly_sensitive = list(
      rds = "output/descriptive/tables/table1*.rds"
    ),
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
    highly_sensitive = list(
      rds = "output/descriptive/tables/table_irr.rds"
    ),
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
    highly_sensitive = list(
      rds = "output/descriptive/km/plot_survival*.rds"
    ),
    moderately_sensitive = list(
      png = "output/descriptive/km/plot_survival*.png",
      svg = "output/descriptive/km/plot_survival*.svg"
    )
  ),

  action(
    name = "descr_vaxdate",
    run = "r:latest analysis/descriptive/vax_date.R",
    needs = list("design", "data_selection"),
    highly_sensitive = list(
      rds = "output/descriptive/vaxdate/*.rds"
    ),
    moderately_sensitive = list(
      png = "output/descriptive/vaxdate/*.png"
    )
  ),

  action(
    name = "descr_diagnoses",
    run = "r:latest analysis/descriptive/diagnoses.R",
    needs = list("design", "data_selection"),
    moderately_sensitive = list(
      png = "output/descriptive/diagnoses/*.png"
    )
  ),

  comment("# # # # # # # # # # # # # # # # # # #", "Models", "# # # # # # # # # # # # # # # # # # #"),

  comment("###  SARS-CoV-2 Test"),
  action_model("test", "timesincevax", "cox"),
  action_report("test", "timesincevax", "cox"),
  action_model("test", "calendar", "cox"),
  action_report("test", "calendar", "cox"),
  action_model("test", "timesincevax", "plr", 50000),
  action_report("test", "timesincevax", "plr"),
  action_model("test", "calendar", "plr", 50000),
  action_report("test", "calendar", "plr"),

  comment("###  Positive SARS-CoV-2 Test"),
  action_model("postest", "timesincevax", "cox"),
  action_report("postest", "timesincevax", "cox"),
  action_model("postest", "calendar", "cox"),
  action_report("postest", "calendar", "cox"),
  action_model("postest", "timesincevax", "plr", 50000),
  action_report("postest", "timesincevax", "plr"),
  action_model("postest", "calendar", "plr", 50000),
  action_report("postest", "calendar", "plr"),

  comment("###  A&E attendence"),
  action_model("emergency", "timesincevax", "cox"),
  action_report("emergency", "timesincevax", "cox"),
  action_model("emergency", "calendar", "cox"),
  action_report("emergency", "calendar", "cox"),
  action_model("emergency", "timesincevax", "plr", 50000),
  action_report("emergency", "timesincevax", "plr"),
  action_model("emergency", "calendar", "plr", 50000),
  action_report("emergency", "calendar", "plr"),

  comment("### Unplanned Hospital admission"),
  action_model("admitted", "timesincevax", "cox"),
  action_report("admitted", "timesincevax", "cox"),
  action_model("admitted", "calendar", "cox"),
  action_report("admitted", "calendar", "cox"),
  action_model("admitted", "timesincevax", "plr", 50000),
  action_report("admitted", "timesincevax", "plr"),
  action_model("admitted", "calendar", "plr", 50000),
  action_report("admitted", "calendar", "plr"),

  comment("###  COVID-19 hospital admission"),
  action_model("covidadmitted", "timesincevax", "cox"),
  action_report("covidadmitted", "timesincevax", "cox"),
  action_model("covidadmitted", "calendar", "cox"),
  action_report("covidadmitted", "calendar", "cox"),
  action_model("covidadmitted", "timesincevax", "plr", 50000),
  action_report("covidadmitted", "timesincevax", "plr"),
  action_model("covidadmitted", "calendar", "plr", 50000),
  action_report("covidadmitted", "calendar", "plr"),

  # action_model("covidcc", "timesincevax", "cox"),
  # action_report("covidcc", "timesincevax", "cox"),
  # action_model("covidcc", "calendar", "cox"),
  # action_report("covidcc", "calendar", "cox"),
  # action_model("covidcc", "timesincevax", "plr", 50000),
  # action_report("covidcc", "timesincevax", "plr"),
  # action_model("covidcc", "calendar", "plr", 50000),
  # action_report("covidcc", "calendar", "plr"),

  comment("# # # # # # # # # # # # # # # # # # #", "Reports", "# # # # # # # # # # # # # # # # # # #"),

  action(
    name = "rmd_report",
    run = glue(
      "r:latest -e {q}",
      q = single_quote('rmarkdown::render("analysis/report/effectiveness_report.Rmd",  knit_root_dir = "/workspace",  output_dir = "/workspace/output/report", output_format = c("rmarkdown::github_document")   )')
    ),
    needs = splice(
      "design", "data_selection",
      "descr_table1", "descr_irr",
      "descr_km", "descr_vaxdate",
      as.list(
        glue(
             outcome = c("test", "postest", "emergency", "admitted", "covidadmitted"),
             "report_{outcome}_timesincevax_plr"
        )
      )
    ),
    moderately_sensitive = list(
      html = "output/report/effectiveness_report.html",
      md = "output/report/effectiveness_report.md",
      figures = "output/report/figures/*.png"
    )
  ),

  action(
    name = "rmd_report_timescales",
    run = glue(
      "r:latest -e {q}",
      q = single_quote('rmarkdown::render("analysis/report/effectiveness_report_comparetimescales.Rmd",  knit_root_dir = "/workspace",  output_dir = "/workspace/output/report", output_format = c("rmarkdown::github_document")   )')
    ),
    needs = splice(
      "design", "data_selection",
      "descr_table1", "descr_irr",
      "descr_km", "descr_vaxdate",
      as.list(
        glue_data(
          .x = expand_grid(
            outcome = c("test", "postest", "emergency", "admitted", "covidadmitted"),
            modeltype = c("cox", "plr"),
            timescale = c("timesincevax", "calendar")
          ),
          "report_{outcome}_{timescale}_{modeltype}"
        )
      )
    ),
    moderately_sensitive = list(
      html = "output/report/effectiveness_report_comparetimescales.html",
      md = "output/report/effectiveness_report_comparetimescales.md",
      figures = "output/report/figures_timescales/*.png"
    )
  )

)



project_list <- splice(
  defaults_list,
  list(actions = actions_list)
)


## convert list to yaml, reformat comments and whitespace,and output ----
as.yaml(project_list, indent=2) %>%
  # convert comment actions to comments
  convert_comment_actions() %>%
  # add one blank line before level 1 and level 2 keys
  str_replace_all("\\\n(\\w)", "\n\n\\1") %>%
  str_replace_all("\\\n\\s\\s(\\w)", "\n\n  \\1") %>%
  writeLines(here("project.yaml"))

#yaml::write_yaml(project_list, file =here("project.yaml"))


## grab all action names and send to a txt file

names(actions_list) %>% tibble(action=.) %>%
  mutate(
    model = action==""  & lag(action!="", 1, TRUE),
    model_number = cumsum(model),
  ) %>%
  group_by(model_number) %>%
  summarise(
    sets = str_trim(paste(action, collapse=" "))
  ) %>% pull(sets) %>%
  paste(collapse="\n") %>%
  writeLines(here("actions.txt"))

