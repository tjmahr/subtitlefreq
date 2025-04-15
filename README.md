
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

## Obtaining the raw SUBTLEX-US data

As a matter of caution, I won’t provide the original subtitle corpus.
But you can download it the same way that I did.

- Go to the following URL: <http://www.lexique.org/?page_id=241> and
  download the corpus.
- Move `Subtlex US.rar` into `data` folder.

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

## The targets package builds the corpus

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
#> # ℹ 74,276 more rows
#> # ℹ 6 more variables: Dom_PoS_SUBTLEX <chr>, Freq_dom_PoS_SUBTLEX <dbl>,
#> #   Percentage_dom_PoS <dbl>, All_PoS_SUBTLEX <chr>, All_freqs_SUBTLEX <chr>,
#> #   `Zipf-value` <dbl>
```

## Data processing

Data processing here works in four stages.

1.  Pre-R line repairs. The script `data/patch-line.sh` fixes any lines
    that interfere with loading the text corpus. The corpus is read in
    to the target `data_raw_corpus`.

2.  Line repairs. These apply a series of text repairs to the corpus
    lines of text. Any error that effects the spacing of words—for
    example, contractions being split up (`I' ll go`)—is repaired here.
    Other OCR errors are repaired here. The result is stored in the
    target `data_raw_corpus_patched`.

3.  Initial word counts. The text is separated into words and those
    words are counted. The result is stored in the target `data_pooled`.

4.  Word patching and recounting. Systematic word-level errors are
    repaired. For example, the OCR error `lrish` for *Irish* is replaced
    with `irish` and the counts are updated.

In steps (1) and (2), the corpus is a tibble of lines with row per
subtitle line. The `batch` column is used for splitting the corpus into
batches so that words can be counted in parallel.

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
#> # ℹ 6,043,178 more rows
```

In step (3), the counts from each batch are pooled together to give the
following frequency counts:

``` r
data_pooled <- targets::tar_read(data_counts_pooled)
data_pooled |> 
  print(n = 20)
#> # A tibble: 197,112 × 2
#>    word        n
#>    <chr>   <int>
#>  1 you   1842898
#>  2 the   1472439
#>  3 i     1463947
#>  4 to    1142666
#>  5 a     1024589
#>  6 and    670085
#>  7 it     659502
#>  8 of     579718
#>  9 that   545121
#> 10 in     495987
#> 11 me     466417
#> 12 is     454121
#> 13 what   424831
#> 14 this   402427
#> 15 on     350957
#> 16 for    346988
#> 17 my     340032
#> 18 i'm    335624
#> 19 your   324869
#> 20 we     318234
#> # ℹ 197,092 more rows
```

Notice that there are around 200,000 words here, instead of the
60,000-70,000 words we might see elsewhere. This is probably because we
did not lump any inflections together or performed similar reductions.

In step (4), I repair errors in this word list. Basically, if I see ever
any typos in the counts, I try to store a correction in the csv file
`data/patches.csv`. This is probably a futile, never-ending endeavor,
but it’s lightweight and easy to update.

``` r
data_patches <- targets::tar_read("data_patches")
data_patches
#> # A tibble: 3,281 × 2
#>    old        new            
#>    <chr>      <chr>          
#>  1 1,000ft    1,000 feet     
#>  2 1,000km    1,000 kilometer
#>  3 1,000lb    1,000 pound    
#>  4 1,000yds   1,000 yards    
#>  5 1,200years 1,200 years    
#>  6 1,800miles 1,800 miles    
#>  7 14,000ft   14,000 feet    
#>  8 2,000ft    2,000 feet     
#>  9 20,000ft   20,000 feet    
#> 10 3,000ft    3,000 feet     
#> # ℹ 3,271 more rows
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

Many of the direct patches could simplified into
regular-expression-based ones, and some of the very narrow
regular-expression ones could be made into direct patches. It doesn’t
really matter as long as there are no false positive repairs.

After applying the patches in step (4), we obtain the following counts:

``` r
data <- targets::tar_read("data_counts_patched")
data
#> # A tibble: 193,517 × 2
#>    word        n
#>    <chr>   <int>
#>  1 you   1843993
#>  2 the   1472783
#>  3 i     1463970
#>  4 to    1142780
#>  5 a     1024721
#>  6 and    670128
#>  7 it     659564
#>  8 of     582164
#>  9 that   545204
#> 10 in     496060
#> # ℹ 193,507 more rows
```

