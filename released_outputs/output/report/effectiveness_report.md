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
-   The study end date, 26 April 2021

### Identifying vaccinated HCWs

Those vaccinated as part of England's national vaccination programme (for example not including vaccine trial participants) are asked whether they work in health or social care. This information is sent to OpenSAFELY-TPP from NHS Digital's COVID-19 data store.

Note -- many of those flagged as HCWs do not have a vaccination record, which shouldn't be the case if the question was asked as part of the vaccination process.

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

Patient characteristics used for adjustment include: age, sex, deprivation, ethnicity, NHS region, clinically “at risk” (but not clinically extremely vulnerable) as per national prioritisation guidelines, asthma, number of previous SARS-CoV-2 tests (via SGSS), rurality, evidence of prior covid infection (positive test or COVID-19 hospitalisation), number of recorded comorbidities, severe mental illness. All variables are ascertained as at the time of vaccination.

NHS regions are used as a stratification variable to account for geographical variation in event rates for the outcomes of interest (primarily driven by changes in local infection rates).

### Time-dependent Cox models

Time-dependent Cox models are used to estimate the time-varying effects for each vaccine type. Two time-scales are used for triangulation:

-   On the *calendar time-scale*, time zero is 04 January 2021, and people only contribute follow-up time once they have been vaccinated (i.e., delayed study entry). Vaccine type, time since vaccination in weekly intervals, and the interaction between these two terms are included to estimate time-varying vaccine effects for each vaccine type. In `R`'s `coxph` function, this is modelled using `vaccine_type*week_since_first_dose`

-   On the *treatment time-scale*, time zero is the date of vaccination. Calendar-time is included as an additional covariate, in weekly intervals, using restricted cubic spline with knots at the first and second tertile, plus boundary knots. Here, follow-up time is stratified into weekly intervals with the vaccine-specific effect estimated within each time-strata. In `R`'s `coxph` function, this is modelled using `vaccine_type:strata(week_since_first_dose)`.

### Pooled Logistic Regression models

We emulate the Cox models described above using pooled logistic regression (PLR), with the outcome risk estimated at daily intervals. This serves two purposes. Firstly, a continuous-time estimate of comparative effectiveness, as opposed to the piecewise-linear approximation above, can be obtained using flexible parametric splines. Secondly, the absolute cumulative risk of each outcome of interest for each vaccine type, marginalised over the population, can be obtained using the parametric g-formula. These models include a restricted cubic spline with 3 degrees of freedom on the timescale of interest, interacted with vaccine type. Cumulative risk is then calculated as the average risk for each day of follow-up predicted by the PLR model, under the (complimentary counterfactual) assumptions that every patient received the BNT162b2 vaccine or that every patient received the ChAdOx1 vaccine.

The person-time dataset needed to fit the PLR model is large and leads to infeasible RAM requirements / computation time. To deal with this, a sampling strategy is used such that all those who experienced an outcome and a random sample of 50000 who did not experience the ouotcome are selected for the models. The models are weighted to recover the characteristics of the complete dataset. This weighting is also applied to the average cumulative risk.

Results
=======

Note all counts below 6 are redacted and Kaplan-Meier survival estimates are rounded for disclosure control.

Flowchart
---------

<!--html_preserve-->
<style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#hbhukrrswd .gt_table {
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

#hbhukrrswd .gt_heading {
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

#hbhukrrswd .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#hbhukrrswd .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 4px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#hbhukrrswd .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#hbhukrrswd .gt_col_headings {
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

#hbhukrrswd .gt_col_heading {
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

#hbhukrrswd .gt_column_spanner_outer {
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

#hbhukrrswd .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#hbhukrrswd .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#hbhukrrswd .gt_column_spanner {
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

#hbhukrrswd .gt_group_heading {
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

#hbhukrrswd .gt_empty_group_heading {
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

#hbhukrrswd .gt_from_md > :first-child {
  margin-top: 0;
}

#hbhukrrswd .gt_from_md > :last-child {
  margin-bottom: 0;
}

#hbhukrrswd .gt_row {
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

#hbhukrrswd .gt_stub {
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

#hbhukrrswd .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#hbhukrrswd .gt_first_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#hbhukrrswd .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#hbhukrrswd .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#hbhukrrswd .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#hbhukrrswd .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#hbhukrrswd .gt_footnotes {
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

