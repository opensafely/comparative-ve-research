
from cohortextractor import (
    StudyDefinition,
    patients,
    codelist_from_csv,
    codelist,
    filter_codes_by_category,
    combine_codelists,
)

# Import Codelists
import codelists

# import json module
import json

# import date modules
from datetime import datetime, timedelta

# import global-variables.json
with open("./analysis/global-variables.json") as f:
    gbl_vars = json.load(f)

# define variables explicitly
start_date = gbl_vars["start_date"] # change this in global-variables.json if necessary
start_date_pfizer = gbl_vars["start_date_pfizer"] # change this in global-variables.json if necessary
start_date_az = gbl_vars["start_date_az"] # change this in global-variables.json if necessary
start_date_moderna = gbl_vars["start_date_moderna"] # change this in global-variables.json if necessary
end_date = gbl_vars["end_date"] # change this in global-variables.json if necessary

today = datetime.today().strftime('%Y-%m-%d')


def days(datestring, days):
    
    dt = datetime.strptime(datestring, "%Y-%m-%d").date()
    dt_add = dt + timedelta(days)
    datestring_add = datetime.strftime(dt_add, "%Y-%m-%d")
    
    return datestring_add




# Specifiy study defeinition
study = StudyDefinition(
    # Configure the expectations framework
    default_expectations={
        "date": {"earliest": "1970-01-01", "latest": end_date},
        "rate": "uniform",
        "incidence": 0.2,
    },
    
    index_date = "2020-03-31",
    # This line defines the study population
    population=patients.with_healthcare_worker_flag_on_covid_vaccine_record(returning="binary_flag"),
    
    
    ###############################################################################
    # COVID VACCINATION
    ###############################################################################
    
    #################################################################
    ## COVID VACCINATION TYPE = pfizer
    #################################################################
    
    covid_vax_pfizer_1_date=patients.with_tpp_vaccination_record(
        product_name_matches="COVID-19 mRNA Vaccine Pfizer-BioNTech BNT162b2 30micrograms/0.3ml dose conc for susp for inj MDV",
        on_or_before=today,
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {
                "earliest": days(start_date_pfizer, -120),  
                "latest": days(start_date_pfizer, -1),
            },
            "incidence": 0.001
        },
    ),


    covid_vax_pfizer_2_date=patients.with_tpp_vaccination_record(
        product_name_matches="COVID-19 mRNA Vaccine Pfizer-BioNTech BNT162b2 30micrograms/0.3ml dose conc for susp for inj MDV",
        on_or_after="covid_vax_pfizer_1_date + 1 day",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {
                "earliest": start_date_pfizer,  
                "latest": days(start_date_pfizer, 120),
            },
            "incidence": 1
        },
    ),

    covid_vax_pfizer_3_date=patients.with_tpp_vaccination_record(
        product_name_matches="COVID-19 mRNA Vaccine Pfizer-BioNTech BNT162b2 30micrograms/0.3ml dose conc for susp for inj MDV",
        on_or_after="covid_vax_pfizer_2_date + 1 day",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {
                "earliest": "2020-12-29",  # first reported second dose administered on the 29/12
                "latest": "2021-02-01",
            },
            "incidence": 0.2
        },
    ),


    #################################################################
    ## COVID VACCINATION TYPE = Oxford -AZ
    #################################################################
    
    covid_vax_az_1_date=patients.with_tpp_vaccination_record(
        product_name_matches="COVID-19 Vac AstraZeneca (ChAdOx1 S recomb) 5x10000000000 viral particles/0.5ml dose sol for inj MDV",
        on_or_before=today,
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {
               "earliest": days(start_date_az, -120), 
                "latest": days(start_date_az, -1),
            },
            "incidence": 0.001
        },
    ),


    covid_vax_az_2_date=patients.with_tpp_vaccination_record(
        product_name_matches="COVID-19 Vac AstraZeneca (ChAdOx1 S recomb) 5x10000000000 viral particles/0.5ml dose sol for inj MDV",
        on_or_after="covid_vax_az_1_date + 1 day",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {
                "earliest": start_date_az,  
                "latest": days(start_date_az, 120),
            },
            "incidence": 1
        },
    ),

    covid_vax_az_3_date=patients.with_tpp_vaccination_record(
        product_name_matches="COVID-19 Vac AstraZeneca (ChAdOx1 S recomb) 5x10000000000 viral particles/0.5ml dose sol for inj MDV",
        on_or_after="covid_vax_az_2_date + 1 day",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {
                "earliest": "2021-02-01",
                "latest": "2021-03-01",
                "incidence": 0.3
            }
        },
    ),
    
    
    #################################################################
    ## COVID VACCINATION TYPE = moderna
    #################################################################
    covid_vax_moderna_1_date=patients.with_tpp_vaccination_record(
        product_name_matches="COVID-19 mRNA (nucleoside modified) Vaccine Moderna 0.1mg/0.5mL dose dispersion for inj MDV",
        on_or_before=today,
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {
                "earliest": days(start_date_moderna, -120), 
                "latest": days(start_date_moderna, -1),
            },
            "incidence": 0.001
        },
    ),


    covid_vax_moderna_2_date=patients.with_tpp_vaccination_record(
        product_name_matches="COVID-19 mRNA (nucleoside modified) Vaccine Moderna 0.1mg/0.5mL dose dispersion for inj MDV",
        on_or_after="covid_vax_moderna_1_date + 1 day",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {
                "earliest": start_date_moderna, 
                "latest": days(start_date_moderna, 120),
            },
            "incidence": 1
        },
    ),

    covid_vax_moderna_3_date=patients.with_tpp_vaccination_record(
        product_name_matches="COVID-19 mRNA (nucleoside modified) Vaccine Moderna 0.1mg/0.5mL dose dispersion for inj MDV",
        on_or_after="covid_vax_moderna_2_date + 1 day",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {
                "earliest": "2021-02-01",
                "latest": "2021-03-01",
                "incidence": 0.3
            }
        },
    ),
    
    
     #################################################################
    ## COVID VACCINATION TYPE = any based on disease target
    #################################################################
    
    # any covid vaccination identified by target disease/virus
    covid_vax_disease_1_date=patients.with_tpp_vaccination_record(
        target_disease_matches="SARS-2 CORONAVIRUS",
        on_or_before = today,
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {
                "earliest": days(start_date, -120), 
                "latest": days(start_date, -1),
            },
            "incidence": 0.001
        },
    ),

    covid_vax_disease_2_date=patients.with_tpp_vaccination_record(
        target_disease_matches="SARS-2 CORONAVIRUS",
        on_or_after="covid_vax_disease_1_date + 1 day",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {
                "earliest": start_date, 
                "latest": days(start_date, 120),
            },
            "incidence": 1
        },
    ),
    # SECOND DOSE COVID VACCINATION - any type
    covid_vax_disease_3_date=patients.with_tpp_vaccination_record(
        target_disease_matches="SARS-2 CORONAVIRUS",
        on_or_after="covid_vax_disease_2_date + 1 day",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {
                "earliest": "2021-02-02",
                "latest": "2021-04-30",
            }
        },
    ),
    
     #################################################################
    ## COVID VACCINATION TYPE = combine brands
    #################################################################
    # any COVID vaccination, combination of az and pfizer and moderna

    covid_vax_any_1_date=patients.minimum_of(
        "covid_vax_pfizer_1_date", "covid_vax_az_1_date", "covid_vax_moderna_1_date"
    ),

    covid_vax_any_2_date=patients.minimum_of(
        "covid_vax_pfizer_2_date", "covid_vax_az_2_date", "covid_vax_moderna_2_date"
    ),

    covid_vax_any_3_date=patients.minimum_of(
        "covid_vax_pfizer_3_date", "covid_vax_az_3_date", "covid_vax_moderna_3_date"
    ),


    
    ###############################################################################
    # ADMIN AND DEMOGRAPHICS
    ###############################################################################

    # https://github.com/opensafely/risk-factors-research/issues/49
    age=patients.age_as_of(
        "index_date",
        return_expectations={
            "rate": "universal",
            "int": {"distribution": "population_ages"},
            "incidence" : 1
        },
    ),
    
    # https://github.com/opensafely/risk-factors-research/issues/46
    sex=patients.sex(
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"M": 0.49, "F": 0.51}},
            "incidence": 1,
        }
    ),


    # ETHNICITY IN 16 CATEGORIES
    # ethnicity_16=patients.with_these_clinical_events(
    #     ethnicity_16,
    #     returning="category",
    #     find_last_match_in_period=True,
    #     include_date_of_match=False,
    #     return_expectations={
    #         "category": {
    #             "ratios": {
    #                 "1": 0.0625,
    #                 "2": 0.0625,
    #                 "3": 0.0625,
    #                 "4": 0.0625,
    #                 "5": 0.0625,
    #                 "6": 0.0625,
    #                 "7": 0.0625,
    #                 "8": 0.0625,
    #                 "9": 0.0625,
    #                 "10": 0.0625,
    #                 "11": 0.0625,
    #                 "12": 0.0625,
    #                 "13": 0.0625,
    #                 "14": 0.0625,
    #                 "15": 0.0625,
    #                 "16": 0.0625,
    #             }
    #         },
    #         "incidence": 0.75,
    #     },
    # ),

    # ETHNICITY IN 6 CATEGORIES
    ethnicity = patients.with_these_clinical_events(
        codelists.ethnicity,
        returning="category",
        find_last_match_in_period=True,
        include_date_of_match=False,
        return_expectations={
            "category": {"ratios": {"1": 0.2, "2": 0.2, "3": 0.2, "4": 0.2, "5": 0.2}},
            "incidence": 0.75,
        },
    ),
    
    # New ethnicity variable that takes data from SUS
    ethnicity_6_sus = patients.with_ethnicity_from_sus(
        returning="group_6",  
        use_most_frequent_code=True,
        return_expectations={
            "category": {"ratios": {"1": 0.2, "2": 0.2, "3": 0.2, "4": 0.2, "5": 0.2}},
            "incidence": 0.8,
            },
    ),

    ################################################
    ###### PRACTICE AND PATIENT ADDRESS VARIABLES ##
    ################################################
    # practice pseudo id
    practice_id=patients.registered_practice_as_of(
        "index_date",
        returning="pseudo_id",
        return_expectations={
            "int": {"distribution": "normal", "mean": 1000, "stddev": 100},
            "incidence": 1,
        },
    ),
    
    # msoa
    msoa=patients.address_as_of(
        "index_date",
        returning="msoa",
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"E02000001": 0.0625, "E02000002": 0.0625, "E02000003": 0.0625, "E02000004": 0.0625,
                                    "E02000005": 0.0625, "E02000007": 0.0625, "E02000008": 0.0625, "E02000009": 0.0625, 
                                    "E02000010": 0.0625, "E02000011": 0.0625, "E02000012": 0.0625, "E02000013": 0.0625, 
                                    "E02000014": 0.0625, "E02000015": 0.0625, "E02000016": 0.0625, "E02000017": 0.0625}},
        },
    ),    

    # stp is an NHS administration region based on geography
    stp=patients.registered_practice_as_of(
        "index_date",
        returning="stp_code",
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "STP1": 0.1,
                    "STP2": 0.1,
                    "STP3": 0.1,
                    "STP4": 0.1,
                    "STP5": 0.1,
                    "STP6": 0.1,
                    "STP7": 0.1,
                    "STP8": 0.1,
                    "STP9": 0.1,
                    "STP10": 0.1,
                }
            },
        },
    ),
    
    # NHS administrative region
    region=patients.registered_practice_as_of(
        "index_date",
        returning="nuts1_region_name",
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "North East": 0.1,
                    "North West": 0.1,
                    "Yorkshire and The Humber": 0.2,
                    "East Midlands": 0.1,
                    "West Midlands": 0.1,
                    "East": 0.1,
                    "London": 0.1,
                    "South East": 0.1,
                    "South West": 0.1,
                    #"" : 0.01
                },
            },
        },
    ),

    imd=patients.address_as_of(
        "index_date",
        returning="index_of_multiple_deprivation",
        round_to_nearest=100,
        return_expectations={
             "category": {"ratios": {c: 1/320 for c in range(100, 32100, 100)}}
        }
    ),

    rural_urban=patients.address_as_of(
        "index_date",
        returning="rural_urban_classification",
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {1: 0.125, 2: 0.125, 3: 0.125, 4: 0.125, 5: 0.125, 6: 0.125, 7: 0.125, 8: 0.125}},
        },
    ),


    # COVID-RELATED DEATH
    coviddeath_date=patients.with_these_codes_on_death_certificate(
        codelists.covid_icd10,
        returning="date_of_death",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2021-06-01", "latest" : "2021-08-01"},
            "rate": "uniform",
            "incidence": 0.02
        },
    ),
    # ALL-CAUSE DEATH
    death_date=patients.died_from_any_cause(
        returning="date_of_death",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2021-06-01", "latest" : "2021-08-01"},
            "rate": "uniform",
            "incidence": 0.02
        },
    ),


    ############################################################
    ######### CLINICAL CO-MORBIDITIES ##########################
    ############################################################

    # https://github.com/opensafely/risk-factors-research/issues/51
    bmi=patients.categorised_as(
        {
            "Not obese": "DEFAULT",
            "Obese I (30-34.9)": """ bmi_value >= 30 AND bmi_value < 35""",
            "Obese II (35-39.9)": """ bmi_value >= 35 AND bmi_value < 40""",
            "Obese III (40+)": """ bmi_value >= 40 AND bmi_value < 100""",
            # set maximum to avoid any impossibly extreme values being classified as obese
        },
        bmi_value=patients.most_recent_bmi(
            on_or_after="index_date",
            minimum_age_at_measurement=16
            ),
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "Not obese": 0.7,
                    "Obese I (30-34.9)": 0.1,
                    "Obese II (35-39.9)": 0.1,
                    "Obese III (40+)": 0.1,
                }
            },
        },
    ),

    chronic_cardiac_disease=patients.with_these_clinical_events(
        codelists.chronic_cardiac_disease,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01},
    ),
    heart_failure=patients.with_these_clinical_events(
        codelists.heart_failure,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01},
    ),
    other_heart_disease=patients.with_these_clinical_events(
        codelists.other_heart_disease,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01},
    ),

    diabetes=patients.with_these_clinical_events(
        codelists.diabetes,
        returning="binary_flag",
        find_last_match_in_period=True,
        on_or_before="index_date",
        return_expectations={"incidence": 0.01},
    ),
    dialysis=patients.with_these_clinical_events(
        codelists.dialysis,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    chronic_liver_disease=patients.with_these_clinical_events(
        codelists.chronic_liver_disease,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01},
    ),

    current_copd=patients.with_these_clinical_events(
        codelists.current_copd,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01},
    ),
    LD_incl_DS_and_CP=patients.with_these_clinical_events(
        codelists.learning_disability_including_downs_syndrome_and_cerebral_palsy,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    cystic_fibrosis=patients.with_these_clinical_events(
        codelists.cystic_fibrosis,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    other_resp_conditions=patients.with_these_clinical_events(
        codelists.other_respiratory_conditions,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01},
    ),

    lung_cancer=patients.with_these_clinical_events(
        codelists.lung_cancer,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    haematological_cancer=patients.with_these_clinical_events(
        codelists.haematological_cancer,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    cancer_excl_lung_and_haem=patients.with_these_clinical_events(
        codelists.cancer_excluding_lung_and_haematological,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),

    chemo_or_radio=patients.with_these_clinical_events(
        codelists.chemotherapy_or_radiotherapy,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    solid_organ_transplantation=patients.with_these_clinical_events(
        codelists.solid_organ_transplantation,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    permanant_immunosuppression=patients.with_these_clinical_events(
        codelists.permanent_immunosuppression,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    temporary_immunosuppression=patients.with_these_clinical_events(
        codelists.temporary_immunosuppression,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    asplenia=patients.with_these_clinical_events(
        codelists.asplenia,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    dmards=patients.with_these_medications(
        codelists.dmards,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    # dementia
    dementia=patients.with_these_clinical_events(
        codelists.dementia,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    other_neuro_conditions=patients.with_these_clinical_events(
        codelists.other_neuro,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01},
    ),

    psychosis_schiz_bipolar=patients.with_these_clinical_events(
        codelists.psychosis_schizophrenia_bipolar_affective_disease,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01},
    ),



    ############################################################
    ######### PRIMIS CODELIST DERIVED CLINICAL VARIABLES     ###
    ############################################################


    cev_ever = patients.with_these_clinical_events(
        codelists.shield,
        returning="binary_flag",
        on_or_before = "index_date",
        find_last_match_in_period = True,
        return_expectations={"incidence": 0.02},
    ),

    cev = patients.satisfying(
        """severely_clinically_vulnerable AND NOT less_vulnerable""",

        ### SHIELDED GROUP - first flag all patients with "high risk" codes
        severely_clinically_vulnerable=patients.with_these_clinical_events(
            codelists.shield,
            returning="binary_flag",
            on_or_before = "index_date",
            find_last_match_in_period = True,
        ),

        # find date at which the high risk code was added
        date_severely_clinically_vulnerable=patients.date_of(
            "severely_clinically_vulnerable",
            date_format="YYYY-MM-DD",
        ),

        ### NOT SHIELDED GROUP (medium and low risk) - only flag if later than 'shielded'
        less_vulnerable=patients.with_these_clinical_events(
            codelists.nonshield,
            between=["date_severely_clinically_vulnerable + 1 day", "index_date - 1 day"],
        ),

        return_expectations={"incidence": 0.01},
    ),

)
