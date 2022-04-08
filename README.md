
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
#> # A tibble: 197,203 × 2
#>    word        n
#>    <chr>   <int>
#>  1 you   1848683
#>  2 i     1478061
#>  3 the   1472729
#>  4 to    1142753
#>  5 a     1024990
#>  6 and    670364
#>  7 it     666204
#>  8 of     579964
#>  9 that   548509
#> 10 in     492712
#> 11 me     466534
#> 12 is     454161
#> 13 what   426276
#> 14 this   402461
#> 15 on     351029
#> 16 for    347074
#> 17 my     340061
#> 18 i'm    327469
#> 19 your   324879
#> 20 we     320716
#> # … with 197,183 more rows
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
#> # A tibble: 623 × 2
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
#> # … with 613 more rows
```

These individual patches are followed by regular-expression-based
patches. These are stored in a `data/patches-regex.csv` so that they can
have a `comment` column that describes their behavior.

``` r
data_patches_regex <- targets::tar_read("data_patches_regex")
data_patches_regex
#> # A tibble: 17 × 3
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
#> 10 nooo+                                    "no"            <NA>                
#> 11 meee+                                    "me"            <NA>                
#> 12 helloo+                                  "hello"         <NA>                
#> 13 sooo+                                    "so"            <NA>                
#> 14 whaaa+                                   "whaa"          <NA>                
#> 15 grr+                                     "grr"           <NA>                
#> 16 brr+                                     "brr"           <NA>                
#> 17 rrr+                                     "rrr"           <NA>
```

After applying the patches, we obtain the following counts:

``` r
data <- targets::tar_read("data_counts_patched")
data
#> # A tibble: 195,567 × 2
#>    word        n
#>    <chr>   <int>
#>  1 you   1849097
#>  2 i     1478079
#>  3 the   1472819
#>  4 to    1142853
#>  5 a     1025032
#>  6 and    670400
#>  7 it     666242
#>  8 of     580401
#>  9 that   548543
#> 10 in     492769
#> # … with 195,557 more rows
```

We can rationalize our patching activity by looking at how many words
are affected:

``` r
data_pooled |>
  anti_join(data, by = "word") |> 
  print(n = 20)
