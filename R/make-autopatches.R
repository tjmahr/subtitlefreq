library(tidyverse)
targets::tar_load(data_counts_patched)
targets::tar_load(data_raw_corpus)

try <- data_counts_patched$word %>%
  str_subset(regex("'ve\\w+")) %>%
  unlist()
try

data_raw_corpus$line %>%
  str_subset(fixed("ain'tight"))

data <- tibble(
  match = try,
  guess = try %>%
    str_replace("'ve", "'ve "),
  fix = guess,
  line = paste0(match, ",", fix),
  left = str_extract(guess, "^.+ "),
  right = str_extract(guess, " .+$"),
  spell_l = hunspell::hunspell_check(left),
  spell_r = hunspell::hunspell_check(right)
)
data$match %>% str_subset("est$")

data %>%
  arrange(match) %>%
  filter(spell_r) %>%
  pull(line) %>%
  unique() %>%
  writeClipboard()

writeLines()


data$fix

