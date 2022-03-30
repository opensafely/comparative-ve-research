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
  outcome, timescale, censor_seconddose, modeltype, samplesize_nonoutcomes_n=NULL, exclude_prior_infection=NULL
){

  if(is.null(exclude_prior_infection)){
    exclude_prior_infection_path<-""
    exclude_prior_infection_needs<-""
  } else{
    if(exclude_prior_infection=="1"){
      exclude_prior_infection_path<-"/1"
      exclude_prior_infection_needs<-"_1"
    }
  }

  action(
    name = glue("model_{outcome}_{timescale}_{censor_seconddose}{exclude_prior_infection_needs}_{modeltype}"),
    run = glue("r:latest analysis/models/model_{modeltype}.R"),
    arguments = c(outcome, timescale, censor_seconddose, samplesize_nonoutcomes_n, exclude_prior_infection),
    needs = list("design", "data_selection"),
    highly_sensitive = lst(
      rds = glue("output/models/{outcome}/{timescale}/{censor_seconddose}{exclude_prior_infection_path}/model{modeltype}*.rds")
    ),
    moderately_sensitive = lst(
      txt = glue("output/models/{outcome}/{timescale}/{censor_seconddose}{exclude_prior_infection_path}/model{modeltype}*.txt"),
      csv = glue("output/models/{outcome}/{timescale}/{censor_seconddose}{exclude_prior_infection_path}/model{modeltype}*.csv")
    )
  )
}


## report action function ----
action_report <- function(
  outcome, timescale, censor_seconddose, modeltype, exclude_prior_infection=NULL
){
  if(is.null(exclude_prior_infection)){
    exclude_prior_infection_path<-""
    exclude_prior_infection_needs<-""
  } else{
    if(exclude_prior_infection=="1"){
      exclude_prior_infection_path<-"/1"
      exclude_prior_infection_needs<-"_1"
    }
  }

  action(
    name = glue("report_{outcome}_{timescale}_{censor_seconddose}{exclude_prior_infection_needs}_{modeltype}"),
    run = glue("r:latest analysis/models/report_{modeltype}.R"),
    arguments = c(outcome, timescale, censor_seconddose, exclude_prior_infection),
    needs = list("design", glue("model_{outcome}_{timescale}_{censor_seconddose}{exclude_prior_infection_needs}_{modeltype}")),
    highly_sensitive = lst(
      rds = glue("output/models/{outcome}/{timescale}/{censor_seconddose}{exclude_prior_infection_path}/report{modeltype}_*.rds")
    ),
    moderately_sensitive = lst(
      csv = glue("output/models/{outcome}/{timescale}/{censor_seconddose}{exclude_prior_infection_path}/report{modeltype}_*.csv"),
      svg = glue("output/models/{outcome}/{timescale}/{censor_seconddose}{exclude_prior_infection_path}/report{modeltype}_*.svg"),
      png = glue("output/models/{outcome}/{timescale}/{censor_seconddose}{exclude_prior_infection_path}/report{modeltype}_*.png")
    )
  )
}



# specify project ----

