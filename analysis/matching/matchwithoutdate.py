from osmatching import match

match(
    case_csv="data_vax_az_withoutdate",
    match_csv="data_vax_pfizer_withoutdate",
    matches_per_case=1,
    match_variables={
        "sex": "category",
        "age": 3,
        "region": "category",
        "imd": 500,
        "ethnicity_combined": "category"
        
    },
    index_date_variable="vax1_date",
    closest_match_variables=["age"],
    min_matches_per_case=1,
    indicator_variable_name ="az",
    output_path="output/data",
    output_suffix="_withoutdate"
)