We can rationalize our patching activity by looking at how many words
are affected. These words have been removed by the patching:

``` r
data_pooled |>
  anti_join(data, by = "word") |> 
  print(n = 20)
#> # A tibble: 3,812 × 2
#>    word              n
#>    <chr>         <int>
#>  1 i'il           2179
#>  2 lsland         1180
#>  3 lndian         1104
#>  4 ltalian        1018
#>  5 lndians         647
#>  6 lnspector       638
#>  7 we'il           583
#>  8 ltaly           558
#>  9 you'il          525
#> 10 lnternet        522
#> 11 lndia           428
#> 12 lnn             345
#> 13 lce             319
#> 14 lt's            302
#> 15 of'em           289
#> 16 lnternational   277
#> 17 offence         269
#> 18 lvy             266
#> 19 ofthe           252
#> 20 lreland         238
#> # ℹ 3,792 more rows
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
#> [1] 47675658
51000000 - sum(data$n)
#> [1] 3324342
```

Or perhaps I am missing just 2 million words, based on the published
frequencies:

``` r
sum(data_subtlexus$FREQcount)
#> [1] 49719560
sum(data_subtlexus$FREQcount) - sum(data$n)
#> [1] 2043902
```

When we repair many segmentation errors (where multiple words are
combined together), we recover additional words, so we might be
underestimating how many word tokens we are missing from the corpus.

Let’s check our frequencies against a specific set of counts by the
authors.

> For instance, there are 18,081 occurrences of the word *play* in
> SUBTLEXUS, 1,521 of the word *plays*, 2,870 of the word *played*, and
> 7,515 of the word *playing*.

``` r
data |> 
  filter(word %in% c("playing", "plays", "play", "played")) 
#> # A tibble: 4 × 2
#>   word        n
#>   <chr>   <int>
#> 1 play    17981
#> 2 playing  7692
#> 3 played   2795
#> 4 plays    1492
```

This is a pretty good match, but we have a few more *playing* tokens
because we patched `"lng"` words.

The published counts fortunately do not have “lng” words.

``` r
data_subtlexus |> 
  filter(str_detect(Word, "lng"))
#> # A tibble: 0 × 15
#> # ℹ 15 variables: Word <chr>, FREQcount <dbl>, CDcount <dbl>, FREQlow <dbl>,
#> #   Cdlow <dbl>, SUBTLWF <dbl>, Lg10WF <dbl>, SUBTLCD <dbl>, Lg10CD <dbl>,
#> #   Dom_PoS_SUBTLEX <chr>, Freq_dom_PoS_SUBTLEX <dbl>,
#> #   Percentage_dom_PoS <dbl>, All_PoS_SUBTLEX <chr>, All_freqs_SUBTLEX <chr>,
#> #   Zipf-value <dbl>
```

But the combination of treating contractions as separate words and the
l-\>i conversion means that there are a few thousand spurious tokens of
“il” in SUBTLEXUS:

``` r
# raw, unpatched
data_pooled |> 
  filter(str_detect(word, "^il$|'il")) |> 
  mutate(sum(n))
#> # A tibble: 37 × 3
#>    word        n `sum(n)`
#>    <chr>   <int>    <int>
#>  1 i'il     2179     4143
#>  2 we'il     583     4143
#>  3 you'il    525     4143
#>  4 he'il     175     4143
#>  5 il        143     4143
#>  6 it'il     123     4143
#>  7 they'il   105     4143
#>  8 l'il       70     4143
#>  9 she'il     58     4143
#> 10 s'il       54     4143
#> # ℹ 27 more rows

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
#> 1 cia    1083
#> 2 fbi     911
#> 3 irs     121

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

## miscellany

### let’s try something

I saw the textstem package as a solution for lemmatizing words. Let’s
try that.

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
#> # Groups:   lemma [823]
#>    word        n lemma lemma_n
#>    <chr>   <int> <chr>   <int>
#>  1 you   1843993 you   1851697
#>  2 ya       7704 you   1851697
#>  3 is     454127 be    1535662
#>  4 be     289158 be    1535662
#>  5 was    284082 be    1535662
#>  6 are    262933 be    1535662
#>  7 been    87371 be    1535662
#>  8 were    83517 be    1535662
#>  9 am      49878 be    1535662
#> 10 being   24596 be    1535662
#> 11 the   1472783 the   1472783
#> 12 i     1463970 i     1463970
#> 13 to    1142780 to    1142780
#> 14 a     1024721 a     1118445
#> 15 an      93724 a     1118445
#> 16 and    670128 and    670128
#> 17 it     659564 it     659564
#> 18 that   545204 that   583133
#> 19 those   37929 that   583133
#> 20 of     582164 of     582164
#> # ℹ 980 more rows
```

