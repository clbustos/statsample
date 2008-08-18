#!/usr/bin/ruby
require 'delegate'
class Numeric
  def square ; self * self ; end
end

module RubySS
	VERSION = '0.1.2'
	class Vector < DelegateClass(Array)
		attr_reader :type, :data, :valid_data, :missing_values, :missing_data
		def initialize(data=[],t=:nominal)
			@data=data
			@valid_data=[]
			@missing_values=[]
			@missing_data=[]
			@labels={}
			set_valid_data
			self.type=t
			super(@delegate)
		end
		def set_valid_data
			@valid_data.clear
			@missing_data.clear
			@data.each do |n|
				if n.nil? or @missing_values.include? n
					@missing_data.push(n)
				else
					@valid_data.push(n)
				end
			end
		end
		def missing_values=(vals)
			@missing_values = vals
			set_valid_data
		end
		def type=(t)
			case t
			when :nominal
				@delegate=Type::Nominal.new(@valid_data)
			when :ordinal
				@delegate=Type::Ordinal.new(@valid_data)
			when :scale
				@delegate=Type::Scale.new(@valid_data)
			else
				raise "Type doesn't exists"
			end
			__setobj__(@delegate)
			@type=t			
		end
	end
	module Type
		class Nominal
			def initialize(data)
				@data=data
			end
			def [](i)
				@data[i]
			end
			def sample_with_replacement(n=1) 
				(0...n).collect{ @data[rand(@data.size)] }
			end
			def frequencies
				@data.inject(Hash.new) {|a,x|
					a[x]=0 if a[x].nil?
					a[x]=a[x]+1
					a
				}
			end
			def factors
				@data.uniq
			end
			def mode
				frequencies.max{|a,b| a[1]<=>b[1]}[0]
			end
			def n; @data.size ; end
		end
		class Ordinal <Nominal
			def percentil(q)
				sorted=@data.sort
				v= (n.to_f * q / 100)
				if(v.to_i!=v)
					sorted[v.to_i]
				else
					(sorted[(v-0.5).to_i].to_f + sorted[(v+0.5).to_i]) / 2
				end
			end
			def median
				percentil(50)
			end
		end
		class Scale <Ordinal
			def range; @data.max - @data.min; end
			def sum ; @data.inject(0){|a,x|x+a} ; end
			def mean ; sum.to_f/ n ; end
			def squares ; @data.inject(0){|a,x|x.square+a} ; end
			def variance_poblation ; squares.to_f / n - mean.square; end
			def standard_deviation_poblation ; Math::sqrt( variance_poblation ) ; end
			def variance_sample
				m=mean
				@data.inject(0){|a,x|a+(x-m).square} / (n - 1)
			end
			def standard_deviation_sample
				Math::sqrt(variance_sample)
			end
			def coefficient_of_variation
				standard_deviation_sample / mean
			end
			alias_method :sdp, :standard_deviation_poblation
			alias_method :sds, :standard_deviation_sample			
			alias_method :cov, :coefficient_of_variation
		end
	end
end


