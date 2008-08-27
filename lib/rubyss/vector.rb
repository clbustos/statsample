class Array
	def to_vector(*args)
		RubySS::Vector.new(self,*args)
	end
end

module RubySS
    # Create a matrix using vectors as columns
    # Use:
    #
    # matrix=RubySS.vector_cols_matrix(v1,v2)
	def self.vector_cols_matrix(*vs)
		# test
		size=vs[0].size
		vs.each{|v|
			raise ArgumentError,"Arguments should be Vector" unless v.instance_of? RubySS::Vector
			raise ArgumentError,"Vectors size should be the same" if v.size!=size
		}
		Matrix.rows((0...size).to_a.collect() {|i|
			vs.collect{|v| v[i]}
		})
	end
class Vector < DelegateClass(Array)
	
    include Enumerable
        attr_reader :type, :data, :valid_data, :missing_values, :missing_data
        attr_accessor :labels, :population_size
        # Creates a new 
        # data = Array of data
        # t = level of meausurement. Could be: 
        # [:nominal] : Nominal level of measurement
        # [:ordinal] : Ordinal level of measurement
        # [:scale]   : Scale level of meausurement
        #
		def initialize(data=[],t=:nominal,missing_values=[],labels={},population_size=nil)
			@data=data
			@missing_values=missing_values
			@labels=labels
            @population_size=(population_size.nil? or population_size<@data.size) ? @data.size : population_size.to_i

			@valid_data=[]
			@missing_data=[]
			set_valid_data
			self.type=t
			super(@delegate)
		end
        # Vector equality
        # Two vector will be the same if their data, missing values, type, labels and population_size are equals
        def ==(v2)
            @data==v2.data and @missing_values==v2.missing_values and @type==v2.type and @labels=v2.labels and @population_size=v2.population_size
        end
        def _dump(i)
            Marshal.dump({'data'=>@data,'missing_values'=>@missing_values, 'labels'=>@labels, 'population_size'=>@population_size, 'type'=>@type})
        end
        def self._load(data)
            h=Marshal.load(data)
            Vector.new(h['data'], h['type'], h['missing_values'], h['labels'], h['population_size'])
        end
        def recode
            @data.collect!{|x|
                yield x
            }
            set_valid_data
        end
        def each
            @data.each{|x|
                yield x
            }
        end
        def add(v,update_valid=true)
            @data.push(v)
            set_valid_data if update_valid
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
        # Returns a Vector with the data with labels replaced by the label
        def vector_labeled
            d=@data.collect{|x|
                if @labels.has_key? x
                    @labels[x]
                else
                    x
                end
            }
            Vector.new(d,@type)
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
				@delegate=Nominal.new(@valid_data)
			when :ordinal
				@delegate=Ordinal.new(@valid_data)
			when :scale
				@delegate=Scale.new(@valid_data)
			else
				raise "Type doesn't exists"
			end
			__setobj__(@delegate)
			@type=t			
		end
        def n; @data.size ; end
        def to_a
            @data.dup
        end
        alias_method :to_ary, :to_a 
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
        
        # Returns an random sample of size n, with replacement,
        # only with valid data.
        #
        # In all the trails, every item have the same probability
        # of been selected
		def sample_with_replacement(sample=1)
            Vector.new( (0...sample).collect{ @valid_data[rand(@valid_data.size)] },@type)
        end
        # Returns an random sample of size n, without replacement,
        # only with valid data.
        #
        # Every element could only be selected once
        # A sample of the same size of the vector is the vector itself
            
        def sample_without_replacement(sample=1)
                raise ArgumentError, "Sample size couldn't be greater than n" if sample>@valid_data.size
                out=[]
                while out.size<sample
                    value=rand(@valid_data.size)
                    out.push(value) if !out.include?value
                end
                Vector.new(out.collect{|i|@valid_data[i]},@type)
         end
         
            def count(x=false)
                if block_given?
                    r=@data.inject(0) {|s, i|
                        r=yield i
                        s+(r ? 1 : 0)
                    }
                    r.nil? ? 0 : r
                else
                    frequencies[x].nil? ? 0 : frequencies[x]
                end
            end
            def to_s
                sprintf("Vector(type:%s, n:%d, N:%d)[%s]",@type.to_s,@data.size, @population_size,@data.join(","))
            end

    end
        
	
		class Nominal
			def initialize(data)
				@data=data
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
            def summary(out="")
                out << sprintf("n valid:%d\n",n_valid)
                out <<  sprintf("factors:%s\n",factors.join(","))
                out <<  "mode:"+mode.to_s+"\n"
                out <<  "Distribution:\n"
                frequencies.sort.each{|k,v|
                    out <<  sprintf("%s : %s (%0.2f%%)\n",k,v, (v.to_f / n_valid)*100)
                }
                out
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
            def summary(out="")
                out << sprintf("n valid:%d\n",n_valid)
                out <<  "median:"+median.to_s+"\n"
                out <<  "percentil 25:"+percentil(25).to_s+"\n"
                out <<  "percentil 75:"+percentil(75).to_s+"\n"
                out
            end
		end
		class Scale <Ordinal
			attr_reader :gsl 
            def initialize(data)
				@data=data.collect{|x|
                    x.to_f
                }
				if HAS_GSL
                    @gsl=GSL::Vector.alloc(@data)
				end
			end
            def _dump(i)
                Marshal.dump(@data)
            end
            def _load(data)
                @data=Marshal.restore(data)
				if HAS_GSL
                    @gsl=GSL::Vector.alloc(@data)
				end                
            end
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
            
			def variance_sample(m=false)
				m=mean unless m
				@data.inject(0){|a,x|a+(x-m).square} / (n_valid - 1)
			end

            # Sample Standard deviation (divided by n-1)
            
			def standard_deviation_sample(m=false)
				m=mean unless m
				Math::sqrt(variance_sample(m))
			end
			
			if HAS_GSL
                %w{variance_sample standard_deviation_sample mean sum}.each{|m|
                    m_nuevo=("slow_"+m).intern
                    alias_method m_nuevo, m.intern
                }
				def sum
					@gsl.sum
				end
				def mean
					@gsl.mean
				end				
				def variance_sample(m=false)
					m=mean unless m
					@gsl.variance_m
				end
				def standard_deviation_sample(m=false)
					m=mean unless m
					@gsl.sd(m)
				end
				def skew
					@gsl.skew
				end
				def kurtosis
					@gsl.kurtosis
				end
				def correlation(v2)
					raise ArgumentError, "Vector should be of the same size" if(v2.size!=@data.size)
					GSL::Stats::correlation(@gsl,v2.gsl)
				end
				
			end
			
            # Coefficient of variation
            # Calculed with the sample standard deviation
			def coefficient_of_variation
				standard_deviation_sample / mean
			end
            def summary(out="")
                out << sprintf("n valid:%d\n",n_valid)
                out <<  "mean:"+mean.to_s+"\n"
                out <<  "sum:"+sum.to_s+"\n"
                out <<  "range:"+range.to_s+"\n"
                out <<  "variance (pop):"+variance_population.to_s+"\n"
                out <<  "sd (pop):"+sdp.to_s+"\n"
                out <<  "variance (sample):"+variance_sample.to_s+"\n"
                out <<  "sd (sample):"+sds.to_s+"\n"
                
                out
            end
            
			alias_method :sdp, :standard_deviation_population
			alias_method :sds, :standard_deviation_sample			
			alias_method :cov, :coefficient_of_variation
		end
end