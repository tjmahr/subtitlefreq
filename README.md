
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
the corpus.

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
#> # A tibble: 80 × 2
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
#> # … with 70 more rows
```

After applying the patches, we obtain the following counts:

``` r
data <- targets::tar_read("data_counts_patched")
data
#> # A tibble: 199,107 × 2
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
#> # … with 199,097 more rows
```

We can rationalize our patching activity by looking at how many words
are affected:

``` r
data_pooled |>
  inner_join(data_patches, by = c("word" = "old")) |> 
  arrange(desc(n))
#> # A tibble: 75 × 3
#>    word         n new      
#>    <chr>    <int> <chr>    
#>  1 i'il      2070 i'll     
#>  2 lreland    238 ireland  
#>  3 lrene      156 irene    
#>  4 i'amour     26 l'amour  
#>  5 i'ts        26 it's     
#>  6 umplre      23 umpire   
#>  7 slren       19 siren    
#>  8 i'mjust     15 i'm just 
#>  9 lt'd        14 it'd     
#> 10 i'lljust    13 i'll just
#> # … with 65 more rows

# some of the patches are regular expressions so this is the best way
# to view them
data_pooled |>
  anti_join(data, by = "word") |> 
  print(n = 20)
#> # A tibble: 614 × 2
#>    word           n
#>    <chr>      <int>
#>  1 i'il        2070
#>  2 speaklng     292
#>  3 lreland      238
#>  4 slnglng      187
#>  5 playlng      186
#>  6 rlnglng      166
#>  7 lrene        156
#>  8 laughlng     132
#>  9 chatterlng   102
#> 10 knocklng      76
#> 11 cheerlng      74
#> 12 screamlng     70
#> 13 golng         67
#> 14 rlght         59
#> 15 dlrector      57
#> 16 groanlng      54
#> 17 slghlng       49
#> 18 shoutlng      47
#> 19 rapplng       41
#> 20 chuckllng     38
#> # … with 594 more rows
```

## open questions (so far)

I’m not sure what’s going on with the encoding and whether that matters.
If you find all lines with the string “Zellweger”, you will find some
`"Ren\xe9e Zellweger"` and some `"Renee Zellweger"` tokens.

Numerals show up. I imagine that one would want to decompose them into
subwords so that, e.g., “1993” is “nineteen”, “ninety”, and “three”.