Hmm, I wish I could skip irregular forms from being lemmatized. I am
also not a fan of “being” is reduced down to “be”.

### some comparisons for my own interest

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
#> Joining with `by = join_by(word)`
#> Joining with `by = join_by(word)`
```

Line-repair tries to correct OCR errors and contractions with extra
spacing (“isn ’t”). These are words that would not exist if not for the
line patches. For example, *HIV* appears because OCR reads the word as
`"HlV"`.

``` r
abc |> 
  filter(is.na(n_a)) |> 
  mutate(
    n_b_tokens = sum(n_b, na.rm = TRUE),
    n_c_tokens = sum(n_c, na.rm = TRUE)
  )
#> # A tibble: 2,828 × 6
#>    word       n_a   n_b   n_c n_b_tokens n_c_tokens
#>    <chr>    <int> <int> <int>      <int>      <int>
#>  1 hiv         NA   227   227       9395       9916
#>  2 rené        NA   142   142       9395       9916
#>  3 cliché      NA   132   132       9395       9916
#>  4 º           NA   112   112       9395       9916
#>  5 señora      NA   105   105       9395       9916
#>  6 führer      NA    99    99       9395       9916
#>  7 pelé        NA    97    97       9395       9916
#>  8 fräulein    NA    90    90       9395       9916
#>  9 señorita    NA    90    90       9395       9916
#> 10 temüjin     NA    68    68       9395       9916
#> # ℹ 2,818 more rows
```

Some words were lost in the line patching. Some subtitles would have
annotations like `"(SlNGlNG)"` or `"(lN ENGLlSH)"` so the OCR correction
repaired these.

``` r
abc |> 
  filter(!is.na(n_a), is.na(n_b)) |> 
  mutate(
    n_a_tokens = sum(n_a, na.rm = TRUE)
  )
#> # A tibble: 5,060 × 5
#>    word            n_a   n_b   n_c n_a_tokens
#>    <chr>         <int> <int> <int>      <int>
#>  1 teli           1002    NA    NA      29937
#>  2 realiy          859    NA    NA      29937
#>  3 www.forom.com   722    NA    NA      29937
#>  4 rlggs           682    NA    NA      29937
#>  5 lsn't           660    NA    NA      29937
#>  6 stili           445    NA    NA      29937
#>  7 helio           442    NA    NA      29937
#>  8 sdl             360    NA    NA      29937
#>  9 alds            302    NA    NA      29937
#> 10 slpowlcz        199    NA    NA      29937
#> # ℹ 5,050 more rows
```

These are words that increased during line-repairing. (“Kitt”, by the
way, is the car from *Knight Rider*.)

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

# raw increase
diffs |> 
  select(-n_c, -starts_with("c_vs")) |> 
  arrange(desc(b_vs_a))
#> # A tibble: 202,384 × 5
#>    word      n_a    n_b b_vs_a b_vs_a_prop
#>    <chr>   <int>  <int>  <int>       <dbl>
#>  1 i'm    327469 335624   8155     0.0249 
#>  2 it's   276006 283795   7789     0.0282 
#>  3 don't  309965 316493   6528     0.0211 
#>  4 that's 159049 163181   4132     0.0260 
#>  5 you're 184816 188698   3882     0.0210 
#>  6 in     492327 495987   3660     0.00743
#>  7 all    257743 261033   3290     0.0128 
#>  8 i'll   111235 113741   2506     0.0225 
#>  9 kitt       11   2079   2068   172.     
#> 10 can't   90478  92488   2010     0.0222 
#> # ℹ 202,374 more rows

# proportion increase
diffs |> 
  select(-n_c, -starts_with("c_vs")) |> 
  arrange(desc(b_vs_a_prop)) 
#> # A tibble: 202,384 × 5
#>    word     n_a   n_b b_vs_a b_vs_a_prop
#>    <chr>  <int> <int>  <int>       <dbl>
#>  1 hiv        0   227    227        227 
#>  2 kitt      11  2079   2068        172.
#>  3 rené       0   142    142        142 
#>  4 cliché     0   132    132        132 
#>  5 cia        8  1083   1075        119.
#>  6 º          0   112    112        112 
#>  7 fiancé     2   323    321        107 
#>  8 señora     0   105    105        105 
#>  9 führer     0    99     99         99 
#> 10 pelé       0    97     97         97 
#> # ℹ 202,374 more rows
```

