#! /bin/ruby
# encoding: utf-8

require 'rubygems'
require 'mechanize'

# Configuration
Delay=(30..60) # seconds
Version="0.9"
Documentation=<<EOS
NAME
 gsdownload - allows to download the pdf document referenced in a given bibtex file

SYNOPSIS
 ruby gsdownload.rb [OPTIONS] [FILE]+
 ruby gsdownload.rb -h
 ruby gsdownload.rb -V

DESCRIPTION
 Downloads all referenced pdf documents in a given bibtex file and 
 producess an annotated bibtex file via STDOUT. This program uses the 
 howpublished links in each bibtex entry which must be of the form:
   howpublished = {\\url{LINK}}
 The tool not only downloads the pdf documents, but also emits
 modified bibtex entries containing an additional reference to the file
 if it could be accessed.

 Please note, this program currently only grab pdf's from ieee.org, 
 acm.org, springer.com and sciencedirect.com. In order to extend this 
 program to support new sites, you may edit the gsdownload-modules.rb.

OPTIONS
 -v    produces verbose output.
 -V    Shows the version number.
 -h    Show this document.
 -dDIRECTORY
       All files are downloaded to the given directory.
 -tDIRECTORY
       All file references created within a bibtex file assume
       that the file is located in this directory.
USAGE
 ruby gsdownload.rb -h
  - shows this document
 ruby gsdownload.rb -V
  - shows the version number
 ruby gsdownload.rb paper.bib 1> withfiles.bib
  - try to download every pdf document referenced in paper.bib 
    in the current directory and save the resulting annotaded bibtex 
    entries into the withfiles.bib file

AUTHOR
 Thomas "Eden_06" Kuehn

VERSION
 %s
EOS

# load extensions

Modules = Hash.new

require './gsdownload-modules'

# Try's to grab the PDF document from the given url
# and stores it into a file with the given filename
# using the given useragent.
# Note: This method is only able to grab pdfs from ieee.org, acm.org, 
# springer.com and sciencedirect.com.
# Params:
# * agent    the Mechanize::Agent instance
# * url      the url to the referenced document
# * filename the filename to store the found pdf document
# Return:
#  true only if the file could be grabbed and downloaded else false
def saveto(agent,url,filename)
  page = nil
  file = nil
  k=Modules.keys.detect{|k| k =~ url}
  unless k.nil?
   begin
    page = agent.get(url)
   rescue Mechanize::ResponseCodeError => e
    page = nil
    $stderr.puts "ERROR: HTML Request failed with %s on %s"%[e.to_s,url]
   end
   file=Modules[k].call(page) unless page.nil?
  end
  return true if (not file.nil?) and file.class==Mechanize::File and file.save!(filename)
  false
end


# begin of execution
files=[]
downloaddir="."
targetdir="."
verbose=false
key=""
ARGV.each do|x| 
 case x
  when /^-[hV]$/
   key=$~.to_s
  when /^-v$/
   verbose=true
  when /^-d(.*)/ # TODO: check what happens if we pass a path containing whitespace character
   downloaddir=$1.to_s
  when /^-t(.*)/
   targetdir=$1.to_s
  else
   files << x
 end
end

if key=="-V"
 puts Version
 puts "Extensions for:"
 puts Modules.keys.map{|x| x.source }
 exit(1)
end

if files.empty? or key=="-h"
 puts Documentation % Version
 exit(1)
end

files.each do|file|
  unless File.exists?(file)
   $stderr.puts "The selected file %s did not exist." % file
   exit(2)
  end
end

bibitems=[]
files.each do|file|
  open(file,"r") do|f|
   f.each_line do|line|
    bibitems << []  if /^@.*/ =~ line
    bibitems.last << line.strip unless bibitems.last.nil?
   end
  end
end

$stderr.puts "found %d bibitems"%bibitems.size if verbose

i=0
hits=0

bibitems.each_with_index.map do|bib,i|
  url =if (bib.find{|l| /howpublished.*=.*\{\\url\{(.+)\}\}/ =~ l }).nil? then nil else $1.to_s end
  year=if (bib.find{|l| /year.*=.*\{([0-9]+)\}/ =~ l }).nil? then nil else $1.to_s end
  unless year.nil? or url.nil?
    $stderr.puts "Loading: %s"%url if verbose
    filename="%s_%d.pdf"%[year,i+=1]
    Mechanize.new do|agent|
      agent.keep_alive=false
      agent.history.max_size=1
		  if saveto(agent,url,File.join(downloaddir,filename))
		    p=bib.index{|x| x.strip=="}"}
		    bib[p-1]+=",\nfile={:%s:PDF}"%File.join(targetdir,filename) unless i.nil?
				hits+=1
		  else
		    $stderr.puts "ERROR: Could not load pdf" if verbose        
		  end
      sleep(Delay.min+rand(Delay.max-Delay.min))
    end    
  end
  bib
end.each{|bib| puts bib }

$stderr.puts "%d of %d pdf documents successfully loaded" % [hits,bibitems.size] if verbose
exit(0)


