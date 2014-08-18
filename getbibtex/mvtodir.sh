#!/bin/bash

ls -1 | grep -E "(.*)[_](.*)[.]pdf" | while read name;
do
 dir=$(echo "$name" | sed -r 's/^(.+[ ])?(.+)[_].*/\2/')
 mkdir -p "$dir"
 echo "Moving $name to $dir"
 mv "$name" "$dir/"
done
