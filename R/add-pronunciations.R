library(tidyverse)
okay <- read_lines("https://github.com/cmusphinx/cmudict/raw/master/cmudict.dict")

df <- okay |>
  str_replace_all("#.*", "") |>
  str_split_fixed(" ", 2) |>
  as.data.frame() |>
  magrittr::set_colnames(c("word", "phones")) |>
  as_tibble()

df <- df |>
  mutate(
    phones = phones |> stringr::str_remove_all("\\d"),
    word = word |>
      stringr::str_remove_all("[(]\\d+[)]")
  ) |>
  group_by(word) |>
  mutate(pronunciation_number = seq_along(phones)) |>
  ungroup()

freq <- targets::tar_read("data_counts_patched")

df |>
  inner_join(freq) |>
  write_csv("freqs-with-phones.csv")


subset_neighbors <- function(data, pronunciation_col, target_string, ...) {
  pronunciation_col <- enquo(pronunciation_col)
  words <- data |> pull(!! pronunciation_col )
  data[LexFindR::get_neighbors(target_string, words, ...), ]
}


df |>
  subset_neighbors(phones, "D OW N T") |>
  left_join(freq) |>
  filter(!is.na(n), pronunciation_number == 1) |>
  print(n = Inf)

df |>
  subset_neighbors(phones, "S N OW") |>
  left_join(freq) |>
  filter(!is.na(n), pronunciation_number == 1) |>
  print(n = Inf)
