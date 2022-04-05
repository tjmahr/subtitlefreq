library(stringr)

count_words_in_lines <- function(x) {
  tibble::tibble(line = x) |>
    tidytext::unnest_tokens(word, line) |>
    dplyr::count(word)
}


count_words_in_tibble <- function(x) {
  x |>
    tidytext::unnest_tokens(word, line) |>
    dplyr::count(word)
}


patch_word_counts <- function(data_counts, data_patches) {
  rules <- stats::setNames(data_patches$new, paste0("^", data_patches$old, "$"))

  data_counts |>
    # dplyr::filter(word %in% data_patches$old) |>
    dplyr::mutate(word = str_replace_all(word, rules)) |>
    tidytext::unnest_tokens(word, word) |>
    dplyr::group_by(word) |>
    dplyr::summarise(n = sum(n)) |>
    dplyr::arrange(dplyr::desc(n))

}

patch_text_contractions <- function(data) {
  pat_nt <- regex("(didn|wouldn|wasn|should|isn|aren) 't", ignore_case = TRUE)
  data |>
    # filter(str_detect(line, regex("(?<=\\W)don 't", ignore_case = TRUE)))
    dplyr::mutate(
      line = line |>
        str_replace_all(pat_nt, " \\1't ") |>
        str_replace_all(
          pattern = regex("(?<=\\W)don 't", ignore_case = TRUE),
          replacement = " don't "
        ) |>
        str_replace_all(
          pattern = regex("(?<=\\W)can 't", ignore_case = TRUE),
          replacement = " can't "
        )
    )
}

patch_false_spaces <- function(data) {
  pat_to <- regex(" t o (?=\\S\\S+)", ignore_case = TRUE)
  pat_that <- regex("\\Wt hat ", ignore_case = TRUE)
  pat_thats <- regex("\\Wt hat's ", ignore_case = TRUE)

  data |>
    dplyr::mutate(
      line = line |>
        str_replace_all(pat_to, " to ") |>
        str_replace_all(pat_that, " that ") |>
        str_replace_all(pat_thats, " that's ")
    )
}
