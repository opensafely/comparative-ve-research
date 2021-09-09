library('tidyverse')
library('here')
library('gt')

# import codelists from json
codelists <- jsonlite::read_json(
  path=here("codelists", "codelists.json"),
)


# reformat
codelists_formatted <- enframe(codelists[[1]]) %>% unnest_wider(value) %>%
  mutate(
    file = name,
    name= str_extract(id, "(?<=/)(.+)(?=/)"),
    downloaded_at = as.Date(downloaded_at, "%Y-%m-%d")
  )

# output to html
codelists_formatted %>%
  select(name, url, downloaded_at) %>%
  gt() %>%
    cols_label(
      name = "Name",
      url = "URL",
      downloaded_at = "Accessed on"
    ) %>%
    gtsave(here("output", "codelists.html"))

