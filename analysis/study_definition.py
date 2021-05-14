
from cohortextractor import (
    StudyDefinition,
    patients,
    codelist_from_csv,
    codelist,
    filter_codes_by_category,
    combine_codelists,
)

# Import Codelists
from codelists import *

# import json module
import json

# import global-variables.json
with open("./analysis/global-variables.json") as f:
    gbl_vars = json.load(f)

# define variables explicitly
start_date = gbl_vars["start_date"] # change this in global-variables.json if necessary
end_date = gbl_vars["end_date"] # change this in global-variables.json if necessary

# start_date is currently set to the start of the vaccination campaign
# end_date depends on the most reent data coverage in the database, and the particular variables of interest



# Specifiy study defeinition
study = StudyDefinition(
    # Configure the expectations framework
    default_expectations={
        "date": {"earliest": "1970-01-01", "latest": end_date},
        "rate": "uniform",
        "incidence": 0.2,
    },
        
    index_date = start_date,
    # This line defines the study population
    population=patients.satisfying(
        """
        registered
        AND
        (age >= 18 AND age < 110)
        AND
        NOT has_died
        """,
        registered=patients.registered_as_of(
            "index_date",
        ),
        has_died=patients.died_from_any_cause(
            on_or_before="index_date",
            returning="binary_flag",
        ),
    ),


    # https://github.com/opensafely/risk-factors-research/issues/49
    age=patients.age_as_of(
        "2020-03-31",
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
        }
    ),

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
            on_or_after="2015-12-01",
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

    has_follow_up_previous_year=patients.registered_with_one_practice_between(
        start_date="index_date - 1 year",
        end_date="index_date",
        return_expectations={"incidence": 0.99},
    ),

    registered_at_latest=patients.registered_as_of(
        reference_date=end_date,
        return_expectations={"incidence": 0.99},
    ),
    
    dereg_date=patients.date_deregistered_from_all_supported_practices(
        on_or_after="index_date", date_format="YYYY-MM-DD",
    ),

    # ETHNICITY IN 16 CATEGORIES
    # ethnicity_16=patients.with_these_clinical_events(
    #     ethnicity_codes_16,
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
    ethnicity=patients.with_these_clinical_events(
        ethnicity_codes,
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
        "index_date",  # day before vaccine campaign start
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
                    "North West": 0.2,
                    "Yorkshire and the Humber": 0.2,
                    "East Midlands": 0.1,
                    "West Midlands": 0.1,
                    "East of England": 0.1,
                    "London": 0.1,
                    "South East": 0.09,
                    "" : 0.01
                },
            },
        },
    ),

    # IMD - quintile
    imd=patients.categorised_as(
        {
            "0": "DEFAULT",
            "1": """index_of_multiple_deprivation >=1 AND index_of_multiple_deprivation < 32844*1/5""",
            "2": """index_of_multiple_deprivation >= 32844*1/5 AND index_of_multiple_deprivation < 32844*2/5""",
            "3": """index_of_multiple_deprivation >= 32844*2/5 AND index_of_multiple_deprivation < 32844*3/5""",
            "4": """index_of_multiple_deprivation >= 32844*3/5 AND index_of_multiple_deprivation < 32844*4/5""",
            "5": """index_of_multiple_deprivation >= 32844*4/5 """,
        },
        index_of_multiple_deprivation=patients.address_as_of(
            "index_date",
            returning="index_of_multiple_deprivation",
            round_to_nearest=100,
        ),
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "0": 0.01,
                    "1": 0.20,
                    "2": 0.20,
                    "3": 0.20,
                    "4": 0.20,
                    "5": 0.19,
                }
            },
        },
    ),
    
    rural_urban=patients.address_as_of(
        "2020-03-01",
        returning="rural_urban_classification",
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {1: 0.125, 2: 0.125, 3: 0.125, 4: 0.125, 5: 0.125, 6: 0.125, 7: 0.125, 8: 0.125}},
        },
    ),

    # CAREHOME STATUS
    care_home_type=patients.care_home_status_as_of(
        "index_date",
        categorised_as={
            "Carehome": """
              IsPotentialCareHome
              AND LocationDoesNotRequireNursing='Y'
              AND LocationRequiresNursing='N'
            """,
            "Nursinghome": """
              IsPotentialCareHome
              AND LocationDoesNotRequireNursing='N'
              AND LocationRequiresNursing='Y'
            """,
            "Mixed": "IsPotentialCareHome",
            "": "DEFAULT",  # use empty string
        },
        return_expectations={
            "category": {"ratios": {"Carehome": 0.05, "Nursinghome": 0.05, "Mixed": 0.05, "": 0.85, }, },
            "incidence": 1,
        },
    ),

    # simple care home flag
    care_home_tpp=patients.satisfying(
        """care_home_type""",
        return_expectations={"incidence": 0.01},
    ),
    
    care_home_code=patients.with_these_clinical_events(
        carehome_primis_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01},
    ),
    
    household_id = patients.household_as_of(
        "2020-02-01",
        returning="pseudo_id",
        return_expectations = {
            "int": {"distribution": "normal", "mean": 100000, "stddev": 20000},
            "incidence": 1,
        },
    ),
    
    # mixed household flag 
    # nontpp_household = patients.household_as_of(
    #     "2020-02-01",
    #     returning="has_members_in_other_ehr_systems",
    #     return_expectations={"incidence": 0.75},
    # ),
    # # mixed household percentage 
    # tpp_coverage = patients.household_as_of(
    #     "2020-02-01", 
    #     returning="percentage_of_members_with_data_in_this_backend", 
    #     return_expectations={
    #         "int": {"distribution": "normal", "mean": 75, "stddev": 10},
    #         "incidence": 1,
    #     },
    # ),


    ###############################################################################
    # COVID VACCINATION
    ###############################################################################
    
    
    # any COVID vaccination (first dose)
    covid_vax_1_date=patients.with_tpp_vaccination_record(
        target_disease_matches="SARS-2 CORONAVIRUS",
        on_or_after="index_date + 1 day",  
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {
                "earliest": "2020-12-08",  # first vaccine administered on the 8/12
                "latest": "2021-02-01",
            }
        },
    ),
    # SECOND DOSE COVID VACCINATION - any type
    covid_vax_2_date=patients.with_tpp_vaccination_record(
        target_disease_matches="SARS-2 CORONAVIRUS",
        on_or_after="covid_vax_1_date + 15 days",
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
    # THIRD DOSE COVID VACCINATION - any type
    covid_vax_3_date=patients.with_tpp_vaccination_record(
        target_disease_matches="SARS-2 CORONAVIRUS",
        on_or_after="covid_vax_2_date + 1 day",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {
                "earliest": "2021-05-01", 
                "latest": "2021-06-30",
            }
        },
    ),

    
    # COVID VACCINATION TYPE = Pfizer BioNTech - first record of a pfizer vaccine 
       # NB *** may be patient's first COVID vaccine dose or their second if mixed types are given ***
    covid_vax_pfizer_1_date=patients.with_tpp_vaccination_record(
        product_name_matches="COVID-19 mRNA Vac BNT162b2 30mcg/0.3ml conc for susp for inj multidose vials (Pfizer-BioNTech)",
        on_or_after="index_date + 1 day",  
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {
                "earliest": "2020-12-08",  # first vaccine administered on the 8/12
                "latest": "2021-01-01",
            }
        },
    ),

    # SECOND DOSE COVID VACCINATION, TYPE = Pfizer (after patient's first dose of same vaccine type)
    covid_vax_pfizer_2_date=patients.with_tpp_vaccination_record(
        product_name_matches="COVID-19 mRNA Vac BNT162b2 30mcg/0.3ml conc for susp for inj multidose vials (Pfizer-BioNTech)",
        on_or_after="covid_vax_pfizer_1_date + 15 days",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {
                "earliest": "2020-12-29",  # first reported second dose administered on the 29/12
                "latest": "2021-02-01",
            }
        },
    ),
    
    # THIRD DOSE COVID VACCINATION, TYPE = Pfizer (after patient's second dose of same vaccine type)
    covid_vax_pfizer_3_date=patients.with_tpp_vaccination_record(
        product_name_matches="COVID-19 mRNA Vac BNT162b2 30mcg/0.3ml conc for susp for inj multidose vials (Pfizer-BioNTech)",
        on_or_after="covid_vax_pfizer_2_date + 1 day",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {
                "earliest": "2020-12-29",  # first reported second dose administered on the 29/12
                "latest": "2021-02-01",
            }
        },
    ),
    


    # COVID VACCINATION TYPE = Oxford AZ - first record of an Oxford AZ vaccine 
        # NB *** may be patient's first COVID vaccine dose or their second if mixed types are given ***
    covid_vax_az_1_date=patients.with_tpp_vaccination_record(
        product_name_matches="COVID-19 Vac AstraZeneca (ChAdOx1 S recomb) 5x10000000000 viral particles/0.5ml dose sol for inj MDV",
        on_or_after="index_date + 1 day",  
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {
                "earliest": "2021-01-04",  # first vaccine administered on the 4/1
                "latest": "2021-02-01",
            }
        },
    ),

    # SECOND DOSE COVID VACCINATION, TYPE = Oxford AZ
    covid_vax_az_2_date=patients.with_tpp_vaccination_record(
        product_name_matches="COVID-19 Vac AstraZeneca (ChAdOx1 S recomb) 5x10000000000 viral particles/0.5ml dose sol for inj MDV",
        on_or_after="covid_vax_az_1_date + 15 days",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {
                "earliest": "2021-02-01",
                "latest": "2021-03-01",
            }
        },
    ),

    # THIRD DOSE COVID VACCINATION, TYPE = Oxford AZ
    covid_vax_az_3_date=patients.with_tpp_vaccination_record(
        product_name_matches="COVID-19 Vac AstraZeneca (ChAdOx1 S recomb) 5x10000000000 viral particles/0.5ml dose sol for inj MDV",
        on_or_after="covid_vax_az_2_date + 1 day",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {
                "earliest": "2021-03-02",  
                "latest": "2021-04-01",
            }
        },
    ),
    

    unknown_vaccine_brand = patients.satisfying(
        """
        (
            covid_vax_1_date != ""
            AND
            covid_vax_pfizer_1_date = ""
            AND
            covid_vax_az_1_date = ""
        ) 
            OR 
        (
            covid_vax_pfizer_1_date = covid_vax_az_1_date 
            AND
            covid_vax_pfizer_1_date != "" 
            AND
            covid_vax_az_1_date != ""
        )
        """,
        return_expectations={"incidence": 0.0001},
    ),

    ################################################
    ############ pre-vaccine events ################
    ################################################
    # FIRST EVER SGSS POSITIVE
    prior_positive_test_date=patients.with_test_result_in_sgss(
        pathogen="SARS-CoV-2",
        test_result="positive",
        returning="date",
        date_format="YYYY-MM-DD",
        on_or_before="index_date",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-02-01"},
            "rate": "exponential_increase",
            "incidence": 0.01
        },
    ),
    # FIRST EVER PRIMARY CARE CASE IDENTIFICATION
    prior_primary_care_covid_case_date=patients.with_these_clinical_events(
        combine_codelists(
            covid_primary_care_code,
            covid_primary_care_positive_test,
            covid_primary_care_sequalae,
        ),
        returning="date",
        date_format="YYYY-MM-DD",
        on_or_before="index_date + 1 day",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-02-01"},
            "rate": "exponential_increase",
            "incidence": 0.01
        },
    ),
    
    # PRIOR COVID-RELATED HOSPITAL ADMISSION
    prior_covidadmitted_date=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=covid_codes,
        on_or_before="index_date",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-02-01"},
            "rate": "exponential_increase",
            "incidence": 0.01,
        },
    ),
    

    ################################################
    ############ events during study period ########
    ################################################
    
    # SGSS POSITIVE    
    covid_test_1_date=patients.with_test_result_in_sgss(
        pathogen="SARS-CoV-2",
        test_result="any",
        on_or_after="index_date + 1 day",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2021-01-01",  "latest" : "2021-02-01"},
            "rate": "exponential_increase",
        },
    ),
    covid_test_2_date=patients.with_test_result_in_sgss(
        pathogen="SARS-CoV-2",
        test_result="any",
        on_or_after="covid_test_1_date + 1 day",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2021-02-01", "latest" : "2021-04-01"},
            "rate": "uniform",
        },
    ),
    
    # SGSS POSITIVE    
    positive_test_1_date=patients.with_test_result_in_sgss(
        pathogen="SARS-CoV-2",
        test_result="positive",
        on_or_after="index_date + 1 day",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2021-01-01",  "latest" : "2021-02-01"},
            "rate": "exponential_increase",
        },
    ),
    positive_test_2_date=patients.with_test_result_in_sgss(
        pathogen="SARS-CoV-2",
        test_result="positive",
        on_or_after="positive_test_1_date + 1 day",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2021-02-01", "latest" : "2021-03-01"},
            "rate": "uniform",
        },
    ),
    positive_test_3_date=patients.with_test_result_in_sgss(
        pathogen="SARS-CoV-2",
        test_result="positive",
        on_or_after="positive_test_2_date + 1 day",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2021-04-01", "latest" : "2021-05-01"},
            "rate": "uniform",
        },
    ),
    positive_test_4_date=patients.with_test_result_in_sgss(
        pathogen="SARS-CoV-2",
        test_result="positive",
        on_or_after="positive_test_3_date + 1 day",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2021-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
        },
    ),
    
    
    # RIMARY CARE CASE IDENTIFICATION
    primary_care_covid_case_1_date=patients.with_these_clinical_events(
        combine_codelists(
            covid_primary_care_code,
            covid_primary_care_positive_test,
            covid_primary_care_sequalae,
        ),
        returning="date",
        find_last_match_in_period=True,
        date_format="YYYY-MM-DD",
        on_or_after="index_date + 1 day",
        return_expectations={
            "date": {"earliest": "2021-04-01", "latest" : "2021-05-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),
    
    primary_care_covid_case_2_date=patients.with_these_clinical_events(
        combine_codelists(
            covid_primary_care_code,
            covid_primary_care_positive_test,
            covid_primary_care_sequalae,
        ),
        returning="date",
        find_last_match_in_period=True,
        date_format="YYYY-MM-DD",
        on_or_after="primary_care_covid_case_1_date + 1 day",
        return_expectations={
            "date": {"earliest": "2021-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),


    # ANY EMERGENCY ATTENDANCE
    emergency_1_date=patients.attended_emergency_care(
        returning="date_arrived",
        on_or_after="index_date + 1 day",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2021-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),
    
    emergency_2_date=patients.attended_emergency_care(
        returning="date_arrived",
        on_or_after="emergency_1_date + 1 day",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2021-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    # COVID-RELATED UNPLANNED HOSPITAL ADMISSION
    covidadmitted_1_date=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=covid_codes,
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        on_or_after="index_date + 1 day",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2021-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),
    covidadmitted_2_date=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=covid_codes,
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        on_or_after="covidadmitted_1_date + 1 day",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2021-07-01", "latest" : "2021-08-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),
    covidadmitted_3_date=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=covid_codes,
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        on_or_after="covidadmitted_2_date + 1 day",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2021-07-01", "latest" : "2021-08-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),
    covidadmitted_4_date=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=covid_codes,
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        on_or_after="covidadmitted_3_date + 1 day",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2021-07-01", "latest" : "2021-08-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),
    

    # COVID-RELATED DEATH
    coviddeath_date=patients.with_these_codes_on_death_certificate(
        covid_codes,
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
    
    #######################################################
    ## unplanned hospital admissions during study period, up to 5  ##
    #######################################################

    admitted_unplanned_0_date=patients.admitted_to_hospital(
        returning="date_admitted",
        on_or_before="index_date",
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        with_patient_classification = ["1"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    discharged_unplanned_0_date=patients.admitted_to_hospital(
        returning="date_discharged",
        on_or_before="index_date",
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        with_patient_classification = ["1"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),    
    
    admitted_unplanned_1_date=patients.admitted_to_hospital(
        returning="date_admitted",
        on_or_after="index_date + 1 day",
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        with_patient_classification = ["1"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    discharged_unplanned_1_date=patients.admitted_to_hospital(
        returning="date_discharged",
        on_or_after="index_date + 1 day",
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        with_patient_classification = ["1"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    admitted_unplanned_2_date=patients.admitted_to_hospital(
        returning="date_admitted",
        on_or_after="admitted_unplanned_1_date + 1 day",
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        with_patient_classification = ["1"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    discharged_unplanned_2_date=patients.admitted_to_hospital(
        returning="date_discharged",
        on_or_after="admitted_unplanned_1_date + 1 day",
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        with_patient_classification = ["1"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    admitted_unplanned_3_date=patients.admitted_to_hospital(
        returning="date_admitted",
        on_or_after="admitted_unplanned_2_date + 1 day",
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        with_patient_classification = ["1"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    discharged_unplanned_3_date=patients.admitted_to_hospital(
        returning="date_discharged",
        on_or_after="admitted_unplanned_2_date + 1 day",
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        with_patient_classification = ["1"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),


    admitted_unplanned_4_date=patients.admitted_to_hospital(
        returning="date_admitted",
        on_or_after="admitted_unplanned_3_date + 1 day",
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        with_patient_classification = ["1"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    discharged_unplanned_4_date=patients.admitted_to_hospital(
        returning="date_discharged",
        on_or_after="admitted_unplanned_3_date + 1 day",
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        with_patient_classification = ["1"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),


    admitted_unplanned_5_date=patients.admitted_to_hospital(
        returning="date_admitted",
        on_or_after="admitted_unplanned_4_date + 1 day",
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        with_patient_classification = ["1"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    discharged_unplanned_5_date=patients.admitted_to_hospital(
        returning="date_discharged",
        on_or_after="admitted_unplanned_4_date + 1 day",
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        with_patient_classification = ["1"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),



    #######################################################
    ## unplanned infectious hospital admissions during study period, up to 5  ##
    #######################################################

    admitted_unplanned_infectious_0_date=patients.admitted_to_hospital(
        returning="date_admitted",
        on_or_before="index_date",
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        with_patient_classification = ["1"],
        with_these_diagnoses = ICD10_I_codes,
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    discharged_unplanned_infectious_0_date=patients.admitted_to_hospital(
        returning="date_discharged",
        on_or_before="index_date",
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        with_patient_classification = ["1"],
        with_these_diagnoses = ICD10_I_codes,
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),    
    
    admitted_unplanned_infectious_1_date=patients.admitted_to_hospital(
        returning="date_admitted",
        on_or_after="index_date + 1 day",
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        with_patient_classification = ["1"],
        with_these_diagnoses = ICD10_I_codes,
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    discharged_unplanned_infectious_1_date=patients.admitted_to_hospital(
        returning="date_discharged",
        on_or_after="index_date + 1 day",
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        with_patient_classification = ["1"],
        with_these_diagnoses = ICD10_I_codes,
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    admitted_unplanned_infectious_2_date=patients.admitted_to_hospital(
        returning="date_admitted",
        on_or_after="admitted_unplanned_infectious_1_date + 1 day",
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        with_patient_classification = ["1"],
        with_these_diagnoses = ICD10_I_codes,
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    discharged_unplanned_infectious_2_date=patients.admitted_to_hospital(
        returning="date_discharged",
        on_or_after="admitted_unplanned_infectious_1_date + 1 day",
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        with_patient_classification = ["1"],
        with_these_diagnoses = ICD10_I_codes,
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    admitted_unplanned_infectious_3_date=patients.admitted_to_hospital(
        returning="date_admitted",
        on_or_after="admitted_unplanned_infectious_2_date + 1 day",
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        with_patient_classification = ["1"],
        with_these_diagnoses = ICD10_I_codes,
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    discharged_unplanned_infectious_3_date=patients.admitted_to_hospital(
        returning="date_discharged",
        on_or_after="admitted_unplanned_infectious_2_date + 1 day",
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        with_patient_classification = ["1"],
        with_these_diagnoses = ICD10_I_codes,
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),


    admitted_unplanned_infectious_4_date=patients.admitted_to_hospital(
        returning="date_admitted",
        on_or_after="admitted_unplanned_infectious_3_date + 1 day",
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        with_patient_classification = ["1"],
        with_these_diagnoses = ICD10_I_codes,
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    discharged_unplanned_infectious_4_date=patients.admitted_to_hospital(
        returning="date_discharged",
        on_or_after="admitted_unplanned_infectious_3_date + 1 day",
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        with_patient_classification = ["1"],
        with_these_diagnoses = ICD10_I_codes,
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),


    admitted_unplanned_infectious_5_date=patients.admitted_to_hospital(
        returning="date_admitted",
        on_or_after="admitted_unplanned_infectious_4_date + 1 day",
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        with_patient_classification = ["1"],
        with_these_diagnoses = ICD10_I_codes,
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    discharged_unplanned_infectious_5_date=patients.admitted_to_hospital(
        returning="date_discharged",
        on_or_after="admitted_unplanned_infectious_4_date + 1 day",
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        with_patient_classification = ["1"],
        with_these_diagnoses = ICD10_I_codes,
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),





#######################################################
    ## planned hospital admissions during study period, up to 5  ##
    #######################################################

    admitted_planned_0_date=patients.admitted_to_hospital(
        returning="date_admitted",
        on_or_before="index_date",
        with_admission_method=["11", "12", "13", "81"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    discharged_planned_0_date=patients.admitted_to_hospital(
        returning="date_discharged",
        on_or_before="index_date",
        with_admission_method=["11", "12", "13", "81"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),    
    
    admitted_planned_1_date=patients.admitted_to_hospital(
        returning="date_admitted",
        on_or_after="index_date + 1 day",
        with_admission_method=["11", "12", "13", "81"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    discharged_planned_1_date=patients.admitted_to_hospital(
        returning="date_discharged",
        on_or_after="index_date + 1 day",
        with_admission_method=["11", "12", "13", "81"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    admitted_planned_2_date=patients.admitted_to_hospital(
        returning="date_admitted",
        on_or_after="admitted_planned_1_date + 1 day",
        with_admission_method=["11", "12", "13", "81"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    discharged_planned_2_date=patients.admitted_to_hospital(
        returning="date_discharged",
        on_or_after="admitted_planned_1_date + 1 day",
        with_admission_method=["11", "12", "13", "81"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    admitted_planned_3_date=patients.admitted_to_hospital(
        returning="date_admitted",
        on_or_after="admitted_planned_2_date + 1 day",
        with_admission_method=["11", "12", "13", "81"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    discharged_planned_3_date=patients.admitted_to_hospital(
        returning="date_discharged",
        on_or_after="admitted_planned_2_date + 1 day",
        with_admission_method=["11", "12", "13", "81"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),


    admitted_planned_4_date=patients.admitted_to_hospital(
        returning="date_admitted",
        on_or_after="admitted_planned_3_date + 1 day",
        with_admission_method=["11", "12", "13", "81"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    discharged_planned_4_date=patients.admitted_to_hospital(
        returning="date_discharged",
        on_or_after="admitted_planned_3_date + 1 day",
        with_admission_method=["11", "12", "13", "81"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),


    admitted_planned_5_date=patients.admitted_to_hospital(
        returning="date_admitted",
        on_or_after="admitted_planned_4_date + 1 day",
        with_admission_method=["11", "12", "13", "81"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    discharged_planned_5_date=patients.admitted_to_hospital(
        returning="date_discharged",
        on_or_after="admitted_planned_4_date + 1 day",
        with_admission_method=["11", "12", "13", "81"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest" : "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),




    ############################################################
    ## PRIMARY CARE COVID CODING DURING STUDY PERIOD, UP TO 5 ##
    ############################################################
    ## PROBABLE
    primary_care_probable_covid_1_date=patients.with_these_clinical_events(
        covid_primary_care_probable_combined,
        returning="date",
        on_or_after="index_date + 1 day",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest": "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),
    primary_care_probable_covid_2_date=patients.with_these_clinical_events(
        covid_primary_care_probable_combined,
        returning="date",
        on_or_after="primary_care_probable_covid_1_date + 1 day",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest": "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),
    primary_care_probable_covid_3_date=patients.with_these_clinical_events(
        covid_primary_care_probable_combined,
        returning="date",
        on_or_after="primary_care_probable_covid_2_date + 1 day",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest": "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),
    primary_care_probable_covid_4_date=patients.with_these_clinical_events(
        covid_primary_care_probable_combined,
        returning="date",
        on_or_after="primary_care_probable_covid_3_date + 1 day",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest": "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),
    primary_care_probable_covid_5_date=patients.with_these_clinical_events(
        covid_primary_care_probable_combined,
        returning="date",
        on_or_after="primary_care_probable_covid_4_date + 1 day",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest": "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),
    ## SUSPECTED
    primary_care_suspected_covid_1_date=patients.with_these_clinical_events(
        primary_care_suspected_covid_combined,
        returning="date",
        on_or_after="index_date + 1 day",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest": "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),
    primary_care_suspected_covid_2_date=patients.with_these_clinical_events(
        primary_care_suspected_covid_combined,
        returning="date",
        on_or_after="primary_care_suspected_covid_1_date + 1 day",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest": "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),
    primary_care_suspected_covid_3_date=patients.with_these_clinical_events(
        primary_care_suspected_covid_combined,
        returning="date",
        on_or_after="primary_care_suspected_covid_2_date + 1 day",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest": "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),
    primary_care_suspected_covid_4_date=patients.with_these_clinical_events(
        primary_care_suspected_covid_combined,
        returning="date",
        on_or_after="primary_care_suspected_covid_3_date + 1 day",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest": "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),
    primary_care_suspected_covid_5_date=patients.with_these_clinical_events(
        primary_care_suspected_covid_combined,
        returning="date",
        on_or_after="primary_care_suspected_covid_4_date + 1 day",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-05-01", "latest": "2021-06-01"},
            "rate": "uniform",
            "incidence": 0.05,
        },
    ),

    
    
    ############################################################
    ######### CLINICAL CO-MORBIDITIES ##########################
    ############################################################
    ### THESE CODELISTS ARE AVAILABLE ON CODELISTS.OPENSAFELY.ORG
    #### AND CAN BE UPDATED. PLEASE REVIEW AND CHECK YOU ARE HAPPY
    #### WITH THE CODELIST USED #################################


    chronic_cardiac_disease=patients.with_these_clinical_events(
        chronic_cardiac_disease_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01},
    ),
    heart_failure=patients.with_these_clinical_events(
        heart_failure_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01},
    ),
    other_heart_disease=patients.with_these_clinical_events(
        other_heart_disease_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01},
    ),

    diabetes=patients.with_these_clinical_events(
        diabetes_codes,
        returning="binary_flag",
        find_last_match_in_period=True,
        on_or_before="index_date",
        return_expectations={"incidence": 0.01},
    ),
    dialysis=patients.with_these_clinical_events(
        dialysis_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    chronic_liver_disease=patients.with_these_clinical_events(
        chronic_liver_disease_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01},
    ),
    
    current_copd=patients.with_these_clinical_events(
        current_copd_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01},
    ),
    LD_incl_DS_and_CP=patients.with_these_clinical_events(
        learning_disability_including_downs_syndrome_and_cerebral_palsy_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    cystic_fibrosis=patients.with_these_clinical_events(
        cystic_fibrosis_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    other_resp_conditions=patients.with_these_clinical_events(
        other_respiratory_conditions_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01},
    ),
    
    
    lung_cancer=patients.with_these_clinical_events(
        lung_cancer_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    haematological_cancer=patients.with_these_clinical_events(
        haematological_cancer_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    cancer_excl_lung_and_haem=patients.with_these_clinical_events(
        cancer_excluding_lung_and_haematological_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    
    chemo_or_radio=patients.with_these_clinical_events(
        chemotherapy_or_radiotherapy_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    solid_organ_transplantation=patients.with_these_clinical_events(
        solid_organ_transplantation_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    bone_marrow_transplant=patients.with_these_clinical_events(
        bone_marrow_transplant_codes,
        between=["2020-07-01", "index_date"],
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    
    sickle_cell_disease=patients.with_these_clinical_events(
        sickle_cell_disease_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    permanant_immunosuppression=patients.with_these_clinical_events(
        permanent_immunosuppression_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    temporary_immunosuppression=patients.with_these_clinical_events(
        temporary_immunosuppression_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    asplenia=patients.with_these_clinical_events(
        asplenia_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    dmards=patients.with_these_medications(
        dmards_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    # dementia
    dementia=patients.with_these_clinical_events(
        dementia_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),
    other_neuro_conditions=patients.with_these_clinical_events(
        other_neuro_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01},
    ),
    
    psychosis_schiz_bipolar=patients.with_these_clinical_events(
        psychosis_schizophrenia_bipolar_affective_disease_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.01, },
    ),

    flu_vaccine=patients.satisfying(
        """
        flu_vaccine_tpp_table>0 OR
        flu_vaccine_med>0 OR
        flu_vaccine_clinical>0
        """,
        
        flu_vaccine_tpp_table=patients.with_tpp_vaccination_record(
            target_disease_matches="INFLUENZA",
            between=["2015-04-01", "2020-03-31"], 
            returning="binary_flag",
        ),
        
        flu_vaccine_med=patients.with_these_medications(
            flu_med_codes,
            between=["2015-04-01", "2020-03-31"], 
            returning="binary_flag",
        ),
        flu_vaccine_clinical=patients.with_these_clinical_events(
            flu_clinical_given_codes,
            ignore_days_where_these_codes_occur=flu_clinical_not_given_codes,
            between=["2015-04-01", "2020-03-31"], 
            returning="binary_flag",
        ),
        
        return_expectations={"incidence": 0.5, },
    ),
    
    efi = patients.with_these_decision_support_values(
        algorithm = "electronic_frailty_index",
        on_or_before = "2020-12-08", # hard-coded because there are no other dates available for efi
        find_last_match_in_period = True,
        returning="numeric_value",
        return_expectations={
            #"category": {"ratios": {0.1: 0.25, 0.15: 0.25, 0.30: 0.25, 0.5: 0.25}},
            "float": {"distribution": "normal", "mean": 0.15, "stddev": 0.05},
            "incidence": 0.99
        },
    ),

    endoflife = patients.satisfying(
        """
        midazolam OR
        endoflife_coding
        """,
        
        midazolam = patients.with_these_medications(
            midazolam_codes,
            returning="binary_flag",
            on_or_before = "index_date",
        ),
    
        endoflife_coding = patients.with_these_clinical_events(
            eol_codes,
            returning="binary_flag",
            on_or_before = "index_date",
            find_last_match_in_period = True,
        ),
        
        return_expectations={"incidence": 0.001},
    
    ),
    
    
    
    ############################################################
    ######### PRIMIS CODELIST DERIVED CLINICAL VARIABLES     ###
    ############################################################


    shielded_ever = patients.with_these_clinical_events(
            shield_codes,
            returning="binary_flag",
            on_or_before = "index_date",
            find_last_match_in_period = True,
        ),

    shielded = patients.satisfying(
        """severely_clinically_vulnerable AND NOT less_vulnerable""", 

        ### SHIELDED GROUP - first flag all patients with "high risk" codes
        severely_clinically_vulnerable=patients.with_these_clinical_events(
            shield_codes,
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
            nonshield_codes, 
            between=["date_severely_clinically_vulnerable + 1 day", "index_date"],
        ),
        
        return_expectations={"incidence": 0.01},
    ),
    
)
