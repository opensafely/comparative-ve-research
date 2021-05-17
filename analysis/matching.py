from osmatching import match

match(
    case_csv="data_vax_az_only",
    match_csv="data_vax_pfizer_only",
    matches_per_case=1,
    match_variables={
        "sex": "category",
        "age": 1,
        "region": "category",
        "vax_day": 0
    },
    index_date_variable="covid_vax_1_date",
    closest_match_variables=["age"],
    min_matches_per_case=1,
    indicator_variable_name ="az",
    output_path="output"
)
