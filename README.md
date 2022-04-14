
<!-- README.md is generated from README.Rmd. Please edit that file -->

# subtitlefreq

<!-- badges: start -->
<!-- badges: end -->

The goal of subtitlefreq is to provide alternative word frequency counts
from the SUBTLEX-US corpus. My problem with the SUBTLEX-US corpus is
that it separates “word+t” into “word” + “t”, so that the contractions
“isn’t”, “aren’t”, “don’t”, etc. count as two words. This project is a
naive attempt to rebuild some frequency counts from scratch.

⚠️ This is not a drop-in replacement for the SUBTLEX-US corpus. I just
wanted to estimate how frequent “don’t” is so I could compute some
neighborhood frequency measures.

## obtaining the raw SUBTLEX-US data

As a matter of caution, I won’t provide the original subtitle corpus.
But you can download it the same way that I did.

-   Go to the following URL: <http://www.lexique.org/?page_id=241> and
    download the corpus.
-   Move `Subtlex US.rar` into `data` folder.

We can test our download by reading the embedded readme file from it.

``` r
readme <- archive::archive_read(
  "data/Subtlex US.rar", 
  "Subtlex US/readme.txt"
)

writeLines(readLines(readme))
#> If you use this corpus please cite:
#> Brysbaert, M. & New, B. (2009)  Moving beyond Kucera and Francis:  A Critical Evaluation of Current Word Frequency Norms and the Introduction of a New and Improved Word Frequency Measure for American English. Behavior Research Methods, 41 (4), 977-990. 
#> 
#> This is a corpus of movies subtitles made from an original corpus of 51 million words.
#> Lines from all the movies inside a given category have been randomized for copyright reasons.
#> You are not allowed to distribute or modify this corpus.
```

That last line is why I don’t redistribute the corpus.

## then run targets

