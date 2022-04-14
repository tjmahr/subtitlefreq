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
  pat_nt <- regex("(doesn|didn|wouldn|wasn|hadn|shouldn|isn|aren)( 't| ' t | t | ' t$)", ignore_case = TRUE)
  # pat_bad_contractions <- regex("�(t|m|s|d|ll|il|ve)(\\W)|$", ignore_case = TRUE)
  pat_quote_contractions <- regex("(\\w)\\\"(t|m|s|d|ll|il|ve)(\\W)|$", ignore_case = TRUE)

  data |>
    # filter(str_detect(line, regex("(?<=\\W)don 't", ignore_case = TRUE)))
    mutate(
      line = line |>
        str_replace_all(pat_nt, " \\1't ") |>
        str_replace_all(
          pattern = regex("(?<=\\W)don( 't| ' t | t | ' t$)", ignore_case = TRUE),
          replacement = " don't "
        ) |>
        str_replace_all(
          pattern = regex("(?<=\\W)won( 't| ' t | t | ' t$)", ignore_case = TRUE),
          replacement = " won't "
        ) |>
        str_replace_all(
          pattern = regex("(?<=\\W)can( 't| ' t | t | ' t$)", ignore_case = TRUE),
          replacement = " can't "
        ) |>
        str_replace_all(
          pattern = regex("(?<=\\W)I( 'd| ' d | ' d$)", ignore_case = TRUE),
          replacement = " I'd "
        ) |>
        str_replace_all(
          pattern = regex("([A-z]+)( ' s | ' s$)", ignore_case = TRUE),
          replacement = " \\1's "
        ) |>
        # str_replace_all(pat_bad_contractions, "'\\1\\2") |>
        str_replace_all(pat_quote_contractions, "\\1'\\2\\3")
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


patch_encoding <- function(data, raw_file) {
  gsub_bytes <- function(x, pattern, replacement) {
    gsub(pattern = pattern, replacement = replacement, x = x, useBytes = TRUE)
  }

  grep_bytes <- function(x, pattern, invert = FALSE) {
    grep(
      pattern = pattern,
      x = x,
      value = TRUE,
      useBytes = TRUE,
      invert = invert
    )
  }

  pat_bad_char <- "�"
  enc <- data |>
    filter(str_detect(line, pat_bad_char))

  # This doesn't read every line :( !!!
  lines_raw <- readLines(raw_file)

  # lines_raw2 <- readLines(raw_file, )
  # tail(lines_raw)
  # lines_raw <- stringi::stri_read_lines(raw_file)
  # tail(lines_raw)
  # lines_raw2 <- readLines(raw_file, encoding = "UTF-8")


  lines_repaired <- lines_raw[enc$index] |>
    # two-character cases
    gsub_bytes("crudit\xa0\xc1s", "crudités") |>
    gsub_bytes("\xa1\xa6", "...") |>
    gsub_bytes("\xa1\xad", " ") |>
    gsub_bytes("\xa1\xb0", " ") |>
    gsub_bytes("\xa1\xd3", " ") |>
    gsub_bytes("\xa2\xdc", "") |>
    gsub_bytes("\xe2\x80", " ") |>
    gsub_bytes("\xb0\xb0", " ") |>
    gsub_bytes("\xb4\xb4", " ") |>
    gsub_bytes("\xa3\xba", " ") |>
    gsub_bytes("\xa1\xb1", " ") |>
    gsub_bytes("\xa3\xbf", " ") |>
    gsub_bytes("\xa2\xdc", " ") |>
    gsub_bytes("\xa7\xa7", " ") |>
    gsub_bytes("\xa1\xaa", " ") |>
    gsub_bytes("\xb6\xb6", " ") |>
    gsub_bytes("\xa1\xc9", "¡É") |>
    # gsub_bytes("\xef\xbf\xbd", "na") |>
    gsub_bytes("fianc\xc8e", "fiancèe") |>
    gsub_bytes("Voil\xc3", "Voilà") |>
    # these all have equivalent meanings in ISO-8859-1 and WINDOWS-1252
    gsub_bytes("\xea", "ê") |>
    gsub_bytes("\xeb", "ë") |>
    gsub_bytes("\xed", "í") |>
    gsub_bytes("\xee", "î") |>
    gsub_bytes("\xe1", "á") |>
    gsub_bytes("\xe3", "ã") |>
    gsub_bytes("\xe4", "ä") |>
    gsub_bytes("\xe2", "â") |>
    gsub_bytes("\xe7", "ç") |>
    gsub_bytes("\xe8", "è") |>
    gsub_bytes("\xe9", "é") |>
    gsub_bytes("\xe0", "à") |>
    gsub_bytes("\xf3", "ó") |>
    gsub_bytes("\xf4", "ô") |>
    gsub_bytes("\xf6", "ö") |>
    gsub_bytes("\xf8", "ø") |>
    gsub_bytes("\xfa", "ú") |>
    gsub_bytes("\xfc", "ü") |>
    gsub_bytes("\xa0", " ") |>
    gsub_bytes("\xa1S", "¡S") |>
    gsub_bytes("\xbf", "¿") |>
    gsub_bytes("\xc1", "Á") |>
    gsub_bytes("\xc4", "Ä") |>
    gsub_bytes("\xc7", "Ç") |>
    gsub_bytes("\xc9", "É") |>
    gsub_bytes("\xf1", "ñ") |>
    gsub_bytes("\xb4", "'") |>
    gsub_bytes("\xdf", "ß") |>
    # these don't have ISO8859-1 entries
    gsub_bytes("\x85", "...") |>
    gsub_bytes("\x91", "'") |>
    gsub_bytes("\x92", "'") |>
    gsub_bytes("\x93", '"') |>
    gsub_bytes("\x94", '"') |>
    gsub_bytes("\x96", " ") |> # –
    gsub_bytes("\x97", " ") |> # —
    # these are probably non-ISO-8859-1 and WINDOWS-1252 characters
    gsub_bytes("\xba", "ş") |>
    # \x9d is "ť" in "windows-1250" so these are probably OCR errors
    # like "let's" is OCRed as "leťs"
    gsub_bytes("\x9ds", "t's") |>
    gsub_bytes("\x9dll", "t'll") |>
    gsub_bytes("\x9dve", "t've") |>
    gsub_bytes("\xefs", "d's") |>
    gsub_bytes("\xefve", "d've") |>
    # weird cases
    gsub_bytes(" \xa4 ", " ") |>
    gsub_bytes(" \x80 ", " ") |>
    gsub_bytes(" \xa6 ", " ") |>
    gsub_bytes(" ~\xa7 ", " ") |>
    gsub_bytes(" \xa7 ", " ") |>
    gsub_bytes(" \xb6 ", " ") |>
    gsub_bytes(" \xc3 ", " ")


  data[enc$index, "line"] <- lines_repaired
  data
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


  # capital I in a lowercase word
  data$line <- data$line |>
    str_replace_all(regex("([A-z])(a|e|i|o|u)lI"), "\\1\\2ll") |>
    # don't hit "alive"
    str_replace_all(fixed("alIve"), "alive") |>
    str_replace_all(regex("(a|e|i|o|u)lI([a-z])"), "\\1ll\\2")

  # trying to contextually fix "alI" for "all".
  data$line <- data$line |>
    str_replace_all(
      regex("alI (for|just|angles|fours|on|day|alone|week|those|wrong|be|lies|upset|\\d|you|of|the|that|by|very|right|over|my|about|your|his|our|day|I|night|kinds|this)", ignore_case = TRUE),
      "all \\1"
    ) |>
    str_replace_all(
      regex("(on|or|him|and|not|were|was|they|I'm|let's|it's|us|could|at|they're|we're|you're|that's|after|of|we|it|for|you|are) alI", ignore_case = TRUE),
      "\\1 all"
    ) |>
    str_replace_all(
      fixed("y'alI", ignore_case = TRUE), "y'all"
    ) |>
    str_replace_all(
      fixed("for-alI", ignore_case = TRUE), "for-all"
    ) |>
    str_replace_all(
      fixed("iet's alI", ignore_case = TRUE), "let's all"
    )

   data
 }