## defaults ----
defaults_list <- lst(
  version = "3.0",
  expectations= lst(population_size=100000L)
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
    highly_sensitive = lst(
      cohort = "output/input_2dose.feather"
    )
  ),

  action(
    name = "seconddose_process",
    run = "r:latest analysis/seconddose/process.R",
    needs = list("seconddose_extract"),
    highly_sensitive = lst(
      data = "output/data/seconddose_data_processed.rds"
    )
  ),

  action(
    name = "seconddose_graphs",
    run = "r:latest analysis/seconddose/graphs.R",
    needs = list("seconddose_process"),
    moderately_sensitive = lst(
      data = "output/seconddose/plots/plot*.png"
    )
  ),


  comment("# # # # # # # # # # # # # # # # # # #", "HCW characteristics", "# # # # # # # # # # # # # # # # # # #"),

  action(
    name = "hcw_extract",
    run = "cohortextractor:latest generate_cohort --study-definition study_definition_hcw --output-format feather",
    highly_sensitive = lst(
      cohort = "output/input_hcw.feather"
    )
  ),

  action(
    name = "hcw_process",
    run = "r:latest analysis/hcw/process.R",
    needs = list("hcw_extract"),
    highly_sensitive = lst(
      data = "output/data/hcw_data_processed.rds",
      datavax = "output/data/hcw_data_vax.rds"
    )
  ),

  action(
    name = "hcw_properties",
    run = "r:latest analysis/process/data_properties.R",
    arguments = c("output/data/hcw_data_processed.rds", "output/data_properties"),
    needs = list("hcw_process"),
    moderately_sensitive = lst(
      cohort = "output/data_properties/hcw_data_processed*.txt"
    )
  ),

  action(
    name = "hcw_descr",
    run = "r:latest analysis/hcw/descr.R",
    needs = list("hcw_process"),
    moderately_sensitive = lst(
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
    moderately_sensitive = lst(
      metadata = "output/data/metadata*"
    )
  ),

  action(
    name = "extract",
    run = "cohortextractor:latest generate_cohort --study-definition study_definition --output-format feather",
    needs = list("design"),
    highly_sensitive = lst(
      cohort = "output/input.feather"
    )
  ),

  action(
    name = "data_process",
    run = "r:latest analysis/process/data_process.R",
    needs = list("design", "extract"),
    highly_sensitive = lst(
      processed = "output/data/data_processed.rds"
    )
  ),

  action(
    name = "data_properties",
    run = "r:latest analysis/process/data_properties.R",
    arguments = c("output/data/data_processed.rds", "output/data_properties"),
    needs = list("data_process"),
    moderately_sensitive = lst(
      cohort = "output/data_properties/data_processed*.txt"
    )
  ),

  action(
    name = "data_selection",
    run = "r:latest analysis/process/data_selection.R",
    needs = list("design", "data_process"),
    highly_sensitive = lst(
      data_allvax = "output/data/data_cohort_allvax.rds",
      data = "output/data/data_cohort.rds"
    ),
    moderately_sensitive = lst(
      flow = "output/data/flowchart.csv"
    )
  ),

  comment("# # # # # # # # # # # # # # # # # # #", "Descriptive stats", "# # # # # # # # # # # # # # # # # # #"),

  action(
    name = "descr_table1",
    run = "r:latest analysis/descriptive/table1.R",
    needs = list("design", "data_selection"),
    # highly_sensitive = lst(
    #   rds = "output/descriptive/tables/table1*.rds"
    # ),
    moderately_sensitive = lst(
      html = "output/descriptive/tables/table1*.html",
      csv = "output/descriptive/tables/table1*.csv"
    )
  ),

  action(
    name = "descr_table1_allvax",
    run = "r:latest analysis/descriptive/table1_allvax.R",
    needs = list("design", "data_selection"),
    moderately_sensitive = lst(
      #rds = "output/descriptive/tables/table1_allvax*.rds",
      html = "output/descriptive/tables/table1_allvax*.html",
      csv = "output/descriptive/tables/table1_allvax*.csv"
    )
  ),

  action(
    name = "descr_irr",
    run = "r:latest analysis/descriptive/table_irr.R",
    arguments = c("output/data/data_processed.rds", "output/data_properties"),
    needs = list("design", "data_selection"),
    highly_sensitive = lst(
      rds = "output/descriptive/tables/table_irr*.rds"
    ),
    moderately_sensitive = lst(
      html = "output/descriptive/tables/table_irr*.html",
      csv = "output/descriptive/tables/table_irr*.csv"
    )
  ),

  action(
    name = "descr_km",
    run = "r:latest analysis/descriptive/km.R",
    arguments = c("output/data/data_processed.rds", "output/data_properties"),
    needs = list("design", "data_selection"),
    highly_sensitive = lst(
      rds = "output/descriptive/km/plot_survival*.rds"
    ),
    moderately_sensitive = lst(
      png = "output/descriptive/km/plot_survival*.png",
      svg = "output/descriptive/km/plot_survival*.svg"
    )
  ),

  action(
    name = "descr_vaxdate",
    run = "r:latest analysis/descriptive/vax_date.R",
    needs = list("design", "data_selection"),
    highly_sensitive = lst(
      rds = "output/descriptive/vaxdate/*.rds"
    ),
    moderately_sensitive = lst(
      png = "output/descriptive/vaxdate/*.png",
      pdf = "output/descriptive/vaxdate/*.pdf",
      svg = "output/descriptive/vaxdate/*.svg"
    )
  ),

  action(
    name = "descr_seconddose",
    run = "r:latest analysis/descriptive/seconddose.R",
    needs = list("design", "data_selection"),
    highly_sensitive = lst(
      rds = "output/descriptive/seconddose/*.rds"
    ),
    moderately_sensitive = lst(
      png = "output/descriptive/seconddose/*.png",
      pdf = "output/descriptive/seconddose/*.pdf",
      csv = "output/descriptive/seconddose/*.csv",
    )
  ),

  action(
    name = "descr_eventdate",
    run = "r:latest analysis/descriptive/event_date.R",
    needs = list("design", "data_selection"),
    highly_sensitive = lst(
      rds = "output/descriptive/eventdate/*.rds"
    ),
    moderately_sensitive = lst(
      png = "output/descriptive/eventdate/*.png",
      pdf = "output/descriptive/eventdate/*.pdf",
      svg = "output/descriptive/eventdate/*.svg",
    )
  ),


  comment("# # # # # # # # # # # # # # # # # # #", "Models", "# # # # # # # # # # # # # # # # # # #"),

  # comment("###  SARS-CoV-2 Test"),
  # action_model("test", "timesincevax", "cox"),
  # action_report("test", "timesincevax", "cox"),
  # action_model("test", "calendar", "cox"),
  # action_report("test", "calendar", "cox"),
  # action_model("test", "timesincevax", "plr", 50000),
  # action_report("test", "timesincevax", "plr"),
  # action_model("test", "calendar", "plr", 50000),
  # action_report("test", "calendar", "plr"),

  comment("###  Positive SARS-CoV-2 Test"),
  action_model("postest", "timesincevax", "1", "cox"),
  action_report("postest", "timesincevax", "1", "cox"),
  action_model("postest", "calendar", "1", "cox"),
  action_report("postest", "calendar", "1", "cox"),
  action_model("postest", "timesincevax", "1", "plr", 50000),
  action_report("postest", "timesincevax", "1", "plr"),
  action_model("postest", "calendar", "1", "plr", 50000),
  action_report("postest", "calendar", "1", "plr"),

  action_model("postest", "timesincevax", "0", "cox"),
  action_report("postest", "timesincevax", "0", "cox"),
  action_model("postest", "calendar", "0", "cox"),
  action_report("postest", "calendar", "0", "cox"),
  action_model("postest", "timesincevax", "0", "plr", 50000),
  action_report("postest", "timesincevax", "0", "plr"),
  action_model("postest", "calendar", "0", "plr", 50000),
  action_report("postest", "calendar", "0", "plr"),

  comment("###  A&E attendence"),
  action_model("emergency", "timesincevax", "1", "cox"),
  action_report("emergency", "timesincevax", "1", "cox"),
  action_model("emergency", "calendar", "1", "cox"),
  action_report("emergency", "calendar", "1", "cox"),
  action_model("emergency", "timesincevax", "1", "plr", 50000),
  action_report("emergency", "timesincevax", "1", "plr"),
  action_model("emergency", "calendar", "1", "plr", 50000),
  action_report("emergency", "calendar", "1", "plr"),

  action_model("emergency", "timesincevax", "0", "cox"),
  action_report("emergency", "timesincevax", "0", "cox"),
  action_model("emergency", "calendar", "0", "cox"),
  action_report("emergency", "calendar", "0", "cox"),
  action_model("emergency", "timesincevax", "0", "plr", 50000),
  action_report("emergency", "timesincevax", "0", "plr"),
  action_model("emergency", "calendar", "0", "plr", 50000),
  action_report("emergency", "calendar", "0", "plr"),

  comment("###  COVID-19 A&E attendence"),
  action_model("covidemergency", "timesincevax", "1", "cox"),
  action_report("covidemergency", "timesincevax", "1", "cox"),
  action_model("covidemergency", "calendar", "1", "cox"),
  action_report("covidemergency", "calendar", "1", "cox"),
  action_model("covidemergency", "timesincevax", "1", "plr", 50000),
  action_report("covidemergency", "timesincevax", "1", "plr"),
  action_model("covidemergency", "calendar", "1", "plr", 50000),
  action_report("covidemergency", "calendar", "1", "plr"),

  action_model("covidemergency", "timesincevax", "0", "cox"),
  action_report("covidemergency", "timesincevax", "0", "cox"),
  action_model("covidemergency", "calendar", "0", "cox"),
  action_report("covidemergency", "calendar", "0", "cox"),
  action_model("covidemergency", "timesincevax", "0", "plr", 50000),
  action_report("covidemergency", "timesincevax", "0", "plr"),
  action_model("covidemergency", "calendar", "0", "plr", 50000),
  action_report("covidemergency", "calendar", "0", "plr"),



  comment("### Unplanned Hospital admission"),
  action_model("admitted", "timesincevax", "1", "cox"),
  action_report("admitted", "timesincevax", "1", "cox"),
  action_model("admitted", "calendar", "1", "cox"),
  action_report("admitted", "calendar", "1", "cox"),
  action_model("admitted", "timesincevax", "1", "plr", 50000),
  action_report("admitted", "timesincevax", "1", "plr"),
  action_model("admitted", "calendar", "1", "plr", 50000),
  action_report("admitted", "calendar", "1", "plr"),

  action_model("admitted", "timesincevax", "0", "cox"),
  action_report("admitted", "timesincevax", "0", "cox"),
  action_model("admitted", "calendar", "0", "cox"),
  action_report("admitted", "calendar", "0", "cox"),
  action_model("admitted", "timesincevax", "0", "plr", 50000),
  action_report("admitted", "timesincevax", "0", "plr"),
  action_model("admitted", "calendar", "0", "plr", 50000),
  action_report("admitted", "calendar", "0", "plr"),


  comment("###  COVID-19 hospital admission"),
  action_model("covidadmitted", "timesincevax", "1", "cox"),
  action_report("covidadmitted", "timesincevax", "1", "cox"),
  action_model("covidadmitted", "calendar", "1", "cox"),
  action_report("covidadmitted", "calendar", "1", "cox"),
  action_model("covidadmitted", "timesincevax", "1", "plr", 50000),
  action_report("covidadmitted", "timesincevax", "1", "plr"),
  action_model("covidadmitted", "calendar", "1", "plr", 50000),
  action_report("covidadmitted", "calendar", "1", "plr"),

  action_model("covidadmitted", "timesincevax", "0", "cox"),
  action_report("covidadmitted", "timesincevax", "0", "cox"),
  action_model("covidadmitted", "calendar", "0", "cox"),
  action_report("covidadmitted", "calendar", "0", "cox"),
  action_model("covidadmitted", "timesincevax", "0", "plr", 50000),
  action_report("covidadmitted", "timesincevax", "0", "plr"),
  action_model("covidadmitted", "calendar", "0", "plr", 50000),
  action_report("covidadmitted", "calendar", "0", "plr"),




  comment("# # # # # # # # # # # # # # # # # # #", "sensitivity -- exclude prior infection", "# # # # # # # # # # # # # # # # # # #"),

  comment("###  Positive SARS-CoV-2 Test"),
  action_model("postest", "timesincevax", "1", "plr", 50000, "1"),
  action_report("postest", "timesincevax", "1", "plr", "1"),

  action_model("postest", "timesincevax", "0", "plr", 50000, "1"),
  action_report("postest", "timesincevax", "0", "plr", "1"),

  comment("###  A&E attendence"),
  action_model("emergency", "timesincevax", "1", "plr", 50000, "1"),
  action_report("emergency", "timesincevax", "1", "plr", "1"),

  action_model("emergency", "timesincevax", "0", "plr", 50000, "1"),
  action_report("emergency", "timesincevax", "0", "plr", "1"),

  comment("###  COVID-19 A&E attendence"),
  action_model("covidemergency", "timesincevax", "1", "plr", 50000, "1"),
  action_report("covidemergency", "timesincevax", "1", "plr", "1"),

  action_model("covidemergency", "timesincevax", "0", "plr", 50000, "1"),
  action_report("covidemergency", "timesincevax", "0", "plr", "1"),


  comment("### Unplanned Hospital admission"),
  action_model("admitted", "timesincevax", "1", "plr", 50000, "1"),
  action_report("admitted", "timesincevax", "1", "plr", "1"),

  action_model("admitted", "timesincevax", "0", "plr", 50000, "1"),
  action_report("admitted", "timesincevax", "0", "plr", "1"),


  comment("###  COVID-19 hospital admission"),

  action_model("covidadmitted", "timesincevax", "1", "plr", 50000, "1"),
  action_report("covidadmitted", "timesincevax", "1", "plr", "1"),

  action_model("covidadmitted", "timesincevax", "0", "plr", 50000, "1"),
  action_report("covidadmitted", "timesincevax", "0", "plr", "1"),


  comment("# # # # # # # # # # # # # # # # # # #", "Reports", "# # # # # # # # # # # # # # # # # # #"),


  action(
    name = "report_objects",
    run = "r:latest analysis/report/report-objects.R",
    arguments = NULL,
    needs = splice(
      "design", "data_selection",
      as.list(
        glue_data(
          .x = expand_grid(
            outcome = c("postest", "covidemergency", "covidadmitted"),
            censor_seconddose = c("0", "1")
          ),
          "report_{outcome}_timesincevax_{censor_seconddose}_plr"
        )
      )
      ),
    moderately_sensitive = lst(
      out = "output/report/objects/*"
    )
  ),


  action(
    name = "report_objects_sensitivity",
    run = "r:latest analysis/report/report-objects-sensitivity.R",
    arguments = NULL,
    needs = splice(
      "design", "data_selection",
      as.list(
        glue_data(
          .x = expand_grid(
            outcome = c("postest", "covidemergency", "covidadmitted"),
            censor_seconddose = c("0", "1")
          ),
          "report_{outcome}_timesincevax_{censor_seconddose}_1_plr"
        )
      )
    ),
    moderately_sensitive = lst(
      out = "output/report/objects/sensitivty/exclude_prior_infection/*"
    )
  ),

  action(
    name = "rmd_report",
    run = glue(
      "r:latest -e {q}",
      q = single_quote('rmarkdown::render("analysis/report/effectiveness_report.Rmd",  knit_root_dir = "/workspace",  output_dir = "/workspace/output/report", output_format = c("html_document")   )')
    ),
    needs = splice(
      "design", "data_selection",
      "descr_table1", "descr_irr",
      "descr_km", "descr_vaxdate",
      as.list(
        glue(
             outcome = c("postest", "emergency", "covidemergency", "admitted", "covidadmitted"),
             "report_{outcome}_timesincevax_1_plr"
        )
      )
    ),
    moderately_sensitive = lst(
      html = "output/report/effectiveness_report.html",
      md = "output/report/effectiveness_report.md"
    )
  ),


  action(
    name = "rmd_report_models",
    run = glue(
      "r:latest -e {q}",
      q = single_quote('rmarkdown::render("analysis/report/effectiveness_report_comparemodels.Rmd",  knit_root_dir = "/workspace",  output_dir = "/workspace/output/report", output_format = c("rmarkdown::github_document")   )')
    ),
    needs = splice(
      "design", "data_selection",
      "descr_table1", "descr_irr",
      "descr_km", "descr_vaxdate",
      as.list(
        glue_data(
          .x = expand_grid(
            outcome = c("postest", "covidemergency", "covidadmitted"),
            modeltype = c("cox", "plr"),
            timescale = c("timesincevax", "calendar"),
            censor_seconddose = c("0", "1")
          ),
          "report_{outcome}_{timescale}_{censor_seconddose}_{modeltype}"
        )
      )
    ),
    moderately_sensitive = lst(
      html = "output/report/effectiveness_report_comparemodels.html",
      md = "output/report/effectiveness_report_comparemodels.md",
      figures = "output/report/figures_timescales/*.png"
    )
  )


  # action(
  #   name = "rmd_manuscript",
  #   run = glue(
  #     "r:latest -e {q}",
  #     q = single_quote('rmarkdown::render("analysis/report/draft-manuscript.Rmd",  knit_root_dir = "/workspace",  output_dir = "/workspace/output/report", output_format = c("html_document")   )')
  #   ),
  #   needs = splice(
  #     "design", "data_selection",
  #     "descr_table1", "descr_irr",
  #     "descr_km", "descr_vaxdate",
  #     "report_objects"
  #   ),
  #   moderately_sensitive = lst(
  #     html = "output/report/draft-manuscript.html",
  #     md = "output/report/draft-manuscript.md"
  #   )
  # ),
  #
  # action(
  #   name = "rmd_supplement",
  #   run = glue(
  #     "r:latest -e {q}",
  #     q = single_quote('rmarkdown::render("analysis/report/draft-supplement.Rmd",  knit_root_dir = "/workspace",  output_dir = "/workspace/output/report", output_format = c("html_document")   )')
  #   ),
  #   needs = splice(
  #     "design", "data_selection",
  #     "descr_table1_allvax", "descr_irr",
  #     "descr_km", "descr_vaxdate",
  #     "descr_seconddose",
  #     as.list(
  #       glue_data(
  #         .x = expand_grid(
  #           outcome = c("postest", "emergency", "covidemergency", "covidadmitted"),
  #           censor_seconddose = c("0", "1")
  #         ),
  #         "report_{outcome}_timesincevax_{censor_seconddose}_plr"
  #       )
  #     )
  #   ),
  #   moderately_sensitive = lst(
  #     html = "output/report/draft-supplement.html",
  #     md = "output/report/draft-supplement.md"
  #   )
  # )



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

