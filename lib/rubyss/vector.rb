module RubySS
class Vector < DelegateClass(Array)
		attr_reader :type, :data, :valid_data, :missing_values, :missing_data
        # Creates a new 
        # data = Array of data
        # t = level of meausurement. Could be: 
        # [:nominal] : Nominal level of measurement
        # [:ordinal] : Ordinal level of measurement
        # [:scale]   : Scale level of meausurement
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
        def collect
            @data.collect{|x|
                yield x
            }
        end
        def each
            @data.each{|x|
                yield x
            }
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
        def size
            @data.size
        end
        def [](i)
            @data[i]
        end
        # Return true if a value is valid (not nil and not included on missing values)
        
        def is_valid?(x)
            !x.nil? and !@missing_values.include?x
        end
        # Set missing_values
		def missing_values=(vals)
			@missing_values = vals
			set_valid_data
		end
        # Set level of measurement. 
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
        def n; @data.size ; end
        def to_a
            @data
        end
        # Vector sum. 
        # - If v is a scalar, add this value to all elements
        # - If v is a Array or a Vector, should be of the same size of this vector
        #   every item of this vector will be added to the value of the
        #   item at the same position on the other vector
        def +(v)
            _vector_ari("+",v)
        end
        # Vector rest. 
        # - If v is a scalar, rest this value to all elements
        # - If v is a Array or a Vector, should be of the same 
        #   size of this vector
        #   every item of this vector will be rested to the value of the
        #   item at the same position on the other vector
        
        def -(v)
            _vector_ari("-",v)
        end
        
        def _vector_ari(method,v) # :nodoc:
            if(v.is_a? Vector or v.is_a? Array)
                if v.size==@data.size
                    i=0
                    sum=[]
                    0.upto(v.size-1) {|i|
                        if((v.is_a? Vector and v.is_valid?(v[i]) and is_valid?(@data[i])) or (v.is_a? Array and !v[i].nil? and !data[i].nil?))
                            sum.push(@data[i].send(method,v[i]))
                        else
                            sum.push(nil)
                        end
                    }
                    RubySS::Vector.new(sum)
                else
                    raise ArgumentError, "The array/vector parameter should be of the same size of the original vector"
                end
            elsif(v.respond_to? method )
                RubySS::Vector.new(
                    @data.collect  {|x|
                        if(is_valid?(x))
                        x.send(method,v)
                        else
                            nil
                        end
                    }
                )
            else
                raise TypeError,"You should pass a scalar or a array/vector"
            end
        end
        # Returns a hash of Vectors, defined by the different values
        # defined on the fields
        # Example:
        #
        # a=Vector.new(["a,b","c,d","a,b"])
        #  a.split_by_separator
        #    {"a"=>#<RubySS::Type::Nominal:0x7f2dbcc09d88 @data=[1, 0, 1]>,
        #     "b"=>#<RubySS::Type::Nominal:0x7f2dbcc09c48 @data=[1, 1, 0]>,
        #     "c"=>#<RubySS::Type::Nominal:0x7f2dbcc09b08 @data=[0, 1, 1]>}
        #
        def split_by_separator(sep=",")
            splitted=@data.collect{|x|
                if x.nil?
                    nil
                elsif (x.respond_to? :split)
                    x.split(",")
                else
                    [x]
                end
            }
            factors=splitted.flatten.uniq.compact
            out=factors.inject({}) {|a,x|
                a[x]=[]
                a
            }
            splitted.each{|r|
                if r.nil?
                    factors.each{|f|
                        out[f].push(nil)
                    }
                else
                factors.each{|f|
                    out[f].push(r.include?(f) ? 1:0) 
                }
                end
            }
            out.inject({}){|s,v|
                s[v[0]]=Vector.new(v[1],:nominal)
                s
            }
        end

    end
        
	module Type
		class Nominal
			def initialize(data)
				@data=data
			end
            # Returns an random sample, with replacement, of size n
            # In all the trails, every item have the same probability
            # of been selected
			def sample_with_replacement(n=1) 
				(0...n).collect{ @data[rand(@data.size)] }
			end
            # Returns a hash with the distribution of frecuencies of
            # the sample
			def frequencies
				@data.inject(Hash.new) {|a,x|
					a[x]=0 if a[x].nil?
					a[x]=a[x]+1
					a
				}
			end
            # Return an array of the different values of the data
			def factors
				@data.uniq
			end
            # Returns the most frequent item
			def mode
				frequencies.max{|a,b| a[1]<=>b[1]}[0]
			end
            # The numbers of item with valid data
            def n_valid
                @data.size
            end
            # Returns a hash with the distribution of proportions of
            # the sample
            def proportions
                frequencies.inject({}){|a,v|
                    a[v[0]] = v[1].to_f / n_valid
                    a
                }
            end
		end
        
		class Ordinal <Nominal
			# Return the value of the percentil q
            def percentil(q)
				sorted=@data.sort
				v= (n_valid.to_f * q / 100)
				if(v.to_i!=v)
					sorted[v.to_i]
				else
					(sorted[(v-0.5).to_i].to_f + sorted[(v+0.5).to_i]) / 2
				end
			end
            # Return the median (percentil 50)
			def median
				percentil(50)
			end
		end
		class Scale <Ordinal
            # The range of the data (max - min)
			def range; @data.max - @data.min; end
            # The sum of values for the data
            def sum
                @data.inject(0){|a,x|x+a} ; end
            # The arithmetical mean of data
            def mean
                sum.to_f/ n_valid
            end
            # Sum of squares
			def squares
                @data.inject(0){|a,x|x.square+a}
            end
            # Population variance (divided by n)
            def variance_population
                squares.to_f / n_valid - mean.square
            end
            # Population Standard deviation (divided by n)
            def standard_deviation_population
                Math::sqrt( variance_population )
            end
            # Sample Variance (divided by n-1)
            
			def variance_sample
				m=mean
				@data.inject(0){|a,x|a+(x-m).square} / (n_valid - 1)
			end
            # Sample Standard deviation (divided by n-1)
            
			def standard_deviation_sample
				Math::sqrt(variance_sample)
			end
            # Coefficient of variation
            # Calculed with the sample standard deviation
			def coefficient_of_variation
				standard_deviation_sample / mean
			end
            
			alias_method :sdp, :standard_deviation_population
			alias_method :sds, :standard_deviation_sample			
			alias_method :cov, :coefficient_of_variation
		end
	end
end