#!/bin/bash

# downloading papers

Dir="downloads"

echo "Downloading all referenced documents to the $Dir folder..."

mkdir -p "$Dir"
for f in `ls filter_human/` ; do
 ruby gsdownload.rb -d$Dir -v "filter_human/$f" > "$Dir/$f" ;
done
