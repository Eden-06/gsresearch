#!/bin/ruby
# encoding : utf-8

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

	#called before querying to set up a connection to the publication site
	def prepare()
		puts "Preparing Crawler" if @verbose
	end

	#called after prepare and acutally queries the publication site and calls proc
	#for each found publication providing the bibtex string and/or an error
	#message.
	def query(query,&proc)
		if proc.nil? or not proc.respond_to?(:call)
			throw ArgumentError.new("query() must be called with a block, lambda or callable procedure!")
		end
		@query=if query.nil? or query.empty? then "nil" else query end
		puts("Querying for: %s"% [@query]) if @verbose 
		10.times do
			proc.call(nil,"[Warning]: This is just a dummy implementation!") 	
		end
		nil
	end

end

# register module
Modules["test"]=lambda do|agent,verbose|
	DummyCrawler.new(agent,verbose)
end

