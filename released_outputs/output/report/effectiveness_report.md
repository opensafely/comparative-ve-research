---
title: "Comparative vaccine effectiveness (ChAdOx1 versus BNT162b2) in Health and Social Care workers"
output:
  html_document:
    self_contained: TRUE
    keep_md: TRUE
  #  code_folding: hide
    #keep_md: yes
  #pdf_document: default
  # md_document:
  #   variant: gfm
  github_document:
    keep_html: TRUE
---




# Introduction

The COVID-19 global pandemic has prompted the rapid development and delivery of vaccines to combat the disease. Following demonstration of high safety and efficacy against symptomatic and severe disease in phase-III randomised clinical trials (RCTs), two vaccines have been approved and widely administered as part of the national vaccination programme in the United Kingdom: the Pfizer-BioNTech BNT162b2 mRNA COVID-19 vaccine (*BNT162b2*) and the Oxford-AstraZeneca ChAdOx1 nCoV-19 vaccine (*ChAdOx1*). To date, there have been no RCTs that have directly compared these two vaccines to estimate the relative efficacy against COVID-19 infection and disease in the same cohort. The concurrent roll-out of BNT162b2 and ChAdOx1 within the same UK population provides an opportunity to emulate such a trial using observational data.

COVID-19 vaccination in the UK has been prioritised based on the risk of infection and subsequent severity of disease. Patient-facing health and social care workers (HCWs) were amongst the first groups eligible for vaccination due to the high occupational exposure to the SARS-CoV-2 virus, and many were vaccinated during the period where both vaccines were widely used (04 January 2021 onwards). This study assessed the comparative effectiveness of one dose of ChAdOx1 with one dose of BNT162b2 in HCWs, using the OpenSAFELY-TPP database covering around 40% of England's population. 

The code and data for this report can be found at the OpenSafely [comparative-ve-research GitHub repository](https://github.com/opensafely/comparative-ve-research). 

# Methods

## Study population

Vaccinated HCWs were included in the study if: 

* registered at a GP practice using TPP's SystmOne clinical information system on the day of they received their first dose of BNT162b2 or ChAdOx1; 
* the date of vaccination was between 04 January and 28 February 2021 (55 days), a period when both vaccines were being administered widely;
* aged between 18 and 64 inclusive; 
* not classed as Clinically Extremely Vulnerable, as set out by government guidance, at the time of vaccination; 
* information on sex, ethnicity, deprivation, and geographical region was known.

Study participants were followed up for 14 weeks from the date of the first dose, or until the first of: 

* death or deregistration;
* Second vaccine dose;
* The study end date, 25 April 2021.

### Identifying vaccinated HCWs

Those vaccinated as part of England's national vaccination programme (for example not including vaccine trial participants) are asked whether they work in health or social care. This information is sent to OpenSAFELY-TPP from NHS Digital's COVID-19 data store.

Note -- many of those flagged as HCWs do not have a vaccination record, which shouldn't be the case if the question was asked as part of the vaccination process. This needs further investigation.

### Outcomes

* SARS-CoV-2 infection, as identified via SGSS records. Both PCR and LFT tests are included.
* Unplanned COVID-19-related hospitalisation via HES records. ICD-10 codes are used to identify COVID-19-related admissions. 
* Unplanned COVID-19-related ICU admission via HES records. ICD-10 codes are used to identify COVID-19-related admissions. 
* COVID-19-related death via death registration records. With COVID-19 ICD-10 codes anywhere on the death certificate (i.e., as an underlying or contributing cause of death)

## Statistical Analysis

The aim is to estimate comparative vaccine effectiveness, i.e., the relative hazard of each outcome for ChAdOx1 versus BNT162b2 vaccine recipients. The effect is permitted to vary by time since vaccination, to account for the potential differences in vaccine protection over time between the two brands. 

Patient characteristics used for adjustment include: age, sex, deprivation, ethnicity, NHS region, clinically “at risk” (but not clinically extremely vulnerable) as per national prioritisation guidelines, asthma, number of previous SARS-CoV-2 tests (via SGSS), rurality, evidence of prior covid infection (positive test or COVID-19 hospitalisation), number of recorded comorbidities, severe mental illness. All characteristics are ascertained as at the time of vaccination. 

NHS regions are used as a stratification variable to account for geographical variation in event rates for the outcomes of interest, for example due to changes in local infection rates. 

### Time-dependent Cox models
Time-dependent Cox models are used to estimate the time-varying effects for each vaccine type. Time zero is the date of vaccination, i.e., using a treatment time-scale. Outcome events occurring on the same day as vaccination are included in follow-up. Date of vaccination is included as an additional baseline covariate using a restricted cubic spline with knots at the first and second tertile, plus boundary knots. Here, follow-up time is stratified into weekly intervals with the vaccine-specific effect estimated within each time-strata. In `R`'s `coxph` function, this is modelled using `vaccine_type:strata(week_since_first_dose)`.

### Pooled Logistic Regression models

We emulate the Cox model described above using pooled logistic regression (PLR), with the outcome risk estimated at daily intervals. These models include a restricted cubic spline with 3 degrees of freedom on the log of the timescale (time since vaccination), interacted with vaccine type. The PLR models serve two purposes. Firstly, a continuous-time estimate of comparative effectiveness, as opposed to the piecewise-linear approximation above, is obtained. Secondly, the risk-adjusted survival rates for each vaccine type are obtained using the parametric g-formula. This is the average risk for each day of follow-up predicted by the PLR model, under the (complimentary counterfactual) assumption that every patient received the BNT162b2 vaccine or that every patient received the ChAdOx1 vaccine. 

Confidence intervals for the risk-adjusted survival rates are calculated using the delta method (i.e, a first-order Taylor series approximation of the variance of the cumulative incidence).

The person-time dataset needed to fit the PLR model is large and leads to infeasible RAM requirements / computation time. To deal with this, a sampling strategy is used such that all those who experienced an outcome and a random sample of 50000 who did not experience the outcome are selected for the models. The models are weighted to recover the characteristics of the complete dataset. This weighting is also applied to the risk-adjusted survival curves. 


# Results

Note all counts below 6 are redacted and survival estimates are rounded for disclosure control.

## Flowchart


<!--html_preserve--><style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#sugaixmjfz .gt_table {
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

#sugaixmjfz .gt_heading {
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

#sugaixmjfz .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#sugaixmjfz .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 4px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#sugaixmjfz .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#sugaixmjfz .gt_col_headings {
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

#sugaixmjfz .gt_col_heading {
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

#sugaixmjfz .gt_column_spanner_outer {
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

#sugaixmjfz .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#sugaixmjfz .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#sugaixmjfz .gt_column_spanner {
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

#sugaixmjfz .gt_group_heading {
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

#sugaixmjfz .gt_empty_group_heading {
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

#sugaixmjfz .gt_from_md > :first-child {
  margin-top: 0;
}

