
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
#> # A tibble: 197,659 × 2
#>    word        n
#>    <chr>   <int>
#>  1 you   1843014
#>  2 the   1472724
#>  3 i     1464109
#>  4 to    1142750
#>  5 a     1024674
#>  6 and    670364
#>  7 it     659571
#>  8 of     579893
#>  9 that   545167
#> 10 in     492714
#> 11 me     466443
#> 12 is     454166
#> 13 what   424856
#> 14 this   402462
#> 15 on     350991
#> 16 for    347072
#> 17 my     340057
#> 18 i'm    335604
#> 19 your   324879
#> 20 we     318267
#> # … with 197,639 more rows
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
#> # A tibble: 196,004 × 2
#>    word        n
#>    <chr>   <int>
#>  1 you   1843428
#>  2 the   1472814
#>  3 i     1464127
#>  4 to    1142851
#>  5 a     1024717
#>  6 and    670400
#>  7 it     659609
#>  8 of     580330
#>  9 that   545201
#> 10 in     492771
#> # … with 195,994 more rows
```

We can rationalize our patching activity by looking at how many words
are affected:

``` r
data_pooled |>
  anti_join(data, by = "word") |> 
  print(n = 20)
#> # A tibble: 1,733 × 2
#>    word          n
#>    <chr>     <int>
#>  1 i'il       2178
#>  2 ltalian    1018
#>  3 iike        681
#>  4 lnspector   638
#>  5 we'il       581
#>  6 ltaly       558
#>  7 you'il      525
#>  8 lnn         345
#>  9 lce         319
#> 10 lt's        302
#> 11 of'em       289
#> 12 lreland     238
#> 13 lron        223
#> 14 lmperial    188
#> 15 he'il       175
#> 16 ifyou       166
#> 17 lrene       156
#> 18 ltalians    135
#> 19 lra         126
#> 20 it'il       123
#> # … with 1,713 more rows
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
#> [1] 47687755
51000000 - sum(data$n)
#> [1] 3312245
```

Or perhaps I am missing just 2 million words, based on the published
frequencies:

``` r
sum(data_subtlexus$FREQcount)
#> [1] 49719560
sum(data_subtlexus$FREQcount) - sum(data$n)
#> [1] 2031805
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
#> # A tibble: 820 × 3
#>    word             n   sum
#>    <chr>        <int> <int>
#>  1 tryin'to        36  1269
#>  2 goin'on         25  1269
#>  3 feelin'lucky    23  1269
#>  4 lookin'for      20  1269
#>  5 goin'to         17  1269
#>  6 fillin'up       13  1269
#>  7 goin'over       13  1269
#>  8 waitin'for      11  1269
#>  9 ain'tight       10  1269
#> 10 goin'out        10  1269
#> # … with 810 more rows
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
#> 1 play    17980
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
#> # A tibble: 37 × 3
#>    word        n `sum(n)`
#>    <chr>   <int>    <int>
#>  1 i'il     2178     4143
#>  2 we'il     581     4143
#>  3 you'il    525     4143
#>  4 he'il     175     4143
#>  5 il        146     4143
#>  6 it'il     123     4143
#>  7 they'il   105     4143
#>  8 l'il       70     4143
#>  9 she'il     58     4143
#> 10 s'il       54     4143
#> # … with 27 more rows

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
#> 2 fbi     912
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
#> # Groups:   lemma [823]
#>    word        n lemma lemma_n
#>    <chr>   <int> <chr>   <int>
#>  1 you   1843428 you   1851142
#>  2 ya       7714 you   1851142
#>  3 is     454171 be    1535701
#>  4 be     289169 be    1535701
#>  5 was    284105 be    1535701
#>  6 are    262903 be    1535701
#>  7 been    87376 be    1535701
#>  8 were    83517 be    1535701
#>  9 am      49879 be    1535701
#> 10 being   24581 be    1535701
#> 11 the   1472814 the   1472814
#> 12 i     1464127 i     1464127
#> 13 to    1142851 to    1142851
#> 14 a     1024717 a     1118460
#> 15 an      93743 a     1118460
#> 16 and    670400 and    670400
#> 17 it     659609 it     659609
#> 18 that   545201 that   583112
#> 19 those   37911 that   583112
#> 20 of     580330 of     580330
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
#> # A tibble: 2,636 × 6
#>    word       n_a   n_b   n_c n_b_tokens n_c_tokens
#>    <chr>    <int> <int> <int>      <int>      <int>
#>  1 hiv         NA   227   227       9004       9126
#>  2 rené        NA   141   141       9004       9126
#>  3 cliché      NA   128   128       9004       9126
#>  4 señora      NA   105   105       9004       9126
#>  5 führer      NA    99    99       9004       9126
#>  6 pelé        NA    97    97       9004       9126
#>  7 fräulein    NA    90    90       9004       9126
#>  8 señorita    NA    90    90       9004       9126
#>  9 temüjin     NA    68    68       9004       9126
#> 10 adiós       NA    63    63       9004       9126
#> # … with 2,626 more rows
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
#> # A tibble: 4,567 × 5
#>    word       n_a   n_b   n_c n_a_tokens
#>    <chr>    <int> <int> <int>      <int>
#>  1 teli      1002    NA    NA      26407
#>  2 realiy     859    NA    NA      26407
#>  3 rlggs      682    NA    NA      26407
#>  4 lsn't      660    NA    NA      26407
#>  5 stili      445    NA    NA      26407
#>  6 helio      442    NA    NA      26407
#>  7 sdl        360    NA    NA      26407
#>  8 alds       302    NA    NA      26407
#>  9 slpowlcz   199    NA    NA      26407
#> 10 slnglng    187    NA    NA      26407
#> # … with 4,557 more rows
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
#> # A tibble: 202,300 × 5
#>    word      n_a    n_b b_vs_a b_vs_a_prop
#>    <chr>   <int>  <int>  <int>       <dbl>
#>  1 i'm    327468 335604   8136      0.0248
#>  2 it's   276005 283775   7770      0.0282
#>  3 don't  309965 316454   6489      0.0209
#>  4 that's 159049 163172   4123      0.0259
#>  5 you're 184816 188674   3858      0.0209
#>  6 all    257742 261045   3303      0.0128
#>  7 i'll   111235 113720   2485      0.0223
#>  8 kitt       11   2079   2068    172.    
#>  9 can't   90478  92499   2021      0.0223
#> 10 well   152957 154964   2007      0.0131
#> # … with 202,290 more rows

