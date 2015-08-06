#!/bin/ruby
# encoding : utf-8

require 'rubygems'
require 'mechanize'

#Configuration
Scholar="http://scholar.google.com/"
Delay=(30..60) # seconds
Version="0.9"

Documentation=<<EOS
NAME
 gsresearch -  is a tool for brute force harvesting of Google Scholar.

SYNOPSIS
 ruby gsresearch.rb [EXPRESSION]

DESCRIPTION
 gsresearch.rb is a tool for brute force harvesting of Google Scholar.
 It is designed to collect all the papers found for a given expression
 and emit the bibtex reference found for each publication, 
 the citation count as well as a link to the publication.

EXPRESSION
 Is represented as a keyword followed by list of query terms.
 The tool supports the following keywords:
 * help
   shows this document
 * with
   all following terms are required to be present within the result
   (This keyword is assumed as default)
 * any
   at least one following terms is required to be present within the result
 * without
   all following terms are prohibited to be present within the result
 * exact
   the following terms are concatenated to form a sentence which is required
   to present in its entirety 
 * year [ from..to | from ]
   the following term is interpreted as either a range of from and to a year or
   as the exact year from which the publications will be selected
   (Numbers must be positive integers)
 * verbose
   indicates that the output should be verbose
   (All verbose output is directed to STDERR)
 * version
   shows the version of gsresearch

 Please note, that if the same keyword is present twice only the first one
 will be evaluated. 
  
USAGE
 ruby gsresearch.rb help 
  - shows this document
 ruby gsresearch.rb version
  - shows this version
 ruby gsresearch.rb models runtime verification
  - grab publication containing all the terms: models, runtime, verification
 ruby gsresearch.rb models runtime verification year 2010 2012
  - grab publication containing all the terms: models, runtime, verification
    published in the years between 2010 and 2012
 ruby gsresearch.rb with verification without hardware teaching
  - grab publication containing the term: verification
    and none of the terms: hardware, teaching
 ruby gsresearch.rb models runtime verification verbose
  - grab publication containing all the terms: models, runtime, verification
    and give additional information to STDOUT

ISSUES
 * Google Scholar limits the search results to at most 1000
   (10 results per page and at most 100 Pages).
 * Currently only German Google Scholar (scholar.google.com) 
   is supported

AUTHOR
 Thomas "Eden_06" Kuehn

VERSION
 #{Version}
EOS

commands=["help","version","with","any","without","exact","year","verbose"]

#method definitions

def filter(l)
 url=l.first
 bib=l.find{|x| /scholar.bib/ =~ x.attributes[:href] }
 c=l.find{|x| /scholar[?]cite/ =~ x.attributes[:href] }
 cites=if c.nil? then 0 else c.to_s.sub(/[^0-9]+/,"").to_i end
 begin
  [bib,cites,url.uri.to_s,url.to_s] 
 rescue # if the URI.parse(url) failed use the href attribute
  [bib,cites,url.href,url.to_s] 
 end 
end

def make_range(low,high)
  lo=low.to_i
  hi=high.to_i
  if lo==0 then   
    if hi==0 then [] else [hi,hi] end
  else
    if hi==0 then [lo,lo] else 
     lo,hi=hi,lo if hi < lo    
     [lo,hi]
    end
  end
end


# start of execution

query=ARGV.inject([]) do|s,e|
 s << ["with"] if s.empty? and commands.index(e).nil? 
 s << []       unless commands.index(e).nil?
 s.last << e
 s
end

## catch help and version keyword
if query.empty? or (not query.assoc("help").nil?)
 puts Documentation
 exit(1)
end

if query.empty? or (not query.assoc("version").nil?)
 puts Version
 exit(1)
end

## automatically extract values
c=Hash.new
commands.each do|x|
 r=query.assoc(x)
 c[x]=if r.nil? or r.size==1 then [] else r[1..-1] end
end

## customize
c["year"]=if c["year"].nil? or c["year"].empty?
            []
          else
            lo,hi=c["year"][0].split("..").map{|x| x.to_i}
            hi=lo if hi.nil?
            make_range(lo,hi)
          end  

verbose=!(c["verbose"].nil?)

#begin of the search specific part

agent = Mechanize.new
## Start interacting with Google Scholar
begin
 page = agent.get(Scholar)
rescue => e
 $stderr.puts "ERROR: Could not access %s" % Scholar
 $stderr.puts "(Ruby Exception: %s)"       % e.to_s
 exit(2)
end

## change google scholar settings
page=page.link_with(:href => /scholar_settings/).click
config_form = page.form_with(:action => '/scholar_setprefs')
config_form.radiobutton_with(:name => 'scis', :value => 'yes').check
$stderr.puts "[%s] Configuration"%page.title if verbose
page=agent.submit(config_form,config_form.button_with( :name=> 'save'))

## query google scholar for search string
sleep(Delay.min+rand(Delay.max-Delay.min))
google_form = page.form_with( :id => "gs_hdr_frm_adv")
google_form.as_q = c["with"].join(" ") unless c["with"].nil? or c["with"].empty?
google_form.as_epq = c["exact"].join(" ") unless c["exact"].nil? or c["exact"].empty?
google_form.as_oq = c["any"].join(" ") unless c["any"].nil? or c["any"].empty?
google_form.as_eq  = c["without"].join(" ") unless c["without"].nil? or c["without"].empty?
unless c["year"].nil? or c["year"].empty?
 google_form.as_ylo = c["year"][0]
 google_form.as_yhi = c["year"][1]
end

if verbose
	$stderr.puts "querying for:"
  commands.each do|com|
   $stderr.puts " %s: %s" % [com,c[com].join(" ")] unless c[com].nil? or c[com].empty? or com=="verbose"
  end
end
page = agent.submit(google_form)

id=1
loop do

  nextlink=page.links_with( :href => /scholar[?]start/ ).find{|l| /[Aa]vanti|[Nn]ext|[Ww]eiter/ =~ l.to_s }
 
  #collect and split all links and filter url, citationcount, and biblink
  headings=page.search("//h3/a/@href").map{|x| x.to_s}
  result=page.links.inject([]) do|s,l|
          # splitt list of links in accordance to the headings
          s << [] unless headings.index(l.attributes[:href]).nil? or /\[PDF\]/ =~ l.to_s
          # Drop all links before the first heading
          s.last << l unless s.last.nil? 
          s
         end.map{|l| filter(l) }

  $stderr.puts "found %d items" % result.size if verbose

  result.each do|link,cites,url,name|
    sleep(Delay.min+rand(Delay.max-Delay.min))
    result=if link.nil? then nil else link.click end
    unless result.nil?
      bib=String.new(result.body)
      # Set the character encoding to utf-8 and hope for google scholar to comply
      bib.encode!('UTF-8',bib.encoding, {invalid: :replace, undef: :replace, replace: ' '} )
      bib.sub!(/\}[\n\r\t ]+\}/,
               "},\n  howpublished = {\\url{%s}},\n  citations={%d} \n}"%
                [url,cites])
      puts bib 
    else
      $stderr.puts "[ERROR] Could not grab : %s (%s)" % [name,url] if verbose  
    end
  end
  break if nextlink.nil?
  sleep(Delay.min+rand(Delay.max-Delay.min))
  id+=1
  $stderr.puts "next page: %d (%s)" % [id,nextlink.uri.to_s] if verbose
  page=nextlink.click

end

agent.shutdown()
exit(0)