Words that decreased during line-patching.

``` r
diffs |> 
  select(-n_c, -starts_with("c_vs")) |> 
  arrange(b_vs_a)
#> # A tibble: 202,384 × 5
#>    word      n_a     n_b b_vs_a b_vs_a_prop
#>    <chr>   <int>   <int>  <int>       <dbl>
#>  1 s       30140    4347 -25793    -0.856  
#>  2 t       19441    3611 -15830    -0.814  
#>  3 i     1478397 1463947 -14450    -0.00977
#>  4 m       10902    2620  -8282    -0.760  
#>  5 it     666532  659502  -7030    -0.0105 
#>  6 don      8418    1866  -6552    -0.778  
#>  7 re       8044    2064  -5980    -0.743  
#>  8 you   1848677 1842898  -5779    -0.00313
#>  9 ll       5413     721  -4692    -0.867  
#> 10 ln       3696      14  -3682    -0.996  
#> # ℹ 202,374 more rows

diffs |> 
  select(-n_c, -starts_with("c_vs")) |> 
  arrange(b_vs_a_prop) 
#> # A tibble: 202,384 × 5
#>    word            n_a   n_b b_vs_a b_vs_a_prop
#>    <chr>         <int> <int>  <int>       <dbl>
#>  1 teli           1002     0  -1002      -0.999
#>  2 realiy          859     0   -859      -0.999
#>  3 www.forom.com   722     0   -722      -0.999
#>  4 rlggs           682     0   -682      -0.999
#>  5 lsn't           660     0   -660      -0.998
#>  6 stili           445     0   -445      -0.998
#>  7 helio           442     0   -442      -0.998
#>  8 sdl             360     0   -360      -0.997
#>  9 weli           2015     5  -2010      -0.997
#> 10 alds            302     0   -302      -0.997
#> # ℹ 202,374 more rows
```

Finally, these are words that changed with word-level patching.

``` r
diffs |> 
  select(-n_a, -starts_with("b_vs")) |> 
  arrange(desc(c_vs_b))
#> # A tibble: 202,384 × 5
#>    word          n_b     n_c c_vs_b c_vs_b_prop
#>    <chr>       <int>   <int>  <int>       <dbl>
#>  1 of         579718  582164   2446    0.00422 
#>  2 i'll       113741  115956   2215    0.0195  
#>  3 island       1949    3129   1180    0.605   
#>  4 indian        178    1282   1104    6.17    
#>  5 you       1842898 1843993   1095    0.000594
#>  6 italian       237    1255   1018    4.28    
#>  7 just       241453  242183    730    0.00302 
#>  8 like       202350  203054    704    0.00348 
#>  9 indians       145     794    649    4.45    
#> 10 inspector    1089    1728    639    0.586   
#> # ℹ 202,374 more rows

diffs |> 
  select(-n_a, -starts_with("b_vs")) |> 
  arrange(desc(c_vs_b_prop)) 
#> # A tibble: 202,384 × 5
#>    word        n_b   n_c c_vs_b c_vs_b_prop
#>    <chr>     <int> <int>  <int>       <dbl>
#>  1 mcintyre      0   120    120       120  
#>  2 ided          2    77     75        25  
#>  3 iii           8   189    181        20.1
#>  4 indian's      0    19     19        19  
#>  5 indies        2    52     50        16.7
#>  6 inquirer      1    31     30        15  
#>  7 mcintosh      0    15     15        15  
#>  8 innsbruck     0    14     14        14  
#>  9 mcintire      0    13     13        13  
#> 10 indochina     1    26     25        12.5
#> # ℹ 202,374 more rows
```

