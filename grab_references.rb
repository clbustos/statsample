#!/usr/bin/env ruby1.9
require 'reportbuilder'
refs=[]
Dir.glob "**/*.rb" do |f|
  next if f=~/pkg/
	reference=false
	File.open(f).each_line 	do |l|
		
		if l=~/== Reference/
		    reference=true
		elsif reference
			if l=~/\*\s+(.+)/
				refs.push $1
			else
				reference=false
			end
	        end
	    
	end
end


rb=ReportBuilder.new(:name=>"References") do |g|
	refs.uniq.sort.each do |r|
		g.text "* #{r}"
	end
end

rb.save_text("references.txt")