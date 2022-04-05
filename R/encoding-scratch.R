
library(tidyverse)


z <- "There you go. Number 53.  Dr. von Hagens\x92 Body Worlds  invites visitors\x85   \x85to observe the body\x92s various  locomotive, digestive\x85   \x85nervous and vascular systems.   Please may I have your attention,  ladies and gentlemen?   I believe it is something very special,  what we see here.   This is edutainment.   -fixed in dramatic and athletic poses\x85   \x85 that reveal the true-to-life spatial  relationships amongst organs"

data_raw <- targets::tar_read(data_raw_corpus)


# Find which lines have some garbages in them
zs <- data_raw$line
z2s <- iconv(zs, "", "ASCII", sub = "byte")
i_z2s <- z2s |> stringr::str_which("<.+>")

# We could modify the elements in here
z2s[i_z2s]

# then repair the main data by inserting them here
# zs[i_z2s] <- z2s[i_z2s]

