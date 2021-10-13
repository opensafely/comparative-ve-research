# Comparative vaccine effectiveness in health and social care workers

This study compares effectiveness of the Oxford-AstraZenenca vaccine versus the Pfizer-BNT vaccine in vaccinated health and social care workers.

## Repository navigation

-   The [protocol is in the OpenSAFELY Google drive](https://docs.google.com/document/d/1eQ6N0JiFmUOFP2EA-AEE3PhGJ8yxjHEaA5IVSehOAXI/edit#)

-   If you are interested in how we defined our codelists, look in the [`codelists/`](./codelists/) directory.

-   Analysis scripts are in the [`analysis/`](./analysis) directory.

    -   The instructions used to extract data from the OpensAFELY-TPP database is specified in the [study definition](./analysis/study_definition.py); this is written in Python, but non-programmers should be able to understand what is going on there
    -   The [`lib/`](./analysis/lib) directory contains useful functions and look-up tables.
    -   The remaining folders mostly contain the R scripts that process, describe, and analyse the extracted database data.

-   Non-disclosive model outputs, including tables, figures, etc, are in the [`released_outputs/`](./released_outputs) directory.

-   The [`project.yaml`](./project.yaml) defines run-order and dependencies for all the analysis scripts. **This file should *not* be edited directly**. To make changes to the yaml, edit and run the [`create-project.R`](./create-project.R) script instead.

## Analysis scripts

Scripts are organised into five directories:

-   [`dummy/`](./analysis/dummy)

    -   [`data_makedummy.R`](analysis/R/process/data_makedummy.R) contains the script used to generate dummy data. This is used instead of the usual dummy data specified in the study definition, because it is then possible to impose some more useful structure in the data, such as ensuring nobody has a first dose of both the Pfizer and Astra-Zeneca vaccines. If the study definition is updated, this script must also be updated to ensure variable names and types match.

-   [`process/`](./analysis/process)

    -   [`design.R`](analysis/R/process/design.R) defines some common design elements used throughout the study, such as follow-up dates, model outcomes, and covariates.
    -   [`data_process.R`](analysis/R/process/data_process.R) imports the extracted database data (or dummy data), standardises some variables and derives some new ones.
    -   [`data_selection.R`](./analysis/R/process/data_selection.R) filters out participants who should not be included in the main analysis, and creates a small table used for the inclusion/exclusion flowchart
    -   [`data_properties.R`](./analysis/R/process/data_properties.R) tabulates and summarises the variables in the processed data for inspection / sense-checking.

-   [`descriptive/`](./analysis/descriptive)

    -   [`table1.R`](./analysis/R/descriptive/table1.R) creates a "table 1" table describing cohort characteristics at baseline, stratified by vaccine type.
    -   [`table1_allvax.R`](./analysis/R/descriptive/table1.R) same as `table1.r`, but on the pre-exclusion cohort.
    -   [`table_irr.R`](./analysis/R/descriptive/table_irr.R) calculates unadjusted incidence rates for various outcomes, stratified by vaccine type and times since vaccination.
    -   [`km.R`](./analysis/R/descriptive/km.R) unadjusted Kaplan-Meier plots for outcomes, by vaccine type.
    -   [`seconddose.R`](./analysis/R/descriptive/seconddose.R) cumulative incidence of second dose coverage, by vaccine type.
    -   [`vaxdate.R`](./analysis/R/descriptive/vaxdate.R) cumulative coverage of first vaccine dose over calendar time.

-   [`models/`](./analysis/models)

    -   [`model_plr.R`](./analysis/R/models/model_plr.R) fits the pooled logistic regression models. This script takes four arguments:

        -   `outcome`, for example `postest` for positive SARS-CoV-2 test or `covidadmitted` COVID-19 hospitalisation
        -   `timescale`, either `calendar` for calendar-time or `timesincevax` for vaccination-time
        -   `censor_seconddose`, whether (`1`) or not (`0`) to censor follow-up at the second dose
        -   `samplesize_nonoutcomes_n`, to reduce computations time, the size of the sample for those who did not experience the outcome of interest. All those who experienced the outcome were included.

    -   [`report_plr.R`](./analysis/R/models/report_plr.R) outputs summary information, effect estimates, and marginalised cumulative incidence estimates for the pooled logistic regression models from `model_plr.R`. This script has the `outcome`, `timescale`, and `censor_seconddose` arguments of the `model_plr.R` script to pick up the correct models.

    -   [`model_cox.R`](./analysis/R/models/model_cox.R) fits Cox models with time-varying effects, which were used to check consistency with the pooled logistic regression models.

    -   [`report_cox.R`](./analysis/R/models/report_cox.R) outputs summary information for the Cox models from `model_cox.R`.

-   [`report/`](./analysis/report)

    -   [`report_objects.R`](./analysis/report/report_objects.R) collates some of the baseline data and model outputs and saves to file, to make it easier to incorporate outputs across different actions in the main R markdown script that generates the study manuscript.
    -   [`effectiveness_report.rmd`](./analysis/report/effectiveness_report.rmd) is a R markdown file that puts a lot of the outputs together in one file for easy checking distribution. A pre-cursor to the manuscript.
    -   [`effectiveness_report_comparemodels.rmd`](./analysis/report/effectiveness_report_comparemodels.rmd) makes it easy to compare Cox versus PLR models, and calendar-time or vaccination-time timescales.

## Manuscript

Materials for the manuscript are in the [`manuscript/`](./manuscript) directory. This includes a bibliography, author list, citation style, [the Rmarkdown document where the manuscript is authored](./manuscript/draft-manuscript.Rmd), and rendered copies of the latest version of the manuscript itself.

Figures, tables, and inline numbers in the Rmarkdown manuscript are taken from [non-disclosive, released materials](./released_outputs) from the OpenSAFELY platform.

# About the OpenSAFELY framework

The OpenSAFELY framework is a secure analytics platform for electronic health records research in the NHS.

Instead of requesting access for slices of patient data and transporting them elsewhere for analysis, the framework supports developing analytics against dummy data, and then running against the real data *within the same infrastructure that the data is stored*. Read more at [OpenSAFELY.org](https://opensafely.org).

Developers and epidemiologists interested in the framework should review [the OpenSAFELY documentation](https://docs.opensafely.org)
