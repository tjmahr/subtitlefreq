
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
    dplyr::mutate(word = stringr::str_replace_all(word, rules)) |>
    tidytext::unnest_tokens(word, word) |>
    dplyr::group_by(word) |>
    dplyr::summarise(n = sum(n)) |>
    dplyr::arrange(dplyr::desc(n))

}
