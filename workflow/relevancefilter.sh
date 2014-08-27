#!/bin/bash

# Discard every entry whose citation count is below the logarithm of its
# age multiplied by a constant factor.
#    Constant * Log(Age)
# As a rule of thumb, the constant is the number of citations you assume
# a ten year old publications would would have at least.

CONSTANT="12"
YEAR=`date +%Y`

for f in `ls filter_pub/` ; do
 i="$(sed -r 's/paper([0-9]+)[.]bib/\1/' <<< $f)" ; 
 CITATIONCOUNT=`echo "a=$CONSTANT*(l($YEAR-$i)/l(10)); scale=0; if(a>0){ (a+0.5)/1 }else{ 0 }" | bc -l` ;
 echo " filter citations from the year $i below the citation limit of $CITATIONCOUNT"
 ruby bibfilter.rb -c$CITATIONCOUNT "filter_pub/$f" > "filter_rel/$f" ;
done