#hbhukrrswd .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 4px;
}

#hbhukrrswd .gt_sourcenotes {
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

#hbhukrrswd .gt_sourcenote {
  font-size: 90%;
  padding: 4px;
}

#hbhukrrswd .gt_left {
  text-align: left;
}

#hbhukrrswd .gt_center {
  text-align: center;
}

#hbhukrrswd .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#hbhukrrswd .gt_font_normal {
  font-weight: normal;
}

#hbhukrrswd .gt_font_bold {
  font-weight: bold;
}

#hbhukrrswd .gt_font_italic {
  font-style: italic;
}

#hbhukrrswd .gt_super {
  font-size: 65%;
}

#hbhukrrswd .gt_footnote_marks {
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
      <td class="gt_row gt_right">504,399</td>
      <td class="gt_row gt_right">-</td>
      <td class="gt_row gt_right">-</td>
      <td class="gt_row gt_right">100.0&percnt;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">with no missing demographic information</td>
      <td class="gt_row gt_right">456,073</td>
      <td class="gt_row gt_right">48,326</td>
      <td class="gt_row gt_right">9.6&percnt;</td>
      <td class="gt_row gt_right">90.4&percnt;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">who are not clinically extremely vulnerable</td>
      <td class="gt_row gt_right">440,277</td>
      <td class="gt_row gt_right">15,796</td>
      <td class="gt_row gt_right">3.5&percnt;</td>
      <td class="gt_row gt_right">87.3&percnt;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">with vaccination on or before study end date</td>
      <td class="gt_row gt_right">419,342</td>
      <td class="gt_row gt_right">20,935</td>
      <td class="gt_row gt_right">4.8&percnt;</td>
      <td class="gt_row gt_right">83.1&percnt;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">with vaccination on or after study start date</td>
      <td class="gt_row gt_right">353,089</td>
      <td class="gt_row gt_right">66,253</td>
      <td class="gt_row gt_right">15.8&percnt;</td>
      <td class="gt_row gt_right">70.0&percnt;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">with Pfizer/BNT or Oxford/AZ vaccine</td>
      <td class="gt_row gt_right">352,826</td>
      <td class="gt_row gt_right">263</td>
      <td class="gt_row gt_right">0.1&percnt;</td>
      <td class="gt_row gt_right">69.9&percnt;</td>
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

#vifcotyxba .gt_table {
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

#vifcotyxba .gt_heading {
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

#vifcotyxba .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#vifcotyxba .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 4px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#vifcotyxba .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#vifcotyxba .gt_col_headings {
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

#vifcotyxba .gt_col_heading {
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

#vifcotyxba .gt_column_spanner_outer {
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

#vifcotyxba .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#vifcotyxba .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#vifcotyxba .gt_column_spanner {
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

#vifcotyxba .gt_group_heading {
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

#vifcotyxba .gt_empty_group_heading {
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

#vifcotyxba .gt_from_md > :first-child {
  margin-top: 0;
}

#vifcotyxba .gt_from_md > :last-child {
  margin-bottom: 0;
}

#vifcotyxba .gt_row {
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

#vifcotyxba .gt_stub {
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

#vifcotyxba .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#vifcotyxba .gt_first_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#vifcotyxba .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#vifcotyxba .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#vifcotyxba .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#vifcotyxba .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#vifcotyxba .gt_footnotes {
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

#vifcotyxba .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 4px;
}

#vifcotyxba .gt_sourcenotes {
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

#vifcotyxba .gt_sourcenote {
  font-size: 90%;
  padding: 4px;
}

#vifcotyxba .gt_left {
  text-align: left;
}

#vifcotyxba .gt_center {
  text-align: center;
}

#vifcotyxba .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#vifcotyxba .gt_font_normal {
  font-weight: normal;
}

#vifcotyxba .gt_font_bold {
  font-weight: bold;
}

#vifcotyxba .gt_font_italic {
  font-style: italic;
}

#vifcotyxba .gt_super {
  font-size: 65%;
}