#> # A tibble: 1,709 × 2
#>    word             n
#>    <chr>        <int>
#>  1 i'il          2070
#>  2 lsn't          657
#>  3 lnspector      638
#>  4 we'il          544
#>  5 you'il         490
#>  6 lnn            346
#>  7 lce            319
#>  8 of'em          289
#>  9 lt's           244
#> 10 lreland        238
#> 11 lron           223
#> 12 lmperial       188
#> 13 ifyou          167
#> 14 he'il          158
#> 15 lrene          156
#> 16 lra            126
#> 17 lsaac          125
#> 18 lvan           124
#> 19 lndependence   122
#> 20 l'm            117
#> # … with 1,689 more rows
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
#> [1] 47755775
51000000 - sum(data$n)
#> [1] 3244225
```

Or perhaps I am missing just 2 million words, based on the published
frequencies:

``` r
sum(data_subtlexus$FREQcount)
#> [1] 49719560
sum(data_subtlexus$FREQcount) - sum(data$n)
#> [1] 1963785
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
#> 1 play    17982
#> 2 playing  7694
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
#> # A tibble: 35 × 3
#>    word        n `sum(n)`
#>    <chr>   <int>    <int>
#>  1 i'il     2070     4144
#>  2 we'il     544     4144
#>  3 you'il    490     4144
#>  4 il        433     4144
#>  5 he'il     158     4144
#>  6 it'il     113     4144
#>  7 they'il    96     4144
#>  8 she'il     56     4144
#>  9 s'il       52     4144
#> 10 that'il    30     4144
#> # … with 25 more rows

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
#> 1 cia    1084
#> 2 fbi     907
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
#> # Groups:   lemma [822]
#>    word        n lemma lemma_n
#>    <chr>   <int> <chr>   <int>
#>  1 you   1849097 you   1856811
#>  2 ya       7714 you   1856811
#>  3 is     454166 be    1546665
#>  4 be     289169 be    1546665
#>  5 was    284105 be    1546665
#>  6 are    262903 be    1546665
#>  7 been    87376 be    1546665
#>  8 were    83517 be    1546665
#>  9 am      49947 be    1546665
#> 10 being   24581 be    1546665
#> 11 m       10901 be    1546665
#> 12 i     1478079 i     1478079
#> 13 the   1472819 the   1472819
#> 14 to    1142853 to    1142853
#> 15 a     1025032 a     1118804
#> 16 an      93772 a     1118804
#> 17 and    670400 and    670400
#> 18 it     666242 it     666242
#> 19 that   548543 that   586454
#> 20 those   37911 that   586454
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
#> # A tibble: 618 × 6
#>    word          n_a   n_b   n_c n_b_tokens n_c_tokens
#>    <chr>       <int> <int> <int>      <int>      <int>
#>  1 hiv            NA   227   227       1465       1596
#>  2 ims            NA    40    40       1465       1596
#>  3 cia's          NA    35    35       1465       1596
#>  4 afis           NA    26    26       1465       1596
#>  5 africaaddio    NA    26    26       1465       1596
#>  6 codis          NA    22    22       1465       1596
#>  7 yril           NA    22    22       1465       1596
#>  8 jindraike      NA    21    21       1465       1596
#>  9 kcia           NA    18    18       1465       1596
#> 10 cic            NA    17    17       1465       1596
#> # … with 608 more rows
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
#> # A tibble: 3,009 × 5
#>    word       n_a   n_b   n_c n_a_tokens
#>    <chr>    <int> <int> <int>      <int>
#>  1 rlggs      682    NA    NA      15839
#>  2 sdl        360    NA    NA      15839
#>  3 alds       302    NA    NA      15839
#>  4 slpowlcz   199    NA    NA      15839
#>  5 slnglng    187    NA    NA      15839
#>  6 engllsh    157    NA    NA      15839
#>  7 mlchael    157    NA    NA      15839
#>  8 lcu        140    NA    NA      15839
#>  9 dellnda    127    NA    NA      15839
#> 10 benedlct   126    NA    NA      15839
#> # … with 2,999 more rows
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
#> # A tibble: 200,282 × 5
#>    word      n_a    n_b b_vs_a b_vs_a_prop
#>    <chr>   <int>  <int>  <int>       <dbl>
#>  1 kitt       11   2079   2068  172.      
#>  2 cia         8   1084   1076  120.      
#>  3 fbi        93    907    814    8.66    
#>  4 don't  309965 310724    759    0.00245 
#>  5 riggs     212    894    682    3.20    
#>  6 it's   276005 276453    448    0.00162 
#>  7 in     492327 492712    385    0.000782
#>  8 sdi        15    375    360   22.5     
#>  9 martin   2065   2379    314    0.152   
#> 10 aids      108    410    302    2.77    
#> # … with 200,272 more rows

diffs |> 
  select(-n_c, -starts_with("c_vs")) |> 
  arrange(desc(b_vs_a_prop)) 
#> # A tibble: 200,282 × 5
#>    word          n_a   n_b b_vs_a b_vs_a_prop
#>    <chr>       <int> <int>  <int>       <dbl>
#>  1 hiv             0   227    227       227  
#>  2 kitt           11  2079   2068       172. 
#>  3 cia             8  1084   1076       120. 
#>  4 ims             0    40     40        40  
#>  5 cia's           0    35     35        35  
#>  6 kitt's          2    92     90        30  
#>  7 afis            0    26     26        26  
#>  8 africaaddio     0    26     26        26  
#>  9 sdi            15   375    360        22.5
#> 10 codis           0    22     22        22  
#> # … with 200,272 more rows
```

Words that decreased during line-patching.

``` r
diffs |> 
  select(-n_c, -starts_with("c_vs")) |> 
  arrange(b_vs_a)
#> # A tibble: 200,282 × 5
#>    word     n_a    n_b b_vs_a b_vs_a_prop
#>    <chr>  <int>  <int>  <int>       <dbl>
#>  1 kltt    2120     52  -2068   -0.975   
#>  2 t      19441  17722  -1719   -0.0884  
#>  3 s      30138  28589  -1549   -0.0514  
#>  4 cla     1083      7  -1076   -0.993   
#>  5 fbl     1752    938   -814   -0.464   
#>  6 don     8418   7661   -757   -0.0899  
#>  7 rlggs    682      0   -682   -0.999   
#>  8 ln      3696   3313   -383   -0.104   
#>  9 sdl      360      0   -360   -0.997   
#> 10 it    666532 666204   -328   -0.000492
#> # … with 200,272 more rows

