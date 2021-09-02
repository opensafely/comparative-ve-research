---
title: "Comparative vaccine effectiveness of ChAdOx1 versus BNT162b2 in Health and Social Care workers in England"
output:
  html_document: 
    keep_md: yes
    self_contained: TRUE
  word_document: default
  bookdown::html_document2:
    number_sections: false
    toc: false
#bibliography: references.bib
#csl: nature.csl # from https://raw.githubusercontent.com/citation-style-language/styles/master/nature.csl
#link-citations: yes
#zotero: true
---



# Introduction

The COVID-19 global pandemic has prompted the rapid development and delivery of vaccines to combat the disease. Following demonstration of high safety and efficacy against symptomatic and severe disease in phase-III randomised clinical trials (RCTs), two vaccines have been approved and widely administered as part of the national vaccination programme in the United Kingdom: the Pfizer-BioNTech BNT162b2 mRNA COVID-19 vaccine <!--# @polack2020 --> (*BNT162b2*) and the Oxford-AstraZeneca ChAdOx1 nCoV-19 vaccine <!--# @voysey2021 --> (*ChAdOx1*). Post-authorisation assessment of vaccine effectiveness using observational data is necessary to monitor the success of such programmes as, invariably, target populations and settings differ substantially from those of trials. To date, there have been no RCTs that have directly compared the BNT162b2 and ChAdOx1 vaccines to estimate the relative efficacy against COVID-19 infection and disease in the same population. The concurrent roll-out of these vaccines across the UK, combined with the country's well-developed electronic health record infrastructure, provides a rare opportunity to emulate such a trial using observational data.

COVID-19 vaccination in the UK has been prioritised based on the risk of infection and subsequent severity of disease . Patient-facing health and social care workers (HCWs) were amongst the first groups eligible for vaccination due to the high occupational exposure to the SARS-CoV-2 virus, and many were vaccinated during the period where both vaccines were widely used <!--#  @collaborative2021 -->. This study assesses the comparative effectiveness of one dose of ChAdOx1 with one dose of BNT162b2 in HCWs, using the OpenSAFELY-TPP linked primary care database covering around 40% of England's population.

# Methods

## Study data

The OpenSAFELY-TPP database covers 24 million people registered at GP surgeries that use TPP's SystmOne software. This primary care data is linked (via NHS numbers) with A&E attendance and in-patient hospital spell records via NHS Digital's Hospital Episode Statistics (HES), national coronavirus testing records via the Second Generation Surveillance System (SGSS), and national death registry records from the Office for National Statistics (ONS). Vaccination status is available in the GP record directly via the National Immunisation Management System (NIMS). HCW status is recorded for all vaccine recipients at the time of vaccination, and this information is sent to OpenSAFELY-TPP from NHS Digital's COVID-19 data store.

## Study population

We studied health and social care workers in England vaccinated with either BNT162b2 or ChAdOx1. This group was prioritised for vaccination at the start of the vaccine roll-out due to the high occupational exposure to the SARS-CoV-2 virus, and many were vaccinated during the period where both vaccines were widely used.

Vaccinated HCWs were included in the study if: they were registered at a GP practice using TPP's SystmOne clinical information system on the day of they received their first dose of BNT162b2 or ChAdOx1; the date of vaccination was between 04 January and 28 February 2021 (56 days), a period when both vaccines were being administered widely; they aged between 18 and 64 inclusive; not classed as Clinically Extremely Vulnerable, as set out by government guidance, at the time of vaccination; information on sex, ethnicity, deprivation, and geographical region was known.

Study participants were followed up for no more than 14 weeks from the day of the first dose. Follow-up was censored at: the study end date, 25 April 2021; a second vaccine dose; death or de-registration.

## Outcomes

Three outcomes were defined. Positive SARS-CoV-2 tests were identified using SGSS records and based on swab date. Both polymerase chain reaction (PCR) and lateral flow tests are included. We did not differentiate between symptomatic and asymptomatic infection. A&E attendances were identified using HES emergency care records. COVID-19 hospital admissions were identified using HES in-patient hospital records. Admissions where the ICD-10 coded primary or non-primary "reason for admission" included U07.1 ("COVID-19, virus identified") and U07.2 ( "COVID-19, virus not identified") were included <!--# @emergenc --> .

