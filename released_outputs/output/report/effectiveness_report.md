Comparative vaccine effectiveness (ChAdOx1 versus BNT162b2) in Health and Social Care workers
================

Introduction
============

This study compares the effectiveness of the *BNT162b2* mRNA (Pfizer-BioNTech) and *ChAdOx1* (Oxford-AstraZeneca) vaccines amongst health and social care workers (HCWs). This group was chosen as they were prioritised for vaccination due to high occupational exposure and during the period where both vaccines were available (04 January 2021 onwards) it is expected that the actual vaccine brand received will not be strongly influenced by other determinants of COVID-19-related outcomes (i.e., approximately random treatment allocation and therefore reduced confounding).

The code and data for this report can be found at the OpenSafely [comparative-ve-research GitHub repository](https://github.com/opensafely/comparative-ve-research).

Methods
=======

Study population
----------------

People meeting the following criteria are included:

-   HCWs who have received at least one dose of BNT162b2 or ChAdOx1.
-   Registered at a GP practice using TPP's SystmOne clinical information system on the day of vaccination.
-   Aged 18-65.
-   Vaccinated on or after 04 January 2021, when both vaccine brands were being administered.
-   Not Clinically Extremely Vulnerable (CEV), as set out by government guidance, at the time of vaccination.

Study participants are followed up from vaccination date until the first of:

-   The outcome of interest
-   Death or deregistration
-   Second vaccine dose
-   The study end date, 25 April 2021

### Identifying vaccinated HCWs

Those vaccinated as part of England's national vaccination programme (for example not including vaccine trial participants) are asked whether they work in health or social care. This information is sent to OpenSAFELY-TPP from NHS Digital's COVID-19 data store.

Note -- many of those flagged as HCWs do not have a vaccination record, which shouldn't be the case if the question was asked as part of the vaccination process. This needs further investigation.

Study measures
--------------

### Exposure

The vaccination brand, BNT162b2 or ChAdOx1. This is available in the GP record directly, via the National Immunisation Management System (NIMS).

### Outcomes

-   SARS-CoV-2 infection, as identified via SGSS records. Both PCR and LFT tests are included.
-   Unplanned COVID-19-related hospitalisation via HES records. ICD-10 codes are used to identify COVID-19-related admissions.
-   Unplanned COVID-19-related ICU admission via HES records. ICD-10 codes are used to identify COVID-19-related admissions.
-   COVID-19-related death via death registration records. With COVID-19 ICD-10 codes anywhere on the death certificate (i.e., as an underlying or contributing cause of death)

Statistical Analysis
--------------------

The aim is to estimate comparative vaccine effectiveness, i.e., the relative hazard of each outcome for ChAdOx1 versus BNT162b2 vaccine recipients. The effect is permitted to vary by time since vaccination, to account for the potential differences in vaccine protection over time between the two brands.

Patient characteristics used for adjustment include: age, sex, deprivation, ethnicity, NHS region, clinically “at risk” (but not clinically extremely vulnerable) as per national prioritisation guidelines, asthma, number of previous SARS-CoV-2 tests (via SGSS), rurality, evidence of prior covid infection (positive test or COVID-19 hospitalisation), number of recorded comorbidities, severe mental illness. All characteristics are ascertained as at the time of vaccination.

NHS regions are used as a stratification variable to account for geographical variation in event rates for the outcomes of interest, for example due to changes in local infection rates.

### Time-dependent Cox models

Time-dependent Cox models are used to estimate the time-varying effects for each vaccine type. Time zero is the date of vaccination, i.e., using a treatment time-scale. Outcome events occurring on the same day as vaccination are included in follow-up. Date of vaccination is included as an additional baseline covariate using a restricted cubic spline with knots at the first and second tertile, plus boundary knots. Here, follow-up time is stratified into weekly intervals with the vaccine-specific effect estimated within each time-strata. In `R`'s `coxph` function, this is modelled using `vaccine_type:strata(week_since_first_dose)`.

### Pooled Logistic Regression models

We emulate the Cox model described above using pooled logistic regression (PLR), with the outcome risk estimated at daily intervals. These models include a restricted cubic spline with 3 degrees of freedom on the log of the timescale (time since vaccination), interacted with vaccine type. The PLR models serve two purposes. Firstly, a continuous-time estimate of comparative effectiveness, as opposed to the piecewise-linear approximation above, is obtained. Secondly, the risk-adjusted survival rates for each vaccine type are obtained using the parametric g-formula. This is the average risk for each day of follow-up predicted by the PLR model, under the (complimentary counterfactual) assumption that every patient received the BNT162b2 vaccine or that every patient received the ChAdOx1 vaccine.

Confidence intervals for the risk-adjusted survival rates are calculated using the delta method (i.e, a first-order Taylor series approximation of the variance of the cumulative incidence).

The person-time dataset needed to fit the PLR model is large and leads to infeasible RAM requirements / computation time. To deal with this, a sampling strategy is used such that all those who experienced an outcome and a random sample of 50000 who did not experience the outcome are selected for the models. The models are weighted to recover the characteristics of the complete dataset. This weighting is also applied to the risk-adjusted survival curves.

Results
=======

Note all counts below 6 are redacted and survival estimates are rounded for disclosure control.

Flowchart
---------

<!--html_preserve-->
<style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#mynjtanbqe .gt_table {
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

#mynjtanbqe .gt_heading {
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

#mynjtanbqe .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#mynjtanbqe .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 4px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#mynjtanbqe .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#mynjtanbqe .gt_col_headings {
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

#mynjtanbqe .gt_col_heading {
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

#mynjtanbqe .gt_column_spanner_outer {
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

#mynjtanbqe .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#mynjtanbqe .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#mynjtanbqe .gt_column_spanner {
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

#mynjtanbqe .gt_group_heading {
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

#mynjtanbqe .gt_empty_group_heading {
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

#mynjtanbqe .gt_from_md > :first-child {
  margin-top: 0;
}

