gsresearch
==========
This is a commandline tool for brute force harvesting of publication search sites.

System requirements
-------------------

* Ruby Version 1.9.3 (or higher) [\[get here\]](https://www.ruby-lang.org/de/downloads/)
* Mechanize Version 2.7.1 (or higher) [\[get here\]](https://github.com/sparklemotion/mechanize)

Synopsis
--------
```bash
 ruby gsresearch.rb [OPTIONS] MODULE QUERY
```

Description
-----------

GSresearch is a tool for brute force harvesting of publication sites.
It is designed to collect all the papers found for a given query
and emit the bibtex reference found for each publication, 
the citation count as well as a link to the publication.

Options
-------

* `-v`  
    indicates that the output should be verbose
    (All verbose output is directed to STDERR)

Module
------

Specify the website papers are retrieved:

* `help`  
    shows this document
* `version`  
    shows the version of gsresearch
* `gs` or `googlescholar`  
    Selects google scholar as target for querying
* `scopus` *(not yet supported)*  
    Selects Elsevier's Scopus as target for querying 

Qurery
------

Is represented a list of query terms, however, the semantics and keywords depend
on the used module. See ruby gsresearch.rb help MODULE for more information.

 
Disclaimer
---------- 
Please note that you should not use this script in jurisdictions,
where automated use of publication sites is prohibited (almost everywhere).
Please read Google's Terms of Service for more information.
  
Usage
-----
To show this documentation.
```bash
 ruby gsresearch.rb help 
```
To show the documentation of a MODULE.
```bash
 ruby gsresearch.rb help MODULE
```
To show the version number
```bash
ruby gsresearch.rb version
```


Google Scholar Module
=====================

This is a module for gsresearch for brute force harvesting of Google Scholar.

Synopsis
--------
```bash
 ruby gsresearch.rb [-v] (gs|googlescholar) QUERY
```

Query
-----

Is represented as a keyword followed by list of query terms.
The tool supports the following keywords:

Keyword       | Behavior
:------------:|---------------------------------------------------------
 help         | Shows this document
 with         | All following terms are required to be present within the result. (This keyword is assumed as default)
 any          | At least one following terms is required to be present within the result.
 without      | All following terms are prohibited to be present within the result.
 exact        | The following terms are concatenated to form a sentence which is required to present in its entirety.
 year [ from..to / from ] |  The following term is interpreted as either a range of from and to a year or as the exact year from which the publications will be selected. (Numbers must be positive integers)
 verbose      | Indicates that the output should be verbose. (All verbose output is directed to STDERR)
 version      | Shows the version of gsresearch

Please note that if the same keyword is present twice only the first one
will be evaluated.

Usage
-----
    
To grab publication containing all the terms: models, runtime, verification.
```bash
ruby gsresearch.rb gs models runtime verification
```
To grab publication containing all the terms: models, runtime, verification published in the years between 2010 and 2012.
```bash
ruby gsresearch.rb gs models runtime verification year 2010 2012
```
To grab publication containing the term: verification and none of the terms: hardware, teaching.
```bash
 ruby gsresearch.rb gs with verification without hardware teaching
```
grab publication containing all the terms: models, runtime, verification and give additional information to STDERR and the bibitems to STDOUT.
```bash
 ruby gsresearch.rb gs models runtime verification verbose 1> papers.bib 2> error.log
```

Limitiations
------------

 * Google Scholar limits the search results to at most 1000 (10 results per page and at most 100 Pages).
 * Currently only German, English and Italian Google Scholar (scholar.google.com) is supported
