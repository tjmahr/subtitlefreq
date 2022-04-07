library(dplyr)
library(stringr)

count_words_in_lines <- function(x) {
  tibble::tibble(line = x) |>
    tidytext::unnest_tokens(word, line) |>
    count(word)
}


count_words_in_tibble <- function(x) {
  x |>
    tidytext::unnest_tokens(word, line) |>
    count(word)
}


patch_word_counts <- function(data_counts, data_patches) {
  rules <- stats::setNames(data_patches$new, paste0("^", data_patches$old, "$"))

  data_counts |>
    mutate(word = str_replace_all(word, rules)) |>
    tidytext::unnest_tokens(word, word) |>
    group_by(word) |>
    summarise(n = sum(n)) |>
    arrange(desc(n))

}

patch_text_contractions <- function(data) {
  pat_nt <- regex("(didn|wouldn|wasn|should|isn|aren) 't", ignore_case = TRUE)
  data |>
    # filter(str_detect(line, regex("(?<=\\W)don 't", ignore_case = TRUE)))
    mutate(
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
    mutate(
      line = line |>
        str_replace_all(pat_to, " to ") |>
        str_replace_all(pat_that, " that ") |>
        str_replace_all(pat_thats, " that's ")
    )
}


patch_easy_ocr_errors <- function(data) {
  # find XlX (ClA)
  pat_l_between_caps <- regex("([A-Z])l([A-Z])")
  # ignore xXlX
  pat_l_between_caps_false1 <- regex("[a-km-z]([A-Z])l([A-Z])")
  # ignore XlXx
  pat_l_between_caps_false2 <- regex("([A-Z])l([A-Z])[a-km-z]")
  # ignore AlI ("All" with bad OCR)
  pat_l_between_caps_false3 <- regex("(\\W|^)AlI")

  data_xlx <- data |>
    filter(str_detect(line, pat_l_between_caps)) |>
    filter(!str_detect(line, pat_l_between_caps_false1)) |>
    filter(!str_detect(line, pat_l_between_caps_false2)) |>
    filter(!str_detect(line, pat_l_between_caps_false3)) |>
    mutate(
      line = line |>
        str_replace_all(pat_l_between_caps, "\\1I\\2") |>
        # running it again to fix things like "COMMUNlTlES"
        str_replace_all(pat_l_between_caps, "\\1I\\2")
    )

  data <- data |>
    anti_join(data_xlx, by = "index") |>
    bind_rows(data_xlx) |>
    arrange(index)


  # K -> lK errors
  pat_lk <- regex("(^| |Mc)(lK)([a-z]+)")
  data_lk <- data |>
    filter(str_detect(line, pat_lk)) |>
    mutate(
      line = line |> str_replace_all(pat_lk, "\\1K\\3")
    )

  data <- data |>
    anti_join(data_lk, by = "index") |>
    bind_rows(data_lk) |>
    arrange(index)

  # very short lXx and lXXx words
  data_lxx <- data |>
    filter(str_detect(line, "( |^)l[A-Z]{1,2}[a-z]")) |>
    mutate(
      line = line |>
        str_replace_all(" lVs", " IVs") |>
        str_replace_all(" lMs", " IMs") |>
        str_replace_all(" lMd", " IMed") |>
        str_replace_all(" lMing", " IMing") |>
        str_replace_all(" lQs", " IQs") |>
        str_replace_all(" lDs", " IDs") |>
        str_replace_all(" lDed", " IDed") |>
        str_replace_all(" lDd", " IDed") |>
        str_replace_all(" lDing", " IDing") |>
        str_replace_all(" lCs", " ICs") |>
        str_replace_all(" lTs", " ITs") |>
        str_replace_all("lNsiDE", "INSIDE") |>
        str_replace_all("lOst", "lost") |>
        str_replace_all("lOt", "lot") |>
        str_replace_all("lOUs", "IOUs") |>
        str_replace_all("lPOs", "IPOs") |>
        str_replace_all("lBMs", "IBMs") |>
        str_replace_all("lSPs", "ISPs") |>
        str_replace_all("lMGs", "IMGs") |>
        str_replace_all("lRAs", "IRAs") |>
        str_replace_all("lKKennard", "Kennard") |>
        str_replace_all("lSVs", "ISVs")
    ) |>
    filter(str_detect(line, "l[A-Z]{1,2}[a-z]"))

  data <- data |>
    anti_join(data_lxx, by = "index") |>
    bind_rows(data_lxx) |>
    arrange(index)

  # lXX words
  data_lxx2 <- data |>
    filter(str_detect(line, " l[A-Z][A-Z]+")) |>
    mutate(
      line = line |>
        str_replace_all(" l([A-Z][A-Z]+)", " I\\1")
    )

  data <- data |>
    anti_join(data_lxx2, by = "index") |>
    bind_rows(data_lxx2) |>
    arrange(index)

  # XX lX -> X IX
  data_lx1 <- data |>
    filter(str_detect(line, "[A-Z][A-Z]+ l[A-Z]")) |>
    mutate(
      line = line |>
        str_replace_all("([A-Z][A-Z]+) l([A-Z])", "\\1 I\\2")
    )

  data <- data |>
    anti_join(data_lx1, by = "index") |>
    bind_rows(data_lx1) |>
    arrange(index)

  # lX XX -> IX XX
  data_lx2 <- data |>
    filter(str_detect(line, "l[A-Z] [A-Z][A-Z]+")) |>
    filter(!str_detect(line, pat_l_between_caps_false3)) |>
    mutate(
      line = line |>
        str_replace_all("l([A-Z]) ([A-Z][A-Z]+)", "I\\1 \\2")
    )

  data <- data |>
    anti_join(data_lx2, by = "index") |>
    bind_rows(data_lx2) |>
    arrange(index)


  # XXl -> XXI (FBl -> FBI)
   data_xxl <- data |>
    filter(str_detect(line, "[A-Z][A-Z]l( |$)")) |>
    mutate(
      line = line |>
        str_replace_all("([A-Z][A-Z])l( |$)", "\\1I\\2")
    )

   data <- data |>
     anti_join(data_xxl, by = "index") |>
     bind_rows(data_xxl) |>
     arrange(index)

   data
 }