#sugaixmjfz .gt_from_md > :last-child {
  margin-bottom: 0;
}

#sugaixmjfz .gt_row {
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

#sugaixmjfz .gt_stub {
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

#sugaixmjfz .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#sugaixmjfz .gt_first_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#sugaixmjfz .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#sugaixmjfz .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#sugaixmjfz .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#sugaixmjfz .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#sugaixmjfz .gt_footnotes {
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

#sugaixmjfz .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 4px;
}

#sugaixmjfz .gt_sourcenotes {
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

#sugaixmjfz .gt_sourcenote {
  font-size: 90%;
  padding: 4px;
}

#sugaixmjfz .gt_left {
  text-align: left;
}

#sugaixmjfz .gt_center {
  text-align: center;
}

#sugaixmjfz .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#sugaixmjfz .gt_font_normal {
  font-weight: normal;
}

#sugaixmjfz .gt_font_bold {
  font-weight: bold;
}

#sugaixmjfz .gt_font_italic {
  font-style: italic;
}

#sugaixmjfz .gt_super {
  font-size: 65%;
}

#sugaixmjfz .gt_footnote_marks {
  font-style: italic;
  font-size: 65%;
}
</style>
<div id="sugaixmjfz" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;"><table class="gt_table">
  
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
      <td class="gt_row gt_left">All HCWs aged 18-64
  receiving first dose of BNT162b2 or ChAdOx1
  between 4 January and 28 February 2021</td>
      <td class="gt_row gt_right">361,005</td>
      <td class="gt_row gt_right">-</td>
      <td class="gt_row gt_right">-</td>
      <td class="gt_row gt_right">100.0&percnt;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">with no missing demographic information</td>
      <td class="gt_row gt_right">326,336</td>
      <td class="gt_row gt_right">34,669</td>
      <td class="gt_row gt_right">9.6&percnt;</td>
      <td class="gt_row gt_right">90.4&percnt;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">who are not clinically extremely vulnerable</td>
      <td class="gt_row gt_right">316,449</td>
      <td class="gt_row gt_right">9,887</td>
      <td class="gt_row gt_right">3.0&percnt;</td>
      <td class="gt_row gt_right">87.7&percnt;</td>
    </tr>
  </tbody>
  
  
</table></div><!--/html_preserve-->


## Baseline demographics

<!--html_preserve--><style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#qzautwskba .gt_table {
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

#qzautwskba .gt_heading {
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

