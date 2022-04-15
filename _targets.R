library(targets)
library(tarchetypes)
library(future)
library(furrr)
library(tidyverse)
plan(multisession)

source("R/functions.R")
num_batches <- 200

list(
  tar_file(
    "file_subtlexus",
    {
      osfr::osf_retrieve_node("djpqz") |>
        osfr::osf_ls_files(pattern = "SUBTLEX-US frequency") |>
        osfr::osf_download(path = "data", conflicts = "skip") |>
        dplyr::pull(local_path)
    }
  ),

  tar_target(
    data_subtlexus,
    readxl::read_excel(file_subtlexus)
  ),


  # original compressed file
  tar_file("rar_raw_corpus", "data/Subtlex US.rar"),

  # extract the corpus file and move to a convenient location
  tar_file(
    "txt_raw_corpus",
    {
      archive::archive_extract(
        archive = rar_raw_corpus,
        dir = "data",
        files = "Subtlex US/Subtlex.US.txt"
      )
      fs::file_move("data/Subtlex US/Subtlex.US.txt", "data/Subtlex.US.txt")
      fs::dir_delete("data/Subtlex US")

      a <- shell("bash data/patch-line.sh")
      file.remove("data/Subtlex.US.txt")
      file.rename("data/Subtlex.US2.txt", "data/Subtlex.US.txt")
      "data/Subtlex.US.txt"
    }
  ),

  # read the corpus into a tibble, adding batch numbers
  tar_target(
    "data_raw_corpus",
    tibble::tibble(
      line = readr::read_lines(txt_raw_corpus),
      index = seq_along(line),
      batch = line |> purrr::rep_along(seq_len(num_batches)) |> sort()
    ) |>
      dplyr::relocate(index, batch, line),
    format = "fst_tbl"
  ),

  tar_target(
    "data_raw_corpus_patched",
    data_raw_corpus |>
      dplyr::mutate(
        line = line |>
          stringr::str_remove_all(stringr::fixed("{i", ignore_case = TRUE)) |>
          stringr::str_remove_all(stringr::fixed("{/i", ignore_case = TRUE))
      ) |>
      patch_encoding() |>
      patch_false_spaces() |>
      patch_text_contractions() |>
      patch_easy_ocr_errors(),
    format = "fst_tbl"
  ),

  # count words in each batch and combine
  tar_target(
    "data_counts_pooled",
    data_raw_corpus_patched |>
      dplyr::select(-index) |>
      tidyr::nest(data = line) |>
      dplyr::mutate(
        # count words in parallel
        counts = furrr::future_map(data, count_words_in_tibble)
      ) |>
      dplyr::select(batch, counts) |>
      tidyr::unnest(counts) |>
      # combine all the counts together
      dplyr::group_by(word) |>
      dplyr::summarise(n = sum(n)) |>
      dplyr::arrange(dplyr::desc(n))
  ),

  # count words in each batch
  tar_target(
    "data_counts_pooled_raw_lines",
    data_raw_corpus |>
      dplyr::select(-index) |>
      tidyr::nest(data = line) |>
      dplyr::mutate(
        # count words in parallel
        counts = furrr::future_map(data, count_words_in_tibble)
      ) |>
      dplyr::select(batch, counts) |>
      tidyr::unnest(counts) |>
      dplyr::group_by(word) |>
      dplyr::summarise(n = sum(n)) |>
      dplyr::arrange(dplyr::desc(n))
  ),

  # read in a file of patches for typos in the counts
  tar_file_read(
    data_patches,
    command = "data/patches.csv",
    read = readr::read_csv(!! .x, col_types = "cc")
  ),

  # read in a file of patches for typos in the counts
  tar_file_read(
    data_patches_regex,
    command = "data/patches-regex.csv",
    read = readr::read_csv(!! .x, col_types = "cc")
  ),

  # apply patches
  tar_target(
    "data_counts_patched",
    data_counts_pooled |>
      patch_word_counts(data_patches) |>
      patch_word_counts(data_patches_regex)
  ),

  tar_render(readme, "README.Rmd")
)


