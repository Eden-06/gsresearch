#!/bin/ruby
# encoding : utf-8

GSDisclaimer=<<EOS
+-------------------------Disclaimer------------------------------+
|Please note that you should not use this script in jurisdictions,|
|where automated use of Google is prohibited (almost everywhere). |
|Please read Google's Terms of Service for more information.      |
+-------------------------Disclaimer------------------------------+
EOS

#Pattern to identify the next link in a google scholar page 
GSLanguages=/avanti|next|weiter|volgende/i
Delay=(30..60) # seconds

class GSCrawler

	def __doc__
<<EOS
NAME
 googlescholar - is a module for gsresearch for brute force harvesting of Google Scholar.

SYNOPSIS
 ruby gsresearch.rb [-v] (gs|googlescholar) QUERY
 
DISCLAIMER
 Please note that you should not use this script in jurisdictions,
 where automated use of Google is prohibited (almost everywhere).
 Please read Google's Terms of Service for more information. 

QUERY
 Is represented as a keyword followed by list of query terms.
 The tool supports the following keywords:
 * with
   all following terms are required to be present within the result
   (This keyword is assumed as default)
 * any
   at least one of the following terms must be present within the result
 * without
   all following terms are prohibited to be present within the result
 * exact
   the following terms are concatenated to form a sentence which is required
   to present in its entirety 
 * year [ from..to | from ]
   the following term is interpreted as either a range of from and to a year or
   as the exact year from which the publications will be selected
   (Numbers must be positive integers)
 Please note, that if the same keyword is present twice only the first one
 will be evaluated. 

USAGE
  ruby gsresearch.rb gs models runtime verification
  - grab publication containing all the terms: models, runtime, verification
 ruby gsresearch.rb gs models runtime verification year 2010 2012
  - grab publication containing all the terms: models, runtime, verification
    published in the years between 2010 and 2012
 ruby gsresearch.rb gs with verification without hardware teaching
  - grab publication containing the term: verification
    and none of the terms: hardware, teaching
 ruby gsresearch.rb gs models runtime verification verbose
  - grab publication containing all the terms: models, runtime, verification
    and give additional information to STDOUT
    
ISSUES
 * Google Scholar (gs module) limits the search results to at most 1000
   (10 results per page and at most 100 Pages).
 * Currently only German, English, and Italian Google Scholar is supported