#mynjtanbqe .gt_from_md > :last-child {
  margin-bottom: 0;
}

#mynjtanbqe .gt_row {
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

#mynjtanbqe .gt_stub {
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

#mynjtanbqe .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#mynjtanbqe .gt_first_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#mynjtanbqe .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#mynjtanbqe .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#mynjtanbqe .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#mynjtanbqe .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#mynjtanbqe .gt_footnotes {
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

#mynjtanbqe .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 4px;
}

#mynjtanbqe .gt_sourcenotes {
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

#mynjtanbqe .gt_sourcenote {
  font-size: 90%;
  padding: 4px;
}

#mynjtanbqe .gt_left {
  text-align: left;
}

#mynjtanbqe .gt_center {
  text-align: center;
}

#mynjtanbqe .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#mynjtanbqe .gt_font_normal {
  font-weight: normal;
}

#mynjtanbqe .gt_font_bold {
  font-weight: bold;
}

#mynjtanbqe .gt_font_italic {
  font-style: italic;
}

#mynjtanbqe .gt_super {
  font-size: 65%;
}

#mynjtanbqe .gt_footnote_marks {
  font-style: italic;
  font-size: 65%;
}
</style>
<table class="gt_table">
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
      <td class="gt_row gt_left">All vaccinated HCWs aged 16-65</td>
      <td class="gt_row gt_right">504,673</td>
      <td class="gt_row gt_right">-</td>
      <td class="gt_row gt_right">-</td>
      <td class="gt_row gt_right">100.0&percnt;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">with no missing demographic information</td>
      <td class="gt_row gt_right">456,395</td>
      <td class="gt_row gt_right">48,278</td>
      <td class="gt_row gt_right">9.6&percnt;</td>
      <td class="gt_row gt_right">90.4&percnt;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">who are not clinically extremely vulnerable</td>
      <td class="gt_row gt_right">440,591</td>
      <td class="gt_row gt_right">15,804</td>
      <td class="gt_row gt_right">3.5&percnt;</td>
      <td class="gt_row gt_right">87.3&percnt;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">with vaccination on or before recruitment end date</td>
      <td class="gt_row gt_right">382,100</td>
      <td class="gt_row gt_right">58,491</td>
      <td class="gt_row gt_right">13.3&percnt;</td>
      <td class="gt_row gt_right">75.7&percnt;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">with vaccination on or after recruitment start date</td>
      <td class="gt_row gt_right">315,811</td>
      <td class="gt_row gt_right">66,289</td>
      <td class="gt_row gt_right">17.3&percnt;</td>
      <td class="gt_row gt_right">62.6&percnt;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">with Pfizer/BNT or Oxford/AZ vaccine</td>
      <td class="gt_row gt_right">315,809</td>
      <td class="gt_row gt_right">2</td>
      <td class="gt_row gt_right">0.0&percnt;</td>
      <td class="gt_row gt_right">62.6&percnt;</td>
    </tr>

