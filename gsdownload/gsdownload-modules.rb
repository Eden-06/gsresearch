# This file is included by the gsdownload and it specifies the methods to
# grab the pdf document from a given website.
# 
# The general Specification for a method consists of a regular expression
# applied to each url and a lambda expression returning a Mechanize::File 
# object or nil if no pdf file could be grabbed:
#  Module[ /.../ ] = lambda {|page| file=nil; ...  file }
# where page is either a Mechanize::File and Mechanize::Page object
# and the pattern is matched against the url.

Modules[ /.*[.]pdf$/ ] = lambda{|agent,page|
	r=nil
	r=page if page.class==Mechanize::File
	unless page.iframes.empty?
		l=page.iframes.first
		r=l.click unless l.nil?
	end
	r
}

# extension for IEEE
Modules[ /ieee\.org/ ] = lambda{|agent,page|
	r=nil
	link=nil
	pdfurl=page.body.match(/"pdfUrl":"([^"]+)"/)
	link="https://ieeexplore.ieee.org"+pdfurl[1] unless pdfurl.nil?
	l=page.link_with( :href => /ieee\.org/ )
	unless l.nil? and link.nil?
	 page=agent.get(link, [], l.referer)
	 l=page.iframe_with( :src => /ieee\.org/ )
	 r=l.click unless l.nil?
	end
	r
}

# extension for ACM
Modules[ /acm\.org/ ] = lambda{|agent,page|
	r=nil
	l=page.links.detect{|l| 
	not ((/fulltextpdf/i =~ l.attributes.attributes['name']).nil?)
	}
	r=l.click unless l.nil?
	r
}

# extension for Springer
Modules[ /springer\.com/ ] = lambda{|agent,page|
	r=nil
	l=page.links.detect{|l| 
	not ((/gtm-pdf-link/ =~ l.attributes.attributes['class']).nil?)
	}
	r=l.click unless l.nil?
	r
}

# extension for ScienceDirect
Modules[ /sciencedirect\.com/ ] = lambda{|agent,page|
	r=nil
	link=nil
	pdfurl=page.body.match(/"pdfUrlForCrawlers":"([^"]+)"/)
	link=pdfurl[1] unless pdfurl.nil?
	l=page.link_with( :href => /science/ )
	unless l.nil? or link.nil?
	 page=agent.get(link, [], l.referer)
 	 l=page.link_with( :href => /els-cdn\.com/ )
	 r=l.click unless l.nil?
	end
	r
}
