#!/bin/ruby
# encoding : utf-8

require 'rubygems'
require 'mechanize'

#Configuration
Scholar="http://scholar.google.com/"
Version="1.1"

Documentation=<<EOS
NAME
 gsresearch - is a tool for brute force harvesting of publication search sites.

SYNOPSIS
 ruby gsresearch.rb [-v] MODULE QUERY

DESCRIPTION
 gsresearch.rb is a tool for brute force harvesting of publication sites.
 It is designed to collect all the papers found for a given query
 and emit the bibtex reference found for each publication, 
 the citation count as well as a link to the publication.
 
DISCLAIMER
 Please note that you should not use this script in jurisdictions,
 where automated use of publication sites is prohibited (almost everywhere).
 Please read Google's Terms of Service for more information. 

MODULE
 Specify the website papers are retrieved:
 * help
   shows this document
 * version
   shows the version of gsresearch
 * gsresearch (Default)
   Selects google scholar as target for querying
 * scopus
   Selects Elsevier's Scopus as target for querying 

QUERY
 Is represented a list of query terms, however, the semantics and keywords depend
 on the used module. See ruby gsresearch.rb help MODULE for more information.

OPTIONS
 * -v
   indicates that the output should be verbose
   (All verbose output is directed to STDERR)
 
USAGE
 ruby gsresearch.rb help 
  - shows this document
 ruby gsresearch.rb help MODULE 
  - shows the help document of the given module.
 ruby gsresearch.rb version
  - shows this version

AUTHOR
 Thomas "Eden_06" Kuehn

VERSION
 #{Version}
EOS

class HelpCrawler

	def __doc__
	  Documentation
	end
	
	def prepare()
		
	end

	def query(query,&proc)
		if query.nil? or not query.respond_to?(:to_a)
			throw ArgumentError.new("query argument must not be nil and must respond to to_a()!")
		end
		if proc.nil? or not proc.respond_to?(:call)
			throw ArgumentError.new("query() must be called with a block, lambda or callable procedure!")
		end		
		@query=query.to_a
		command=@query.first
		if @query.empty? or not Modules.has_key?(command)
			puts Documentation
			exit(1)
		end
		crawler=Modules[command].call(Mechanize.new,false)
		puts crawler.__doc__
		exit(2)
	end

end

class DummyCrawler

	def __doc__
<<EOS
NAME
 test - is used for testing and consumes arbitrary non empty queries.

SYNOPSIS
 ruby gsresearch.rb [-v] test [QUERY]
EOS
	end

	def initialize(agent,verbose)
		@agent=agent
		@verbose=verbose
		@query=nil
	end

	def prepare()
		puts "Preparing Crawler" if @verbose
	end

	def query(query,&proc)
		if proc.nil? or not proc.respond_to?(:call)
			throw ArgumentError.new("query() must be called with a block, lambda or callable procedure!")
		end
		@query=if query.nil? or query.empty? then "nil" else query end
		puts("Querying for: %s"% [@query]) if @verbose 
		10.times do
			proc.call(nil,"[Warning]: This is just a dummy implementation!") 	
		end
	end

end

Modules=Hash.new

# define default modules for help and version
Modules["help"]=lambda do|agent,verbose|
	HelpCrawler.new
end
Modules["version"]=lambda do|agent,verbose|
	puts Version
	exit(1)
end
Modules["test"]=lambda do|agent,verbose|
	DummyCrawler.new(agent,verbose)
end


require_relative 'gsresearch-modules'

#start execution
verbose=false
query=ARGV.map{|e| e.to_s }
if query.first=="-v"
	verbose=true
	query.shift
end
if query.empty?
	command="help"
else
	command=query.shift
end
unless Modules.has_key?(command)
	$stderr.puts("ERROR: %s is not a valide MODULE!" %command)
	$stderr.puts(" Valid modules are:"+Modules.keys.join(", "))
	exit(1)
end

agent=Mechanize.new
begin
	crawler=Modules[command].call(agent,verbose)
	# prepare the crawler passing the query
	crawler.prepare()
	# perform the query iteratively returning the found bib items
	crawler.query(query) do|bib,error|
		puts(bib) unless bib.nil?
		$stderr.puts error if verbose and not error.nil?
	end
rescue => e
	$stderr.puts("ERROR: In module %s" %command)
	$stderr.puts("(Ruby Exception: %s)"%e.to_s)
ensure
	agent.shutdown()
end
exit(0)

__END__
