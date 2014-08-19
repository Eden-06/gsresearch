gsresearch
==========

Is a proof of concept tool belt that automatically grabs bibtex entries from Google Scholar
and filters them according with respect to publishers and citation count.

System requirements
------------------

* Ruby Version 1.9.3 (or higher) [\[get here\]](https://www.ruby-lang.org/de/downloads/)
* Mechanize Version 2.7.1 (or higher) [\[get here\]](https://github.com/sparklemotion/mechanize)
* bibfilter Version 0.9 (or higher) [\[get here\]](https://github.com/Eden-06/bibfilter)

Installation
------------

1. Create a gsresearch folder you use as a base for your projects
2. Clone the [bibfilter repository](https://github.com/Eden-06/bibfilter) to that folder
3. Clone this repository to that folder, as well
4. Copy the various scripts depending on your use into the desired folder

Tool Belt
---------

Tool       | Purpose
:---------:|------------------------------------------------------------
getbibtex  | fetches Bibtex entries for the currently stored publications [(more)](https://github.com/Eden-06/gsresearch/tree/master/getbibtex) 
gsresearch | querys Google Scholar for all entries and fetches their bibtex entries [(more)](https://github.com/Eden-06/gsresearch/tree/master/gsresearch) 
gsdownload | downloads all the referenced files in a bibtex files from the respective publishers [(more)](https://github.com/Eden-06/gsresearch/tree/master/gsdownload) 
workflow   | contains a bunch of shell scripts, which perform a semi-automatic survey by employing gsresearch, bibfilter, and gsdownload  [(more)](https://github.com/Eden-06/gsresearch/tree/master/workflow) 

Disclaimer
---------- 
Please note that you should not use this script in jurisdictions,
where automated use of Google is prohibited (almost everywhere).
Please read Google's Terms of Service for more information.

Usage
-----

In general there are two basic usage scenarios:

1. Use **getbibtex** to start managing all the stored publications in a
	folder and iteratively update your bibliography when ever new publications arrive.
	[(Read more)](https://github.com/Eden-06/gsresearch/tree/master/getbibtex) 
2. Use the scripts found in the workflow together with **gsresearch**, **bibfilter** and **gsdownload**
	to conduct a semi-automatic survey based on a search query, filter them and download the relevant publications as pdf.
	[(Read more)](https://github.com/Eden-06/gsresearch/tree/master/workflow) 
	 

Limitations
-----------

* Currently, the scripts are limited to using Google Scholar alas it would be beneficial to use other research gateways.
* All tools are closely coupled with Mechanize, this should be factored out for better modularity.
* Mechanizes file download some how does not support utf-8 character encoding (hopefully this issue might be fixed soon).
* You cannot overcome paywalls and legal restraints!
