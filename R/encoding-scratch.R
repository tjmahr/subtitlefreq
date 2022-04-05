
library(tidyverse)

maybe_bad <- data$word |>
  str_subset("l") |>
  str_subset("i", negate = TRUE)
maybe_good <- maybe_bad |>
  str_replace_all("l", "i")

tibble(maybe_bad, maybe_good) |>
  filter(maybe_good %in% data$word) |>
  inner_join(data, by = c(maybe_bad = "word")) |>
  rename(maybe_bad_n = n) |>
  inner_join(data, by = c(maybe_good = "word")) |>
  rename(maybe_good_n = n) |>
  arrange(desc(maybe_bad_n )) |>
  filter(maybe_good_n > maybe_bad_n) |>
  mutate(paste0(maybe_bad, ",", maybe_good)) |>
  print(n = 100)




z <- "There you go. Number 53.  Dr. von Hagens\x92 Body Worlds  invites visitors\x85   \x85to observe the body\x92s various  locomotive, digestive\x85   \x85nervous and vascular systems.   Please may I have your attention,  ladies and gentlemen?   I believe it is something very special,  what we see here.   This is edutainment.   -fixed in dramatic and athletic poses\x85   \x85 that reveal the true-to-life spatial  relationships amongst organs"

data_raw <- targets::tar_read(data_raw_corpus)
data_raw$line |> str_subset(regex("aslan", ignore_case = TRUE))

# Find which lines have some garbages in them
zs <- data_raw$line
z2s <- iconv(zs, "", "ASCII", sub = "byte")
i_z2s <- z2s |> stringr::str_which("<.+>")

# We could modify the elements in here
z2s[i_z2s]

# then repair the main data by inserting them here
# zs[i_z2s] <- z2s[i_z2s]

data <- targets::tar_read("data_counts_patched")

a <- sample(data$word, 50)
unlist(a)
unlist(tokenizers::tokenize_word_stems(a))
library(SnowballC)
wordStem(c("win", "winning", "winner"))



library(tokenizers)

# Simple example

# Test some of the vocabulary supplied at https://github.com/snowballstem/snowball-data
for(lang in getStemLanguages()) {
  load(system.file("words", paste0(lang, ".RData"), package="SnowballC"))

  stopifnot(all(wordStem(dat$words, lang) == dat$stem))
}
