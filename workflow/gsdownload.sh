#!/bin/bash

# downloading papers

Dir="downloads"
RUBY="ruby1.9.1"

echo "Downloading all referenced documents to the $Dir folder..."

mkdir -p "$Dir"
for f in `ls filter_human/` ; do
 $RUBY gsdownload.rb -d$Dir -v "filter_human/$f" > "$Dir/$f" ;
done