#vifcotyxba .gt_footnote_marks {
  font-style: italic;
  font-size: 65%;
}
</style>
<table class="gt_table">
<thead class="gt_col_headings">
    <tr>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1"><strong>Characteristic</strong></th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1"><strong>BNT162b2</strong>, N = 259,725</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1"><strong>ChAdOx1</strong>, N = 93,101</th>
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
      <td class="gt_row gt_center">43,035 (17%)</td>
      <td class="gt_row gt_center">16,340 (18%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">30s</td>
      <td class="gt_row gt_center">61,640 (24%)</td>
      <td class="gt_row gt_center">21,676 (23%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">40s</td>
      <td class="gt_row gt_center">65,961 (25%)</td>
      <td class="gt_row gt_center">22,350 (24%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">50s</td>
      <td class="gt_row gt_center">68,672 (26%)</td>
      <td class="gt_row gt_center">25,258 (27%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">60-64</td>
      <td class="gt_row gt_center">20,417 (7.9%)</td>
      <td class="gt_row gt_center">7,477 (8.0%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Sex</td>
      <td class="gt_row gt_center"></td>
      <td class="gt_row gt_center"></td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Female</td>
      <td class="gt_row gt_center">205,353 (79%)</td>
      <td class="gt_row gt_center">72,267 (78%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Male</td>
      <td class="gt_row gt_center">54,372 (21%)</td>
      <td class="gt_row gt_center">20,834 (22%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Ethnicity</td>
      <td class="gt_row gt_center"></td>
      <td class="gt_row gt_center"></td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">White</td>
      <td class="gt_row gt_center">215,824 (83%)</td>
      <td class="gt_row gt_center">76,533 (82%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Black</td>
      <td class="gt_row gt_center">9,103 (3.5%)</td>
      <td class="gt_row gt_center">5,531 (5.9%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">South Asian</td>
      <td class="gt_row gt_center">24,312 (9.4%)</td>
      <td class="gt_row gt_center">7,590 (8.2%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Mixed</td>
      <td class="gt_row gt_center">4,049 (1.6%)</td>
      <td class="gt_row gt_center">1,685 (1.8%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Other</td>
      <td class="gt_row gt_center">6,437 (2.5%)</td>
      <td class="gt_row gt_center">1,762 (1.9%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">IMD</td>
      <td class="gt_row gt_center"></td>
      <td class="gt_row gt_center"></td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">1 most deprived</td>
      <td class="gt_row gt_center">38,232 (15%)</td>
      <td class="gt_row gt_center">15,960 (17%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">2</td>
      <td class="gt_row gt_center">48,682 (19%)</td>
      <td class="gt_row gt_center">18,057 (19%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">3</td>
      <td class="gt_row gt_center">57,210 (22%)</td>
      <td class="gt_row gt_center">19,921 (21%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">4</td>
      <td class="gt_row gt_center">58,807 (23%)</td>
      <td class="gt_row gt_center">20,243 (22%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">5 least deprived</td>
      <td class="gt_row gt_center">56,794 (22%)</td>
      <td class="gt_row gt_center">18,920 (20%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Day of vaccination</td>
      <td class="gt_row gt_center">12 (7, 19)</td>
      <td class="gt_row gt_center">33 (17, 65)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Body Mass Index</td>
      <td class="gt_row gt_center"></td>
      <td class="gt_row gt_center"></td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Not obese</td>
      <td class="gt_row gt_center">203,956 (79%)</td>
      <td class="gt_row gt_center">71,626 (77%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Obese I (30-34.9)</td>
      <td class="gt_row gt_center">31,802 (12%)</td>
      <td class="gt_row gt_center">12,203 (13%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Obese II (35-39.9)</td>
      <td class="gt_row gt_center">14,607 (5.6%)</td>
      <td class="gt_row gt_center">5,553 (6.0%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">Obese III (40+)</td>
      <td class="gt_row gt_center">9,360 (3.6%)</td>
      <td class="gt_row gt_center">3,719 (4.0%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Heart failure</td>
      <td class="gt_row gt_center">638 (0.2%)</td>
      <td class="gt_row gt_center">252 (0.3%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Other heart disease</td>
      <td class="gt_row gt_center">4,705 (1.8%)</td>
      <td class="gt_row gt_center">1,694 (1.8%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Dialysis</td>
      <td class="gt_row gt_center">17 (&lt;0.1%)</td>
      <td class="gt_row gt_center">6 (&lt;0.1%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Diabetes</td>
      <td class="gt_row gt_center">14,139 (5.4%)</td>
      <td class="gt_row gt_center">4,858 (5.2%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Chronic liver disease</td>
      <td class="gt_row gt_center">660 (0.3%)</td>
      <td class="gt_row gt_center">321 (0.3%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">COPD</td>
      <td class="gt_row gt_center">1,319 (0.5%)</td>
      <td class="gt_row gt_center">472 (0.5%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Other respiratory conditions</td>
      <td class="gt_row gt_center">753 (0.3%)</td>
      <td class="gt_row gt_center">309 (0.3%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Lung Cancer</td>
      <td class="gt_row gt_center">53 (&lt;0.1%)</td>
      <td class="gt_row gt_center">14 (&lt;0.1%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Haematological cancer</td>
      <td class="gt_row gt_center">444 (0.2%)</td>
      <td class="gt_row gt_center">168 (0.2%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Cancer excl. lung, haemo</td>
      <td class="gt_row gt_center">6,652 (2.6%)</td>
      <td class="gt_row gt_center">2,279 (2.4%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Immunosuppressed</td>
      <td class="gt_row gt_center">5,491 (2.1%)</td>
      <td class="gt_row gt_center">1,823 (2.0%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Other neurological conditions</td>
      <td class="gt_row gt_center">1,255 (0.5%)</td>
      <td class="gt_row gt_center">452 (0.5%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Learning disabilities</td>
      <td class="gt_row gt_center">371 (0.1%)</td>
      <td class="gt_row gt_center">165 (0.2%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Serious mental illness</td>
      <td class="gt_row gt_center">1,631 (0.6%)</td>
      <td class="gt_row gt_center">900 (1.0%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Morbidity count</td>
      <td class="gt_row gt_center"></td>
      <td class="gt_row gt_center"></td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">0</td>
      <td class="gt_row gt_center">208,269 (80%)</td>
      <td class="gt_row gt_center">74,072 (80%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">1</td>
      <td class="gt_row gt_center">42,306 (16%)</td>
      <td class="gt_row gt_center">15,627 (17%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">2</td>
      <td class="gt_row gt_center">8,090 (3.1%)</td>
      <td class="gt_row gt_center">3,004 (3.2%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">3+</td>
      <td class="gt_row gt_center">1,060 (0.4%)</td>
      <td class="gt_row gt_center">398 (0.4%)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">Prior SARS-CoV-2 infection</td>
      <td class="gt_row gt_center">28,809 (11%)</td>
      <td class="gt_row gt_center">15,087 (16%)</td>
    </tr>

</tbody>
</table>

<!--/html_preserve-->
Event rates
-----------

<!--html_preserve-->
<style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#ourxkwzrao .gt_table {
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

#ourxkwzrao .gt_heading {
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

#ourxkwzrao .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#ourxkwzrao .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 4px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#ourxkwzrao .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#ourxkwzrao .gt_col_headings {
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

#ourxkwzrao .gt_col_heading {
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

#ourxkwzrao .gt_column_spanner_outer {
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

#ourxkwzrao .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#ourxkwzrao .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#ourxkwzrao .gt_column_spanner {
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

#ourxkwzrao .gt_group_heading {
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

#ourxkwzrao .gt_empty_group_heading {
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

#ourxkwzrao .gt_from_md > :first-child {
  margin-top: 0;
}

#ourxkwzrao .gt_from_md > :last-child {
  margin-bottom: 0;
}

#ourxkwzrao .gt_row {
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

#ourxkwzrao .gt_stub {
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

#ourxkwzrao .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#ourxkwzrao .gt_first_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#ourxkwzrao .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#ourxkwzrao .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#ourxkwzrao .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#ourxkwzrao .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#ourxkwzrao .gt_footnotes {
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

#ourxkwzrao .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 4px;
}

#ourxkwzrao .gt_sourcenotes {
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

#ourxkwzrao .gt_sourcenote {
  font-size: 90%;
  padding: 4px;
}

#ourxkwzrao .gt_left {
  text-align: left;
}

#ourxkwzrao .gt_center {
  text-align: center;
}

#ourxkwzrao .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#ourxkwzrao .gt_font_normal {
  font-weight: normal;
}

#ourxkwzrao .gt_font_bold {
  font-weight: bold;
}

#ourxkwzrao .gt_font_italic {
  font-style: italic;
}

#ourxkwzrao .gt_super {
  font-size: 65%;
}

#ourxkwzrao .gt_footnote_marks {
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
      <td class="gt_row gt_right">3.67</td>
      <td class="gt_row gt_right">17,710 /  4,820</td>
      <td class="gt_row gt_right">3.08</td>
      <td class="gt_row gt_right">5,329 /  1,730</td>
      <td class="gt_row gt_right">0.84</td>
      <td class="gt_row gt_right">(0.81-0.86)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">2.48</td>
      <td class="gt_row gt_right">11,211 /  4,517</td>
      <td class="gt_row gt_right">1.58</td>
      <td class="gt_row gt_right">2,586 /  1,637</td>
      <td class="gt_row gt_right">0.64</td>
      <td class="gt_row gt_right">(0.61-0.66)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">1.55</td>
      <td class="gt_row gt_right">6,695 /  4,329</td>
      <td class="gt_row gt_right">1.14</td>
      <td class="gt_row gt_right">1,796 /  1,577</td>
      <td class="gt_row gt_right">0.74</td>
      <td class="gt_row gt_right">(0.70-0.78)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">1.12</td>
      <td class="gt_row gt_right">4,715 /  4,194</td>
      <td class="gt_row gt_right">0.98</td>
      <td class="gt_row gt_right">1,492 /  1,519</td>
      <td class="gt_row gt_right">0.87</td>
      <td class="gt_row gt_right">(0.82-0.93)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">0.93</td>
      <td class="gt_row gt_right">3,796 /  4,068</td>
      <td class="gt_row gt_right">0.88</td>
      <td class="gt_row gt_right">1,236 /  1,412</td>
      <td class="gt_row gt_right">0.94</td>
      <td class="gt_row gt_right">(0.88-1.00)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36+</td>
      <td class="gt_row gt_right">0.74</td>
      <td class="gt_row gt_right">15,593 / 20,952</td>
      <td class="gt_row gt_right">0.78</td>
      <td class="gt_row gt_right">4,689 /  6,022</td>
      <td class="gt_row gt_right">1.05</td>
      <td class="gt_row gt_right">(1.01-1.08)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">1.39</td>
      <td class="gt_row gt_right">59,720 / 42,880</td>
      <td class="gt_row gt_right">1.23</td>
      <td class="gt_row gt_right">17,128 / 13,897</td>
      <td class="gt_row gt_right">0.88</td>
      <td class="gt_row gt_right">(0.87-0.90)</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="7" class="gt_group_heading">Positive SARS-CoV-2 test</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-7</td>
      <td class="gt_row gt_right">0.35</td>
      <td class="gt_row gt_right">1,724 /  4,961</td>
      <td class="gt_row gt_right">0.16</td>
      <td class="gt_row gt_right">292 /  1,776</td>
      <td class="gt_row gt_right">0.47</td>
      <td class="gt_row gt_right">(0.42-0.54)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">0.38</td>
      <td class="gt_row gt_right">1,856 /  4,906</td>
      <td class="gt_row gt_right">0.17</td>
      <td class="gt_row gt_right">301 /  1,753</td>
      <td class="gt_row gt_right">0.45</td>
      <td class="gt_row gt_right">(0.40-0.51)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">0.14</td>
      <td class="gt_row gt_right">660 /  4,865</td>
      <td class="gt_row gt_right">0.10</td>
      <td class="gt_row gt_right">174 /  1,728</td>
      <td class="gt_row gt_right">0.74</td>
      <td class="gt_row gt_right">(0.62-0.88)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">0.07</td>
      <td class="gt_row gt_right">350 /  4,829</td>
      <td class="gt_row gt_right">0.05</td>
      <td class="gt_row gt_right">86 /  1,697</td>
      <td class="gt_row gt_right">0.70</td>
      <td class="gt_row gt_right">(0.55-0.89)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">0.05</td>
      <td class="gt_row gt_right">251 /  4,773</td>
      <td class="gt_row gt_right">0.04</td>
      <td class="gt_row gt_right">67 /  1,606</td>
      <td class="gt_row gt_right">0.79</td>
      <td class="gt_row gt_right">(0.60-1.04)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36+</td>
      <td class="gt_row gt_right">0.03</td>
      <td class="gt_row gt_right">727 / 25,885</td>
      <td class="gt_row gt_right">0.03</td>
      <td class="gt_row gt_right">201 /  7,213</td>
      <td class="gt_row gt_right">0.99</td>
      <td class="gt_row gt_right">(0.84-1.16)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">0.11</td>
      <td class="gt_row gt_right">5,568 / 50,219</td>
      <td class="gt_row gt_right">0.07</td>
      <td class="gt_row gt_right">1,121 / 15,773</td>
      <td class="gt_row gt_right">0.64</td>
      <td class="gt_row gt_right">(0.60-0.68)</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="7" class="gt_group_heading">A&amp;E attendance</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-7</td>
      <td class="gt_row gt_right">0.20</td>
      <td class="gt_row gt_right">1,001 /  4,963</td>
      <td class="gt_row gt_right">0.29</td>
      <td class="gt_row gt_right">515 /  1,773</td>
      <td class="gt_row gt_right">1.44</td>
      <td class="gt_row gt_right">(1.29-1.60)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">0.21</td>
      <td class="gt_row gt_right">1,045 /  4,929</td>
      <td class="gt_row gt_right">0.21</td>
      <td class="gt_row gt_right">373 /  1,748</td>
      <td class="gt_row gt_right">1.01</td>
      <td class="gt_row gt_right">(0.89-1.13)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">0.20</td>
      <td class="gt_row gt_right">994 /  4,893</td>
      <td class="gt_row gt_right">0.25</td>
      <td class="gt_row gt_right">424 /  1,722</td>
      <td class="gt_row gt_right">1.21</td>
      <td class="gt_row gt_right">(1.08-1.36)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">0.19</td>
      <td class="gt_row gt_right">944 /  4,847</td>
      <td class="gt_row gt_right">0.23</td>
      <td class="gt_row gt_right">385 /  1,686</td>
      <td class="gt_row gt_right">1.17</td>
      <td class="gt_row gt_right">(1.04-1.32)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">0.20</td>
      <td class="gt_row gt_right">970 /  4,780</td>
      <td class="gt_row gt_right">0.24</td>
      <td class="gt_row gt_right">375 /  1,591</td>
      <td class="gt_row gt_right">1.16</td>
      <td class="gt_row gt_right">(1.03-1.31)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36+</td>
      <td class="gt_row gt_right">0.21</td>
      <td class="gt_row gt_right">5,328 / 25,663</td>
      <td class="gt_row gt_right">0.24</td>
      <td class="gt_row gt_right">1,704 /  7,089</td>
      <td class="gt_row gt_right">1.16</td>
      <td class="gt_row gt_right">(1.10-1.22)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">0.21</td>
      <td class="gt_row gt_right">10,282 / 50,076</td>
      <td class="gt_row gt_right">0.24</td>
      <td class="gt_row gt_right">3,776 / 15,608</td>
      <td class="gt_row gt_right">1.18</td>
      <td class="gt_row gt_right">(1.13-1.22)</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="7" class="gt_group_heading">COVID-19 hospitalisation</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-7</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,972</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,778</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">0.02</td>
      <td class="gt_row gt_right">82 /  4,956</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,761</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">0.01</td>
      <td class="gt_row gt_right">25 /  4,938</td>
      <td class="gt_row gt_right">0.01</td>
      <td class="gt_row gt_right">10 /  1,741</td>
      <td class="gt_row gt_right">1.13</td>
      <td class="gt_row gt_right">(0.49-2.45)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">7 /  4,911</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,712</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,860</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,622</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">(NA-15.95)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36+</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">9 / 26,458</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">7 /  7,327</td>
      <td class="gt_row gt_right">2.81</td>
      <td class="gt_row gt_right">(0.89-8.47)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">130 / 51,095</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">25 / 15,942</td>
      <td class="gt_row gt_right">0.62</td>
      <td class="gt_row gt_right">(0.38-0.95)</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="7" class="gt_group_heading">COVID-19 critical care</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-7</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,972</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,778</td>
      <td class="gt_row gt_right">Inf</td>
      <td class="gt_row gt_right">(0.07-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">9 /  4,957</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,761</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">(NA-1.43)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,940</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,741</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,913</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,713</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,862</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,623</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36+</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 / 26,471</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  7,329</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">11 / 51,115</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- / 15,945</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="7" class="gt_group_heading">COVID-19 death</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-7</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,972</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,778</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,957</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,761</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,940</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,742</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,913</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,713</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,863</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,623</td>
      <td class="gt_row gt_right">Inf</td>
      <td class="gt_row gt_right">(0.08-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36+</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 / 26,473</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  7,330</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- / 51,117</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- / 15,946</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="7" class="gt_group_heading">Non-COVID-19 death</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-7</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,972</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,778</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,957</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,761</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,940</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,742</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,913</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,713</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,863</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,623</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">(NA-15.96)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36+</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">9 / 26,473</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  7,330</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">17 / 51,117</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- / 15,946</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr class="gt_group_heading_row">
      <td colspan="7" class="gt_group_heading">Any death</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">1-7</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  4,972</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">0 /  1,778</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">(NA-NA)</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">8-14</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,957</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,761</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">15-21</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,940</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,742</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">22-28</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,913</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,713</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">29-35</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  4,863</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  1,623</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">36+</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">9 / 26,473</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">-- /  7,330</td>
      <td class="gt_row gt_right">&ndash;</td>
      <td class="gt_row gt_right">&ndash;</td>
    </tr>
    <tr>
      <td class="gt_row gt_left">All</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">18 / 51,117</td>
      <td class="gt_row gt_right">0.00</td>
      <td class="gt_row gt_right">6 / 15,946</td>
      <td class="gt_row gt_right">1.07</td>
      <td class="gt_row gt_right">(0.35-2.81)</td>
    </tr>

</tbody>
</table>

<!--/html_preserve-->
Comparative effectiveness
-------------------------

The plots below show:

-   Unadjusted Kaplan-Meier curves
-   *ChAdOx1* versus *BNT162b2* piecewise-linear hazard ratios estimated using the Cox models
-   *ChAdOx1* versus *BNT162b2* continuous hazard ratios estimated using the PLR models
-   Marginalised cumulative risk for *ChAdOx1* and *BNT162b2* estimated using the PLR models

### SARS-CoV-2 test

#### Unadjusted

<img src="/workspace/output/report/figures/curves-1.png" width="80%" />

#### Cox

<img src="/workspace/output/report/figures/curves-2.png" width="80%" />

#### PLR

<img src="/workspace/output/report/figures/curves-3.png" width="80%" />

<img src="/workspace/output/report/figures/curves-4.png" width="80%" />

<img src="/workspace/output/report/figures/curves-5.png" width="80%" />

### SARS-CoV-2 positive test

#### Unadjusted

<img src="/workspace/output/report/figures/curves-6.png" width="80%" />

#### Cox

<img src="/workspace/output/report/figures/curves-7.png" width="80%" />

#### PLR, peicewise

<img src="/workspace/output/report/figures/curves-8.png" width="80%" />

#### PLR, spline

<img src="/workspace/output/report/figures/curves-9.png" width="80%" />

<img src="/workspace/output/report/figures/curves-10.png" width="80%" />

### A&E attendance

#### Unadjusted

<img src="/workspace/output/report/figures/curves-11.png" width="80%" />

#### Cox

<img src="/workspace/output/report/figures/curves-12.png" width="80%" />

#### PLR, peicewise

<img src="/workspace/output/report/figures/curves-13.png" width="80%" />

#### PLR, spline

<img src="/workspace/output/report/figures/curves-14.png" width="80%" />

<img src="/workspace/output/report/figures/curves-15.png" width="80%" />

### COVID-19 hospital admission

#### Unadjusted

<img src="/workspace/output/report/figures/curves-16.png" width="80%" />

#### Cox

<img src="/workspace/output/report/figures/curves-17.png" width="80%" />

#### PLR, peicewise

<img src="/workspace/output/report/figures/curves-18.png" width="80%" />

#### PLR, spline

<img src="/workspace/output/report/figures/curves-19.png" width="80%" />

<img src="/workspace/output/report/figures/curves-20.png" width="80%" />