Although severe disease (such as requirement for intensive or critical care) and mortality were of interest there were too few events to investigate these outcomes fully. Unadjusted rates for these outcomes are reported descriptively. COVID-19 critical care admissions were identified via HES. COVID-19 deaths were identified using linked death registration data. Death with COVID-19 ICD-10 codes (as above) mentioned anywhere on the death certificate (i.e., as an underlying or contributing cause of death) were included.

## Additional variables

Participant characteristics used describe the cohort and for confounder adjustment include: age, sex (male or female), English Index of Multiple Deprivation (IMD, grouped by quintiles), ethnicity (Black, Mixed, South Asian, White, Other, as per the UK census), NHS region (East of England, Midlands, London, North East and Yorkshire, North West, South East, South West), number of conditions in the clinically "at risk" (but not clinically extremely vulnerable) classification, as per national prioritisation guidelines, <!--number of previous SARS-CoV-2 tests (via SGSS),--> rurality, evidence of prior SARS-CoV-2 infection (positive test or COVID-19 hospitalisation), learning disabilities, severe mental illness. All characteristics were ascertained as at the time of vaccination.

## Statistical Analysis

We estimated the relative effectiveness of a first dose of ChAdOx1 versus BNT162b2 using pooled logistic regression (PLR) models <!--# [@cupples1988a; @ngwa2016] --> with the outcome risk estimated at daily intervals. The effect is permitted to vary by time since vaccination to account for the potential differences in vaccine protection over time between the two brands. The PLR models approximate Cox models with time-varying effects, and enables the estimation of risk-adjusted survival rates for each vaccine type using the parametric g-formula. This is one minus the average of the cumulative incidence for each day of follow-up predicted by the PLR model, under the (counterfactual) assumption that every participant received the BNT162b2 vaccine or that every participant received the ChAdOx1 vaccine. Assuming appropriate parameterisation of risk (i.e., adequate confounder adjustment), this replicates the cumulative incidence that would have been observed in an RCT comparing the two vaccines in the population under consideration. Standard errors for the PLR model were obtained using the HC0 clustered sandwich estimator to account for within-participant clustering. Confidence intervals for the risk-adjusted cumulative incidence were obtained using the delta method (i.e, a first-order Taylor series approximation of the variance).

Four models were fit for each outcome, with progressive adjustment for confounders: (1) An unadjusted model using a restricted cubic spline term with 4 degrees of freedom for time since vaccination, vaccine type, and their interaction; (2) Additionally adjusting for region-specific calendar-time effects, by including a restricted cubic spline term with 4 degrees of freedom for the date of vaccination and its interaction with region; (3) additionally adjusting for demographic characteristics; (4) additionally adjusting for clinical characteristics.

<!-- Events occurring on the same day as vaccination are included in follow-up. -->

PLR models are computationally expensive to fit, as the input dataset must be arranged as one row per person per day of follow-up. To manage this, a sampling strategy was used such that all those who experienced the event of interest are selected, and a random sample of 50000 who did not experience the event are selected. The models are weighted to recover the characteristics of the complete cohort. Sampling was based on a ranked hash of the person identifier to ensure the sampled non-events overlapped as much as possible across outcomes.

## Data and code

Data management and analyses were conducted in Python 3.8 and R version 4.0.2. All code is available for review and reuse at <https://github.com/opensafely/comparative-ve-research>. No person-level data is shared. Any reported figures based on counts below 6 are redacted or rounded for disclosure control.

# Results

## Study population



A total of 361,196 HCWs aged 18-64 receiving a first dose of BNT162b2 or ChAdOx1 between 4 January and 28 February 2021 and actively registered at at TPP practice were identified, with 316 959 (87.8%) meeting the study eligibility criteria. 252,753 (79.7%) were vaccinated with BNT162b2, contributing 50 462.9 person-years of follow-up. For ChAdOx1, this was 64,206 (20.3%) and 12 967.7 person-years.

#### Table 0: Inclusion criteria

<!--html_preserve--><style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#mmwahrbvfp .gt_table {
  display: table;
  border-collapse: collapse;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}

#mmwahrbvfp .gt_heading {
  background-color: #FFFFFF;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#mmwahrbvfp .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#mmwahrbvfp .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 4px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#mmwahrbvfp .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#mmwahrbvfp .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#mmwahrbvfp .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}

#mmwahrbvfp .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}

#mmwahrbvfp .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#mmwahrbvfp .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#mmwahrbvfp .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}

