# Comparative vaccine effectiveness in health and social care workers

This study investigates the relative effectiveness of Oxford-AstraZenenca versus Pfizer-BNT vaccines in vaccinated health and social care workers. 

Occupation is identified at the time of vaccination.

* The [protocol is in the OpenSAFELY Google drive](https://docs.google.com/document/d/1eQ6N0JiFmUOFP2EA-AEE3PhGJ8yxjHEaA5IVSehOAXI/edit#)
* Raw model outputs, including charts, crosstabs, etc, are in `released_outputs/`
* If you are interested in how we defined our variables, take a look at the [study definition](analysis/study_definition.py); this is written in `python`, but non-programmers should be able to understand what is going on there
* If you are interested in how we defined our code lists, look in the [codelists folder](./codelists/).
* Developers and epidemiologists interested in the framework should review [the OpenSAFELY documentation](https://docs.opensafely.org)

# About the OpenSAFELY framework

The OpenSAFELY framework is a secure analytics platform for
electronic health records research in the NHS.

Instead of requesting access for slices of patient data and
transporting them elsewhere for analysis, the framework supports
developing analytics against dummy data, and then running against the
real data *within the same infrastructure that the data is stored*.
Read more at [OpenSAFELY.org](https://opensafely.org).