</tbody>
</table>

<!--/html_preserve-->
Baseline demographics
---------------------

<!--html_preserve-->
<style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#ljetxsnbmw .gt_table {
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

#ljetxsnbmw .gt_heading {
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

#ljetxsnbmw .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#ljetxsnbmw .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 4px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#ljetxsnbmw .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#ljetxsnbmw .gt_col_headings {
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

#ljetxsnbmw .gt_col_heading {
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

#ljetxsnbmw .gt_column_spanner_outer {
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

#ljetxsnbmw .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#ljetxsnbmw .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#ljetxsnbmw .gt_column_spanner {
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

#ljetxsnbmw .gt_group_heading {
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

#ljetxsnbmw .gt_empty_group_heading {
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

#ljetxsnbmw .gt_from_md > :first-child {
  margin-top: 0;
}

#ljetxsnbmw .gt_from_md > :last-child {
  margin-bottom: 0;
}

#ljetxsnbmw .gt_row {
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

#ljetxsnbmw .gt_stub {
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

#ljetxsnbmw .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#ljetxsnbmw .gt_first_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#ljetxsnbmw .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#ljetxsnbmw .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#ljetxsnbmw .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#ljetxsnbmw .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#ljetxsnbmw .gt_footnotes {
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

#ljetxsnbmw .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 4px;
}

#ljetxsnbmw .gt_sourcenotes {
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

#ljetxsnbmw .gt_sourcenote {
  font-size: 90%;
  padding: 4px;
}

#ljetxsnbmw .gt_left {
  text-align: left;
}

#ljetxsnbmw .gt_center {
  text-align: center;
}

#ljetxsnbmw .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#ljetxsnbmw .gt_font_normal {
  font-weight: normal;
}

#ljetxsnbmw .gt_font_bold {
  font-weight: bold;
}

#ljetxsnbmw .gt_font_italic {
  font-style: italic;
}

#ljetxsnbmw .gt_super {
  font-size: 65%;
}