diffs |> 
  select(-n_c, -starts_with("c_vs")) |> 
  arrange(desc(b_vs_a_prop)) 
#> # A tibble: 202,300 × 5
#>    word       n_a   n_b b_vs_a b_vs_a_prop
#>    <chr>    <int> <int>  <int>       <dbl>
#>  1 hiv          0   227    227        227 
#>  2 kitt        11  2079   2068        172.
#>  3 rené         0   141    141        141 
#>  4 cliché       0   128    128        128 
#>  5 cia          8  1083   1075        119.
#>  6 fiancé       2   319    317        106.
#>  7 señora       0   105    105        105 
#>  8 führer       0    99     99         99 
#>  9 pelé         0    97     97         97 
#> 10 fräulein     0    90     90         90 
#> # … with 202,290 more rows
```

Words that decreased during line-patching.

``` r
diffs |> 
  select(-n_c, -starts_with("c_vs")) |> 
  arrange(b_vs_a)
#> # A tibble: 202,300 × 5
#>    word      n_a     n_b b_vs_a b_vs_a_prop
#>    <chr>   <int>   <int>  <int>       <dbl>
#>  1 s       30138    4531 -25607    -0.850  
#>  2 t       19441    3722 -15719    -0.809  
#>  3 i     1478384 1464109 -14275    -0.00966
#>  4 m       10901    2654  -8247    -0.756  
#>  5 it     666532  659571  -6961    -0.0104 
#>  6 don      8418    1916  -6502    -0.772  
#>  7 re       8044    2112  -5932    -0.737  
#>  8 you   1848677 1843014  -5663    -0.00306
#>  9 ll       5413     765  -4648    -0.859  
#> 10 that   548765  545167  -3598    -0.00656
#> # … with 202,290 more rows

diffs |> 
  select(-n_c, -starts_with("c_vs")) |> 
  arrange(b_vs_a_prop) 
#> # A tibble: 202,300 × 5
#>    word       n_a   n_b b_vs_a b_vs_a_prop
#>    <chr>    <int> <int>  <int>       <dbl>
#>  1 teli      1002     0  -1002      -0.999
#>  2 realiy     859     0   -859      -0.999
#>  3 rlggs      682     0   -682      -0.999
#>  4 lsn't      660     0   -660      -0.998
#>  5 stili      445     0   -445      -0.998
#>  6 helio      442     0   -442      -0.998
#>  7 sdl        360     0   -360      -0.997
#>  8 weli      2015     5  -2010      -0.997
#>  9 alds       302     0   -302      -0.997
#> 10 slpowlcz   199     0   -199      -0.995
#> # … with 202,290 more rows
```

Finally, these are words that changed with word-level patching.

``` r
diffs |> 
  select(-n_a, -starts_with("b_vs")) |> 
  arrange(desc(c_vs_b))
#> # A tibble: 202,300 × 5
#>    word         n_b    n_c c_vs_b c_vs_b_prop
#>    <chr>      <int>  <int>  <int>       <dbl>
#>  1 i'll      113720 115928   2208    0.0194  
#>  2 italian      243   1261   1018    4.17    
#>  3 like      202295 203021    726    0.00359 
#>  4 inspector   1089   1727    638    0.585   
#>  5 just      241474 242107    633    0.00262 
#>  6 we'll      34100  34681    581    0.0170  
#>  7 italy         73    631    558    7.54    
#>  8 you'll     31336  31863    527    0.0168  
#>  9 em         12149  12655    506    0.0416  
#> 10 of        579893 580330    437    0.000754
#> # … with 202,290 more rows

