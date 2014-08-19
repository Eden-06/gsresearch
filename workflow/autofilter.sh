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

## Statistics by Year

echo "Generating statistics for initial dataset..."

mkdir -p states_raw
echo "Year, Count, Median Citations, Min Citations, Max Citations" > states_raw/peryear.csv
for f in raw/*.bib ; do
 echo -n "$(sed -r 's/raw\/paper([0-9]+)[.]bib/\1/' <<< $f), " ; 
 # Note that -d removes duplicates
 ruby bibfilter.rb -d -t $f ; 
done >> states_raw/peryear.csv

## Statistics by Kind without duplicates

ruby bibfilter.rb -d -aarticle raw/*.bib > states_raw/article.bib
ruby bibfilter.rb -d -aincollection raw/*.bib > states_raw/incollection.bib 
ruby bibfilter.rb -d -ainproceedings raw/*.bib > states_raw/inproceedings.bib 
ruby bibfilter.rb -d -apatent raw/*.bib > states_raw/patent.bib
ruby bibfilter.rb -d -aphdthesis raw/*.bib > states_raw/phdthesis.bib
ruby bibfilter.rb -d -amisc raw/*.bib > states_raw/misc.bib
ruby bibfilter.rb -d -abook raw/*.bib > states_raw/book.bib

## Statistics by Publisher without duplicates

ruby bibfilter.rb  -d -i"/ieee\.org/" raw/*.bib > states_raw/pubieee.bib
ruby bibfilter.rb  -d -i"/acm\.org/" raw/*.bib > states_raw/pubacm.bib
ruby bibfilter.rb  -d -i"/springer\.com/" raw/*.bib > states_raw/pubspringer.bib
ruby bibfilter.rb  -d -i"/sciencedirect\.com/" raw/*.bib > states_raw/pubsciencedirect.bib
ruby bibfilter.rb  -d -e"/ieee\.org|acm\.org|springer\.com|sciencedirect\.com/" raw/*.bib > states_raw/pubother.bib

## Show Results

echo "Classifier, Count, Median Citations, Min Citations, Max Citations" > states_raw/states.csv
for f in states_raw/*.bib ; do
 echo -n "$(sed -e 's/states_raw\/\|.bib\|pub//g' <<< $f), " ;
 # Note that -d removes duplicates
 ruby bibfilter.rb -d -t $f; 
done >> states_raw/states.csv

# Filter by Four Main Publishers

echo "Filtering by main publishers..."

mkdir -p filter_pub
for i in `ls raw/` ; do
 # Note that -d removes duplicates
 ruby bibfilter.rb -d -i"/ieee\.org|acm\.org|springer\.com|sciencedirect\.com/" "raw/$i" > "filter_pub/$i" ;
done

echo "Generating statistics for filter_pub dataset..."

## Statistics by Kind

mkdir -p states_filter_pub
ruby bibfilter.rb -aarticle filter_pub/*.bib > states_filter_pub/article.bib
ruby bibfilter.rb -aincollection filter_pub/*.bib > states_filter_pub/incollection.bib 
ruby bibfilter.rb -ainproceedings filter_pub/*.bib > states_filter_pub/inproceedings.bib 
ruby bibfilter.rb -apatent filter_pub/*.bib > states_filter_pub/patent.bib
ruby bibfilter.rb -aphdthesis filter_pub/*.bib > states_filter_pub/phdthesis.bib
ruby bibfilter.rb -amisc filter_pub/*.bib > states_filter_pub/misc.bib
ruby bibfilter.rb -abook filter_pub/*.bib > states_filter_pub/book.bib
ruby bibfilter.rb -i"/ieee\.org/" filter_pub/*.bib > states_filter_pub/pubieee.bib
ruby bibfilter.rb -i"/acm\.org/" filter_pub/*.bib > states_filter_pub/pubacm.bib
ruby bibfilter.rb -i"/springer\.com/" filter_pub/*.bib > states_filter_pub/pubspringer.bib
ruby bibfilter.rb -i"/sciencedirect\.com/" filter_pub/*.bib > states_filter_pub/pubsciencedirect.bib

## Statistics by Year

echo "Year, Count, Median Citations, Min Citations, Max Citations" > states_filter_pub/peryear.csv
for f in filter_pub/*.bib ; do
 echo -n "$(sed -r 's/filter_pub\/paper([0-9]+)[.]bib/\1/' <<< $f), " ; 
 ruby bibfilter.rb -t $f ; 
done >> states_filter_pub/peryear.csv


## Show States

echo "Classifier, Count, Median Citations, Min Citations, Max Citations" > states_filter_pub/states.csv
for f in states_filter_pub/*.bib ; do
 echo -n "$(sed -e 's/states_filter_pub\/\|.bib\|pub//g' <<< $f), " ;
 ruby bibfilter.rb -t $f; 
done >> states_filter_pub/states.csv

# Filter by Citation Count

echo "Filtering by relevance of the article..."

mkdir -p filter_rel
bash relevancefilter.sh

## Statistics by Year

echo "Generating statistics for relevant dataset..."

mkdir -p states_filter_rel

echo "Year, Count, Median Citations, Min Citations, Max Citations" > states_filter_rel/peryear.csv
for f in filter_rel/*.bib ; do
 echo -n "$(sed -r 's/filter_rel\/paper([0-9]+)[.]bib/\1/' <<< $f), " ; 
 ruby bibfilter.rb -t $f ; 
done >> states_filter_rel/peryear.csv

## Statistic by Publisher

ruby bibfilter.rb -i"/ieee\.org/" filter_rel/*.bib > states_filter_rel/pubieee.bib
ruby bibfilter.rb -i"/acm\.org/" filter_rel/*.bib > states_filter_rel/pubacm.bib
ruby bibfilter.rb -i"/springer\.com/" filter_rel/*.bib > states_filter_rel/pubspringer.bib
ruby bibfilter.rb -i"/sciencedirect\.com/" filter_rel/*.bib > states_filter_rel/pubsciencedirect.bib

## Statistics By Kind

ruby bibfilter.rb -aarticle filter_rel/*.bib > states_filter_rel/article.bib
ruby bibfilter.rb -aincollection filter_rel/*.bib > states_filter_rel/incollection.bib 
ruby bibfilter.rb -ainproceedings filter_rel/*.bib > states_filter_rel/inproceedings.bib 
ruby bibfilter.rb -apatent filter_rel/*.bib > states_filter_rel/patent.bib
ruby bibfilter.rb -aphdthesis filter_rel/*.bib > states_filter_rel/phdthesis.bib
ruby bibfilter.rb -amisc filter_rel/*.bib > states_filter_rel/misc.bib
ruby bibfilter.rb -abook filter_rel/*.bib > states_filter_rel/book.bib

## Show States

echo "Classifier, Count, Median Citations, Min Citations, Max Citations" > states_filter_rel/states.csv
for f in states_filter_rel/*.bib ; do
 echo -n "$(sed -e 's/states_filter_rel\/\|.bib\|pub//g' <<< $f), " ;
 ruby bibfilter.rb -t $f;
done >> states_filter_rel/states.csv

if [ -d filter_human/ ]
then

  ## Statistics by Year

  echo "Generating statistics for human dataset..."

  mkdir -p states_filter_human

  echo "Year, Count, Median Citations, Min Citations, Max Citations" > states_filter_human/peryear.csv
  for f in filter_human/*.bib ; do
   echo -n "$(sed -r 's/filter_human\/paper([0-9]+)[.]bib/\1/' <<< $f), " ; 
   ruby bibfilter.rb -t $f ; 
  done >> states_filter_human/peryear.csv

  ## Statistic by Publisher

  ruby bibfilter.rb -i"/ieee\.org/" filter_human/*.bib > states_filter_human/pubieee.bib
  ruby bibfilter.rb -i"/acm\.org/" filter_human/*.bib > states_filter_human/pubacm.bib
  ruby bibfilter.rb -i"/springer\.com/" filter_human/*.bib > states_filter_human/pubspringer.bib
  ruby bibfilter.rb -i"/sciencedirect\.com/" filter_human/*.bib > states_filter_human/pubsciencedirect.bib

  ## Statistics By Kind

  ruby bibfilter.rb -aarticle filter_human/*.bib > states_filter_human/article.bib
  ruby bibfilter.rb -aincollection filter_human/*.bib > states_filter_human/incollection.bib 
  ruby bibfilter.rb -ainproceedings filter_human/*.bib > states_filter_human/inproceedings.bib 
  ruby bibfilter.rb -apatent filter_human/*.bib > states_filter_human/patent.bib
  ruby bibfilter.rb -aphdthesis filter_human/*.bib > states_filter_human/phdthesis.bib
  ruby bibfilter.rb -amisc filter_human/*.bib > states_filter_human/misc.bib
  ruby bibfilter.rb -abook filter_human/*.bib > states_filter_human/book.bib

  ## Show States

  echo "Classifier, Count, Median Citations, Min Citations, Max Citations" > states_filter_human/states.csv
  for f in states_filter_human/*.bib ; do
   echo -n "$(sed -e 's/states_filter_human\/\|.bib\|pub//g' <<< $f), " ;
   ruby bibfilter.rb -t $f;
  done >> states_filter_human/states.csv

fi

if [ -d downloads/ ]
then

  ## Statistics by Year

  echo "Generating statistics for downloads dataset..."

  mkdir -p states_downloads

  echo "Year, Count, Median Citations, Min Citations, Max Citations, Accessible" > states_downloads/peryear.csv
  for f in downloads/*.bib ; do
   echo -n "$(sed -r 's/downloads\/paper([0-9]+)[.]bib/\1/' <<< $f), " ; 
   ruby bibfilter.rb -t -l $f ; 
  done >> states_downloads/peryear.csv

  ## Statistic by Publisher

  ruby bibfilter.rb -i"/ieee\.org/" downloads/*.bib > states_downloads/pubieee.bib
  ruby bibfilter.rb -i"/acm\.org/" downloads/*.bib > states_downloads/pubacm.bib
  ruby bibfilter.rb -i"/springer\.com/" downloads/*.bib > states_downloads/pubspringer.bib
  ruby bibfilter.rb -i"/sciencedirect\.com/"downloads/*.bib > states_downloads/pubsciencedirect.bib

  ## Statistics By Kind

  ruby bibfilter.rb -aarticle downloads/*.bib > states_downloads/article.bib
  ruby bibfilter.rb -aincollection downloads/*.bib > states_downloads/incollection.bib 
  ruby bibfilter.rb -ainproceedings downloads/*.bib > states_downloads/inproceedings.bib 
  ruby bibfilter.rb -apatent downloads/*.bib > states_downloads/patent.bib
  ruby bibfilter.rb -aphdthesis downloads/*.bib > states_downloads/phdthesis.bib
  ruby bibfilter.rb -amisc downloads/*.bib > states_downloads/misc.bib
  ruby bibfilter.rb -abook downloads/*.bib > states_downloads/book.bib

  ## Show States

  echo "Classifier, Count, Median Citations, Min Citations, Max Citations, Accessible" > states_downloads/states.csv
  for f in states_downloads/*.bib ; do
   echo -n "$(sed -e 's/states_downloads\/\|.bib\|pub//g' <<< $f), " ;
   ruby bibfilter.rb -t -l $f;
  done >> states_downloads/states.csv

fi