#ljetxsnbmw .gt_footnote_marks {
  font-style: italic;
  font-size: 65%;
}
</style>
<table class="gt_table">
<thead class="gt_col_headings">
    <tr>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1"><strong>Characteristic</strong></th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1"><strong>BNT162b2</strong>, N = 252,265</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1"><strong>ChAdOx1</strong>, N = 63,544</th>
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
      <td class="gt_row gt_center">40,863 (16%)</td>
      <td class="gt_row gt_center">10,349 (16%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">30s</td>
      <td class="gt_row gt_center">59,326 (24%)</td>
      <td class="gt_row gt_center">14,586 (23%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">40s</td>
      <td class="gt_row gt_center">64,384 (26%)</td>
      <td class="gt_row gt_center">16,131 (25%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">50s</td>
      <td class="gt_row gt_center">67,550 (27%)</td>
      <td class="gt_row gt_center">17,352 (27%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">60-64</td>
      <td class="gt_row gt_center">20,142 (8.0%)</td>
      <td class="gt_row gt_center">5,126 (8.1%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Sex</td>
      <td class="gt_row gt_center"></td>
      <td class="gt_row gt_center"></td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Female</td>
      <td class="gt_row gt_center">199,455 (79%)</td>
      <td class="gt_row gt_center">48,807 (77%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Male</td>
      <td class="gt_row gt_center">52,810 (21%)</td>
      <td class="gt_row gt_center">14,737 (23%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Ethnicity</td>
      <td class="gt_row gt_center"></td>
      <td class="gt_row gt_center"></td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">White</td>
      <td class="gt_row gt_center">210,758 (84%)</td>
      <td class="gt_row gt_center">53,691 (84%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Black</td>
      <td class="gt_row gt_center">8,480 (3.4%)</td>
      <td class="gt_row gt_center">3,147 (5.0%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">South Asian</td>
      <td class="gt_row gt_center">23,048 (9.1%)</td>
      <td class="gt_row gt_center">4,664 (7.3%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Mixed</td>
      <td class="gt_row gt_center">3,853 (1.5%)</td>
      <td class="gt_row gt_center">999 (1.6%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Other</td>
      <td class="gt_row gt_center">6,126 (2.4%)</td>
      <td class="gt_row gt_center">1,043 (1.6%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">IMD</td>
      <td class="gt_row gt_center"></td>
      <td class="gt_row gt_center"></td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">1 most deprived</td>
      <td class="gt_row gt_center">36,726 (15%)</td>
      <td class="gt_row gt_center">10,216 (16%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">2</td>
      <td class="gt_row gt_center">47,094 (19%)</td>
      <td class="gt_row gt_center">11,942 (19%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">3</td>
      <td class="gt_row gt_center">55,616 (22%)</td>
      <td class="gt_row gt_center">13,592 (21%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">4</td>
      <td class="gt_row gt_center">57,318 (23%)</td>
      <td class="gt_row gt_center">14,205 (22%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">5 least deprived</td>
      <td class="gt_row gt_center">55,511 (22%)</td>
      <td class="gt_row gt_center">13,589 (21%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Region</td>
      <td class="gt_row gt_center"></td>
      <td class="gt_row gt_center"></td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">North East and Yorkshire</td>
      <td class="gt_row gt_center">53,288 (21%)</td>
      <td class="gt_row gt_center">16,361 (26%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">East of England</td>
      <td class="gt_row gt_center">62,172 (25%)</td>
      <td class="gt_row gt_center">11,816 (19%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Midlands</td>
      <td class="gt_row gt_center">50,327 (20%)</td>
      <td class="gt_row gt_center">16,730 (26%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">South West</td>
      <td class="gt_row gt_center">35,978 (14%)</td>
      <td class="gt_row gt_center">5,038 (7.9%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">North West</td>
      <td class="gt_row gt_center">23,535 (9.3%)</td>
      <td class="gt_row gt_center">7,841 (12%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">London</td>
      <td class="gt_row gt_center">10,360 (4.1%)</td>
      <td class="gt_row gt_center">2,143 (3.4%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">South East</td>
      <td class="gt_row gt_center">16,605 (6.6%)</td>
      <td class="gt_row gt_center">3,615 (5.7%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Day of vaccination</td>
      <td class="gt_row gt_center">12 (7, 18)</td>
      <td class="gt_row gt_center">20 (13, 33)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Body Mass Index</td>
      <td class="gt_row gt_center"></td>
      <td class="gt_row gt_center"></td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Not obese</td>
      <td class="gt_row gt_center">197,762 (78%)</td>
      <td class="gt_row gt_center">48,307 (76%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Obese I (30-34.9)</td>
      <td class="gt_row gt_center">31,056 (12%)</td>
      <td class="gt_row gt_center">8,524 (13%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Obese II (35-39.9)</td>
      <td class="gt_row gt_center">14,239 (5.6%)</td>
      <td class="gt_row gt_center">4,010 (6.3%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Obese III (40+)</td>
      <td class="gt_row gt_center">9,208 (3.7%)</td>
      <td class="gt_row gt_center">2,703 (4.3%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Heart failure</td>
      <td class="gt_row gt_center">629 (0.2%)</td>
      <td class="gt_row gt_center">197 (0.3%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Other heart disease</td>
      <td class="gt_row gt_center">4,627 (1.8%)</td>
      <td class="gt_row gt_center">1,279 (2.0%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Dialysis</td>
      <td class="gt_row gt_center">17 (&lt;0.1%)</td>
      <td class="gt_row gt_center">[REDACTED] (&lt;0.1%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Diabetes</td>
      <td class="gt_row gt_center">13,913 (5.5%)</td>
      <td class="gt_row gt_center">3,766 (5.9%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Chronic liver disease</td>
      <td class="gt_row gt_center">645 (0.3%)</td>
      <td class="gt_row gt_center">230 (0.4%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">COPD</td>
      <td class="gt_row gt_center">1,291 (0.5%)</td>
      <td class="gt_row gt_center">346 (0.5%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Other respiratory conditions</td>
      <td class="gt_row gt_center">740 (0.3%)</td>
      <td class="gt_row gt_center">232 (0.4%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Lung Cancer</td>
      <td class="gt_row gt_center">53 (&lt;0.1%)</td>
      <td class="gt_row gt_center">9 (&lt;0.1%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Haematological cancer</td>
      <td class="gt_row gt_center">435 (0.2%)</td>
      <td class="gt_row gt_center">116 (0.2%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Cancer excl. lung, haemo</td>
      <td class="gt_row gt_center">6,532 (2.6%)</td>
      <td class="gt_row gt_center">1,614 (2.5%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Immunosuppressed</td>
      <td class="gt_row gt_center">5,400 (2.1%)</td>
      <td class="gt_row gt_center">1,288 (2.0%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Other neurological conditions</td>
      <td class="gt_row gt_center">1,229 (0.5%)</td>
      <td class="gt_row gt_center">326 (0.5%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Learning disabilities</td>
      <td class="gt_row gt_center">361 (0.1%)</td>
      <td class="gt_row gt_center">102 (0.2%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Serious mental illness</td>
      <td class="gt_row gt_center">1,603 (0.6%)</td>
      <td class="gt_row gt_center">536 (0.8%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Morbidity count</td>
      <td class="gt_row gt_center"></td>
      <td class="gt_row gt_center"></td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">0</td>
      <td class="gt_row gt_center">201,866 (80%)</td>
      <td class="gt_row gt_center">49,863 (78%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">1</td>
      <td class="gt_row gt_center">41,348 (16%)</td>
      <td class="gt_row gt_center">11,052 (17%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">2</td>
      <td class="gt_row gt_center">8,005 (3.2%)</td>
      <td class="gt_row gt_center">2,311 (3.6%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">3+</td>
      <td class="gt_row gt_center">1,046 (0.4%)</td>
      <td class="gt_row gt_center">318 (0.5%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Prior SARS-CoV-2 infection</td>
      <td class="gt_row gt_center">27,185 (11%)</td>
      <td class="gt_row gt_center">8,995 (14%)</td>
    </tr>

</tbody>
</table>

<!--/html_preserve-->
Vaccination dates
-----------------

<img src="/workspace/output/report/figures/vaxdate-1.png" width="80%" />

Event rates
-----------

<!--html_preserve-->
<style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#runjkhwbxf .gt_table {
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

#runjkhwbxf .gt_heading {
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

#runjkhwbxf .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#runjkhwbxf .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 4px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#runjkhwbxf .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#runjkhwbxf .gt_col_headings {
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

#runjkhwbxf .gt_col_heading {
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

#runjkhwbxf .gt_column_spanner_outer {
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

#runjkhwbxf .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#runjkhwbxf .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#runjkhwbxf .gt_column_spanner {
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

#runjkhwbxf .gt_group_heading {
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

#runjkhwbxf .gt_empty_group_heading {
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

#runjkhwbxf .gt_from_md > :first-child {
  margin-top: 0;
}

#runjkhwbxf .gt_from_md > :last-child {
  margin-bottom: 0;
}

#runjkhwbxf .gt_row {
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

#runjkhwbxf .gt_stub {
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

#runjkhwbxf .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#runjkhwbxf .gt_first_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#runjkhwbxf .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#runjkhwbxf .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#runjkhwbxf .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#runjkhwbxf .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#runjkhwbxf .gt_footnotes {
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

#runjkhwbxf .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 4px;
}

#runjkhwbxf .gt_sourcenotes {
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

#runjkhwbxf .gt_sourcenote {
  font-size: 90%;
  padding: 4px;
}

#runjkhwbxf .gt_left {
  text-align: left;
}

#runjkhwbxf .gt_center {
  text-align: center;
}

#runjkhwbxf .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#runjkhwbxf .gt_font_normal {
  font-weight: normal;
}

#runjkhwbxf .gt_font_bold {
  font-weight: bold;
}

#runjkhwbxf .gt_font_italic {
  font-style: italic;
}

#runjkhwbxf .gt_super {
  font-size: 65%;
}

#runjkhwbxf .gt_footnote_marks {
  font-style: italic;
  font-size: 65%;
}
</style>
<table class="gt_table">
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
      <td class="gt_row gt_right">17,441 /  4,682</td>
      <td class="gt_row gt_right">3.39</td>
      <td class="gt_row gt_right">3,998 /  1,181</td>
      <td class="gt_row gt_right">0.91</td>
      <td class="gt_row gt_right">(0.88-0.94)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">2.51</td>
      <td class="gt_row gt_right">11,041 /  4,395</td>
      <td class="gt_row gt_right">1.72</td>
      <td class="gt_row gt_right">1,933 /  1,123</td>
      <td class="gt_row gt_right">0.69</td>
      <td class="gt_row gt_right">(0.65-0.72)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">1.56</td>
      <td class="gt_row gt_right">6,601 /  4,222</td>
      <td class="gt_row gt_right">1.20</td>
      <td class="gt_row gt_right">1,307 /  1,091</td>
      <td class="gt_row gt_right">0.77</td>
      <td class="gt_row gt_right">(0.72-0.81)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">1.13</td>
      <td class="gt_row gt_right">4,650 /  4,103</td>
      <td class="gt_row gt_right">0.99</td>
      <td class="gt_row gt_right">1,062 /  1,067</td>
      <td class="gt_row gt_right">0.88</td>
      <td class="gt_row gt_right">(0.82-0.94)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">0.94</td>
      <td class="gt_row gt_right">3,745 /  3,997</td>
      <td class="gt_row gt_right">0.83</td>
      <td class="gt_row gt_right">866 /  1,047</td>
      <td class="gt_row gt_right">0.88</td>
      <td class="gt_row gt_right">(0.82-0.95)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36-42</td>
      <td class="gt_row gt_right">0.87</td>
      <td class="gt_row gt_right">3,405 /  3,904</td>
      <td class="gt_row gt_right">0.73</td>
      <td class="gt_row gt_right">752 /  1,028</td>
      <td class="gt_row gt_right">0.84</td>
      <td class="gt_row gt_right">(0.77-0.91)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">43+</td>
      <td class="gt_row gt_right">0.71</td>
      <td class="gt_row gt_right">12,055 / 16,897</td>
      <td class="gt_row gt_right">0.75</td>
      <td class="gt_row gt_right">3,377 /  4,502</td>
      <td class="gt_row gt_right">1.05</td>
      <td class="gt_row gt_right">(1.01-1.09)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">1.40</td>
      <td class="gt_row gt_right">58,938 / 42,200</td>
      <td class="gt_row gt_right">1.20</td>
      <td class="gt_row gt_right">13,295 / 11,039</td>
      <td class="gt_row gt_right">0.86</td>
      <td class="gt_row gt_right">(0.85-0.88)</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="7" class="gt_group_heading">Positive SARS-CoV-2 test</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-7</td>
      <td class="gt_row gt_right">0.36</td>
      <td class="gt_row gt_right">1,721 /  4,821</td>
      <td class="gt_row gt_right">0.23</td>
      <td class="gt_row gt_right">280 /  1,215</td>
      <td class="gt_row gt_right">0.65</td>
      <td class="gt_row gt_right">(0.57-0.73)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">0.39</td>
      <td class="gt_row gt_right">1,855 /  4,778</td>
      <td class="gt_row gt_right">0.24</td>
      <td class="gt_row gt_right">284 /  1,208</td>
      <td class="gt_row gt_right">0.61</td>
      <td class="gt_row gt_right">(0.53-0.69)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">0.14</td>
      <td class="gt_row gt_right">660 /  4,751</td>
      <td class="gt_row gt_right">0.14</td>
      <td class="gt_row gt_right">170 /  1,203</td>
      <td class="gt_row gt_right">1.02</td>
      <td class="gt_row gt_right">(0.85-1.21)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">0.07</td>
      <td class="gt_row gt_right">351 /  4,730</td>
      <td class="gt_row gt_right">0.07</td>
      <td class="gt_row gt_right">80 /  1,200</td>
      <td class="gt_row gt_right">0.90</td>
      <td class="gt_row gt_right">(0.70-1.15)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">0.05</td>
      <td class="gt_row gt_right">252 /  4,696</td>
      <td class="gt_row gt_right">0.05</td>
      <td class="gt_row gt_right">63 /  1,196</td>
      <td class="gt_row gt_right">0.98</td>
      <td class="gt_row gt_right">(0.73-1.30)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36-42</td>
      <td class="gt_row gt_right">0.05</td>
      <td class="gt_row gt_right">240 /  4,661</td>
      <td class="gt_row gt_right">0.04</td>
      <td class="gt_row gt_right">53 /  1,191</td>
      <td class="gt_row gt_right">0.86</td>
      <td class="gt_row gt_right">(0.63-1.17)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">43+</td>
      <td class="gt_row gt_right">0.02</td>
      <td class="gt_row gt_right">485 / 21,038</td>
      <td class="gt_row gt_right">0.03</td>
      <td class="gt_row gt_right">146 /  5,447</td>
      <td class="gt_row gt_right">1.16</td>
      <td class="gt_row gt_right">(0.96-1.40)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">0.11</td>
      <td class="gt_row gt_right">5,564 / 49,476</td>
      <td class="gt_row gt_right">0.08</td>
      <td class="gt_row gt_right">1,076 / 12,660</td>
      <td class="gt_row gt_right">0.76</td>
      <td class="gt_row gt_right">(0.71-0.81)</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="7" class="gt_group_heading">A&amp;E attendance</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-7</td>
      <td class="gt_row gt_right">0.20</td>
      <td class="gt_row gt_right">963 /  4,824</td>
      <td class="gt_row gt_right">0.27</td>
      <td class="gt_row gt_right">329 /  1,214</td>
      <td class="gt_row gt_right">1.36</td>
      <td class="gt_row gt_right">(1.19-1.54)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">0.21</td>
      <td class="gt_row gt_right">1,014 /  4,802</td>
      <td class="gt_row gt_right">0.18</td>
      <td class="gt_row gt_right">213 /  1,208</td>
      <td class="gt_row gt_right">0.83</td>
      <td class="gt_row gt_right">(0.72-0.97)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">0.20</td>
      <td class="gt_row gt_right">959 /  4,781</td>
      <td class="gt_row gt_right">0.23</td>
      <td class="gt_row gt_right">275 /  1,203</td>
      <td class="gt_row gt_right">1.14</td>
      <td class="gt_row gt_right">(0.99-1.30)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">0.19</td>
      <td class="gt_row gt_right">921 /  4,751</td>
      <td class="gt_row gt_right">0.20</td>
      <td class="gt_row gt_right">236 /  1,197</td>
      <td class="gt_row gt_right">1.02</td>
      <td class="gt_row gt_right">(0.88-1.17)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">0.20</td>
      <td class="gt_row gt_right">950 /  4,704</td>
      <td class="gt_row gt_right">0.22</td>
      <td class="gt_row gt_right">265 /  1,190</td>
      <td class="gt_row gt_right">1.10</td>
      <td class="gt_row gt_right">(0.96-1.26)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36-42</td>
      <td class="gt_row gt_right">0.19</td>
      <td class="gt_row gt_right">889 /  4,657</td>
      <td class="gt_row gt_right">0.22</td>
      <td class="gt_row gt_right">257 /  1,181</td>
      <td class="gt_row gt_right">1.14</td>
      <td class="gt_row gt_right">(0.99-1.31)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">43+</td>
      <td class="gt_row gt_right">0.21</td>
      <td class="gt_row gt_right">4,378 / 20,828</td>
      <td class="gt_row gt_right">0.24</td>
      <td class="gt_row gt_right">1,263 /  5,351</td>
      <td class="gt_row gt_right">1.12</td>
      <td class="gt_row gt_right">(1.05-1.20)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">0.20</td>
      <td class="gt_row gt_right">10,074 / 49,347</td>
      <td class="gt_row gt_right">0.23</td>
      <td class="gt_row gt_right">2,838 / 12,544</td>
      <td class="gt_row gt_right">1.11</td>
      <td class="gt_row gt_right">(1.06-1.16)</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="7" class="gt_group_heading">Unplanned hospitalisation</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-7</td>
      <td class="gt_row gt_right">0.04</td>
      <td class="gt_row gt_right">200 /  4,830</td>
      <td class="gt_row gt_right">0.05</td>
      <td class="gt_row gt_right">66 /  1,217</td>
      <td class="gt_row gt_right">1.31</td>
      <td class="gt_row gt_right">(0.98-1.74)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">0.06</td>
      <td class="gt_row gt_right">281 /  4,823</td>
      <td class="gt_row gt_right">0.05</td>
      <td class="gt_row gt_right">56 /  1,214</td>
      <td class="gt_row gt_right">0.79</td>
      <td class="gt_row gt_right">(0.58-1.06)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">0.05</td>
      <td class="gt_row gt_right">248 /  4,815</td>
      <td class="gt_row gt_right">0.07</td>
      <td class="gt_row gt_right">87 /  1,212</td>
      <td class="gt_row gt_right">1.39</td>
      <td class="gt_row gt_right">(1.08-1.79)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">0.06</td>
      <td class="gt_row gt_right">277 /  4,798</td>
      <td class="gt_row gt_right">0.05</td>
      <td class="gt_row gt_right">60 /  1,210</td>
      <td class="gt_row gt_right">0.86</td>
      <td class="gt_row gt_right">(0.64-1.14)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">0.05</td>
      <td class="gt_row gt_right">249 /  4,764</td>
      <td class="gt_row gt_right">0.06</td>
      <td class="gt_row gt_right">71 /  1,207</td>
      <td class="gt_row gt_right">1.13</td>
      <td class="gt_row gt_right">(0.85-1.47)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36-42</td>
      <td class="gt_row gt_right">0.06</td>
      <td class="gt_row gt_right">264 /  4,729</td>
      <td class="gt_row gt_right">0.06</td>
      <td class="gt_row gt_right">71 /  1,201</td>
      <td class="gt_row gt_right">1.06</td>
      <td class="gt_row gt_right">(0.80-1.38)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">43+</td>
      <td class="gt_row gt_right">0.06</td>
      <td class="gt_row gt_right">1,241 / 21,330</td>
      <td class="gt_row gt_right">0.06</td>
      <td class="gt_row gt_right">344 /  5,492</td>
      <td class="gt_row gt_right">1.08</td>
      <td class="gt_row gt_right">(0.95-1.21)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">0.06</td>
      <td class="gt_row gt_right">2,760 / 50,090</td>
      <td class="gt_row gt_right">0.06</td>
      <td class="gt_row gt_right">755 / 12,753</td>
      <td class="gt_row gt_right">1.07</td>
      <td class="gt_row gt_right">(0.99-1.16)</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="7" class="gt_group_heading">COVID-19 hospitalisation</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-7</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,832</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,217</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">0.02</td>
      <td class="gt_row gt_right">82 /  4,828</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,216</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">24 /  4,824</td>
      <td class="gt_row gt_right">0.01</td>
      <td class="gt_row gt_right">10 /  1,215</td>
      <td class="gt_row gt_right">1.65</td>
      <td class="gt_row gt_right">(0.71-3.59)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">7 /  4,812</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,214</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,783</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,212</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">(NA-21.01)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36-42</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,753</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,208</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">43+</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">7 / 21,516</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">6 /  5,543</td>
      <td class="gt_row gt_right">3.33</td>
      <td class="gt_row gt_right">(0.92-11.56)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">129 / 50,348</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">25 / 12,826</td>
      <td class="gt_row gt_right">0.76</td>
      <td class="gt_row gt_right">(0.47-1.17)</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="7" class="gt_group_heading">COVID-19 critical care</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-7</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,832</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,217</td>
      <td class="gt_row gt_right">Inf</td>
      <td class="gt_row gt_right">(0.10-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">9 /  4,829</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,216</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">(NA-2.01)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,826</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,215</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,814</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,215</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,785</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,212</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36-42</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,755</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,208</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">43+</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 / 21,527</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  5,545</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">11 / 50,368</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- / 12,828</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="7" class="gt_group_heading">COVID-19 death</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-7</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,832</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,217</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,829</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,216</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,826</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,215</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,814</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,215</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,785</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,212</td>
      <td class="gt_row gt_right">Inf</td>
      <td class="gt_row gt_right">(0.10-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36-42</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,755</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,208</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">43+</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 / 21,528</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  5,545</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- / 50,370</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- / 12,829</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="7" class="gt_group_heading">Non-COVID-19 death</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-7</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,832</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,217</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,829</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,216</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,826</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,215</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,814</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,215</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">(NA-9.59)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,785</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,212</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">(NA-21.01)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36-42</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,755</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,208</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">43+</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">8 / 21,528</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  5,545</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">16 / 50,370</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- / 12,829</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="7" class="gt_group_heading">Any death</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-7</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,832</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,217</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,829</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,216</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,826</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,215</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,814</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,215</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">(NA-9.59)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,785</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,212</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36-42</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,755</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,208</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">43+</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">8 / 21,528</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  5,545</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">17 / 50,370</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- / 12,829</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>

</tbody>
</table>

<!--/html_preserve-->
Comparative effectiveness
-------------------------

The plots below show:

-   *ChAdOx1* versus *BNT162b2* hazard ratio splines
-   Risk-adjusted survival curves for *ChAdOx1* and *BNT162b2*

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