Words that decreased from word-patching.

``` r
diffs |> 
  select(-n_a, -starts_with("b_vs")) |> 
  arrange(c_vs_b)
#> # A tibble: 202,384 × 5
#>    word        n_b   n_c c_vs_b c_vs_b_prop
#>    <chr>     <int> <int>  <int>       <dbl>
#>  1 i'il       2179     0  -2179      -1.00 
#>  2 lsland     1180     0  -1180      -0.999
#>  3 lndian     1104     0  -1104      -0.999
#>  4 ltalian    1018     0  -1018      -0.999
#>  5 iike        681    32   -649      -0.952
#>  6 lndians     647     0   -647      -0.998
#>  7 lnspector   638     0   -638      -0.998
#>  8 we'il       583     0   -583      -0.998
#>  9 ltaly       558     0   -558      -0.998
#> 10 you'il      525     0   -525      -0.998
#> # ℹ 202,374 more rows
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
#>  1 don't     316606 717362 don                     321085             899598
#>  2 can't      92549 717362 can                     267620             899598
#>  3 didn't     79968 717362 didn                     80623             899598
#>  4 won't      34274 717362 won                      38729             899598
#>  5 doesn't    32168 717362 doesn                    32435             899598
#>  6 isn't      30325 717362 isn                      29886             899598
#>  7 wouldn't   23406 717362 wouldn                   23628             899598
#>  8 ain't      21812 717362 ain                      22248             899598
#>  9 wasn't     21726 717362 wasn                     21984             899598
#> 10 haven't    18467 717362 haven                    18844             899598
#> 11 couldn't   17100 717362 couldn                   17336             899598
#> 12 aren't     11876 717362 aren                     11946             899598
#> 13 shouldn't   8019 717362 shouldn                   8083             899598
#> 14 hasn't      4561 717362 hasn                      4625             899598
#> 15 hadn't      3085 717362 <NA>                        NA                 NA
#> 16 mustn't      945 717362 <NA>                        NA                 NA
#> 17 needn't      328 717362 needn                      334             899598
#> 18 shan't       147 717362 shan                       192             899598
#> 19 t             NA     NA t                       733338             899598
```

If I count the stems in my counts, I can see about how many contractions
I have missed. We would get around 300 contractions with some patching.

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
#>    word         n could_be_false_positive  total
#>    <chr>    <int> <lgl>                    <int>
#>  1 can     171755 TRUE                    177948
#>  2 won       4087 TRUE                    177948
#>  3 don       1866 TRUE                    177948
#>  4 haven      240 TRUE                    177948
#>  5 ain         54 FALSE                      242
#>  6 shan        52 FALSE                      242
#>  7 didn        46 FALSE                      242
#>  8 aren        16 FALSE                      242
#>  9 doesn       16 FALSE                      242
#> 10 wouldn      14 FALSE                      242
#> 11 couldn      13 FALSE                      242
#> 12 wasn        13 FALSE                      242
#> 13 isn         11 FALSE                      242
#> 14 hasn         5 FALSE                      242
#> 15 needn        1 FALSE                      242
#> 16 shouldn      1 FALSE                      242
```

A quick check of what these remaining errors look like. I seem to have
missed contractions that use an asterisk.

``` r
data_patched_lines <- targets::tar_read("data_raw_corpus_patched")


data_patched_lines |> 
  filter(str_detect(line, "n[*]t"))
#> # A tibble: 155 × 3
#>     index batch line                                                            
#>     <int> <int> <chr>                                                           
#>  1  55402     2 "There ain*t no scripts. It*s just me.  It was me. Larry, stay.…
#>  2 223616     8 "Don*t worry, it*s kosher.  Mr. Luffler gave me a message. Know…
#>  3 255794     9 "No, I don*t kowtow to no mattress company. "                   
#>  4 273735    10 "Of course, their names aren*t on it. "                         
#>  5 301466    10 "Ladies and gentlemen...  ...I give you Mrs. Lonesome Rhodes...…
#>  6 327935    11 "Don*t you worry, I*ve spared you more than you*ve spared yours…
#>  7 332473    12 "He*s a good-looking scoundrel, ain*t he? "                     
#>  8 402505    14 "Now, you good people ain*t so dumb you don*t know what*s impor…
#>  9 406866    14 "My goodness, ain*t we fussy. "                                 
#> 10 412135    14 "Isn*t he something? "                                          
#> # ℹ 145 more rows