#qzautwskba .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#qzautwskba .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 4px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#qzautwskba .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#qzautwskba .gt_col_headings {
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

#qzautwskba .gt_col_heading {
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

#qzautwskba .gt_column_spanner_outer {
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

#qzautwskba .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#qzautwskba .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#qzautwskba .gt_column_spanner {
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

#qzautwskba .gt_group_heading {
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

#qzautwskba .gt_empty_group_heading {
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

#qzautwskba .gt_from_md > :first-child {
  margin-top: 0;
}

#qzautwskba .gt_from_md > :last-child {
  margin-bottom: 0;
}

#qzautwskba .gt_row {
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

#qzautwskba .gt_stub {
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

#qzautwskba .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#qzautwskba .gt_first_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#qzautwskba .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#qzautwskba .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#qzautwskba .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#qzautwskba .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#qzautwskba .gt_footnotes {
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

#qzautwskba .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 4px;
}

#qzautwskba .gt_sourcenotes {
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

#qzautwskba .gt_sourcenote {
  font-size: 90%;
  padding: 4px;
}

#qzautwskba .gt_left {
  text-align: left;
}

#qzautwskba .gt_center {
  text-align: center;
}

#qzautwskba .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#qzautwskba .gt_font_normal {
  font-weight: normal;
}

#qzautwskba .gt_font_bold {
  font-weight: bold;
}

#qzautwskba .gt_font_italic {
  font-style: italic;
}

#qzautwskba .gt_super {
  font-size: 65%;
}

