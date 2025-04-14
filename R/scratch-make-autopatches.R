# interactive script for exploring results and making patches

library(tidyverse)
targets::tar_load(data_counts_patched)
targets::tar_load(data_raw_corpus_patched)
data_counts_patched$word |>
  str_subset("subrip")

urls <- data_raw_corpus_patched$line |>
  str_subset(fixed("Synchro: ", ignore_case = TRUE))

zap_lines <- function(data, pattern) {
  fixed_ic <- function(...) fixed(..., ignore_case = TRUE)
  indices <- data[["line"]] |>
    str_which(fixed_ic(pattern))
  message(paste0("Zapping `", pattern, "`: ", length(indices), " lines"))
  data[["line"]][indices] <- ""
  data
}

zap_lines_re <- function(data, pattern) {
  regex_ic <- function(...) regex(..., ignore_case = TRUE)
  indices <- data[["line"]] |>
    str_which(regex_ic(pattern))
  message(paste0("Zapping `", pattern, "`: ", length(indices), " lines"))
  data[["line"]][indices] <- ""
  data
}


data_raw_corpus_patched <- data_raw_corpus_patched |>
  zap_lines("English Subtitle: ")


data_raw_corpus_patched$line |>
  str_subset(regex_ic("\\w[.]com"))
data_raw_corpus_patched$line |>
  str_subset(fixed_ic("subtitles")) |>
  table() |>
  sort()

try <- data_counts_patched$word %>%
  str_subset(regex("\\w{2,}[,.]\\w{2,}")) %>%
  unlist()

try <- try |>
  str_subset("\\d", negate = TRUE)
  # str_subset("'s$", negate = TRUE) |>
  # str_subset("'ll$", negate = TRUE) |>
# str_subset("^o'", negate = TRUE)
data <- tibble(
  match = try,
  guess = try %>%
    str_replace("'", "' "),
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


targets::tar_load(data_counts_patched)
data_pooled <- data_counts_patched
data_pooled$word |>
  sample(size = 20)
# data_pooled$word |> str_subset("to/d")

data_pooled$word |>
  explore_splits("with") |>
  pull() |>
  writeLines()

data_patched_lines <- data_raw_corpus_patched
data_patched_lines$line |> str_subset(regex_ic("\\bbiddles\\b"))

inc <- data_counts_patched$word |> str_subset(regex_ic("ln(p|r|s|v|w|y|z)"))

paste0(inc, ",", str_replace_all(inc, "ln(p|r|s|v|w|y|z)", "in\\1")) |> sort() |>
  writeLines()


data_pooled |>
  mutate(
    word2 = word |> str_replace_all("l", "i"),
    patch = paste0(word, ",", word2)
  ) |>
  filter(hunspell::hunspell_check(word2), word != word2) |>
  pull(patch) |>
  writeLines()

