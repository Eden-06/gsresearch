#!/bin/ruby

require 'rubygems'
require 'mechanize'

# Configuration
Scholar="http://scholar.google.com/"
Confidence=0.50 #50 percent
Delay=(30..60) #seconds
Seperator="\t" #to delimit File Path from search query
Version="0.9.6"
Documentation=<<EOS
NAME
 getbibtex - allows the automatic retrival of bibtex items for a set of given file names

SYNOPSIS
 ruby gsbibtex.rb FILELIST [BIBFILE]

DESCRIPTION
 Getbibtex downloads and emits all bibtex entries for a set of given pdf
 files and search terms given as FILELIST. To limit the number of
 look ups, you can add your bibliography as bibtex file to the script.
 Thus, the script will only emit bib items for files which are not
 yet included in your bibliography.
 Internally, this script queries Google Scholar for bibtex entries.
 As a result, there is the possibility to get false positives for a 
 given title. To reduce their number, we compute the confidence for each
 return bibtex entry by comparing the title with the query string.
 You can adjust this value in the Configuration section of the 
 getbibtex.rb file.
DISCLAIMER 
 Please note that you should not use this script in jurisdictions,
 where automated use of google is prohibited (almost everywhere).
 Please read Google's Terms of Service for more information.

ARGUMENTS
  FILELIST
  The file list is a simple text file containing the list of pdf 
  documents for which a bibtex entry should be looked up.
  Each line of the file should contain the relative file path as well as
  the corresponding title (or search query) separated by a tab (\\t).
  You can create this list by executing the following command in your
  favorite shell (assuming that each pdf file is formated as 
  Author_Title.pdf):
    find . -name \"*.pdf\" -type f | 
         sed -E 's/(^.+[/](.*[ ])*(.*)[_](.*)[.]pdf)/\\1\t\\4/' 
             > titles.txt

  [BIBFILE]
  If you reference your current Bibtex file as optional argument,
  then the script will only look for those bib items, which are not 
  yet referenced in the given bibliography.
  Please note that we use the file attribute of the bib item to
  recognize already referenced files.

USAGE
 ruby getbibtex.rb
  - shows this document
 ruby getbibtex.rb titles.txt 1> bibliography.bib
  - generates the inital bibliography for all items referenced in titles
 ruby getbibtex.rb titles.txt bibliography.bib 1> newitems.bib
  - retreives only the new items not yet contained in the 
    bibliography.bib and stores them in newitems.bib

LIMITATIONS
  Due to the fact that [Mechanize](https://github.com/sparklemotion/mechanize)
  loads Files with ASCII-8Bit encoding all utf-8 characters are lost.

AUTHOR
 Thomas "Eden_06" Kuehn

VERSION
 %s
EOS

def prep(line)
 a=line.split(Seperator).map{|x| x.strip}
 return [nil,a[0].gsub("-"," ")] if a.size==1
 a[1].gsub!("-"," ")
 a
end

if ARGV.size<1
 puts Documentation % Version
 exit(1)
end

# start executions

searchrecords=[]
file=ARGV[0]
if (File.exists?(file))
 open(file,"r"){|f| 
  f.each_line{|r|
   l=prep(r)
   searchrecords << if l.size==2 then l else [nil,l[0]] end
  }
 }
else
 searchrecord=[nil,file.strip]
end

bibfile=nil
referencedfiles=[]
if ARGV.size>=2
  # retrieve referenced files
  bibfile=ARGV[1]
  if (File.exists?(bibfile))
    open(bibfile,"r") do|f| 
      f.each_line do|l|
        referencedfiles << $1.strip if /file.*=.*\{\:(.*)\:PDF\}/ =~ l        
      end
    end
  end
  searchrecords.reject!{|l| referencedfiles.include?(l[0]) }
  $stderr.puts "Database contains %d entries with referenced files" %referencedfiles.size
end



if searchrecords.empty?
 $stderr.puts "There were no new files in the database" % searchrecords.size
 exit(0)
else
 $stderr.puts "Prepearing search for the following %d entries..." % searchrecords.size
 searchrecords.each {|x| $stderr.puts x[0] }
end

#exit #force dry run

agent = Mechanize.new
#change google scholar settings
page = agent.get(Scholar)
page=page.link_with(:href => /scholar_settings/).click
$stderr.puts page.title
config_form = page.form_with(:action => '/scholar_setprefs')
config_form.radiobutton_with(:name => 'scis', :value => 'yes').check
page=agent.submit(config_form,config_form.button_with( :name=> 'save'))
$stderr.puts page.title

searchrecords.each do|r|
  filename,line=*r
  sleep(Delay.min+rand(Delay.max-Delay.min))
  $stderr.puts "query for %s" % line
  google_form = page.form('f')
  google_form.q = line
  page = agent.submit(google_form)
  link=page.link_with( :href => /scholar.bib/ )
  # Retrieve number of citations
  citation=page.link_with( :href => /scholar[?]cite/ )
  cites=if citation.nil? then 0 else citation.to_s.sub(/[^0-9]+/,"").to_i end
  # Retrieve bibtex entry
  result=if link.nil? then nil else link.click end
  unless result.nil?
   bib=result.body
   if m = /title[ ]*=[ ]*[{](.+)[}],/.match(bib) and m[1]
     #compare line and the title text to estimate a confidence level
     v=m[1].downcase
     a=(line.split(" ").map{|x| x.strip.downcase})
     i=a.map{|x| v.index(x) }.compact.size
     if (i.to_f/a.size < Confidence)
      $stderr.puts "Error:confidence to low with %f" % (i.to_f/a.size)
      $stderr.puts " "+line
      $stderr.puts " "+m[1]
     else
      bib.encode!('UTF-8',bib.encoding, {invalid: :replace, undef: :replace, replace: ' '} )
      unless filename.nil?
       bib.sub!(/\}[\n\r\t ]*\}/,"},\n  file = {:%s:PDF},\n  citations={%d} \n}"%[filename,cites]) 
      else
       bib.sub!(/\}[\n\r\t ]*\}/,"},\n  citations={%d} \n}"%[cites])
      end
      puts bib 
     end
   else
    $stderr.puts "no title found in bibtex"
    $stderr.puts bib
   end
  else
   $stderr.puts "no bibtex found for" % line
   $stderr.puts " "+line
  end
end