diffs |> 
  select(-n_a, -starts_with("b_vs")) |> 
  arrange(desc(c_vs_b_prop)) 
#> # A tibble: 202,300 × 5
#>    word        n_b   n_c c_vs_b c_vs_b_prop
#>    <chr>     <int> <int>  <int>       <dbl>
#>  1 innsbruck     0    14     14       14   
#>  2 rlnging       0    12     12       12   
#>  3 ireland      20   258    238       11.3 
#>  4 l'orange      0    10     10       10   
#>  5 italy        73   631    558        7.54
#>  6 italians     17   152    135        7.5 
#>  7 ignatius      2    17     15        5   
#>  8 l'eveque      0     5      5        5   
#>  9 l'heure       0     5      5        5   
#> 10 wawy          0     5      5        5   
#> # … with 202,290 more rows
```

Words that decreased from word-patching.

``` r
diffs |> 
  select(-n_a, -starts_with("b_vs")) |> 
  arrange(c_vs_b)
#> # A tibble: 202,300 × 5
#>    word        n_b   n_c c_vs_b c_vs_b_prop
#>    <chr>     <int> <int>  <int>       <dbl>
#>  1 i'il       2178     0  -2178      -1.00 
#>  2 ltalian    1018     0  -1018      -0.999
#>  3 iike        681     0   -681      -0.999
#>  4 lnspector   638     0   -638      -0.998
#>  5 we'il       581     0   -581      -0.998
#>  6 ltaly       558     0   -558      -0.998
#>  7 you'il      525     0   -525      -0.998
#>  8 lnn         345     0   -345      -0.997
#>  9 lce         319     0   -319      -0.997
#> 10 lt's        302     0   -302      -0.997
#> # … with 202,290 more rows
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
#>  1 don't     316472 717005 don                     321085             899598
#>  2 can't      92532 717005 can                     267620             899598
#>  3 didn't     79874 717005 didn                     80623             899598
#>  4 won't      34263 717005 won                      38729             899598
#>  5 doesn't    32159 717005 doesn                    32435             899598
#>  6 isn't      30314 717005 isn                      29886             899598
#>  7 wouldn't   23395 717005 wouldn                   23628             899598
#>  8 ain't      21810 717005 ain                      22248             899598
#>  9 wasn't     21714 717005 wasn                     21984             899598
#> 10 haven't    18462 717005 haven                    18844             899598
#> 11 couldn't   17077 717005 couldn                   17336             899598
#> 12 aren't     11860 717005 aren                     11946             899598
#> 13 shouldn't   8012 717005 shouldn                   8083             899598
#> 14 hasn't      4560 717005 hasn                      4625             899598
#> 15 hadn't      3081 717005 <NA>                        NA                 NA
#> 16 mustn't      945 717005 <NA>                        NA                 NA
#> 17 needn't      328 717005 needn                      334             899598
#> 18 shan't       147 717005 shan                       192             899598
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
#>  1 can     171777 TRUE                    178026
#>  2 won       4091 TRUE                    178026
#>  3 don       1916 TRUE                    178026
#>  4 haven      242 TRUE                    178026
#>  5 didn        57 FALSE                      281
#>  6 ain         54 FALSE                      281
#>  7 shan        52 FALSE                      281
#>  8 doesn       24 FALSE                      281
#>  9 couldn      20 FALSE                      281
#> 10 isn         18 FALSE                      281
#> 11 aren        16 FALSE                      281
#> 12 wouldn      16 FALSE                      281
#> 13 wasn        15 FALSE                      281
#> 14 hasn         6 FALSE                      281
#> 15 shouldn      2 FALSE                      281
#> 16 needn        1 FALSE                      281
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
#> 1 5894931   196 "Murray \"Superboy\"babitch.  babitch leaped off the George"    
#> 2 5913674   196 "Totally forget it.  In 1642  Hester Prynne was ln a stew   She…
#> 3 5913885   196 "That's an \"employees only\"area.  "                           
#> 4 5948720   197 "A \"fiancée\"?  \"Fiancée\"is French for the person you intend…
#> 5 6007287   199 "A \"heffalump\"or \"woozle's\" very sly, sly, sly, sly "       
#> 6 6039528   200 "I figured everything before \"I love you\"just doesn't count. "
```

## how to spot errors

My “process” for screening the corpus is to randomly sample words and
see what sticks out. When I noticed `"cla"` in one of these samples, I
figured out the `"I"` to `"l"` OCR problem in all-caps words.

``` r
data_pooled$word |> 
  sample(size = 10)
#>  [1] "tulips"         "mingling"       "blistex"        "sobbing"       
#>  [5] "mcmaster"       "reddi"          "chorologically" "bask"          
#>  [9] "pbbtt"          "misconception"
```

To feel better about things, you could weight by frequency:

``` r
data_pooled$word |> 
  sample(size = 10, prob = data_pooled$n)
#>  [1] "tells"       "wait"        "is"          "could"       "us"         
#>  [6] "andromeda's" "import"      "to"          "wallet"      "matter"
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
