from cohortextractor import (codelist, codelist_from_csv, combine_codelists)


covid_icd10 = codelist_from_csv(
    "codelists/opensafely-covid-identification.csv",
    system="icd10",
    column="icd10_code",
)

covid_primary_care_positive_test = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-probable-covid-positive-test.csv",
    system="ctv3",
    column="CTV3ID",
)

covid_primary_care_code = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-probable-covid-clinical-code.csv",
    system="ctv3",
    column="CTV3ID",
)

covid_primary_care_sequalae = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-probable-covid-sequelae.csv",
    system="ctv3",
    column="CTV3ID",
)

covid_primary_care_probable_combined = combine_codelists(
    covid_primary_care_positive_test,
    covid_primary_care_code,
    covid_primary_care_sequalae,
)
covid_primary_care_suspected_covid_advice = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-suspected-covid-advice.csv",
    system="ctv3",
    column="CTV3ID",
)
covid_primary_care_suspected_covid_had_test = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-suspected-covid-had-test.csv",
    system="ctv3",
    column="CTV3ID",
)
covid_primary_care_suspected_covid_isolation = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-suspected-covid-isolation-code.csv",
    system="ctv3",
    column="CTV3ID",
)
covid_primary_care_suspected_covid_nonspecific_clinical_assessment = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-suspected-covid-nonspecific-clinical-assessment.csv",
    system="ctv3",
    column="CTV3ID",
)
covid_primary_care_suspected_covid_exposure = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-exposure-to-disease.csv",
    system="ctv3",
    column="CTV3ID",
)
primary_care_suspected_covid_combined = combine_codelists(
    covid_primary_care_suspected_covid_advice,
    covid_primary_care_suspected_covid_had_test,
    covid_primary_care_suspected_covid_isolation,
    covid_primary_care_suspected_covid_exposure,
)



ethnicity = codelist_from_csv(
    "codelists/opensafely-ethnicity.csv",
    system="ctv3",
    column="Code",
    category_column="Grouping_6",
)
ethnicity_16 = codelist_from_csv(
    "codelists/opensafely-ethnicity.csv",
    system="ctv3",
    column="Code",
    category_column="Grouping_16",
)


solid_organ_transplantation = codelist_from_csv(
    "codelists/opensafely-solid-organ-transplantation.csv",
    system="ctv3",
    column="CTV3ID",
)

lung_cancer = codelist_from_csv(
    "codelists/opensafely-lung-cancer.csv", system="ctv3", column="CTV3ID",
)
haematological_cancer = codelist_from_csv(
    "codelists/opensafely-haematological-cancer.csv", system="ctv3", column="CTV3ID",
)
bone_marrow_transplant = codelist_from_csv(
    "codelists/opensafely-bone-marrow-transplant.csv", system="ctv3", column="CTV3ID",
)
cystic_fibrosis = codelist_from_csv(
    "codelists/opensafely-cystic-fibrosis.csv", system="ctv3", column="CTV3ID",
)

sickle_cell_disease = codelist_from_csv(
    "codelists/opensafely-sickle-cell-disease.csv", system="ctv3", column="CTV3ID",
)

