library(dplyr)
library(stringr)
source(here::here("R/tribbles.R"))

fixed_ic <- function(...) fixed(..., ignore_case = TRUE)
regex_ic <- function(...) regex(..., ignore_case = TRUE)

gsub_bytes <- function(x, pattern, replacement) {
  gsub(pattern = pattern, replacement = replacement, x = x, useBytes = TRUE)
}
c("a.b", "ab") |> str_subset(fixed(".", ignore_case = TRUE))

grep_bytes <- function(x, pattern, invert = FALSE) {
  grep(
    pattern = pattern,
    x = x,
    value = TRUE,
    useBytes = TRUE,
    invert = invert
  )
}

locate_bytes <- function(x, pattern, invert = FALSE) {
  grep(
    pattern = pattern,
    x = x,
    value = FALSE,
    useBytes = TRUE,
    invert = invert
  )
}

str_context <- function(xs, pattern, amount = 5) {
  padded <- sprintf(".{0,%s}%s.{0,%s}", amount, pattern, amount)
  padded <- regex(padded)
  attr(padded, "options") <- attr(pattern, "options")
  xs |>
    str_extract_all(padded, simplify = FALSE) |>
    unlist()
}

str_replace_all_verbose <- function(xs, pattern, replacement) {
  indices <- xs |> str_which(pattern)

  printed_pattern <- pattern |> str_replace_all(" ", "·")

  message_header <- glue::glue(
    "Replacing {usethis::ui_field(printed_pattern)} ({length(indices)} lines)"
  )

  matches <- xs[indices] |>
    str_extract_all(pattern) |>
    unlist() |>
    table() |>
    sort(decreasing = TRUE)

  matches <- matches[matches > 100]
  if (length(matches)) {
    reps <- str_replace_all(names(matches), pattern, replacement)
    names(matches) <- str_replace_all(names(matches), " ", "·")
    reps <- str_replace_all(reps, " ", "·")
    examples <- character(length(matches))
    for (i in seq_along(matches)) {
      n <- names(matches)[i]
      r <- reps[i]
      m <- matches[i]
      examples[i] <-  glue::glue(
        "e.g., {usethis::ui_field(n)} -> {usethis::ui_field(r)} ({m} lines)"
      )
    }
    message_header <- c(message_header, examples)
  }

  rlang::inform(message_header)

  xs[indices] <- str_replace_all(xs[indices], pattern, replacement)
  xs
}


explore_splits <- function(set, word) {
  pl <- paste0("\\b", word, "(\\w+)")
  pr <- paste0("\\b", "(\\w+)", word, "\\b")
  l <- set |> str_subset(pl)
  r <- set |> str_subset(pr)

  tl <- tibble(
    token = l,
    both = str_replace(token, pl, paste(word, "\\1"))
  )

  tr <- tibble(
    token = r,
    both = str_replace(token, pr, paste("\\1", word))
  )

  bind_rows(tl, tr) |>
    filter(!hunspell::hunspell_check(token)) |>
    mutate(
      left = str_extract(both, "^\\w+\\b"),
      right = str_extract(both, "\\b\\w+$"),
      left_c = hunspell::hunspell_check(left),
      right_c = hunspell::hunspell_check(right),
      patch = paste0(token,",",both)
    )  |>
    filter(left_c, right_c)
}


regexes <- list(
  pat_bad_char = regex("�"),
  pat_badbad_char = regex("��")
)


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


