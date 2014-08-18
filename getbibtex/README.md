getbibtex
=========
 Is a commandline tool which allows the automatic retrival of bibtex
 items for a set of pdf files
Systemrequirements
==================

* Ruby Version 1.9.3 (or higher) [\[get here\]](https://www.ruby-lang.org/de/downloads/)

Synopsis
--------
```bash
ruby gsbibtex.rb FILELIST \[BIBFILE\]
´´´

Description
-----------

Getbibtex downloads and emits all bibtex entries for a set of given pdf
files and search terms given as FILELIST. To limit the number of
look ups, you can add your bibliography as bibtex file to the script.
Thus, the script will only emit bib items for files which are not
yet included in your bibliography.

Internally, this script queries Google Scholar for bibtex entries.
As a result, there is the possibility to get false positives for a 
given title. To reduce their number, we compute the confidence for each
return bibtex entry by comparing the title with the query string.
You can adjust this value in the Configuraiton section of the 
getbibtex.rb file.

Disclaimer
---------- 
Please note that you should not use this script in jurisdictions,
where automated use of google is prohibited (almost everywhere).
Please read Google's Terms of Service for more information.

Arguments
---------

* **FILELIST**  
		The file list is a simple text file containing the list of pdf 
		documents for which a bibtex entry should be looked up.
		Each line of the file should contain the relative file path as well as
		the corresponding title (or search query) separated by a colon (:).
		You can create this list by executing the following command in your
		favorite shell (assuming that each pdf file is formated as 
		Author_Title.pdf):
    ```bash
    find . -name \"*.pdf\" -type f | sed -E 's/(^.+[/](.*[ ])*(.*)[_](.*)[.]pdf)/\\1:\\4/' > titles.txt
    ´´´

*  **\[BIBFILE\]**  
		If you reference your current Bibtex file as optional argument,
		then the script will only look for those bib items, which are not 
		yet referenced in the given bibliography.
		Please note that we use the file attribute of the bib item to
		recognize already referenced files.

Usage
-----
To show this documentation just enter.
```bash
ruby getbibtex.rb
´´´
To generate an inital **bibliography.bib** for all items referenced in the **titles.txt** file
```bash
ruby getbibtex.rb titles.txt > bibliography.bib
´´´
To retreive only the new items not yet contained in the 
    **bibliography.bib** and stores them in **newitems.bib**
```bash
 ruby getbibtex.rb titles.txt bibliography.bib > newitems.bib
´´´

Limitations
-----------

Due to the fact that [Mechanize](https://github.com/sparklemotion/mechanize)
loads Files with ASCII-8Bit encoding all utf-8 characters are lost.