EOS
	end

	def initialize(agent,verbose)
		throw ArgumentError.new("The agent argument must not be nil") if agent.nil?
		@agent=agent
		@verbose=verbose
		@query=nil
		@googlescholar="https://scholar.google.com/"
		@commands=["with","any","without","exact","year"]
		@page=nil
		@query=nil
	end
	
	def prepare()
		## show disclamer
		$stderr.puts GSDisclaimer
		begin
			@page = @agent.get(@googlescholar)
		rescue => e
			$stderr.puts("ERROR: Could not access %s" % @googlescholar)
			$stderr.puts("(Ruby Exception: %s)"       % e.to_s)
			exit(2)
		end
		## change google scholar settings
		@page=@page.link_with(:href => /scholar_settings/).click
		config_form = @page.form_with(:action => '/scholar_setprefs')
		config_form.radiobutton_with(:name => 'scis', :value => 'yes').check
		$stderr.puts("[%s] Configuration " % @page.title) if @verbose
		@page=@agent.submit(config_form,config_form.button_with( :name=> 'save'))
		#Delay next action
		sleep(Delay.min+rand(Delay.max-Delay.min))
	end
	
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
		return []      if lo==0 and hi==0
		return [hi,hi] if lo==0 and hi>0
		return [lo,lo] if lo>0 and hi==0
		#assumes lo!=0 and hi!=0
		lo,hi=hi,lo    if hi < lo
		return [lo,hi] 
	end
	
	def prepare_query(query)
	  q=query.inject([]) do|s,e|
			s << ["with"] if s.empty? and @commands.index(e).nil? 
			s << []       unless @commands.index(e).nil?
			s.last << e
			s
		end
		## automatically extract values
		result=Hash.new
		@commands.each do|x|
			r=q.assoc(x)
			result[x]=if r.nil? or r.size==1 then [] else r[1..-1] end
		end
		## customize
		result["year"]=if result["year"].nil? or result["year"].empty?
								[]
							else
								lo,hi=result["year"][0].split("..").map{|x| x.to_i}
								hi=lo if hi.nil?
								make_range(lo,hi)
							end
		result
	end
	
	#collect and split all links and filter url, citationcount, and biblink
	#
	#returns a list of publication entries ([link, citationcount, url, name])
	def collect_entries(page)
		headings=page.search("//h3/a/@href").map{|x| x.to_s}
		entries=page.links.inject([]) do|s,l|
			# splitt list of links in accordance to the headings
			s << [] unless headings.index(l.attributes[:href]).nil? or /\[PDF\]/ =~ l.to_s
			# Drop all links before the first heading
			s.last << l unless s.last.nil? 
			s
		end.map{|l| filter(l) }
		entries
	end
	
	#Find and Execute the advanced query of google scholar
	#
	#returns the result page or nil if no form could be found
	def advanced_query(agent,page,query)
		google_form = page.form_with( :id => "gs_asd_frm") # gs_asd_frm
		return nil if google_form.nil?
		google_form.as_q = query["with"].join(" ") unless query["with"].nil? or query["with"].empty?
		google_form.as_epq = query["exact"].join(" ") unless query["exact"].nil? or query["exact"].empty?
		google_form.as_oq = query["any"].join(" ") unless query["any"].nil? or query["any"].empty?
		google_form.as_eq  = query["without"].join(" ") unless query["without"].nil? or query["without"].empty?
		unless query["year"].nil? or query["year"].empty?
			google_form.as_ylo = query["year"][0]
			google_form.as_yhi = query["year"][1]
		end
		agent.submit(google_form)	
	end	
	
	#Executes the query and calls the given block
	def query(query,&proc)
		if query.nil? or not query.respond_to?(:to_a) or query.to_a.empty?
			throw ArgumentError.new("query argument must not be nil and must respond to to_a()!")
		end
		if proc.nil? or not proc.respond_to?(:call)
			throw ArgumentError.new("query() must be called with a block, lambda or callable procedure!")
		end
		
		#prepare the given query extracting with, any, exact, and year queries
		@query=prepare_query(query.to_a)
		if @verbose
			$stderr.puts "querying for:"
			$stderr.puts (@commands.reject{|c|@query[c].nil? or @query[c].empty?})
			                       .map{|c|" #{c}: #{@query[c].join(' ')}"}
		end
		if @page.nil?
			$stderr.puts "Google scholar could not be found!"
			return nil
		end

		#prepare advanced query and submit it
		@page=advanced_query(@agent,@page,@query)
		if (@verbose and @page.nil?)
			$stderr.puts "Google form could not be found!"
			return nil
		end

		id=1
		loop do
			nextlink=@page.links_with( :href => /scholar[?]start/ ).find{|l| GSLanguages =~ l.to_s }

			entries=collect_entries(@page)			
			$stderr.puts "found %d items on page %d" % [entries.size,id] if @verbose
			
			#iterate through found entries
			entries.each do|link,cites,url,name|
				sleep(Delay.min+rand(Delay.max-Delay.min))
				
				result=if link.nil? then nil else link.click end
				bib,error=[nil,nil]
				unless result.nil?
					bib=String.new(result.body)
					# Set the character encoding to utf-8 and hope for google scholar to comply
					bib.encode!('UTF-8',bib.encoding, {invalid: :replace, undef: :replace, replace: ' '} )
					bib.sub!(/\}[\n\r\t ]+\}/,
									"},\n  howpublished = {\\url{%s}},\n  citations={%d} \n}"%
									[url,cites])
				else
					error="[ERROR] Could not grab : %s (%s)"%[name,url]
				end
				proc.call(bib,error)
			end
			break if nextlink.nil?

			id+=1
			#$stderr.puts "next page: %d (%s)" % [id,nextlink.uri.to_s] if @verbose
			@page=nextlink.click			
		end
		@page
	end
	
end

#register module
Modules["gs"]=lambda do|agent,verbose|
	GSCrawler.new(agent,verbose)
end
Modules["googlescholar"]=lambda do|agent,verbose|
	GSCrawler.new(agent,verbose)
end
