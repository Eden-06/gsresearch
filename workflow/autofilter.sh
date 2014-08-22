#!/bin/bash

# This script generates does the automated filtering and generation of the statistics
# It fetches all papers from the raw/ folder assuming that
# each file is named like paper2000.bib for each year.
# This is the format produced by the gsresearch.sh script.
# If the folders downloads/ or filter_human/ exist
# they will be included in the generation of statistics.
# The automated filter will include the following steps:
# 1. Filter out all publications not published by the big four
#    ACM, IEEE, Springer, ScienceDirect
# 2. Filter out all irrelevant publications
#    (Citation count < Log(Age))
# 3. Creates statistics for each step in the corresponding states folder.
#    (A peryear.csv and a states.csv is created each.)
# A complete run will create the following folders:
#  filter_pub/ 
#  filter_rel/
#  states_raw/
#  states_filter_pub/
#  states_filter_rel/
#  states_filter_human/
#  states_downloads/

echo "Filtering by main publishers..."

mkdir -p filter_pub
for i in `ls raw/` ; do
 # Note that -d removes duplicates
 ruby bibfilter.rb -d -i"/ieee\.org|acm\.org|springer\.com|sciencedirect\.com/" "raw/$i" > "filter_pub/$i" ;
done

# Filter by Citation Count

echo "Filtering by relevance of the article..."

mkdir -p filter_rel
bash relevancefilter.sh

### Statistics by Year

# Generate Generic Statistics

Folders="raw filter_pub filter_rel filter_human downloads"

for d in $Folders ; do 
  if [ -d $d ]; then
   
    echo "Generating statistics for $d dataset..."

    mkdir -p "states_$d"

		## Statistic by Publisher

		ruby bibfilter.rb -d -i"/ieee\.org/" $d/*.bib > states_$d/pubieee.bib
		ruby bibfilter.rb -d -i"/acm\.org/" $d/*.bib > states_$d/pubacm.bib
		ruby bibfilter.rb -d -i"/springer\.com/" $d/*.bib > states_$d/pubspringer.bib
		ruby bibfilter.rb -d -i"/sciencedirect\.com/" $d/*.bib > states_$d/pubsciencedirect.bib
    ruby bibfilter.rb -e"/ieee\.org|acm\.org|springer\.com|sciencedirect\.com/" $d/*.bib > states_$d/pubother.bib
		
    ## Statistics By Kind

		ruby bibfilter.rb -d -aarticle $d/*.bib > states_$d/article.bib
		ruby bibfilter.rb -d -aincollection $d/*.bib > states_$d/incollection.bib 
		ruby bibfilter.rb -d -ainproceedings $d/*.bib > states_$d/inproceedings.bib 
		ruby bibfilter.rb -d -apatent $d/*.bib > states_$d/patent.bib
		ruby bibfilter.rb -d -aphdthesis $d/*.bib > states_$d/phdthesis.bib
		ruby bibfilter.rb -d -amisc $d/*.bib > states_$d/misc.bib
		ruby bibfilter.rb -d -abook $d/*.bib > states_$d/book.bib

		## Show States
    reg_peryear="s/${d}\/paper([0-9]+)[.]bib/\1/" 
    reg_states="s/states_${d}\/\|.bib\|pub//g"

	  if [ "$d" == "downloads" ]; then
	    # add option -l to add linked files to the output
			echo "Year, Count, Median Citations, Min Citations, Max Citations, Accessible" > states_$d/peryear.csv
			for f in $d/*.bib ; do
        echo -n "$(sed -r $reg_peryear <<< $f), " ; 
				ruby bibfilter.rb -d -t -l $f ; 
			done >> states_$d/peryear.csv ;
		
			echo "Classifier, Count, Median Citations, Min Citations, Max Citations, Accessible" > states_$d/states.csv
			for f in states_$d/*.bib ; do
				echo -n "$(sed -e $reg_states <<< $f), " ;
				ruby bibfilter.rb -d -t -l $f;
			done >> states_$d/states.csv ;
		else
	    echo "Year, Count, Median Citations, Min Citations, Max Citations" > states_$d/peryear.csv
			for f in $d/*.bib ; do
				echo -n "$(sed -r $reg_peryear <<< $f), " ; 
				ruby bibfilter.rb -d -t $f ; 
			done >> states_$d/peryear.csv ;

			echo "Classifier, Count, Median Citations, Min Citations, Max Citations" > states_$d/states.csv
			for f in states_$d/*.bib ; do
			 echo -n "$(sed -e $reg_states <<< $f), " ;
			 ruby bibfilter.rb -d -t $f;
			done >> states_$d/states.csv ;
	  fi

	fi
done

if [ ! -d "filter_human" ]; then
  echo "Continue the Human filter step with the following commands:"
  echo "1. mkdir filter_human"
  echo "2. for f in \`ls filter_rel/*.bib\` ; do echo \$f ; ruby bibfilter.rb \"filter_rel/\$f\" > \"filter_human/\$f\""
fi
