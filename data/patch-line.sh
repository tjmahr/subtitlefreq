awk '{ if (NR == 4615823) print "Anything"; else print $0}' data/Subtlex.US.txt > data/Subtlex.US2.txt
