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
      "data/Subtlex.US.txt"
    }
  ),

  # read the corpus into a tibble, adding batch numbers
  tar_target(
    "data_raw_corpus",
    tibble::tibble(
      line = readr::read_lines(txt_raw_corpus),
      batch = line |> purrr::rep_along(seq_len(num_batches)) |> sort()
    ),
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
      patch_false_spaces() |>
      patch_text_contractions(),
    format = "fst_tbl"
  ),



  # count words in each batch
  tar_target(
    "data_counts_by_batch",
    data_raw_corpus_patched |>
      tidyr::nest(data = line) |>
      dplyr::mutate(
        # count words in parallel
        counts = furrr::future_map(data, count_words_in_tibble)
      ) |>
      dplyr::select(batch, counts) |>
      tidyr::unnest(counts)
  ),

  # combine all the counts together
  tar_target(
    "data_counts_pooled",
    data_counts_by_batch |>
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

  # apply patches
  tar_target(
    "data_counts_patched",
    patch_word_counts(data_counts_pooled, data_patches)
  ),

  tar_render(readme, "README.Rmd")
)


