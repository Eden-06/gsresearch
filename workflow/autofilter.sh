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
# 3. Creates statistics for each step in the corresponding stats folder.
#    (A peryear.csv and a stats.csv is created each.)
# A complete run will create the following folders:
#  filter_pub/ 
#  filter_rel/
#  stats_raw/
#  stats_filter_pub/
#  stats_filter_rel/
#  stats_filter_human/
#  stats_downloads/

RUBY="ruby"

echo "Filtering by main publishers..."

mkdir -p filter_pub
for i in `ls raw/` ; do
 # Note that -d removes duplicates
 $RUBY bibfilter.rb -d -i"/ieee\.org|acm\.org|springer\.com|sciencedirect\.com/" "raw/$i" > "filter_pub/$i" ;
done

# Filter by Citation Count

echo "Filtering by relevance of the article..."

mkdir -p filter_rel
bash relevancefilter.sh

if [[ -d downloads && -d approaches ]]; then
  echo "Filtering selected approaches (with comment={...})"
	for f in downloads/*.bib ; do
    # Note that -d removes duplicates
    $RUBY bibfilter.rb -d -i"/comment.+/" "$f" > "${f/downloads/approaches}" ;
  done
fi

### Statistics by Year

# Generate Generic Statistics

Folders="raw filter_pub filter_rel filter_human downloads approaches"

for d in $Folders ; do 
  if [ -d $d ]; then
   
    echo "Generating statistics for $d dataset..."

    mkdir -p "stats_$d"

		## Statistic by Publisher

		$RUBY bibfilter.rb -d -i"/ieee\.org/" $d/*.bib > stats_$d/pubieee.bib
		$RUBY bibfilter.rb -d -i"/acm\.org/" $d/*.bib > stats_$d/pubacm.bib
		$RUBY bibfilter.rb -d -i"/springer\.com/" $d/*.bib > stats_$d/pubspringer.bib
		$RUBY bibfilter.rb -d -i"/sciencedirect\.com/" $d/*.bib > stats_$d/pubsciencedirect.bib
    $RUBY bibfilter.rb -e"/ieee\.org|acm\.org|springer\.com|sciencedirect\.com/" $d/*.bib > stats_$d/pubother.bib
		
    ## Statistics By Kind

		$RUBY bibfilter.rb -d -aarticle $d/*.bib > stats_$d/article.bib
		$RUBY bibfilter.rb -d -aincollection $d/*.bib > stats_$d/incollection.bib 
		$RUBY bibfilter.rb -d -ainbook $d/*.bib > stats_$d/inbook.bib 
		$RUBY bibfilter.rb -d -ainproceedings $d/*.bib > stats_$d/inproceedings.bib 
		$RUBY bibfilter.rb -d -apatent $d/*.bib > stats_$d/patent.bib
		$RUBY bibfilter.rb -d -aphdthesis $d/*.bib > stats_$d/phdthesis.bib
		$RUBY bibfilter.rb -d -amisc $d/*.bib > stats_$d/misc.bib
		$RUBY bibfilter.rb -d -abook $d/*.bib > stats_$d/book.bib

		## Show stats
    reg_peryear="s/${d}\/paper([0-9]+)[.]bib/\1/" 
    reg_stats="s/stats_${d}\/\|.bib\|pub//g"

		if [ "$d" == "downloads" ]; then
		  # think whether approaches should also include Accessible field
		  # add option -l to add linked files to the output
			echo "Year, Count, Median Citations, Min Citations, Max Citations, Accessible" > stats_$d/peryear.csv
			for f in $d/*.bib ; do
	      echo -n "$(sed -r $reg_peryear <<< $f), " ; 
				$RUBY bibfilter.rb -d -t -l $f ; 
			done >> stats_$d/peryear.csv ;
	
			echo "Classifier, Count, Median Citations, Min Citations, Max Citations, Accessible" > stats_$d/stats.csv
			for f in stats_$d/*.bib ; do
				echo -n "$(sed -e $reg_stats <<< $f), " ;
				$RUBY bibfilter.rb -d -t -l $f;
			done >> stats_$d/stats.csv ;
		else
			echo "Year, Count, Median Citations, Min Citations, Max Citations" > stats_$d/peryear.csv
			for f in $d/*.bib ; do
				echo -n "$(sed -r $reg_peryear <<< $f), " ; 
				$RUBY bibfilter.rb -d -t $f ; 
			done >> stats_$d/peryear.csv ;
			
			echo "Classifier, Count, Median Citations, Min Citations, Max Citations" > stats_$d/stats.csv
			for f in stats_$d/*.bib ; do
			 echo -n "$(sed -e $reg_stats <<< $f), " ;
			 $RUBY bibfilter.rb -d -t $f;
			done >> stats_$d/stats.csv ;
		fi	   
	fi
done


if [ ! -d "filter_human" ]; then
  echo "Continue the Human filter step with the following commands:"
  echo "1. mkdir filter_human"
  echo "2. for f in \`ls filter_rel/\` ; do echo \$f ; $RUBY bibfilter.rb \"filter_rel/\$f\" > \"filter_human/\$f\" ; done"
fi

if [ -d approaches ]; then
	
	#Modify the list of approaches to your needs 
	APPROACHES="lodwick grm tao rbm agr orm ecargo mmr inm dci ontouml helena epsilon chameleon rica jawiro otj rava powerjava rumer fcr scala nextej javastage relations objectz"

  reg_approach="s/stats_approaches\/perapproach\/(.+)[.]bib/\1/" 
  echo "Generating statistics for the following approaches..."
  #echo $APPROACHES
  mkdir -p stats_approaches/perapproach/
	for f in $APPROACHES ; do
 		# Note that -d removes duplicates
 		echo -n " $f"
 		$RUBY bibfilter.rb -d -i"/comment.+$f/" approaches/*.bib > "stats_approaches/perapproach/$f.bib" ;
	done
	echo ""
	
	echo "Year, Count, Median Citations, Min Citations, Max Citations" > stats_approaches/perapproach.csv
		for f in stats_approaches/perapproach/*.bib ; do
	    echo -n "$(sed -r -e '$reg_approach' <<< $f), " ; 
			$RUBY bibfilter.rb -d -t $f ; 	  		
	done >> stats_approaches/perapproach.csv
else
  echo "After you have tagged all selected approaches by adding a comment={tag} to the selected bibtex items in the downloads/ folder, create the approaches folder and rerun ./autofilter.sh once more"
  echo " mkdir approaches"
  echo " ./autofilter.sh"
fi

if [[ -d "raw" && -d "filter_pub" && -d "filter_rel" && -d "filter_human" && -d  "downloads" && -d "approaches" ]]; then
  echo "Generating summary statistics..."
	echo "Year, Search Results, Automatic Filter, Relevance Filter, Abstract Selection, Approach Selection" > peryear.csv
	join -t, -a 1 -o auto stats_raw/peryear.csv stats_filter_pub/peryear.csv | 
	join -t, -a 1 -o auto - stats_filter_rel/peryear.csv |
	join -t, -a 1 -o auto - stats_filter_human/peryear.csv |
	join -t, -a 1 -o auto - stats_approaches/peryear.csv |
	cut -d, -f1,2,6,10,14,18 | tail -n +2 >> peryear.csv
	
		echo "Classifier, Search Results, Automatic Filter, Relevance Filter, Abstract Selection, Approach Selection" > stats.csv
	join -t, -a 1 -o auto stats_raw/stats.csv stats_filter_pub/stats.csv | 
	join -t, -a 1 -o auto - stats_filter_rel/stats.csv |
	join -t, -a 1 -o auto - stats_filter_human/stats.csv |
	join -t, -a 1 -o auto - stats_approaches/stats.csv |
	cut -d, -f1,2,6,10,14,18 | tail -n +2 >> stats.csv
	
fi