didn_lines <- data_patched_lines |> 
  filter(str_detect(line, "didn[^'t]"))
didn_lines
#> # A tibble: 18 × 3
#>      index batch line                                                           
#>      <int> <int> <chr>                                                          
#>  1   85177     3 "I am really tired of all this... sordidness. "                
#>  2  793914    27 "Got you a food ticket at the White Owl for the plug you gave.…
#>  3 1259813    42 "Hey, welcome to the Black Hole of Calcutta.  One place they d…
#>  4 1281548    43 "Seems like there wasn*t a town in Arkansas or Missouri I didn…
#>  5 1570412    52 "I didn*t know a single living soul in Memphis. "              
#>  6 1950264    65 "Fuller didn*t even send me a wire. "                          
#>  7 2279921    76 "That mutt didn*t do Roosevelt any harm, did it? Dick Nixon ei…
#>  8 2468238    82 "Superman didnn't just leap over buildings, he flew. "         
#>  9 2513048    84 "I was out fighting for the gods,  and they didnothing to prot…
#> 10 2840944    95 "I'm going to ask you straight...  because I am tired...  and …
#> 11 3138832   104 "I like your energy, your spunk, your candidness...  and I thi…
#> 12 3160711   105 "I didn...  He was crying out there. How could you do that? "  
#> 13 3783216   126 "Oh, of c... I didn..."                                        
#> 14 4156976   138 "I didn*t go near it. "                                        
#> 15 4214093   140 "You sort of loved him, didn*t you? "                          
#> 16 4740959   157 "You didn*t know I had a sponsor, did you? "                   
#> 17 4861484   161 "In an hour, you*ll be up there.  Oh, Mel. Why didn*t you tell…
#> 18 5456954   181 "So she just walked around and around because she didn*t have …

# Quotations marks in the middle of words
data_patched_lines |> 
  filter(str_detect(line, "\\w\\\"\\w")) |> 
  tail()
#> # A tibble: 6 × 3
#>     index batch line                                                            
#>     <int> <int> <chr>                                                           
#> 1 5894931   196 "Murray \"Superboy\"babitch.  babitch leaped off the George"    
#> 2 5913674   196 "Totally forget it.  In 1642  Hester Prynne was in a stew   She…
#> 3 5913885   196 "That's an \"employees only\"area.  "                           
#> 4 5948720   197 "A \"fiancée\"?  \"Fiancée\"is French for the person you intend…
#> 5 6007287   199 "A \"heffalump\"or \"woozle's\" very sly, sly, sly, sly "       
#> 6 6039528   200 "I figured everything before \"I love you\"just doesn't count. "
```

### how to spot errors

My “process” for screening the corpus is to randomly sample words and
see what sticks out. When I noticed `"cla"` in one of these samples, I
figured out the `"I"` to `"l"` OCR problem in all-caps words.

``` r
data$word |> 
  sample(size = 10)
#>  [1] "nineteenths"   "gafro"         "delhi's"       "buckinghams"  
#>  [5] "sterilizer"    "knowjust"      "chaney'll"     "orchestration"
#>  [9] "treatises"     "seditious"
```

To feel better about things, you could weight by frequency:

``` r
data$word |> 
  sample(size = 10, prob = data$n)
#>  [1] "are"      "all"      "yeah"     "gonna"    "else"     "dear"    
#>  [7] "you"      "him"      "remember" "it"
```

### open questions (so far)

I’m not sure what’s going on with the encoding and whether that matters.
If you find all lines with the string “Zellweger”, you will find some
`"Ren\xe9e Zellweger"` and some `"Renee Zellweger"` tokens.

Numerals show up. I imagine that one would want to decompose them into
subwords so that, e.g., “1993” is “nineteen”, “ninety”, and “three”.

Stray observations:

- There are lots of URLs/usernames in the corpus because the subtitles
  can be signed or sourced.

- If a TV show has a theme song, then you can find many repeated lines.

- other OCR errors to consider: i/l to 1
