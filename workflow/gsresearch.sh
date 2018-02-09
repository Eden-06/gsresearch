#!/bin/bash

# Collection of Data

RUBY="ruby"

echo "Collecting initial dataset..."

# This script must be adapted before you start your research.
# query for
#  with   :model driven development
#  any    :modelling modeling
#  exact  :
#  without:social bio psycho

 mkdir raw
 for i in {2010..2014} ; do
  $RUBY gsresearch.rb gs with model driven development any modelling modeling without social psycho year $i verbose > "raw/paper$i.bib" ;
 done