#mmwahrbvfp .gt_group_heading {
  padding: 8px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
}

#mmwahrbvfp .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}

#mmwahrbvfp .gt_from_md > :first-child {
  margin-top: 0;
}

#mmwahrbvfp .gt_from_md > :last-child {
  margin-bottom: 0;
}

#mmwahrbvfp .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}

#mmwahrbvfp .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 12px;
}

#mmwahrbvfp .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#mmwahrbvfp .gt_first_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#mmwahrbvfp .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#mmwahrbvfp .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#mmwahrbvfp .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#mmwahrbvfp .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#mmwahrbvfp .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#mmwahrbvfp .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 4px;
}

#mmwahrbvfp .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#mmwahrbvfp .gt_sourcenote {
  font-size: 90%;
  padding: 4px;
}

#mmwahrbvfp .gt_left {
  text-align: left;
}

#mmwahrbvfp .gt_center {
  text-align: center;
}

#mmwahrbvfp .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#mmwahrbvfp .gt_font_normal {
  font-weight: normal;
}

#mmwahrbvfp .gt_font_bold {
  font-weight: bold;
}

#mmwahrbvfp .gt_font_italic {
  font-style: italic;
}

#mmwahrbvfp .gt_super {
  font-size: 65%;
}

#mmwahrbvfp .gt_footnote_marks {
  font-style: italic;
  font-size: 65%;
}
</style>
<div id="mmwahrbvfp" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;"><table class="gt_table">
  
  <thead class="gt_col_headings">
    <tr>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1">Criteria</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">N</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">N excluded</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">% excluded</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">% remaining</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr>
      <td class="gt_row gt_left">HCWs aged 18-64
  receiving first dose of BNT162b2 or ChAdOx1
  between 4 January and 28 February 2021</td>
      <td class="gt_row gt_right">361,196</td>
      <td class="gt_row gt_right">-</td>
      <td class="gt_row gt_right">-</td>
      <td class="gt_row gt_right">100.0&percnt;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">with no missing demographic information</td>
      <td class="gt_row gt_right">326,850</td>
      <td class="gt_row gt_right">34,346</td>
      <td class="gt_row gt_right">9.5&percnt;</td>
      <td class="gt_row gt_right">90.5&percnt;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">who are not clinically extremely vulnerable</td>
      <td class="gt_row gt_right">316,959</td>
      <td class="gt_row gt_right">9,891</td>
      <td class="gt_row gt_right">3.0&percnt;</td>
      <td class="gt_row gt_right">87.8&percnt;</td>
    </tr>
  </tbody>
  
  
</table></div><!--/html_preserve-->

Baseline characteristics are reported in Table 1 and were largely well-balanced between recipients of each vaccine, though regional and temporal differences in the distribution of each vaccine are notable. BNT162b2 was on average administered earlier than ChAdOx1 (median day of vaccination 15 January for BNT162b2, 22 January for ChadOx1). BNT162b2 was relatively more likely to be administered in the South and East of England, and ChAdOx1 the Midlands and Northern England. The proportion of each clinical condition is slightly higher in ChAdOx1 recipients, though consistently under a 0.6% percent-point difference.

#### Table 1: Baseline characteristics

<!--html_preserve--><style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#myedhngpqd .gt_table {
  display: table;
  border-collapse: collapse;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}

#myedhngpqd .gt_heading {
  background-color: #FFFFFF;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#myedhngpqd .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#myedhngpqd .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 4px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#myedhngpqd .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#myedhngpqd .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#myedhngpqd .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}

#myedhngpqd .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}

#myedhngpqd .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#myedhngpqd .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#myedhngpqd .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}

#myedhngpqd .gt_group_heading {
  padding: 8px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
}

#myedhngpqd .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}

#myedhngpqd .gt_from_md > :first-child {
  margin-top: 0;
}

#myedhngpqd .gt_from_md > :last-child {
  margin-bottom: 0;
}

#myedhngpqd .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}

#myedhngpqd .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 12px;
}

#myedhngpqd .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#myedhngpqd .gt_first_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#myedhngpqd .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#myedhngpqd .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#myedhngpqd .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#myedhngpqd .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#myedhngpqd .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#myedhngpqd .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 4px;
}

#myedhngpqd .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#myedhngpqd .gt_sourcenote {
  font-size: 90%;
  padding: 4px;
}

#myedhngpqd .gt_left {
  text-align: left;
}

