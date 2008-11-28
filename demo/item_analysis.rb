#!/usr/bin/ruby
require File.dirname(__FILE__)+'/../lib/rubyss'
	n = 300
	k = 5
	error = 20
	a=[]
	(0...n).each{|i|
		habilidad=rand(100)
		a.push((0..k).collect{|i|
				habilidad_med=habilidad+(error/2.0)-rand(error)
				(habilidad_med>i) ? 1 : 0
		}
		)
	}
	vectors={}
	(0..k).each{|var|
		vectors['v'+var.to_s]=(0...n).to_a.collect{|i|
			a[i][var]
		}.to_vector(:scale)
	}
	a= RubySS::Reliability::ItemAnalysis.new(vectors.to_dataset)
	File.open("test.html","w") {|fp|
	fp.puts a.html_summary
	}