remove_subtitle_credits <- function(data) {
  zap_lines <- function(data, pattern) {
    indices <- data[["line"]] |>
      str_which(fixed_ic(pattern))
    message(paste0("Zapping `", pattern, "`: ", length(indices), " lines"))
    data[["line"]][indices] <- ""
    data
  }

  zap_lines_re <- function(data, pattern) {
    indices <- data[["line"]] |>
      str_which(regex_ic(pattern))
    message(paste0("Zapping `", pattern, "`: ", length(indices), " lines"))
    data[["line"]][indices] <- ""
    data
  }

  data <- data |>
    zap_lines("Synchro:" ) |>
    zap_lines("forom.com") |>
    zap_lines("www.forom") |>
    zap_lines("opensubtitles") |>
    zap_lines("www.ydy.com") |>
    zap_lines("YTET") |>
    zap_lines("YDY.com") |>
    zap_lines("subtitlesbox.com") |>
    zap_lines("www.outpost-daria.com") |>
    zap_lines("Dictation: ") |>
    zap_lines_re("^Transcript: ") |>
    zap_lines_re("^Subtitles: ") |>
    zap_lines_re("^English Subtitles") |>
    zap_lines_re("^Subtitles by") |>
    zap_lines_re("^Ripped by") |>
    zap_lines("subtitles conformed") |>
    zap_lines("DVD subtitles by") |>
    zap_lines("asscrewz") |>
    zap_lines("NeKryXe") |>
    zap_lines("Visiontext") |>
    zap_lines("RavyDavy") |>
    zap_lines("sudamerica") |>
    zap_lines("English Subtitle: ") |>
    zap_lines("1000fr") |>
    zap_lines("seriessub") |>
    zap_lines("nate.com") |>
    zap_lines("swsub.com") |>
    zap_lines("Subtitulado") |>
    zap_lines("SubRip") |>
    zap_lines_re("^Sync : ") |>
    zap_lines_re("^Transcript : ") |>
    zap_lines("MySubtitles") |>
    zap_lines("frigorifix") |>
    zap_lines("Ripping & Subtitles") |>
    zap_lines("CaptionMax") |>
    zap_lines("yellowsubteam") |>
    zap_lines("this subtitle") |>
    zap_lines("Subtitles corrected") |>
    zap_lines("ShooCat") |>
    zap_lines("fabiusX") |>
    zap_lines("Subtitulos") |>
    zap_lines("Rainingturds@yahoo") |>
    zap_lines("rinonapo") |>
    zap_lines("heroessubs") |>
    zap_lines("MSN:ts_leo") |>
    zap_lines("dlphimdvd") |>
    zap_lines("deadlikemeonline") |>
    zap_lines("Mircx") |>
    zap_lines("broadcasttext") |>
    zap_lines("Ripped/Corrected") |>
    zap_lines("luckywith007") |>
    zap_lines("darvimil") |>
    zap_lines("itwvfsub") |>
    zap_lines("GRuPoUToPiA") |>
    zap_lines("ir_guitar") |>
    zap_lines("Witewave's") |>
    zap_lines("fitbbs") |>
    zap_lines("walla.com")
  data
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


patch_encoding <- function(data) {
  # preview_iconvlist <- function(x, to = "UTF-8") {
  #   as.list(iconvlist()) |>
  #     stats::setNames(iconvlist()) |>
  #     lapply(
  #       function(y) {
  #         tryCatch(
  #           iconv(x, from = y, to = to),
  #           error = function(e) NA_character_)
  #       }
  #     ) |>
  #     unlist()
  # }
  #
  # myconv <- purrr::possibly(iconv, NA_character_)
  # double_iconv <- function(x, ground_truth, source, target) {
  #   y <- myconv(x, from = ground_truth, to = source)
  #   myconv(y, from = source, to = target)
  # }

  pat_bad_char <- "�"
  pat_badbad_char <- "��"

  enc <- data |>
    filter(str_detect(line, pat_badbad_char))

  lines_raw <- enc$line
  Encoding(lines_raw) <- "unknown"

  lines_repaired <- lines_raw |>
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
    gsub_bytes("\xa0\xe0", "à") |>
    gsub_bytes("\xa0\xc1", "é") |>
    gsub_bytes("p\xa0\xf0t", "pât") |>
    gsub_bytes("Voil\xa0\xf0", "Voilà") |>
    gsub_bytes("\x94\x85", "") |>
    gsub_bytes("\x91\x91", "") |>
    gsub_bytes("\x92\x92", "") |>
    gsub_bytes("\x93\x93", "") |>
    gsub_bytes("\xa1\xaf", "'") |>
    gsub_bytes("\xa3\xac", ", ") |>
    gsub_bytes("\x8d\xa5", "He") |>
    gsub_bytes("\xb0Ͷ\xfb\xb2\xa9\xd1\xc7 would done", "Balboa would do") |>
    gsub_bytes("Rocky\xa1\xa4\xb0Ͷ\xfb\xb2\xa9\xd1\xc7", "Rocky Balboa") |>
    gsub_bytes("\xb0Ͷ\xfb\xb2\xa9\xd1\xc7", "Balboa") |>
    gsub_bytes("Rocky\xa1\xa4Balboa", "Rocky Balboa") |>
    gsub_bytes("\xa1\xa3", " ") |>
    gsub_bytes("\xa2\xdd", " ") |>
    gsub_bytes("\xa3\xa1", " ") |>
    gsub_bytes("\xa0\xc7", "ae")

  # lines_repaired[str_which(lines_repaired, pat_badbad_char)]

  data[enc$index, "line"] <- lines_repaired

  enc <- data |>
    filter(str_detect(line, pat_bad_char))

  lines_raw <- enc$line
  Encoding(lines_raw) <- "unknown"

  lines_repaired <- lines_raw |>
    # this one is probably non-ISO-8859-1 and WINDOWS-1252 characters
    gsub_bytes("I\xbaik", "Işik") |>
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
    gsub_bytes("\xf1", "ñ") |>
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
    gsub_bytes(" \xc3 ", " ") |>
    # the degree symbol showing up in percentage sign
    gsub_bytes("\xba/\xba", "%") |>
    gsub_bytes("%/\xba", "%") |>
    gsub_bytes("%\xba", "%") |>
    gsub_bytes("\xba%", "%") |>
    gsub_bytes("\xba/%", "%") |>
    gsub_bytes("\xba", "º")

  data[enc$index, "line"] <- lines_repaired
  data
}


patch_text_contractions <- function(data) {
  data <- data |>
    anti_join(df_i_to_l_apostrophe, by = "index") |>
    bind_rows(df_i_to_l_apostrophe) |>
    arrange(index)

  # Find everything with a word, space, apostrophe, 1-3 chars, non-word char
  data_space_apostrophe <- data |>
    filter(str_detect(line, "\\w+\\s+'\\s*\\w{1,3}(\\W|$)"))

  # The second pattern in each pair is a less strict pattern. Any nonword
  # character is detected. Use it for checking.

  # [word] ' ve/ll/re/il (s'il vous plait)
  pat_ll_ve_re <- regex_ic("(\\w+)(\\s+'\\s*)(ve|ll|re|il)( |$|[.,-])")
  pat_ll_ve_re2 <- regex_ic("(\\w+)(\\s+'\\s*)(ve|ll|re|il)(\\W|$)")

  # [word] ' s
  pat_s <- regex("(\\w+)(\\s+'\\s*)(s)( |$|[.?,-])")
  pat_s2 <- regex_ic("(\\w+)(\\s+'\\s*)(s)(\\W|$)")

  # [word] ' d
  pat_d <- regex("(\\w+)(\\s+'\\s*)(d)( |$|[.-])")
  pat_d2 <- regex_ic("(\\w+)(\\s+'\\s*)(d)(\\W|$)")

  # [word] ' d
  pat_m <- regex("(\\w+)(\\s+'\\s*)(m)( |$|[.-])")
  pat_m2 <- regex_ic("(\\w+)(\\s+'\\s*)(m)(\\W|$)")

  # [word] ' t
  pat_t <- regex("(\\w+)(\\s+'\\s*)(t)( |$|[\":.,!?-])")
  pat_t2 <- regex_ic("(\\w+)(\\s+'\\s*)(t)(\\W|$)")


  data_space_apostrophe$line <- data_space_apostrophe$line |>
    str_replace_all_verbose(fixed_ic("ma ' am"), "ma'am") |>
    str_replace_all_verbose(fixed_ic(" ' em"), " 'em") |>
    str_replace_all("maitre 'd", "maitre d'") |>
    str_replace_all_verbose(fixed("of'L'"), "of 'L'") |>
    str_replace_all_verbose(pat_ll_ve_re, "\\1'\\3\\4") |>
    str_replace_all_verbose(pat_s, "\\1'\\3\\4") |>
    str_replace_all_verbose(pat_d, "\\1'\\3\\4") |>
    str_replace_all_verbose(pat_m, "\\1'\\3\\4") |>
    str_replace_all_verbose(pat_t, "\\1'\\3\\4")

  # Use these to check what has not changed
  # data_space_apostrophe$line |> str_subset(pat_ll_ve_re2)
  # data_space_apostrophe$line |> str_subset(pat_s2)
  # data_space_apostrophe$line |> str_subset(pat_m2)
  # data_space_apostrophe$line |> str_subset(pat_d2)
  # data_space_apostrophe$line |> str_subset(pat_t2)

  data <- data |>
    anti_join(data_space_apostrophe, by = "index") |>
    bind_rows(data_space_apostrophe) |>
    arrange(index)

  # Find everything with a quotation mark in the middle of it
  data_qc <- data |>
    filter(str_detect(line, regex_ic("\\w+\\\"\\w+(\\W|$)")))

  data_qc$line <- data_qc$line |>
    str_replace_all_verbose(
      regex_ic("(\\w)\\\"(t|m|s|d|ll|il|ve)(\\W|$)"),
      "\\1'\\2\\3"
    ) |>
    str_replace_all_verbose(fixed_ic("y\"all"), "y'all") |>
    str_replace_all_verbose(fixed_ic("ma\"am"), "ma'am") |>
    str_replace_all(fixed_ic("\"hey\"ing"), "heying") |>
    str_replace_all(fixed_ic("for\"give"), "forgive") |>
    str_replace_all(fixed_ic("fin\"e"), "fine") |>
    str_replace_all(fixed_ic("\"D\"ressed"), "Dressed") |>
    str_replace_all(fixed_ic("E\"xorcist"), "Exorcist") |>
    str_replace_all(fixed_ic("\"S\"p\"orts"), "Sports") |>
    str_replace_all(fixed_ic("Com\"p\"osure"), "Composure") |>
    str_replace_all(fixed_ic("\"Slee\"p\"Iess"), "Sleepless") |>
    str_replace_all(fixed_ic("\"fl\""), "fl") |>
    str_replace_all(fixed_ic("fl\""), "fl") |>
    str_replace_all(fixed_ic("fi\""), "fi") |>
    str_replace_all(regex_ic("(\\w)\"ky"), "\1ky") |>
    str_replace_all(regex_ic("(\\w)\"(yt|yw)\"(\\w)"), "\1\2\3") |>
    str_replace_all(regex_ic("(or|of|we|the)\"(\\w+)"), "\1 \2") |>
    str_replace_all(regex_ic("called\"(\\w+)"), "called \1") |>
    str_replace_all(regex_ic(" a\"(\\w+)"), " a \1") |>
    str_replace_all(regex_ic("(\\w+)\"for"), "\1 for") |>
    str_replace_all_verbose(regex_ic("(\\W)(\\w+)\"(\\w+)\"(\\w+)(\\W)"), "\1\2 \3 \4\5")
    # this is not exhaustive.

  data <- data |>
    anti_join(data_qc, by = "index") |>
    bind_rows(data_qc) |>
    arrange(index)

  data$line <- data$line |>
    str_replace_all_verbose(fixed_ic("lsn't"), "isn't")

  pat_contr <- regex_ic(
    "(ain|doesn|didn|wouldn|wasn|hadn|shouldn|isn|aren|haven|don|won|can)\\W"
  )

  pat_nt <- regex(
    "(^|\\W)(ain|doesn|didn|wouldn|wasn|hadn|shouldn|isn|aren|haven|dont|won|can)( t | t$ | t\\W)"
  )

  data_has_possible_contraction <- data |>
    filter(str_detect(line, pat_contr))

  # data_has_possible_contraction$line |> str_subset(pat_nt)

  # fix "can t"-like errors
  data_has_possible_contraction <- data_has_possible_contraction |>
    mutate(
      line = line |>
        str_replace_all_verbose(fixed("Can T ell "), "Can Tell ") |>
        str_replace_all_verbose(fixed("t ake off"), "take off") |>
        str_replace_all_verbose(pat_nt, " \\1't ")
    )

  data <- data |>
    anti_join(data_has_possible_contraction, by = "index") |>
    bind_rows(data_has_possible_contraction) |>
    arrange(index)

  data$line <- data$line |>
    str_replace_all_verbose(regex_ic("( |^)l'm "), "\1I'm ")

  data
}

patch_false_spaces <- function(data) {
  pat_to <- regex(" t o (?=\\S\\S+)", ignore_case = TRUE)
  pat_that <- regex("\\Wt hat ", ignore_case = TRUE)
  pat_thats <- regex("\\Wt hat's ", ignore_case = TRUE)

  data |>
    mutate(
      line = line |>
        str_replace_all_verbose(pat_to, " to ") |>
        str_replace_all_verbose(pat_that, " that ") |>
        str_replace_all_verbose(pat_thats, " that's ") |>
        str_replace_all_verbose(regex_ic(" fo ryou"), " for you") |>
        str_replace_all_verbose(regex_ic(" proud oyou"), " proud of you") |>
        str_replace_all_verbose(regex_ic("\\bNYou"), " You")

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
        str_replace_all_verbose(pat_l_between_caps, "\\1I\\2") |>
        # running it again to fix things like "COMMUNlTlES"
        str_replace_all_verbose(pat_l_between_caps, "\\1I\\2")
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
      line = line |> str_replace_all_verbose(pat_lk, "\\1K\\3")
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
  # (lowercase l plus rest of word in caps)
  data_lxx2 <- data |>
    filter(str_detect(line, " l[A-Z][A-Z]+")) |>
    mutate(
      line = line |>
        str_replace_all_verbose(" l([A-Z][A-Z]+)", " I\\1")
    )

  data <- data |>
    anti_join(data_lxx2, by = "index") |>
    bind_rows(data_lxx2) |>
    arrange(index)

  # XX lX -> X IX
  # (fix lT, lN, etc. if preceded by an all caps word)
  data_lx1 <- data |>
    filter(str_detect(line, "[A-Z][A-Z]+ l[A-Z]")) |>
    mutate(
      line = line |>
        str_replace_all_verbose("([A-Z][A-Z]+) l([A-Z])", "\\1 I\\2")
    )

  data <- data |>
    anti_join(data_lx1, by = "index") |>
    bind_rows(data_lx1) |>
    arrange(index)


  # lX XX -> IX XX
  # (fix lT, lN, etc. if followed by an all caps word)
  data_lx2 <- data |>
    filter(str_detect(line, "l[A-Z] [A-Z][A-Z]+")) |>
    filter(!str_detect(line, pat_l_between_caps_false3)) |>
    mutate(
      line = line |>
        str_replace_all_verbose("l([A-Z]) ([A-Z][A-Z]+)", "I\\1 \\2")
    )

  data <- data |>
    anti_join(data_lx2, by = "index") |>
    bind_rows(data_lx2) |>
    arrange(index)

  # XXl -> XXI
  # (FBl -> FBI)
  data_xxl <- data |>
    filter(str_detect(line, "[A-Z][A-Z]l( |$)")) |>
    mutate(
      line = line |>
        str_replace_all_verbose("([A-Z][A-Z])l( |$)", "\\1I\\2")
    )

  data <- data |>
   anti_join(data_xxl, by = "index") |>
   bind_rows(data_xxl) |>
   arrange(index)

  pat_lI_lc_word1 <- regex("([A-z])(a|e|i|o|u)lI")
  pat_lI_lc_word2 <- regex("(a|e|i|o|u)lI([a-z])")

  data_lI <- data |>
    filter(
      str_detect(line, pat_lI_lc_word1) | str_detect(line, pat_lI_lc_word2)
  )

  # capital I in a lowercase word
  data_lI$line <- data_lI$line |>
    str_replace_all_verbose(pat_lI_lc_word1, "\\1\\2ll") |>
    str_replace_all_verbose(pat_lI_lc_word2, "\\1ll\\2")

  data <- data |>
    anti_join(data_lI, by = "index") |>
    bind_rows(data_lI) |>
    arrange(index)


  # fix "alI" for "all".
  data_all <- data |>
    filter(str_detect(line, regex("(^|\\W)([Aa][l][I])(\\W|$)"))) |>
    # skip one unclear case
    filter(!str_detect(line, fixed("AlI: Forman!")))

  data_all$line <- data_all$line |>
    str_replace_all_verbose(regex("(^|\\W)([Aa][Ll][I])(\\W|$)"), "\\1all\\3")

  data <- data |>
    anti_join(data_all, by = "index") |>
    bind_rows(data_all) |>
    arrange(index)

  data$line <- data$line |>
    str_replace(regex_ic("to/d\\b"), "told")
  data
}


patch_short_ocr_errors <- function(data) {
  # "In" as 'ln'
  indices <- data$line |>
    str_which(regex_ic("\\bln\\b"))

  data$line[indices] <- data$line[indices] |>
    str_replace_all_verbose(fixed_ic("ln f or"), "in for") |>
    str_replace_all_verbose(fixed_ic("ln f act"), "in fact") |>
    str_replace_all_verbose(fixed_ic("ln hl s"), "in his") |>
    str_replace_all_verbose(regex("\\bln\\b"), "in")

  indices <- data$line |>
    str_which(regex_ic("\\blf\\b"))

  data$line <- data$line |>
    str_replace_all_verbose(regex("\\blf\\b"), "if")

  data
}