#myedhngpqd .gt_center {
  text-align: center;
}

#myedhngpqd .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#myedhngpqd .gt_font_normal {
  font-weight: normal;
}

#myedhngpqd .gt_font_bold {
  font-weight: bold;
}

#myedhngpqd .gt_font_italic {
  font-style: italic;
}

#myedhngpqd .gt_super {
  font-size: 65%;
}

#myedhngpqd .gt_footnote_marks {
  font-style: italic;
  font-size: 65%;
}
</style>
<div id="myedhngpqd" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;"><table class="gt_table">
  
  <thead class="gt_col_headings">
    <tr>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1"><strong>Characteristic</strong></th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1"><strong>BNT162b2</strong>, N = 252,753</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1"><strong>ChAdOx1</strong>, N = 64,206</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr>
      <td class="gt_row gt_left">Age</td>
      <td class="gt_row gt_center"></td>
      <td class="gt_row gt_center"></td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">18-30</td>
      <td class="gt_row gt_center">40,993 (16%)</td>
      <td class="gt_row gt_center">10,454 (16%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">30s</td>
      <td class="gt_row gt_center">59,443 (24%)</td>
      <td class="gt_row gt_center">14,726 (23%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">40s</td>
      <td class="gt_row gt_center">64,455 (26%)</td>
      <td class="gt_row gt_center">16,286 (25%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">50s</td>
      <td class="gt_row gt_center">67,678 (27%)</td>
      <td class="gt_row gt_center">17,549 (27%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">60-64</td>
      <td class="gt_row gt_center">20,184 (8.0%)</td>
      <td class="gt_row gt_center">5,191 (8.1%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Sex</td>
      <td class="gt_row gt_center"></td>
      <td class="gt_row gt_center"></td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Female</td>
      <td class="gt_row gt_center">199,839 (79%)</td>
      <td class="gt_row gt_center">49,334 (77%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Male</td>
      <td class="gt_row gt_center">52,914 (21%)</td>
      <td class="gt_row gt_center">14,872 (23%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Ethnicity</td>
      <td class="gt_row gt_center"></td>
      <td class="gt_row gt_center"></td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">White</td>
      <td class="gt_row gt_center">211,135 (84%)</td>
      <td class="gt_row gt_center">54,285 (85%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Black</td>
      <td class="gt_row gt_center">8,510 (3.4%)</td>
      <td class="gt_row gt_center">3,164 (4.9%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">South Asian</td>
      <td class="gt_row gt_center">23,099 (9.1%)</td>
      <td class="gt_row gt_center">4,700 (7.3%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Mixed</td>
      <td class="gt_row gt_center">3,854 (1.5%)</td>
      <td class="gt_row gt_center">1,008 (1.6%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Other</td>
      <td class="gt_row gt_center">6,155 (2.4%)</td>
      <td class="gt_row gt_center">1,049 (1.6%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">IMD</td>
      <td class="gt_row gt_center"></td>
      <td class="gt_row gt_center"></td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">1 most deprived</td>
      <td class="gt_row gt_center">36,801 (15%)</td>
      <td class="gt_row gt_center">10,304 (16%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">2</td>
      <td class="gt_row gt_center">47,201 (19%)</td>
      <td class="gt_row gt_center">12,114 (19%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">3</td>
      <td class="gt_row gt_center">55,740 (22%)</td>
      <td class="gt_row gt_center">13,749 (21%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">4</td>
      <td class="gt_row gt_center">57,410 (23%)</td>
      <td class="gt_row gt_center">14,360 (22%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">5 least deprived</td>
      <td class="gt_row gt_center">55,601 (22%)</td>
      <td class="gt_row gt_center">13,679 (21%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Region</td>
      <td class="gt_row gt_center"></td>
      <td class="gt_row gt_center"></td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">North East and Yorkshire</td>
      <td class="gt_row gt_center">53,421 (21%)</td>
      <td class="gt_row gt_center">16,412 (26%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">East of England</td>
      <td class="gt_row gt_center">62,285 (25%)</td>
      <td class="gt_row gt_center">11,856 (18%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Midlands</td>
      <td class="gt_row gt_center">50,509 (20%)</td>
      <td class="gt_row gt_center">17,245 (27%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">South West</td>
      <td class="gt_row gt_center">35,901 (14%)</td>
      <td class="gt_row gt_center">5,051 (7.9%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">North West</td>
      <td class="gt_row gt_center">23,610 (9.3%)</td>
      <td class="gt_row gt_center">7,870 (12%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">London</td>
      <td class="gt_row gt_center">10,389 (4.1%)</td>
      <td class="gt_row gt_center">2,149 (3.3%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">South East</td>
      <td class="gt_row gt_center">16,638 (6.6%)</td>
      <td class="gt_row gt_center">3,623 (5.6%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Rural/urban category</td>
      <td class="gt_row gt_center"></td>
      <td class="gt_row gt_center"></td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Urban conurbation</td>
      <td class="gt_row gt_center">61,588 (24%)</td>
      <td class="gt_row gt_center">19,300 (30%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Urban city or town</td>
      <td class="gt_row gt_center">144,029 (57%)</td>
      <td class="gt_row gt_center">32,201 (50%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Rural town or village</td>
      <td class="gt_row gt_center">47,136 (19%)</td>
      <td class="gt_row gt_center">12,705 (20%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Day of vaccination</td>
      <td class="gt_row gt_center">12 (7, 18)</td>
      <td class="gt_row gt_center">19 (13, 33)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Body Mass Index &gt; 40 kg/m^2</td>
      <td class="gt_row gt_center">9,779 (3.9%)</td>
      <td class="gt_row gt_center">2,863 (4.5%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Chronic heart disease</td>
      <td class="gt_row gt_center">9,208 (3.6%)</td>
      <td class="gt_row gt_center">2,526 (3.9%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Chronic kidney disease</td>
      <td class="gt_row gt_center">1,994 (0.8%)</td>
      <td class="gt_row gt_center">551 (0.9%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Diabetes</td>
      <td class="gt_row gt_center">12,667 (5.0%)</td>
      <td class="gt_row gt_center">3,340 (5.2%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Chronic liver disease</td>
      <td class="gt_row gt_center">3,851 (1.5%)</td>
      <td class="gt_row gt_center">1,191 (1.9%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Chronic respiratory disease</td>
      <td class="gt_row gt_center">2,579 (1.0%)</td>
      <td class="gt_row gt_center">733 (1.1%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Chronic neurological disease</td>
      <td class="gt_row gt_center">6,053 (2.4%)</td>
      <td class="gt_row gt_center">1,621 (2.5%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Immunosuppressed</td>
      <td class="gt_row gt_center">2,522 (1.0%)</td>
      <td class="gt_row gt_center">681 (1.1%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Asplenia or poor spleen function</td>
      <td class="gt_row gt_center">1,702 (0.7%)</td>
      <td class="gt_row gt_center">481 (0.7%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Learning disabilities</td>
      <td class="gt_row gt_center">187 (&lt;0.1%)</td>
      <td class="gt_row gt_center">61 (&lt;0.1%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Serious mental illness</td>
      <td class="gt_row gt_center">1,271 (0.5%)</td>
      <td class="gt_row gt_center">433 (0.7%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Morbidity count</td>
      <td class="gt_row gt_center"></td>
      <td class="gt_row gt_center"></td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">0</td>
      <td class="gt_row gt_center">209,763 (83%)</td>
      <td class="gt_row gt_center">52,446 (82%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">1</td>
      <td class="gt_row gt_center">36,507 (14%)</td>
      <td class="gt_row gt_center">9,843 (15%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">2+</td>
      <td class="gt_row gt_center">6,483 (2.6%)</td>
      <td class="gt_row gt_center">1,917 (3.0%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Prior SARS-CoV-2 infection</td>
      <td class="gt_row gt_center">27,260 (11%)</td>
      <td class="gt_row gt_center">9,086 (14%)</td>
    </tr>
  </tbody>
  
  
</table></div><!--/html_preserve-->

The cumulative proportion of vaccinated study participants by calendar time is reported in Figure 1.

#### Figure 1: Vaccination dates

<img src="/workspace/output/report/figures/vaxdate-1.png" width="80%" />  

## Event rates

Table 2 shows event rates by vaccine type, and the crude incidence. Over the duration of 63 430.7 person-years of follow-up there were 6663 positive SARS-CoV-2 tests, 12977 A&E attendances, 156 COVID-19 hospital admissions, and 3 COVID-19 deaths.

#### Table 2: Event rates

<!--html_preserve--><style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#njwqxvmwkq .gt_table {
  display: table;
  border-collapse: collapse;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}

#njwqxvmwkq .gt_heading {
  background-color: #FFFFFF;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#njwqxvmwkq .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#njwqxvmwkq .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 4px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#njwqxvmwkq .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#njwqxvmwkq .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#njwqxvmwkq .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}

#njwqxvmwkq .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}

#njwqxvmwkq .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#njwqxvmwkq .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#njwqxvmwkq .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}

#njwqxvmwkq .gt_group_heading {
  padding: 8px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
}

#njwqxvmwkq .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}

#njwqxvmwkq .gt_from_md > :first-child {
  margin-top: 0;
}

#njwqxvmwkq .gt_from_md > :last-child {
  margin-bottom: 0;
}

#njwqxvmwkq .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}

#njwqxvmwkq .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 12px;
}

#njwqxvmwkq .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#njwqxvmwkq .gt_first_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#njwqxvmwkq .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#njwqxvmwkq .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#njwqxvmwkq .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#njwqxvmwkq .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#njwqxvmwkq .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#njwqxvmwkq .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 4px;
}

#njwqxvmwkq .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#njwqxvmwkq .gt_sourcenote {
  font-size: 90%;
  padding: 4px;
}

#njwqxvmwkq .gt_left {
  text-align: left;
}

#njwqxvmwkq .gt_center {
  text-align: center;
}

#njwqxvmwkq .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#njwqxvmwkq .gt_font_normal {
  font-weight: normal;
}

#njwqxvmwkq .gt_font_bold {
  font-weight: bold;
}

#njwqxvmwkq .gt_font_italic {
  font-style: italic;
}

#njwqxvmwkq .gt_super {
  font-size: 65%;
}

#njwqxvmwkq .gt_footnote_marks {
  font-style: italic;
  font-size: 65%;
}
</style>
<div id="njwqxvmwkq" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;"><table class="gt_table">
  
  <thead class="gt_col_headings">
    <tr>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1">Time since first dose</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">BNT162b2
Events / person-years</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">BNT162b2
Incidence</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">ChAdOx1
Events / person-years</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">ChAdOx1
Incidence</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr class="gt_group_heading_row">
      <td colspan="5" class="gt_group_heading">Positive SARS-CoV-2 test</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-14</td>
      <td class="gt_row gt_right">3,583 /  9,618</td>
      <td class="gt_row gt_right">0.373</td>
      <td class="gt_row gt_right">567 /  2,449</td>
      <td class="gt_row gt_right">0.232</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-28</td>
      <td class="gt_row gt_right">1,014 /  9,500</td>
      <td class="gt_row gt_right">0.107</td>
      <td class="gt_row gt_right">252 /  2,428</td>
      <td class="gt_row gt_right">0.104</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-42</td>
      <td class="gt_row gt_right">492 /  9,375</td>
      <td class="gt_row gt_right">0.052</td>
      <td class="gt_row gt_right">118 /  2,412</td>
      <td class="gt_row gt_right">0.049</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">43-70</td>
      <td class="gt_row gt_right">422 / 17,472</td>
      <td class="gt_row gt_right">0.024</td>
      <td class="gt_row gt_right">131 /  4,495</td>
      <td class="gt_row gt_right">0.029</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">71-84</td>
      <td class="gt_row gt_right">57 /  3,385</td>
      <td class="gt_row gt_right">0.017</td>
      <td class="gt_row gt_right">-- /    951</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">85-98</td>
      <td class="gt_row gt_right">8 /    218</td>
      <td class="gt_row gt_right">0.037</td>
      <td class="gt_row gt_right">-- /     63</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">5,576 / 49,567</td>
      <td class="gt_row gt_right">0.112</td>
      <td class="gt_row gt_right">1,087 / 12,798</td>
      <td class="gt_row gt_right">0.085</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="5" class="gt_group_heading">A&amp;E attendance</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-14</td>
      <td class="gt_row gt_right">1,978 /  9,644</td>
      <td class="gt_row gt_right">0.205</td>
      <td class="gt_row gt_right">551 /  2,447</td>
      <td class="gt_row gt_right">0.225</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-28</td>
      <td class="gt_row gt_right">1,890 /  9,550</td>
      <td class="gt_row gt_right">0.198</td>
      <td class="gt_row gt_right">517 /  2,425</td>
      <td class="gt_row gt_right">0.213</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-42</td>
      <td class="gt_row gt_right">1,846 /  9,379</td>
      <td class="gt_row gt_right">0.197</td>
      <td class="gt_row gt_right">526 /  2,396</td>
      <td class="gt_row gt_right">0.220</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">43-70</td>
      <td class="gt_row gt_right">3,561 / 17,328</td>
      <td class="gt_row gt_right">0.206</td>
      <td class="gt_row gt_right">1,034 /  4,423</td>
      <td class="gt_row gt_right">0.234</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">71-84</td>
      <td class="gt_row gt_right">769 /  3,325</td>
      <td class="gt_row gt_right">0.231</td>
      <td class="gt_row gt_right">217 /    927</td>
      <td class="gt_row gt_right">0.234</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">85-98</td>
      <td class="gt_row gt_right">66 /    211</td>
      <td class="gt_row gt_right">0.313</td>
      <td class="gt_row gt_right">22 /     61</td>
      <td class="gt_row gt_right">0.363</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">10,110 / 49,438</td>
      <td class="gt_row gt_right">0.205</td>
      <td class="gt_row gt_right">2,867 / 12,679</td>
      <td class="gt_row gt_right">0.226</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="5" class="gt_group_heading">COVID-19 hospitalisation</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-14</td>
      <td class="gt_row gt_right">87 /  9,679</td>
      <td class="gt_row gt_right">0.009</td>
      <td class="gt_row gt_right">-- /  2,459</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-28</td>
      <td class="gt_row gt_right">31 /  9,655</td>
      <td class="gt_row gt_right">0.003</td>
      <td class="gt_row gt_right">17 /  2,455</td>
      <td class="gt_row gt_right">0.007</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-42</td>
      <td class="gt_row gt_right">-- /  9,554</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  2,445</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">43-70</td>
      <td class="gt_row gt_right">-- / 17,849</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,568</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">71-84</td>
      <td class="gt_row gt_right">-- /  3,473</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /    971</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">85-98</td>
      <td class="gt_row gt_right">0 /    232</td>
      <td class="gt_row gt_right">0</td>
      <td class="gt_row gt_right">0 /     66</td>
      <td class="gt_row gt_right">0</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">129 / 50,441</td>
      <td class="gt_row gt_right">0.003</td>
      <td class="gt_row gt_right">27 / 12,964</td>
      <td class="gt_row gt_right">0.002</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="5" class="gt_group_heading">COVID-19 death</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-14</td>
      <td class="gt_row gt_right">-- /  9,679</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  2,459</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-28</td>
      <td class="gt_row gt_right">-- /  9,659</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  2,455</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-42</td>
      <td class="gt_row gt_right">0 /  9,559</td>
      <td class="gt_row gt_right">0</td>
      <td class="gt_row gt_right">-- /  2,446</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">43-70</td>
      <td class="gt_row gt_right">0 / 17,858</td>
      <td class="gt_row gt_right">0</td>
      <td class="gt_row gt_right">0 /  4,570</td>
      <td class="gt_row gt_right">0</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">71-84</td>
      <td class="gt_row gt_right">0 /  3,475</td>
      <td class="gt_row gt_right">0</td>
      <td class="gt_row gt_right">0 /    972</td>
      <td class="gt_row gt_right">0</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">85-98</td>
      <td class="gt_row gt_right">0 /    232</td>
      <td class="gt_row gt_right">0</td>
      <td class="gt_row gt_right">0 /     66</td>
      <td class="gt_row gt_right">0</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">-- / 50,463</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- / 12,968</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="5" class="gt_group_heading">Any death</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-14</td>
      <td class="gt_row gt_right">-- /  9,679</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  2,459</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-28</td>
      <td class="gt_row gt_right">6 /  9,659</td>
      <td class="gt_row gt_right">&lt;0.001</td>
      <td class="gt_row gt_right">-- /  2,455</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-42</td>
      <td class="gt_row gt_right">-- /  9,559</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  2,446</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">43-70</td>
      <td class="gt_row gt_right">8 / 17,858</td>
      <td class="gt_row gt_right">&lt;0.001</td>
      <td class="gt_row gt_right">-- /  4,570</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">71-84</td>
      <td class="gt_row gt_right">-- /  3,475</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">0 /    972</td>
      <td class="gt_row gt_right">0</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">85-98</td>
      <td class="gt_row gt_right">0 /    232</td>
      <td class="gt_row gt_right">0</td>
      <td class="gt_row gt_right">0 /     66</td>
      <td class="gt_row gt_right">0</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">18 / 50,463</td>
      <td class="gt_row gt_right">&lt;0.001</td>
      <td class="gt_row gt_right">-- / 12,968</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
  </tbody>
  
  
</table></div><!--/html_preserve-->

## Comparative effectiveness



Figure 3 shows, for each outcome based on the fully adjusted model, the time-dependent hazard ratio for ChAdOx1 versus BNT162b2, and one minus the risk-adjusted cumulative incidence, and the absolute risk difference. Similar figures for the non-fully-adjusted models are presented in supplementary materials.

At 6 weeks post-vaccination, the absolute risk difference (ChAdOx1 - BNT162b2) for a positive SARS-CoV-2 test was 0.05 per 1000 people, for A&E attendances was -0.41 and for COVID-19 hospital admissions was -0.03 per 1000 people.

#### Figure 2: Comparative effectivevess

<img src="/workspace/output/report/figures/comp-1.png" width="90%" />

# Discussion

This observational study of almost 1/3 million health and social care workers living in England found no significant differences in rates of COVID-19-related events between those receiving a first dose of BNT162b2 or ChAdOx1. For hospitalisation, it was not possible to rule-out large differences in the risk due to uncertainty in the effect estimates. There is a clear leveling-off of the event rates after around 3 weeks, consistent with the expected time-to-onset of vaccine-induced immunity of around 2 weeks plus the delay from infection to a positive test.

## Strengths and weaknesses

We used routinely-collected health records with comprehensive coverage of primary care, hospital admissions, COVID-19 testing, COVID-19 vaccination, and death registrations to study vaccinated health and social care workers. This group were eligible for vaccination at the start of the UK's vaccination programme due to exposure to higher viral loads and the need to reduce enforced absences in essential healthcare workers during a global pandemic. They are the only early vaccinees who are relatively young and healthy, and were vaccinated during a period where infection rates were high and both vaccines were being administered. This provides a rare opportunity to study comparative effectiveness with sufficient power under conditions that, to some extent, approximate random vaccine allocation. However, some limitations remain.

We were unable to fully investigate differences in protection against severe disease, in large part thanks to clear protective benefits of both vaccines, reducing the absolute numbers of events, and therefore statistical power, in the studied cohort.

Despite reasonable balance of vaccine allocation across baseline characteristics and adjustment for a range of potential confounders, the possibility of unmeasured confounding remains. The cold-chain storage requirements of BNT162b2 meant that it is more likely to have be administered in Acute NHS Trusts and other large vaccination centres, and is thus a potential confounder for instance due to differences in exposure to risk across these settings. Though we adjusted for region, rurality, and deprivation, we were unable to directly account for occupational differences that may affect exposure risk and vaccine type.

The dominant circulating variant during the period of study was the Alpha variant, which has since been supplanted by other strains, in particular the Delta variant which we did not consider here.

## Findings in context

A number of studies estimate COVID-19 vaccine effectiveness in observational data using unvaccinated controls <!--# [@cabezas2021; @vasileiou2021]  -->. [describe pfizer versus AZ findings]

Such designs are extremely vulnerable to confounding for example due to vaccine prioritisation and eligiblity policies, as well as vaccine access and acceptance, that cause substantial imbalance between vaccinated and unvaccinated groups. Many of these biases can be bypassed when making direct comparisons between recipients of different vaccine types. To our knowledge, the present study is the first to assess effectiveness of the BNT162b2 and ChAdOx1 vaccines in a head-to-head comparison. We found...

<!--# Inferring comparative effectiveness from these studies is possible by calculating the ratio of 1 minus the vaccine effectiveness for each vaccine: EAVE-II estimated VE in 18-64 age group in 5th week to be 92% for BNT162b2 and 100% for ChAdOx1, = HR=0.00; EAVE-II estimated VE in 65-79 age group in 4th week to be 91% for BNT162b2 and 68% for ChAdOx1, = HR=3.56; EAVE-II estimated VE in 80+ age group in 4th week to be 88% for BNT162b2 and 81% for ChAdOx1, = HR=1.58.-->

## Conclusion

This study found no substantial difference in the rates of COVID-19-related events following vaccination with BNT162b2 or ChAdOx1 in a cohort of health and social care workers in England. Further studies are needed to assess comparative effectiveness in newer, more prevalent variants.

## References
