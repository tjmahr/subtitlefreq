
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
#> # A tibble: 6,043,188 × 2
#>    line                                                                    batch
#>    <chr>                                                                   <int>
#>  1 "***Tony? Hey, Tony, where you going? "                                     1
#>  2 "That place goes on the market today. "                                     1
#>  3 "I couldn't call myself his friend if I weren't willing to do the same…     1
#>  4 "You don't want to run a wedding magazine for a company that is fallin…     1
#>  5 "Well, I guess the only thing left for us to do  is to wire Marcie and…     1
#>  6 "I, like, dumped her, like, 20 years ago.  So? So, I don't think I eve…     1
#>  7 "Otis Day &amp; The Knights - Shout!  guys escaping from Sandi's house"     1
#>  8 "I'm gonna call it Serendipity.  What does that mean? I don't know.  A…     1
#>  9 "What on earth is wrong with you, besides the obvious lack of fashion …     1
#> 10 "Where would you go ? "                                                     1
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
#> # A tibble: 199,598 × 2
#>    word        n
#>    <chr>   <int>
#>  1 you   1848683
#>  2 i     1478125
#>  3 the   1472729
#>  4 to    1142753
#>  5 a     1024990
#>  6 and    670364
#>  7 it     666533
#>  8 of     579964
#>  9 that   548786
#> 10 in     492329
#> 11 me     466534
#> 12 is     454051
#> 13 what   426374
#> 14 this   402332
#> 15 on     351029
#> 16 for    347074
#> 17 my     340061
#> 18 i'm    327469
#> 19 your   324879
#> 20 we     320716
#> # … with 199,578 more rows
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
#> # A tibble: 153 × 2
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
#> # … with 143 more rows
```

After applying the patches, we obtain the following counts:

``` r
data <- targets::tar_read("data_counts_patched")
data
#> # A tibble: 199,034 × 2
#>    word        n
#>    <chr>   <int>
#>  1 you   1848683
#>  2 i     1478133
#>  3 the   1472730
#>  4 to    1142754
#>  5 a     1024990
#>  6 and    670364
#>  7 it     666542
#>  8 of     579964
#>  9 that   548786
#> 10 in     492329
#> # … with 199,024 more rows
```

We can rationalize our patching activity by looking at how many words
are affected:

``` r
data_pooled |>
  inner_join(data_patches, by = c("word" = "old")) |> 
  arrange(desc(n))
#> # A tibble: 148 × 3
#>    word          n new      
#>    <chr>     <int> <chr>    
#>  1 i'il       2070 i'll     
#>  2 lsn't       660 isn't    
#>  3 lnspector   639 inspector
#>  4 lnn         346 inn      
#>  5 lce         329 ice      
#>  6 martln      316 martin   
#>  7 mlke        284 mike     
#>  8 lt's        254 it's     
#>  9 lreland     238 ireland  
#> 10 lron        223 iron     
#> # … with 138 more rows

# some of the patches are regular expressions so this is the best way
# to view them
data_pooled |>
  anti_join(data, by = "word") |> 
  print(n = 20)
#> # A tibble: 687 × 2
#>    word          n
#>    <chr>     <int>
#>  1 i'il       2070
#>  2 lsn't       660
#>  3 lnspector   639
#>  4 lnn         346
#>  5 lce         329
#>  6 martln      316
#>  7 speaklng    292
#>  8 mlke        284
#>  9 lt's        254
#> 10 lreland     238
#> 11 lron        223
#> 12 offlcer     196
#> 13 slnglng     187
#> 14 playlng     186
#> 15 lra         171
#> 16 rlnglng     166
#> 17 thls        166
#> 18 lrene       156
#> 19 rlchard     145
#> 20 radlo       134
#> # … with 667 more rows
```

## open questions (so far)

I’m not sure what’s going on with the encoding and whether that matters.
If you find all lines with the string “Zellweger”, you will find some
`"Ren\xe9e Zellweger"` and some `"Renee Zellweger"` tokens.

Numerals show up. I imagine that one would want to decompose them into
subwords so that, e.g., “1993” is “nineteen”, “ninety”, and “three”.

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
#> [1] 47754830
51000000 - sum(data$n)
#> [1] 3245170
```

Or perhaps I am missing just 2 million words, based on the published
frequencies:

``` r
sum(data_subtlexus$FREQcount)
#> [1] 49719560
sum(data_subtlexus$FREQcount) - sum(data$n)
#> [1] 1964730
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
#> # A tibble: 818 × 3
#>    word             n   sum
#>    <chr>        <int> <int>
#>  1 tryin'to        36  1266
#>  2 goin'on         25  1266
#>  3 feelin'lucky    23  1266
#>  4 lookin'for      20  1266
#>  5 goin'to         17  1266
#>  6 fillin'up       13  1266
#>  7 goin'over       13  1266
#>  8 waitin'for      11  1266
#>  9 ain'tight       10  1266
#> 10 goin'out        10  1266
#> # … with 808 more rows
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
#> 1 play    17981
#> 2 playing  7694
#> 3 played   2795
#> 4 plays    1492
```

This is a pretty good match, but we have a few more *playing* tokens
because we patched `"lng"` words:

``` r
# Unpatched counts
data_pooled |> 
  filter(str_detect(word, "^play(lng|ing)"))
#> # A tibble: 4 × 2
#>   word           n
#>   <chr>      <int>
#> 1 playing     7507
#> 2 playlng      186
#> 3 playing's      4
#> 4 playingfor     1
```

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
#>  1 i'il     2070     4145
#>  2 we'il     544     4145
#>  3 you'il    490     4145
#>  4 il        433     4145
#>  5 he'il     158     4145
#>  6 it'il     113     4145
#>  7 they'il    96     4145
#>  8 she'il     56     4145
#>  9 s'il       52     4145
#> 10 that'il    30     4145
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
