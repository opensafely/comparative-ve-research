# upload file if it doesn't already exist in google drive

trackdown::upload_file(
  file = "analysis/report/effectiveness_report.Rmd",
  gpath = "Research/Vaccine comparative effectiveness",
  shared_drive = "OpenSAFELY",
  hide_code = TRUE
)

#
trackdown::update_file(
  file = "analysis/report/effectiveness_report.Rmd",
  gpath = "analysis/report/effectiveness_report.Rmd",
  hide_code = TRUE
)