#qzautwskba .gt_footnote_marks {
  font-style: italic;
  font-size: 65%;
}
</style>
<div id="qzautwskba" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;"><table class="gt_table">
  
  <thead class="gt_col_headings">
    <tr>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1"><strong>Characteristic</strong></th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1"><strong>BNT162b2</strong>, N = 252,403</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1"><strong>ChAdOx1</strong>, N = 64,046</th>
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
      <td class="gt_row gt_center">40,901 (16%)</td>
      <td class="gt_row gt_center">10,415 (16%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">30s</td>
      <td class="gt_row gt_center">59,361 (24%)</td>
      <td class="gt_row gt_center">14,685 (23%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">40s</td>
      <td class="gt_row gt_center">64,401 (26%)</td>
      <td class="gt_row gt_center">16,247 (25%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">50s</td>
      <td class="gt_row gt_center">67,586 (27%)</td>
      <td class="gt_row gt_center">17,518 (27%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">60-64</td>
      <td class="gt_row gt_center">20,154 (8.0%)</td>
      <td class="gt_row gt_center">5,181 (8.1%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Sex</td>
      <td class="gt_row gt_center"></td>
      <td class="gt_row gt_center"></td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Female</td>
      <td class="gt_row gt_center">199,567 (79%)</td>
      <td class="gt_row gt_center">49,200 (77%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Male</td>
      <td class="gt_row gt_center">52,836 (21%)</td>
      <td class="gt_row gt_center">14,846 (23%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Ethnicity</td>
      <td class="gt_row gt_center"></td>
      <td class="gt_row gt_center"></td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">White</td>
      <td class="gt_row gt_center">210,869 (84%)</td>
      <td class="gt_row gt_center">54,156 (85%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Black</td>
      <td class="gt_row gt_center">8,486 (3.4%)</td>
      <td class="gt_row gt_center">3,158 (4.9%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">South Asian</td>
      <td class="gt_row gt_center">23,059 (9.1%)</td>
      <td class="gt_row gt_center">4,680 (7.3%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Mixed</td>
      <td class="gt_row gt_center">3,847 (1.5%)</td>
      <td class="gt_row gt_center">1,004 (1.6%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Other</td>
      <td class="gt_row gt_center">6,142 (2.4%)</td>
      <td class="gt_row gt_center">1,048 (1.6%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">IMD</td>
      <td class="gt_row gt_center"></td>
      <td class="gt_row gt_center"></td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">1 most deprived</td>
      <td class="gt_row gt_center">36,736 (15%)</td>
      <td class="gt_row gt_center">10,276 (16%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">2</td>
      <td class="gt_row gt_center">47,143 (19%)</td>
      <td class="gt_row gt_center">12,086 (19%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">3</td>
      <td class="gt_row gt_center">55,643 (22%)</td>
      <td class="gt_row gt_center">13,725 (21%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">4</td>
      <td class="gt_row gt_center">57,359 (23%)</td>
      <td class="gt_row gt_center">14,320 (22%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">5 least deprived</td>
      <td class="gt_row gt_center">55,522 (22%)</td>
      <td class="gt_row gt_center">13,639 (21%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Region</td>
      <td class="gt_row gt_center"></td>
      <td class="gt_row gt_center"></td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">North East and Yorkshire</td>
      <td class="gt_row gt_center">53,300 (21%)</td>
      <td class="gt_row gt_center">16,366 (26%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">East of England</td>
      <td class="gt_row gt_center">62,176 (25%)</td>
      <td class="gt_row gt_center">11,822 (18%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Midlands</td>
      <td class="gt_row gt_center">50,406 (20%)</td>
      <td class="gt_row gt_center">17,205 (27%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">South West</td>
      <td class="gt_row gt_center">35,988 (14%)</td>
      <td class="gt_row gt_center">5,041 (7.9%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">North West</td>
      <td class="gt_row gt_center">23,565 (9.3%)</td>
      <td class="gt_row gt_center">7,851 (12%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">London</td>
      <td class="gt_row gt_center">10,365 (4.1%)</td>
      <td class="gt_row gt_center">2,144 (3.3%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">South East</td>
      <td class="gt_row gt_center">16,603 (6.6%)</td>
      <td class="gt_row gt_center">3,617 (5.6%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Day of vaccination</td>
      <td class="gt_row gt_center">12 (7, 18)</td>
      <td class="gt_row gt_center">19 (13, 33)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Body Mass Index</td>
      <td class="gt_row gt_center"></td>
      <td class="gt_row gt_center"></td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Not obese</td>
      <td class="gt_row gt_center">197,789 (78%)</td>
      <td class="gt_row gt_center">48,666 (76%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Obese I (30-34.9)</td>
      <td class="gt_row gt_center">31,093 (12%)</td>
      <td class="gt_row gt_center">8,605 (13%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Obese II (35-39.9)</td>
      <td class="gt_row gt_center">14,277 (5.7%)</td>
      <td class="gt_row gt_center">4,047 (6.3%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Obese III (40+)</td>
      <td class="gt_row gt_center">9,244 (3.7%)</td>
      <td class="gt_row gt_center">2,728 (4.3%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Heart failure</td>
      <td class="gt_row gt_center">630 (0.2%)</td>
      <td class="gt_row gt_center">200 (0.3%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Other heart disease</td>
      <td class="gt_row gt_center">4,629 (1.8%)</td>
      <td class="gt_row gt_center">1,294 (2.0%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Diabetes</td>
      <td class="gt_row gt_center">13,918 (5.5%)</td>
      <td class="gt_row gt_center">3,806 (5.9%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Chronic liver disease</td>
      <td class="gt_row gt_center">645 (0.3%)</td>
      <td class="gt_row gt_center">231 (0.4%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">COPD</td>
      <td class="gt_row gt_center">1,290 (0.5%)</td>
      <td class="gt_row gt_center">347 (0.5%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Other respiratory conditions</td>
      <td class="gt_row gt_center">740 (0.3%)</td>
      <td class="gt_row gt_center">236 (0.4%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Lung Cancer</td>
      <td class="gt_row gt_center">53 (&lt;0.1%)</td>
      <td class="gt_row gt_center">9 (&lt;0.1%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Haematological cancer</td>
      <td class="gt_row gt_center">435 (0.2%)</td>
      <td class="gt_row gt_center">119 (0.2%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Cancer excl. lung, haemo</td>
      <td class="gt_row gt_center">6,538 (2.6%)</td>
      <td class="gt_row gt_center">1,627 (2.5%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Immunosuppressed</td>
      <td class="gt_row gt_center">5,402 (2.1%)</td>
      <td class="gt_row gt_center">1,292 (2.0%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Other neurological conditions</td>
      <td class="gt_row gt_center">1,229 (0.5%)</td>
      <td class="gt_row gt_center">331 (0.5%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Learning disabilities</td>
      <td class="gt_row gt_center">360 (0.1%)</td>
      <td class="gt_row gt_center">104 (0.2%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Serious mental illness</td>
      <td class="gt_row gt_center">1,604 (0.6%)</td>
      <td class="gt_row gt_center">538 (0.8%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Morbidity count</td>
      <td class="gt_row gt_center"></td>
      <td class="gt_row gt_center"></td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">0</td>
      <td class="gt_row gt_center">201,930 (80%)</td>
      <td class="gt_row gt_center">50,236 (78%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">1</td>
      <td class="gt_row gt_center">41,413 (16%)</td>
      <td class="gt_row gt_center">11,161 (17%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">2</td>
      <td class="gt_row gt_center">8,009 (3.2%)</td>
      <td class="gt_row gt_center">2,328 (3.6%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">3+</td>
      <td class="gt_row gt_center">1,051 (0.4%)</td>
      <td class="gt_row gt_center">321 (0.5%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Prior SARS-CoV-2 infection</td>
      <td class="gt_row gt_center">27,205 (11%)</td>
      <td class="gt_row gt_center">9,054 (14%)</td>
    </tr>
  </tbody>
  
  
</table></div><!--/html_preserve-->

## Vaccination dates

<img src="/workspace/output/report/figures/vaxdate-1.png" width="80%" />  

## Event rates

<!--html_preserve--><style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#thswjtuoys .gt_table {
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

#thswjtuoys .gt_heading {
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

#thswjtuoys .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#thswjtuoys .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 4px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#thswjtuoys .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#thswjtuoys .gt_col_headings {
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

#thswjtuoys .gt_col_heading {
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

#thswjtuoys .gt_column_spanner_outer {
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

#thswjtuoys .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#thswjtuoys .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#thswjtuoys .gt_column_spanner {
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

#thswjtuoys .gt_group_heading {
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

#thswjtuoys .gt_empty_group_heading {
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

#thswjtuoys .gt_from_md > :first-child {
  margin-top: 0;
}

#thswjtuoys .gt_from_md > :last-child {
  margin-bottom: 0;
}

#thswjtuoys .gt_row {
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

#thswjtuoys .gt_stub {
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

#thswjtuoys .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#thswjtuoys .gt_first_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#thswjtuoys .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#thswjtuoys .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#thswjtuoys .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#thswjtuoys .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#thswjtuoys .gt_footnotes {
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

#thswjtuoys .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 4px;
}

#thswjtuoys .gt_sourcenotes {
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

#thswjtuoys .gt_sourcenote {
  font-size: 90%;
  padding: 4px;
}

#thswjtuoys .gt_left {
  text-align: left;
}

#thswjtuoys .gt_center {
  text-align: center;
}

#thswjtuoys .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#thswjtuoys .gt_font_normal {
  font-weight: normal;
}

#thswjtuoys .gt_font_bold {
  font-weight: bold;
}

#thswjtuoys .gt_font_italic {
  font-style: italic;
}

#thswjtuoys .gt_super {
  font-size: 65%;
}

#thswjtuoys .gt_footnote_marks {
  font-style: italic;
  font-size: 65%;
}
</style>
<div id="thswjtuoys" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;"><table class="gt_table">
  
  <thead class="gt_col_headings">
    <tr>
      <th class="gt_col_heading gt_center gt_columns_bottom_border" rowspan="2" colspan="1">Time since first dose</th>
      <th class="gt_center gt_columns_top_border gt_column_spanner_outer" rowspan="1" colspan="2">
        <span class="gt_column_spanner">BNT162b2</span>
      </th>
      <th class="gt_center gt_columns_top_border gt_column_spanner_outer" rowspan="1" colspan="2">
        <span class="gt_column_spanner">ChAdOx1</span>
      </th>
      <th class="gt_col_heading gt_center gt_columns_bottom_border" rowspan="2" colspan="1">Incidence rate ratio</th>
      <th class="gt_col_heading gt_center gt_columns_bottom_border" rowspan="2" colspan="1">95% CI</th>
    </tr>
    <tr>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1">Rate/year</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1">Events / person-years</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1">Incidence</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1">Events / person-years</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr class="gt_group_heading_row">
      <td colspan="7" class="gt_group_heading">SARS-CoV-2 test</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-7</td>
      <td class="gt_row gt_right">3.72</td>
      <td class="gt_row gt_right">17,435 /  4,685</td>
      <td class="gt_row gt_right">3.37</td>
      <td class="gt_row gt_right">4,007 /  1,190</td>
      <td class="gt_row gt_right">0.90</td>
      <td class="gt_row gt_right">(0.87-0.94)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">2.51</td>
      <td class="gt_row gt_right">11,043 /  4,397</td>
      <td class="gt_row gt_right">1.71</td>
      <td class="gt_row gt_right">1,938 /  1,132</td>
      <td class="gt_row gt_right">0.68</td>
      <td class="gt_row gt_right">(0.65-0.72)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">1.56</td>
      <td class="gt_row gt_right">6,602 /  4,225</td>
      <td class="gt_row gt_right">1.20</td>
      <td class="gt_row gt_right">1,316 /  1,100</td>
      <td class="gt_row gt_right">0.77</td>
      <td class="gt_row gt_right">(0.72-0.81)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">1.13</td>
      <td class="gt_row gt_right">4,654 /  4,106</td>
      <td class="gt_row gt_right">0.99</td>
      <td class="gt_row gt_right">1,069 /  1,076</td>
      <td class="gt_row gt_right">0.88</td>
      <td class="gt_row gt_right">(0.82-0.94)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">0.94</td>
      <td class="gt_row gt_right">3,750 /  4,000</td>
      <td class="gt_row gt_right">0.83</td>
      <td class="gt_row gt_right">874 /  1,056</td>
      <td class="gt_row gt_right">0.88</td>
      <td class="gt_row gt_right">(0.82-0.95)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36-42</td>
      <td class="gt_row gt_right">0.87</td>
      <td class="gt_row gt_right">3,405 /  3,906</td>
      <td class="gt_row gt_right">0.73</td>
      <td class="gt_row gt_right">756 /  1,037</td>
      <td class="gt_row gt_right">0.84</td>
      <td class="gt_row gt_right">(0.77-0.91)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">43-70</td>
      <td class="gt_row gt_right">0.72</td>
      <td class="gt_row gt_right">10,160 / 14,126</td>
      <td class="gt_row gt_right">0.78</td>
      <td class="gt_row gt_right">2,913 /  3,745</td>
      <td class="gt_row gt_right">1.08</td>
      <td class="gt_row gt_right">(1.04-1.13)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">71+</td>
      <td class="gt_row gt_right">0.68</td>
      <td class="gt_row gt_right">1,903 /  2,780</td>
      <td class="gt_row gt_right">0.62</td>
      <td class="gt_row gt_right">496 /    800</td>
      <td class="gt_row gt_right">0.91</td>
      <td class="gt_row gt_right">(0.82-1.00)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">1.40</td>
      <td class="gt_row gt_right">58,952 / 42,225</td>
      <td class="gt_row gt_right">1.20</td>
      <td class="gt_row gt_right">13,369 / 11,136</td>
      <td class="gt_row gt_right">0.86</td>
      <td class="gt_row gt_right">(0.84-0.88)</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="7" class="gt_group_heading">Positive SARS-CoV-2 test</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-7</td>
      <td class="gt_row gt_right">0.36</td>
      <td class="gt_row gt_right">1,722 /  4,824</td>
      <td class="gt_row gt_right">0.23</td>
      <td class="gt_row gt_right">280 /  1,225</td>
      <td class="gt_row gt_right">0.64</td>
      <td class="gt_row gt_right">(0.56-0.73)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">0.39</td>
      <td class="gt_row gt_right">1,857 /  4,781</td>
      <td class="gt_row gt_right">0.23</td>
      <td class="gt_row gt_right">284 /  1,218</td>
      <td class="gt_row gt_right">0.60</td>
      <td class="gt_row gt_right">(0.53-0.68)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">0.14</td>
      <td class="gt_row gt_right">659 /  4,754</td>
      <td class="gt_row gt_right">0.14</td>
      <td class="gt_row gt_right">171 /  1,212</td>
      <td class="gt_row gt_right">1.02</td>
      <td class="gt_row gt_right">(0.85-1.21)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">0.07</td>
      <td class="gt_row gt_right">350 /  4,733</td>
      <td class="gt_row gt_right">0.07</td>
      <td class="gt_row gt_right">80 /  1,209</td>
      <td class="gt_row gt_right">0.89</td>
      <td class="gt_row gt_right">(0.69-1.14)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">0.05</td>
      <td class="gt_row gt_right">252 /  4,698</td>
      <td class="gt_row gt_right">0.05</td>
      <td class="gt_row gt_right">63 /  1,206</td>
      <td class="gt_row gt_right">0.97</td>
      <td class="gt_row gt_right">(0.73-1.29)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36-42</td>
      <td class="gt_row gt_right">0.05</td>
      <td class="gt_row gt_right">240 /  4,664</td>
      <td class="gt_row gt_right">0.04</td>
      <td class="gt_row gt_right">54 /  1,200</td>
      <td class="gt_row gt_right">0.87</td>
      <td class="gt_row gt_right">(0.64-1.18)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">43-70</td>
      <td class="gt_row gt_right">0.02</td>
      <td class="gt_row gt_right">422 / 17,449</td>
      <td class="gt_row gt_right">0.03</td>
      <td class="gt_row gt_right">129 /  4,483</td>
      <td class="gt_row gt_right">1.19</td>
      <td class="gt_row gt_right">(0.97-1.45)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">71+</td>
      <td class="gt_row gt_right">0.02</td>
      <td class="gt_row gt_right">64 /  3,598</td>
      <td class="gt_row gt_right">0.02</td>
      <td class="gt_row gt_right">19 /  1,011</td>
      <td class="gt_row gt_right">1.06</td>
      <td class="gt_row gt_right">(0.60-1.79)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">0.11</td>
      <td class="gt_row gt_right">5,566 / 49,500</td>
      <td class="gt_row gt_right">0.08</td>
      <td class="gt_row gt_right">1,080 / 12,765</td>
      <td class="gt_row gt_right">0.75</td>
      <td class="gt_row gt_right">(0.70-0.80)</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="7" class="gt_group_heading">A&amp;E attendance</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-7</td>
      <td class="gt_row gt_right">0.20</td>
      <td class="gt_row gt_right">965 /  4,826</td>
      <td class="gt_row gt_right">0.27</td>
      <td class="gt_row gt_right">334 /  1,224</td>
      <td class="gt_row gt_right">1.37</td>
      <td class="gt_row gt_right">(1.20-1.55)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">0.21</td>
      <td class="gt_row gt_right">1,013 /  4,805</td>
      <td class="gt_row gt_right">0.18</td>
      <td class="gt_row gt_right">217 /  1,218</td>
      <td class="gt_row gt_right">0.85</td>
      <td class="gt_row gt_right">(0.73-0.98)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">0.20</td>
      <td class="gt_row gt_right">958 /  4,784</td>
      <td class="gt_row gt_right">0.23</td>
      <td class="gt_row gt_right">276 /  1,212</td>
      <td class="gt_row gt_right">1.14</td>
      <td class="gt_row gt_right">(0.99-1.30)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">0.19</td>
      <td class="gt_row gt_right">926 /  4,753</td>
      <td class="gt_row gt_right">0.20</td>
      <td class="gt_row gt_right">239 /  1,206</td>
      <td class="gt_row gt_right">1.02</td>
      <td class="gt_row gt_right">(0.88-1.17)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">0.20</td>
      <td class="gt_row gt_right">953 /  4,707</td>
      <td class="gt_row gt_right">0.22</td>
      <td class="gt_row gt_right">267 /  1,199</td>
      <td class="gt_row gt_right">1.10</td>
      <td class="gt_row gt_right">(0.96-1.26)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36-42</td>
      <td class="gt_row gt_right">0.19</td>
      <td class="gt_row gt_right">891 /  4,659</td>
      <td class="gt_row gt_right">0.22</td>
      <td class="gt_row gt_right">258 /  1,190</td>
      <td class="gt_row gt_right">1.13</td>
      <td class="gt_row gt_right">(0.98-1.30)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">43-70</td>
      <td class="gt_row gt_right">0.21</td>
      <td class="gt_row gt_right">3,549 / 17,305</td>
      <td class="gt_row gt_right">0.24</td>
      <td class="gt_row gt_right">1,037 /  4,411</td>
      <td class="gt_row gt_right">1.15</td>
      <td class="gt_row gt_right">(1.07-1.23)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">71+</td>
      <td class="gt_row gt_right">0.24</td>
      <td class="gt_row gt_right">830 /  3,531</td>
      <td class="gt_row gt_right">0.24</td>
      <td class="gt_row gt_right">240 /    985</td>
      <td class="gt_row gt_right">1.04</td>
      <td class="gt_row gt_right">(0.89-1.20)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">0.20</td>
      <td class="gt_row gt_right">10,085 / 49,370</td>
      <td class="gt_row gt_right">0.23</td>
      <td class="gt_row gt_right">2,868 / 12,646</td>
      <td class="gt_row gt_right">1.11</td>
      <td class="gt_row gt_right">(1.06-1.16)</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="7" class="gt_group_heading">Unplanned hospitalisation</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-7</td>
      <td class="gt_row gt_right">0.04</td>
      <td class="gt_row gt_right">199 /  4,833</td>
      <td class="gt_row gt_right">0.05</td>
      <td class="gt_row gt_right">66 /  1,226</td>
      <td class="gt_row gt_right">1.31</td>
      <td class="gt_row gt_right">(0.97-1.74)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">0.06</td>
      <td class="gt_row gt_right">281 /  4,825</td>
      <td class="gt_row gt_right">0.05</td>
      <td class="gt_row gt_right">56 /  1,224</td>
      <td class="gt_row gt_right">0.79</td>
      <td class="gt_row gt_right">(0.58-1.05)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">0.05</td>
      <td class="gt_row gt_right">248 /  4,818</td>
      <td class="gt_row gt_right">0.07</td>
      <td class="gt_row gt_right">87 /  1,222</td>
      <td class="gt_row gt_right">1.38</td>
      <td class="gt_row gt_right">(1.07-1.77)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">0.06</td>
      <td class="gt_row gt_right">277 /  4,801</td>
      <td class="gt_row gt_right">0.05</td>
      <td class="gt_row gt_right">61 /  1,220</td>
      <td class="gt_row gt_right">0.87</td>
      <td class="gt_row gt_right">(0.65-1.15)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">0.05</td>
      <td class="gt_row gt_right">249 /  4,767</td>
      <td class="gt_row gt_right">0.06</td>
      <td class="gt_row gt_right">71 /  1,216</td>
      <td class="gt_row gt_right">1.12</td>
      <td class="gt_row gt_right">(0.85-1.46)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36-42</td>
      <td class="gt_row gt_right">0.06</td>
      <td class="gt_row gt_right">265 /  4,732</td>
      <td class="gt_row gt_right">0.06</td>
      <td class="gt_row gt_right">71 /  1,211</td>
      <td class="gt_row gt_right">1.05</td>
      <td class="gt_row gt_right">(0.79-1.37)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">43-70</td>
      <td class="gt_row gt_right">0.06</td>
      <td class="gt_row gt_right">1,010 / 17,690</td>
      <td class="gt_row gt_right">0.06</td>
      <td class="gt_row gt_right">280 /  4,519</td>
      <td class="gt_row gt_right">1.09</td>
      <td class="gt_row gt_right">(0.95-1.24)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">71+</td>
      <td class="gt_row gt_right">0.06</td>
      <td class="gt_row gt_right">231 /  3,648</td>
      <td class="gt_row gt_right">0.06</td>
      <td class="gt_row gt_right">65 /  1,020</td>
      <td class="gt_row gt_right">1.01</td>
      <td class="gt_row gt_right">(0.75-1.33)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">0.06</td>
      <td class="gt_row gt_right">2,760 / 50,114</td>
      <td class="gt_row gt_right">0.06</td>
      <td class="gt_row gt_right">757 / 12,858</td>
      <td class="gt_row gt_right">1.07</td>
      <td class="gt_row gt_right">(0.99-1.16)</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="7" class="gt_group_heading">COVID-19 hospitalisation</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-7</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,835</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,227</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">0.02</td>
      <td class="gt_row gt_right">82 /  4,831</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,226</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">24 /  4,827</td>
      <td class="gt_row gt_right">0.01</td>
      <td class="gt_row gt_right">10 /  1,225</td>
      <td class="gt_row gt_right">1.64</td>
      <td class="gt_row gt_right">(0.70-3.56)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">7 /  4,815</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,224</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,786</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,222</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">(NA-20.86)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36-42</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,756</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,217</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">43-70</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- / 17,825</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,556</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">71+</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  3,699</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,034</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">129 / 50,373</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">25 / 12,931</td>
      <td class="gt_row gt_right">0.75</td>
      <td class="gt_row gt_right">(0.47-1.17)</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="7" class="gt_group_heading">COVID-19 critical care</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-7</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,835</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,227</td>
      <td class="gt_row gt_right">Inf</td>
      <td class="gt_row gt_right">(0.10-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">9 /  4,831</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,226</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">(NA-2.00)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,829</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,225</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,817</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,224</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,788</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,222</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36-42</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,758</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,218</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">43-70</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 / 17,834</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,558</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">71+</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  3,702</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,035</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">11 / 50,392</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- / 12,934</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="7" class="gt_group_heading">COVID-19 death</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-7</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,835</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,227</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,831</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,226</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,829</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,225</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,817</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,224</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,788</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,222</td>
      <td class="gt_row gt_right">Inf</td>
      <td class="gt_row gt_right">(0.10-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36-42</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,758</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,218</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">43-70</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 / 17,834</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,558</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">71+</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  3,702</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,035</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- / 50,394</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- / 12,934</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="7" class="gt_group_heading">Non-COVID-19 death</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-7</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,835</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,227</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,831</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,226</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,829</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,225</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,817</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,224</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">(NA-9.52)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,788</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,222</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">(NA-20.86)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36-42</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,758</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,218</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">43-70</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">8 / 17,834</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,558</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">71+</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  3,702</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,035</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">17 / 50,394</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- / 12,934</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="7" class="gt_group_heading">Any death</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-7</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,835</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,227</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,831</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,226</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,829</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,225</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,817</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,224</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">(NA-9.52)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,788</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,222</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36-42</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,758</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,218</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">43-70</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">8 / 17,834</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,558</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">71+</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  3,702</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,035</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">18 / 50,394</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- / 12,934</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
  </tbody>
  
  
</table></div><!--/html_preserve-->

## Comparative effectiveness

The plots below show:

* *ChAdOx1* versus *BNT162b2* hazard ratio splines
* Risk-adjusted survival curves for *ChAdOx1* and *BNT162b2*


  

### SARS-CoV-2 test
  

<img src="/workspace/output/report/figures/curves-1.png" width="90%" />  

### SARS-CoV-2 positive test
  

<img src="/workspace/output/report/figures/curves-2.png" width="90%" />  

### A&E attendance
  

<img src="/workspace/output/report/figures/curves-3.png" width="90%" />  

### Any unplanned hospital admission
  

<img src="/workspace/output/report/figures/curves-4.png" width="90%" />  

### COVID-19 hospital admission
  

<img src="/workspace/output/report/figures/curves-5.png" width="90%" />

