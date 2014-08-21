#!/bin/bash

find . -name "*.pdf" -type f -not -path "./Unciteable/*" | sed -E 's/(^.+[/](.*[ ])*(.*)[_](.*)[.]pdf)/\1\t\4/'