permanent_immunosuppression = codelist_from_csv(
    "codelists/opensafely-permanent-immunosuppression.csv",
    system="ctv3",
    column="CTV3ID",
)
temporary_immunosuppression = codelist_from_csv(
    "codelists/opensafely-temporary-immunosuppression.csv",
    system="ctv3",
    column="CTV3ID",
)
chronic_cardiac_disease = codelist_from_csv(
    "codelists/opensafely-chronic-cardiac-disease.csv", system="ctv3", column="CTV3ID",
)
learning_disability = codelist_from_csv(
    "codelists/opensafely-learning-disabilities.csv",
    system="ctv3",
    column="CTV3Code",
)
downs_syndrome = codelist_from_csv(
    "codelists/opensafely-down-syndrome.csv",
    system="ctv3",
    column="code",
)
cerebral_palsy = codelist_from_csv(
    "codelists/opensafely-cerebral-palsy.csv",
    system="ctv3",
    column="code",
)
learning_disability_including_downs_syndrome_and_cerebral_palsy = combine_codelists(
    learning_disability,
    downs_syndrome,
    cerebral_palsy,
)
dialysis = codelist_from_csv(
    "codelists/opensafely-dialysis.csv", system="ctv3", column="CTV3ID",
)
other_respiratory_conditions = codelist_from_csv(
    "codelists/opensafely-other-respiratory-conditions.csv",
    system="ctv3",
    column="CTV3ID",
)
heart_failure = codelist_from_csv(
    "codelists/opensafely-heart-failure.csv", system="ctv3", column="CTV3ID",
)
other_heart_disease = codelist_from_csv(
    "codelists/opensafely-other-heart-disease.csv", system="ctv3", column="CTV3ID",
)

chronic_cardiac_disease = codelist_from_csv(
    "codelists/opensafely-chronic-cardiac-disease.csv", system="ctv3", column="CTV3ID",
)

chemotherapy_or_radiotherapy = codelist_from_csv(
    "codelists/opensafely-chemotherapy-or-radiotherapy.csv",
    system="ctv3",
    column="CTV3ID",
)
cancer_excluding_lung_and_haematological = codelist_from_csv(
    "codelists/opensafely-cancer-excluding-lung-and-haematological.csv",
    system="ctv3",
    column="CTV3ID",
)

current_copd = codelist_from_csv(
    "codelists/opensafely-current-copd.csv", system="ctv3", column="CTV3ID"
)

dementia = codelist_from_csv(
    "codelists/opensafely-dementia-complete.csv", system="ctv3", column="code"
)

diabetes = codelist_from_csv(
    "codelists/opensafely-diabetes.csv", system="ctv3", column="CTV3ID"
)

dmards = codelist_from_csv(
    "codelists/opensafely-dmards.csv", system="snomed", column="snomed_id",
)

dialysis = codelist_from_csv(
    "codelists/opensafely-dialysis.csv", system="ctv3", column="CTV3ID",
)

chronic_liver_disease = codelist_from_csv(
    "codelists/opensafely-chronic-liver-disease.csv", system="ctv3", column="CTV3ID",
)
other_neuro = codelist_from_csv(
    "codelists/opensafely-other-neurological-conditions.csv",
    system="ctv3",
    column="CTV3ID",
)

psychosis_schizophrenia_bipolar_affective_disease = codelist_from_csv(
    "codelists/opensafely-psychosis-schizophrenia-bipolar-affective-disease.csv",
    system="ctv3",
    column="CTV3Code",
)

asplenia = codelist_from_csv(
    "codelists/opensafely-asplenia.csv", system="ctv3", column="CTV3ID"
)

flu_med = codelist_from_csv(
    "codelists/opensafely-influenza-vaccination.csv",  system="snomed",  column="snomed_id",
)

flu_clinical_given = codelist_from_csv(
    "codelists/opensafely-influenza-vaccination-clinical-codes-given.csv",  system="ctv3", column="CTV3ID",
)

flu_clinical_not_given = codelist_from_csv(
    "codelists/opensafely-influenza-vaccination-clinical-codes-not-given.csv",  system="ctv3", column="CTV3ID",
)

ICD10_I = codelist_from_csv(
    "codelists/opensafely-icd-10-chapter-i.csv",
    system="icd10",
    column="code",
)

## PRIMIS

carehome_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-longres.csv", 
    system="snomed", 
    column="code",
)

shield = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-shield.csv",
    system="snomed",
    column="code",
)

nonshield = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-nonshield.csv",
    system="snomed",
    column="code",
)

eol = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-palcare_cod.csv",
    system="snomed",
    column="code",
)

midazolam = codelist_from_csv(
    "codelists/opensafely-midazolam-end-of-life.csv",
    system="snomed",
    column="dmd_id",   
)