Assuming the data are downloaded and the appropriate packages are
installed, then running `targets::tar_make()` should count the words in
the corpus. targets also [downloads](https://osf.io/djpqz/) and prepares
the published version of the SUBTLEX-US frequency counts.

``` r
data_subtlexus <- targets::tar_read(data_subtlexus)
data_subtlexus
#> # A tibble: 74,286 × 15
#>    Word     FREQcount CDcount FREQlow Cdlow    SUBTLWF Lg10WF SUBTLCD Lg10CD
#>    <chr>        <dbl>   <dbl>   <dbl> <dbl>      <dbl>  <dbl>   <dbl>  <dbl>
#>  1 a          1041179    8382  976941  8380 20415.      6.02  99.9     3.92 
#>  2 aa              87      70       6     5     1.71    1.94   0.835   1.85 
#>  3 aaa             25      23       5     3     0.490   1.41   0.274   1.38 
#>  4 aah           2688     634      52    37    52.7     3.43   7.56    2.80 
#>  5 aahed            1       1       1     1     0.0196  0.301  0.0119  0.301
#>  6 aahing           2       2       2     2     0.0392  0.477  0.0238  0.477
#>  7 aahs             5       4       5     4     0.0980  0.778  0.0477  0.699
#>  8 aal              1       1       1     1     0.0196  0.301  0.0119  0.301
#>  9 aardvark        21      12      14     8     0.412   1.34   0.143   1.11 
#> 10 aargh           33      26       2     1     0.647   1.53   0.310   1.43 
#> # … with 74,276 more rows, and 6 more variables: Dom_PoS_SUBTLEX <chr>,
#> #   Freq_dom_PoS_SUBTLEX <dbl>, Percentage_dom_PoS <dbl>,
#> #   All_PoS_SUBTLEX <chr>, All_freqs_SUBTLEX <chr>, `Zipf-value` <dbl>
```

Data processing here works in three stages. First, there is a raw tibble
of lines with row per subtitle line. The `batch` column is used for
splitting the corpus into batches so that words can be counted in
parallel.

``` r
library(tidyverse)
data_raw <- targets::tar_read(data_raw_corpus)
data_raw
#> # A tibble: 6,043,188 × 3
#>    index batch line                                                             
#>    <int> <int> <chr>                                                            
#>  1     1     1 "***Tony? Hey, Tony, where you going? "                          
#>  2     2     1 "That place goes on the market today. "                          
#>  3     3     1 "I couldn't call myself his friend if I weren't willing to do th…
#>  4     4     1 "You don't want to run a wedding magazine for a company that is …
#>  5     5     1 "Well, I guess the only thing left for us to do  is to wire Marc…
#>  6     6     1 "I, like, dumped her, like, 20 years ago.  So? So, I don't think…
#>  7     7     1 "Otis Day &amp; The Knights - Shout!  guys escaping from Sandi's…
#>  8     8     1 "I'm gonna call it Serendipity.  What does that mean? I don't kn…
#>  9     9     1 "What on earth is wrong with you, besides the obvious lack of fa…
#> 10    10     1 "Where would you go ? "                                          
#> # … with 6,043,178 more rows
```

These lines are patched (to remove some garbage I discovered where
markup was included in the dialogue), and then the words are in batch
are counted.

The counts from each batch are pooled together to give the following
frequency counts:

``` r
data_pooled <- targets::tar_read(data_counts_pooled)
data_pooled |> print(n = 20)
#> # A tibble: 194,095 × 2
#>    word        n
#>    <chr>   <int>
#>  1 you   1832939
#>  2 the   1462907
#>  3 i     1454065
#>  4 to    1133806
#>  5 a     1017520
#>  6 and    664051
#>  7 it     655387
#>  8 of     576055
#>  9 that   540955
#> 10 in     489211
#> 11 me     463633
#> 12 is     451810
#> 13 what   423012
#> 14 this   399986
#> 15 on     349129
#> 16 for    344299
#> 17 my     337379
#> 18 i'm    328796
#> 19 your   322789
#> 20 we     317085
#> # … with 194,075 more rows
```

You might notice that there are around 200,000 words here, instead of
the 60,000-70,000 words you might see elsewhere. This is probably
because we did not lump any inflections together or anything.

If I see ever any typos in the counts, I try to store a correction in
the csv file `data/patches.csv`. This is probably a futile, never-ending
endeavor, but hey, at least anyone can add to it.

``` r
data_patches <- targets::tar_read("data_patches")
data_patches
#> # A tibble: 640 × 2
#>    old          new          
#>    <chr>        <chr>        
#>  1 vamplre      vampire      
#>  2 won'em       won 'em      
#>  3 ityet        it yet       
#>  4 dondeys      donkeys      
#>  5 myselfthe    myself the   
#>  6 namastay     namaste      
#>  7 countin'cash countin' cash
#>  8 negociating  negotiating  
#>  9 lt'd         it'd         
#> 10 goin'out     goin' out    
#> # … with 630 more rows
```

These individual patches are followed by regular-expression-based
patches. These are stored in a `data/patches-regex.csv` so that they can
have a `comment` column that describes their behavior.

``` r
data_patches_regex <- targets::tar_read("data_patches_regex")
data_patches_regex
#> # A tibble: 20 × 3
#>    old                                      new            comment              
#>    <chr>                                    <chr>          <chr>                
#>  1 (..+in)+'(?!(s$|ll$|t$|d$|est$|st$))(.+) "\\1' \\3"     "<..in'word> into <.…
#>  2 ^([a-pr-z])(.+)'il$                      "\\1\\2'll"    "<-'il> to <-'ll> un…
#>  3 (.+)lng                                  "\\1ing"       "<-lng> to <-ing>"   
#>  4 (.*)(lgh)(?!(amdi|man))(.*)              "\\1igh\\4"    "<lgh> to <igh> exce…
#>  5 (.*)(flre)(.*)                           "\\1fire\\3"   "<flre> to <fire>"   
#>  6 (.*)(lgn)(.*)                            "\\1ign\\3"    "<lgn> to <ign>"     
#>  7 (.*)(dlrect)(.*)                         "\\1direct\\3" "<dlrect> to <direct…
#>  8 (.+)('nt)(.*)                            "\\1n't\\3"    "<is'nt> to <isn't> …
#>  9 (.+)('em$)                               "\\1 'em"      "<get'em> to <get 'e…
#> 10 milii(.*)                                "milli\\1"     "<million> to <milli…
#> 11 ^ltal(.*)                                "ital\\1"      "<ltaly> to <italy> …
#> 12 ^smali(.*)                               "small\\1"     "<smali> to <small> …
#> 13 nooo+                                    "no"            <NA>                
#> 14 meee+                                    "me"            <NA>                
#> 15 helloo+                                  "hello"         <NA>                
#> 16 sooo+                                    "so"            <NA>                
#> 17 whaaa+                                   "whaa"          <NA>                
#> 18 grr+                                     "grr"           <NA>                
#> 19 brr+                                     "brr"           <NA>                
#> 20 rrr+                                     "rrr"           <NA>
```

After applying the patches, we obtain the following counts:

``` r
data <- targets::tar_read("data_counts_patched")
data
#> # A tibble: 192,458 × 2
#>    word        n
#>    <chr>   <int>
#>  1 you   1833350
#>  2 the   1462998
#>  3 i     1454083
#>  4 to    1133906
#>  5 a     1017562
#>  6 and    664087
#>  7 it     655426
#>  8 of     576490
#>  9 that   540987
#> 10 in     489264
#> # … with 192,448 more rows
```

We can rationalize our patching activity by looking at how many words
are affected:

``` r
data_pooled |>
  anti_join(data, by = "word") |> 
  print(n = 20)
#> # A tibble: 1,713 × 2
#>    word          n
#>    <chr>     <int>
#>  1 allve      2181
#>  2 i'il       2137
#>  3 ltalian    1011
#>  4 iike        686
#>  5 lsn't       664
#>  6 lnspector   642
#>  7 we'il       563
#>  8 ltaly       550
#>  9 you'il      508
#> 10 lnn         340
#> 11 lce         315
#> 12 of'em       290
#> 13 l'm         281
#> 14 lt's        254
#> 15 lreland     228
#> 16 lron        223
#> 17 lmperial    190
#> 18 he'il       170
#> 19 ifyou       165
#> 20 lrene       157
#> # … with 1,693 more rows
```

## comparisons

What text-cleaning did they originally do?

> We rejected all files with more than 2.5% type errors according to the
> spelling checker Aspell. In the end, 8,388 films and television
> episodes were retained, with a total of 51.0 million words (16.1
> million from television series, 14.3 million from films before 1990,
> and 20.6 million from films after 1990).

I seem to be missing around 3 million tokens.

``` r
sum(data$n)
#> [1] 47350355
51000000 - sum(data$n)
#> [1] 3649645
```

Or perhaps I am missing just 2 million words, based on the published
frequencies:

``` r
sum(data_subtlexus$FREQcount)
#> [1] 49719560
sum(data_subtlexus$FREQcount) - sum(data$n)
#> [1] 2369205
```

Our raw text has lots of segmentation errors where multiple words are
combined together. For example, here are types with “in’” followed by 2
characters. If I split “tryin’to” into “tryin’ to”, I get 36 new words.
Would systematically fixing lots of segmentation mistakes rediscover
2,000,000 missing words?

``` r
data_pooled |> 
  filter(str_detect(word, "in'..+$")) |> 
  mutate(sum = sum(n))
#> # A tibble: 805 × 3
#>    word             n   sum
#>    <chr>        <int> <int>
#>  1 tryin'to        36  1244
#>  2 goin'on         24  1244
#>  3 feelin'lucky    23  1244
#>  4 lookin'for      20  1244
#>  5 goin'to         17  1244
#>  6 fillin'up       13  1244
#>  7 goin'over       13  1244
#>  8 waitin'for      11  1244
#>  9 ain'tight       10  1244
#> 10 goin'out        10  1244
#> # … with 795 more rows
```

> For instance, there are 18,081 occurrences of the word *play* in
> SUBTLEXUS, 1,521 of the word *plays*, 2,870 of the word *played*, and
> 7,515 of the word *playing*.

``` r
data |> 
  filter(word %in% c("playing", "plays", "play", "played")) 
#> # A tibble: 4 × 2
#>   word        n
#>   <chr>   <int>
#> 1 play    17846
#> 2 playing  7598
#> 3 played   2765
#> 4 plays    1473
```

This is a pretty good match, but we have a few more *playing* tokens
because we patched `"lng"` words.

The published counts fortunately do not have “lng” words.

``` r
data_subtlexus |> 
  filter(str_detect(Word, "lng"))
#> # A tibble: 0 × 15
#> # … with 15 variables: Word <chr>, FREQcount <dbl>, CDcount <dbl>,
#> #   FREQlow <dbl>, Cdlow <dbl>, SUBTLWF <dbl>, Lg10WF <dbl>, SUBTLCD <dbl>,
#> #   Lg10CD <dbl>, Dom_PoS_SUBTLEX <chr>, Freq_dom_PoS_SUBTLEX <dbl>,
#> #   Percentage_dom_PoS <dbl>, All_PoS_SUBTLEX <chr>, All_freqs_SUBTLEX <chr>,
#> #   Zipf-value <dbl>
```

But the combination of treating contractions as separate words and the
l-\>i conversion means that there are a few thousand spurious tokens of
“il”:

``` r
# raw, unpatched
data_pooled |> 
  filter(str_detect(word, "^il$|'il")) |> 
  mutate(sum(n))
#> # A tibble: 36 × 3
#>    word        n `sum(n)`
#>    <chr>   <int>    <int>
#>  1 i'il     2137     4003
#>  2 we'il     563     4003
#>  3 you'il    508     4003
#>  4 he'il     170     4003
#>  5 il        136     4003
#>  6 it'il     117     4003
#>  7 they'il   102     4003
#>  8 l'il       62     4003
#>  9 she'il     57     4003
#> 10 that'il    32     4003
#> # … with 26 more rows

# published
data_subtlexus |> 
  filter(str_detect(Word, "^il$")) |> 
  select(1:2)
#> # A tibble: 1 × 2
#>   Word  FREQcount
#>   <chr>     <dbl>
#> 1 il         4139
```

Because of OCR converting uppercase “I” to lowercase “l”, I patched the
corpus to replace lowercase “l” with uppercase “I” when it was inside of
an all-caps word. We can see the big differences in the counts between
my counts and the published ones for certain initialisms.

``` r
# my counts
data_pooled |> 
  filter(word %in% c("fbi", "irs", "cia")) |> 
  arrange(word)
#> # A tibble: 3 × 2
#>   word      n
#>   <chr> <int>
#> 1 cia    1086
#> 2 fbi     897
#> 3 irs     119

# published
data_subtlexus |> 
  filter(tolower(Word) %in% c("fbi", "irs", "cia")) |> 
  arrange(Word) |> 
  select(1:2)
#> # A tibble: 3 × 2
#>   Word  FREQcount
#>   <chr>     <dbl>
#> 1 cia           7
#> 2 fbi          95
#> 3 irs          18
```

## let’s try something

I saw the textstem package as a solution for lemmatizing words.

``` r
data |> 
  head(1000) |> 
  mutate(
    lemma = textstem::lemmatize_words(word)
  ) |> 
  group_by(lemma) |> 
  mutate(lemma_n = sum(n)) |> 
  arrange(desc(lemma_n)) |> 
  print(n = 20)
#> # A tibble: 1,000 × 4
#> # Groups:   lemma [824]
#>    word        n lemma lemma_n
#>    <chr>   <int> <chr>   <int>
#>  1 you   1833350 you   1840942
#>  2 ya       7592 you   1840942
#>  3 is     451815 be    1527111
#>  4 be     286496 be    1527111
#>  5 was    283050 be    1527111
#>  6 are    262172 be    1527111
#>  7 been    86410 be    1527111
#>  8 were    83207 be    1527111
#>  9 am      49585 be    1527111
#> 10 being   24376 be    1527111
#> 11 the   1462998 the   1462998
#> 12 i     1454083 i     1454083
#> 13 to    1133906 to    1133906
#> 14 a     1017562 a     1110692
#> 15 an      93130 a     1110692
#> 16 and    664087 and    664087
#> 17 it     655426 it     655426
#> 18 that   540987 that   578734
#> 19 those   37747 that   578734
#> 20 of     576490 of     576490
#> # … with 980 more rows
```

Hmm, I wish I could skip irregular forms from being lemmatized. I am
also not a fan of “being” is reduced down to “be”.

## some comparisons for my own interest

There are two layers of patching. One edits the lines in the corpus and
the other edits the words and recounts the words. I want to compare
counts from three different stages.

``` r
a <- targets::tar_read(data_counts_pooled_raw_lines) |> 
  rename(n_a = n)
b <- targets::tar_read(data_counts_pooled) |> 
    rename(n_b = n)
c <- targets::tar_read(data_counts_patched) |> 
    rename(n_c = n)

abc <- a |> 
  full_join(b) |> 
  full_join(c)
#> Joining, by = "word"
#> Joining, by = "word"
```

Line-patching tries to correct OCR errors and contractions with extra
spacing (“isn ’t”). These are words that would not exist if were not for
the line patches. For example, *HIV* appears because OCR reads the word
as `"HlV"`.

``` r
abc |> 
  filter(is.na(n_a)) |> 
  mutate(
    n_b_tokens = sum(n_b, na.rm = TRUE),
    n_c_tokens = sum(n_c, na.rm = TRUE)
  )
#> # A tibble: 912 × 6
#>    word          n_a   n_b   n_c n_b_tokens n_c_tokens
#>    <chr>       <int> <int> <int>      <int>      <int>
#>  1 <NA>           NA 14977 14977      17025      17098
#>  2 hiv            NA   223   223      17025      17098
#>  3 ims            NA    41    41      17025      17098
#>  4 cia's          NA    35    35      17025      17098
#>  5 afis           NA    26    26      17025      17098
#>  6 africaaddio    NA    26    26      17025      17098
#>  7 yril           NA    22    22      17025      17098
#>  8 codis          NA    21    21      17025      17098
#>  9 jindraike      NA    21    21      17025      17098
#> 10 allgnment      NA    20    NA      17025      17098
#> # … with 902 more rows
```

Words that were lost in the line patching. Some subtitles would have
annotations like `"(SlNGlNG)"` or `"(lN ENGLlSH)"` so the OCR correction
repaired these.

``` r
abc |> 
  filter(!is.na(n_a), is.na(n_b)) |> 
  mutate(
    n_a_tokens = sum(n_a, na.rm = TRUE)
  )
#> # A tibble: 6,409 × 5
#>    word       n_a   n_b   n_c n_a_tokens
#>    <chr>    <int> <int> <int>      <int>
#>  1 teli      1002    NA    NA      28770
#>  2 realiy     859    NA    NA      28770
#>  3 rlggs      682    NA    NA      28770
#>  4 stili      445    NA    NA      28770
#>  5 helio      442    NA    NA      28770
#>  6 sdl        360    NA    NA      28770
#>  7 alds       302    NA    NA      28770
#>  8 shouldn    213    NA    NA      28770
#>  9 slpowlcz   199    NA    NA      28770
#> 10 slnglng    187    NA    NA      28770
#> # … with 6,399 more rows
```

Words that increased during line-patching. “Kitt”, by the way, is the
car from *Knight Rider*.

``` r
diffs <- abc |> 
  tidyr::replace_na(list(n_a = 0, n_b = 0, n_c = 0)) |> 
  mutate(
    b_vs_a = n_b - n_a,
    # proportion change
    b_vs_a_prop = b_vs_a / (n_a + 1),
    c_vs_b = n_c - n_b,
    # proportion change
    c_vs_b_prop = c_vs_b / (n_b + 1),
  ) 

diffs |> 
  select(-n_c, -starts_with("c_vs")) |> 
  arrange(desc(b_vs_a))
#> # A tibble: 200,576 × 5
#>    word      n_a    n_b b_vs_a b_vs_a_prop
#>    <chr>   <int>  <int>  <int>       <dbl>
#>  1 <NA>        0  14977  14977 14977      
#>  2 don't  309965 312469   2504     0.00808
#>  3 allve       7   2181   2174   272.     
#>  4 kitt       11   2089   2078   173.     
#>  5 it's   276005 277713   1708     0.00619
#>  6 all    257742 259241   1499     0.00582
#>  7 i'm    327468 328796   1328     0.00406
#>  8 that's 159049 160240   1191     0.00749
#>  9 cia         8   1086   1078   120.     
#> 10 fbi        93    897    804     8.55   
#> # … with 200,566 more rows

diffs |> 
  select(-n_c, -starts_with("c_vs")) |> 
  arrange(desc(b_vs_a_prop)) 
#> # A tibble: 200,576 × 5
#>    word     n_a   n_b b_vs_a b_vs_a_prop
#>    <chr>  <int> <int>  <int>       <dbl>
#>  1 <NA>       0 14977  14977     14977  
#>  2 allve      7  2181   2174       272. 
#>  3 hiv        0   223    223       223  
#>  4 kitt      11  2089   2078       173. 
#>  5 cia        8  1086   1078       120. 
#>  6 ims        0    41     41        41  
#>  7 allke      1    77     76        38  
#>  8 cia's      0    35     35        35  
#>  9 kitt's     2    93     91        30.3
#> 10 afis       0    26     26        26  
#> # … with 200,566 more rows
```

Words that decreased during line-patching.

``` r
diffs |> 
  select(-n_c, -starts_with("c_vs")) |> 
  arrange(b_vs_a)
#> # A tibble: 200,576 × 5
#>    word      n_a     n_b b_vs_a b_vs_a_prop
#>    <chr>   <int>   <int>  <int>       <dbl>
#>  1 s       30138    5776 -24362    -0.808  
#>  2 i     1478384 1454065 -24319    -0.0164 
#>  3 you   1848677 1832939 -15738    -0.00851
#>  4 t       19441    3913 -15528    -0.799  
#>  5 it     666532  655387 -11145    -0.0167 
#>  6 the   1472725 1462907  -9818    -0.00667
#>  7 to    1142705 1133806  -8899    -0.00779
#>  8 that   548765  540955  -7810    -0.0142 
#>  9 m       10901    3187  -7714    -0.708  
#> 10 a     1024989 1017520  -7469    -0.00729
#> # … with 200,566 more rows

diffs |> 
  select(-n_c, -starts_with("c_vs")) |> 
  arrange(b_vs_a_prop) 
#> # A tibble: 200,576 × 5
#>    word       n_a   n_b b_vs_a b_vs_a_prop
#>    <chr>    <int> <int>  <int>       <dbl>
#>  1 teli      1002     0  -1002      -0.999
#>  2 realiy     859     0   -859      -0.999
#>  3 rlggs      682     0   -682      -0.999
#>  4 stili      445     0   -445      -0.998
#>  5 helio      442     0   -442      -0.998
#>  6 sdl        360     0   -360      -0.997
#>  7 weli      2015     5  -2010      -0.997
#>  8 alds       302     0   -302      -0.997
#>  9 shouldn    213     0   -213      -0.995
#> 10 slpowlcz   199     0   -199      -0.995
#> # … with 200,566 more rows
```

Finally, these are words that changed with word-level patching.

``` r
diffs |> 
  select(-n_a, -starts_with("b_vs")) |> 
  arrange(desc(c_vs_b))
#> # A tibble: 200,576 × 5
#>    word         n_b    n_c c_vs_b c_vs_b_prop
#>    <chr>      <int>  <int>  <int>       <dbl>
#>  1 alive       5547   7731   2184     0.394  
#>  2 i'll      111675 113842   2167     0.0194 
#>  3 italian      237   1248   1011     4.25   
#>  4 like      200724 201454    730     0.00364
#>  5 isn't      29199  29869    670     0.0229 
#>  6 inspector   1075   1717    642     0.597  
#>  7 just      239189 239824    635     0.00265
#>  8 we'll      33644  34207    563     0.0167 
#>  9 italy         74    624    550     7.33   
#> 10 you'll     30862  31372    510     0.0165 
#> # … with 200,566 more rows

diffs |> 
  select(-n_a, -starts_with("b_vs")) |> 
  arrange(desc(c_vs_b_prop)) 
#> # A tibble: 200,576 × 5
#>    word        n_b   n_c c_vs_b c_vs_b_prop
#>    <chr>     <int> <int>  <int>       <dbl>
#>  1 innsbruck     0    14     14       14   
#>  2 rlnging       0    12     12       12   
#>  3 ireland      19   247    228       11.4 
#>  4 l'orange      0     9      9        9   
#>  5 italians     17   152    135        7.5 
#>  6 italy        74   624    550        7.33
#>  7 ignatius      2    17     15        5   
#>  8 l'eveque      0     5      5        5   
#>  9 wawy          0     5      5        5   
#> 10 italian     237  1248   1011        4.25
#> # … with 200,566 more rows
```

Words that decreased from word-patching.

``` r
diffs |> 
  select(-n_a, -starts_with("b_vs")) |> 
  arrange(c_vs_b)
#> # A tibble: 200,576 × 5
#>    word        n_b   n_c c_vs_b c_vs_b_prop
#>    <chr>     <int> <int>  <int>       <dbl>
#>  1 allve      2181     0  -2181      -1.00 
#>  2 i'il       2137     0  -2137      -1.00 
#>  3 ltalian    1011     0  -1011      -0.999
#>  4 iike        686     0   -686      -0.999
#>  5 lsn't       664     0   -664      -0.998
#>  6 lnspector   642     0   -642      -0.998
#>  7 we'il       563     0   -563      -0.998
#>  8 ltaly       550     0   -550      -0.998
#>  9 you'il      508     0   -508      -0.998
#> 10 lnn         340     0   -340      -0.997
#> # … with 200,566 more rows
```

### contraction counts

This was the motivation for this whole exercise. I can find some 715K
`n't` contractions. The published frequencies have around 733K `t`
tokens. That’s a pretty good match. But I sum the contraction stems in
the published counts, I get 900K tokens. That’s because the stem of
`can't` is itself a common word `can`.

``` r
contraction_stems <- c(
  "isn", "aren", "ain", "wasn",
  "can",
  "don", "doesn", "didn",
  "couldn", "shouldn", "wouldn",
  "hasn", "haven", "hadn",
  "won",
  "mustn", "needn", "shan"
)

data_my_counts <- data %>%
  filter(
    word %in% paste0(contraction_stems, "'t")
  ) |> 
  mutate(total = sum(n))
  

data_subtlexus_counts <- data_subtlexus |> 
  select(
    subtlexus_word = Word,
    subtlexus_count = FREQcount 
  ) |> 
  filter(subtlexus_word %in% c("t", contraction_stems)) |> 
  mutate(
    word = ifelse(
      subtlexus_word != "t",
      paste0(subtlexus_word, "'t"),
      subtlexus_word
    ),
    sum_of_non_t_items = sum(subtlexus_count) - 733338
  )

data_my_counts |> 
  full_join(data_subtlexus_counts, by = "word")
#> # A tibble: 19 × 6
#>    word           n  total subtlexus_word subtlexus_count sum_of_non_t_items
#>    <chr>      <int>  <int> <chr>                    <dbl>              <dbl>
#>  1 don't     312487 707356 don                     321085             899598
#>  2 can't      91279 707356 can                     267620             899598
#>  3 didn't     78645 707356 didn                     80623             899598
#>  4 won't      33894 707356 won                      38729             899598
#>  5 doesn't    31656 707356 doesn                    32435             899598
#>  6 isn't      29869 707356 isn                      29886             899598
#>  7 wouldn't   23066 707356 wouldn                   23628             899598
#>  8 ain't      21605 707356 ain                      22248             899598
#>  9 wasn't     21401 707356 wasn                     21984             899598
#> 10 haven't    18169 707356 haven                    18844             899598
#> 11 couldn't   16797 707356 couldn                   17336             899598
#> 12 aren't     11691 707356 aren                     11946             899598
#> 13 shouldn't   7874 707356 shouldn                   8083             899598
#> 14 hasn't      4478 707356 hasn                      4625             899598
#> 15 hadn't      3046 707356 <NA>                        NA                 NA
#> 16 mustn't      926 707356 <NA>                        NA                 NA
#> 17 needn't      325 707356 needn                      334             899598
#> 18 shan't       148 707356 shan                       192             899598
#> 19 t             NA     NA t                       733338             899598
```

If I count the stems in my counts, I can see about how many contractions
I have missed. We would get around 1K contractions with some patching.

``` r
 data %>%
  filter(
    word %in% paste0(contraction_stems),
  ) |> 
  group_by(
    could_be_false_positive = word %in% c("can", "won", "haven", "don")
  ) |> 
  mutate(total = sum(n))
#> # A tibble: 16 × 4
#> # Groups:   could_be_false_positive [2]
#>    word        n could_be_false_positive  total
#>    <chr>   <int> <lgl>                    <int>
#>  1 can    171083 TRUE                    177408
#>  2 won      4069 TRUE                    177408
#>  3 don      1976 TRUE                    177408
#>  4 haven     280 TRUE                    177408
#>  5 ain       116 FALSE                      398
#>  6 couldn     91 FALSE                      398
#>  7 shan       52 FALSE                      398
#>  8 didn       45 FALSE                      398
#>  9 hasn       21 FALSE                      398
#> 10 aren       19 FALSE                      398
#> 11 doesn      14 FALSE                      398
#> 12 wouldn     13 FALSE                      398
#> 13 wasn       12 FALSE                      398
#> 14 isn        10 FALSE                      398
#> 15 mustn       3 FALSE                      398
#> 16 needn       2 FALSE                      398
```

A quick check of what these remaining errors look like:

``` r
data_patched_lines <- targets::tar_read("data_raw_corpus_patched")
didn_lines <- data_patched_lines |> 
  filter(str_detect(line, "didn[^'t]"))

data_patched_lines |> 
  filter(str_detect(line, "\\w\\\"\\w")) |> tail()
#> # A tibble: 6 × 3
#>     index batch line                                                            
#>     <int> <int> <chr>                                                           
#> 1 5979965   198 "Beneath the mil\"ky\" twilight  '"                             
#> 2 5981154   198 "The ever-lilting fragrance of\"Eau deBring 'Em All On.\" '"    
#> 3 5989175   199 "You ever get the feeling you're being watched?  I make up stor…
#> 4 6007287   199 "A \"heffalump\"or \"woozle's\" very sly, sly, sly, sly '"      
#> 5 6038900   200 "Or you could your ass on the phone with Garza  and tell him yo…
#> 6 6039528   200 "I figured everything before \"I love you\"just doesn't count. …
```

## how to spot errors

My “process” for screening the corpus is to randomly sample words and
see what sticks out. When I noticed `"cla"` in one of these samples, I
figured out the `"I"` to `"l"` OCR problem in all-caps words.

``` r
data_pooled$word |> 
  sample(size = 10)
#>  [1] "h.q"         "witherspoon" "buckmans"    "shorter"     "muckya"     
#>  [6] "shirkers"    "constipater" "leonidas"    "prochemical" "sparazza"
```

To feel better about things, you could weight by frequency:

``` r
data_pooled$word |> 
  sample(size = 10, prob = data_pooled$n)
#>  [1] "excellent"     "nothing"       "is"            "where"        
#>  [5] "or"            "strangulation" "vaguely"       "to"           
#>  [9] "circumstances" "matter"
```

## open questions (so far)

I’m not sure what’s going on with the encoding and whether that matters.
If you find all lines with the string “Zellweger”, you will find some
`"Ren\xe9e Zellweger"` and some `"Renee Zellweger"` tokens.

Numerals show up. I imagine that one would want to decompose them into
subwords so that, e.g., “1993” is “nineteen”, “ninety”, and “three”.

Stray observations:

-   There are lots of URLs/usernames in the corpus because the subtitles
    can be signed or sourced.

-   If a TV show has a theme song, then you can find many repeated
    lines.

-   other OCR errors to consider: i/l to 1