diffs |> 
  select(-n_c, -starts_with("c_vs")) |> 
  arrange(b_vs_a_prop) 
#> # A tibble: 200,282 × 5
#>    word       n_a   n_b b_vs_a b_vs_a_prop
#>    <chr>    <int> <int>  <int>       <dbl>
#>  1 rlggs      682     0   -682      -0.999
#>  2 sdl        360     0   -360      -0.997
#>  3 alds       302     0   -302      -0.997
#>  4 slpowlcz   199     0   -199      -0.995
#>  5 slnglng    187     0   -187      -0.995
#>  6 martln     316     1   -315      -0.994
#>  7 engllsh    157     0   -157      -0.994
#>  8 mlchael    157     0   -157      -0.994
#>  9 lcu        140     0   -140      -0.993
#> 10 cla       1083     7  -1076      -0.993
#> # … with 200,272 more rows
```

Finally, these are words that changed with word-level patching.

``` r
diffs |> 
  select(-n_a, -starts_with("b_vs")) |> 
  arrange(desc(c_vs_b))
#> # A tibble: 200,282 × 5
#>    word          n_b     n_c c_vs_b c_vs_b_prop
#>    <chr>       <int>   <int>  <int>       <dbl>
#>  1 i'll       111238  113338   2100    0.0189  
#>  2 isn't       29049   29712    663    0.0228  
#>  3 inspector    1090    1728    638    0.585   
#>  4 just       241476  242107    631    0.00261 
#>  5 we'll       33448   33992    544    0.0163  
#>  6 em          12151   12657    506    0.0416  
#>  7 you'll      30727   31219    492    0.0160  
#>  8 of         579964  580401    437    0.000753
#>  9 you       1848683 1849097    414    0.000224
#> 10 inn           426     772    346    0.810   
#> # … with 200,272 more rows

diffs |> 
  select(-n_a, -starts_with("b_vs")) |> 
  arrange(desc(c_vs_b_prop)) 
#> # A tibble: 200,282 × 5
#>    word        n_b   n_c c_vs_b c_vs_b_prop
#>    <chr>     <int> <int>  <int>       <dbl>
#>  1 innsbruck     0    14     14       14   
#>  2 rlnging       0    12     12       12   
#>  3 ireland      20   258    238       11.3 
#>  4 l'orange      0    10     10       10   
#>  5 ignatius      2    17     15        5   
#>  6 l'eveque      0     5      5        5   
#>  7 l'heure       0     5      5        5   
#>  8 wawy          0     5      5        5   
#>  9 ignacio      13    59     46        3.29
#> 10 bbing         0     3      3        3   
#> # … with 200,272 more rows
```

Words that decreased from word-patching.

``` r
diffs |> 
  select(-n_a, -starts_with("b_vs")) |> 
  arrange(c_vs_b)
#> # A tibble: 200,282 × 5
#>    word        n_b   n_c c_vs_b c_vs_b_prop
#>    <chr>     <int> <int>  <int>       <dbl>
#>  1 i'il       2070     0  -2070      -1.00 
#>  2 lsn't       657     0   -657      -0.998
#>  3 lnspector   638     0   -638      -0.998
#>  4 we'il       544     0   -544      -0.998
#>  5 you'il      490     0   -490      -0.998
#>  6 lnn         346     0   -346      -0.997
#>  7 lce         319     0   -319      -0.997
#>  8 of'em       289     0   -289      -0.997
#>  9 lt's        244     0   -244      -0.996
#> 10 lreland     238     0   -238      -0.996
#> # … with 200,272 more rows
```

## how to spot errors

My “process” for screening the corpus is to randomly sample words and
see what sticks out. When I noticed `"cla"` in one of these samples, I
figured out the `"I"` to `"l"` OCR problem in all-caps words.

``` r
data_pooled$word |> 
  sample(size = 10)
#>  [1] "salud"        "kindred"      "blowfor"      "shells"       "mejiminy"    
#>  [6] "redhook"      "chumbawambas" "adler"        "percenter"    "malady"
```

To feel better about things, you could weight by frequency:

``` r
data_pooled$word |> 
  sample(size = 10, prob = data_pooled$n)
#>  [1] "eh"       "great"    "is"       "where"    "us"       "beamed"  
#>  [7] "shortage" "to"       "windows"  "idea"
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
