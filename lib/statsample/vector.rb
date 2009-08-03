class Array
	def to_vector(*args)
		Statsample::Vector.new(self,*args)
	end
end

module Statsample
    class << self
	# Create a matrix using vectors as columns
    # Use:
    #
    # matrix=Statsample.vector_cols_matrix(v1,v2)
	def vector_cols_matrix(*vs)
		# test
		size=vs[0].size
		vs.each{|v|
			raise ArgumentError,"Arguments should be Vector" unless v.instance_of? Statsample::Vector
			raise ArgumentError,"Vectors size should be the same" if v.size!=size
		}
		Matrix.rows((0...size).to_a.collect() {|i|
			vs.collect{|v| v[i]}
		})
	end
	end
	# Returns a duplicate of the input vectors, without missing data
	# for any of the vectors
	# 
	#  a=[1,2,3,6,7,nil,3,5].to_vector(:scale)
	#  b=[nil,nil,5,6,4,5,10,2].to_vector(:scale)
	#  c=[2,4,6,7,4,5,6,7].to_vector(:scale)
	#  a2,b2,c2=Statsample.only_valid(a,b,c)
	#  => [#<Statsample::Scale:0xb748c8c8 @data=[3, 6, 7, 3, 5]>, 
	#        #<Statsample::Scale:0xb748c814 @data=[5, 6, 4, 10, 2]>, 
	#        #<Statsample::Scale:0xb748c760 @data=[6, 7, 4, 6, 7]>]
	#
	def self.only_valid(*vs)
		i=1
		h=vs.inject({}) {|a,v| a["v#{i}"]=v;i+=1;a}
		ds=Statsample::Dataset.new(h).dup_only_valid
		ds.vectors.values
	end
class Vector < DelegateClass(Array)
	
    include Enumerable
    attr_reader :type, :data, :valid_data, :missing_values, :missing_data, :data_with_nils
        attr_accessor :labels
        # Creates a new 
        # data = Array of data
        # t = level of meausurement. Could be: 
        # [:nominal] : Nominal level of measurement
        # [:ordinal] : Ordinal level of measurement
        # [:scale]   : Scale level of meausurement
        #
		def initialize(data=[],t=:nominal,missing_values=[],labels={})
            raise "Data should be an array" unless data.is_a? Array
			@data=data
			@missing_values=missing_values
			@labels=labels
            @type=t
            @valid_data=[]
            @data_with_nils=[]
            @missing_data=[]
            @has_missing_data=nil
			_set_valid_data
			self.type=t
			super(@delegate)
		end
        def dup
            Vector.new(@data.dup,@type,@missing_values.dup,@labels.dup)
        end
        # Returns an empty duplicate of the vector. Maintains the type, missing
        # values, labels
        def dup_empty
            Vector.new([],@type,@missing_values.dup,@labels.dup)
        end
        # Return a vector usign the standarized values for data
        # with sd with denominator N
		def vector_standarized_pop
			vector_standarized(true)
		end
        
        # Return a vector usign the standarized values for data
        # with sd with denominator n-1
        
        def vector_standarized(use_population=false)
            raise "Should be a scale" unless @type==:scale
            mean=@delegate.mean
            sd=use_population ? @delegate.sdp : @delegate.sds
            @data_with_nils.collect{|x|
                if !x.nil?
                    (x.to_f - mean).quo(sd)
                else
                    nil
                end
            }.to_vector(:scale)
        end
        alias_method :standarized, :vector_standarized
        def box_cox_transformation(lambda)
            raise "Should be a scale" unless @type==:scale
            @data_with_nils.collect{|x|
            if !x.nil?
                if(lambda==0)
                    Math.log(x)
                else
                    (x**lambda-1).quo(lambda)
                end
            else
                nil
            end
            }.to_vector(:scale)
        end
        
        # Vector equality
        # Two vector will be the same if their data, missing values, type, labels are equals
        def ==(v2)
            raise TypeError,"Argument should be a Vector" unless v2.instance_of? Statsample::Vector
            @data==v2.data and @missing_values==v2.missing_values and @type==v2.type and @labels=v2.labels
        end
        def _dump(i)
            Marshal.dump({'data'=>@data,'missing_values'=>@missing_values, 'labels'=>@labels, 'type'=>@type})
        end
        def self._load(data)
            h=Marshal.load(data)
            Vector.new(h['data'], h['type'], h['missing_values'], h['labels'])
        end
        def recode
            @data.collect{|x|
                yield x
            }.to_vector(@type)
        end
        def recode!
            @data.collect!{|x|
                yield x
            }
            set_valid_data
        end
        def each
            @data.each{|x|
                yield(x)
            }
        end
        # Add a value at the end of the vector
        # If second argument set to false, you should update valid data usign
        # Vector#set_valid_data at the end of your insertion cycle
        def add(v,update_valid=true)
            @data.push(v)
            set_valid_data if update_valid
        end
        def set_valid_data
			@valid_data.clear
			@missing_data.clear
            @data_with_nils.clear
            _set_valid_data
            @delegate.set_gsl if(@type==:scale)
		end
        def _set_valid_data
            if Statsample::OPTIMIZED
                Statsample::_set_valid_data(self)
            else
            @data.each do |n|
				if is_valid? n
                    @valid_data.push(n)
                    @data_with_nils.push(n)
				else
                    @data_with_nils.push(nil)
                    @missing_data.push(n)
				end
			end
            @has_missing_data=@missing_data.size>0
            end
        end
        # Retrieves true if data has one o more missing values
        def has_missing_data?
            @has_missing_data
        end
        def labeling(x)
            @labels.has_key?(x) ? @labels[x].to_s : x.to_s
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
        def []=(i,v)
            @data[i]=v
        end
        # Return true if a value is valid (not nil and not included on missing values)
        def is_valid?(x)
            !(x.nil? or @missing_values.include? x)
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
	# Redundant, but necessary
	# Spreadsheet creates Array#sum, so calling sum 
	# doesn't call the delegates method
	def sum
	    @delegate.sum
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
        # Reports all values that doesn't comply with a condition
        # Returns a hash with the index of data and the invalid data
        def verify
            h={}
            (0...@data.size).to_a.each{|i|
                if !(yield @data[i])
                    h[i]=@data[i]
                end
            }
            h
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
                    Statsample::Vector.new(sum)
                else
                    raise ArgumentError, "The array/vector parameter should be of the same size of the original vector"
                end
            elsif(v.respond_to? method )
                Statsample::Vector.new(
                    @data.collect  {|x|
                        if(!x.nil?)
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
        # Return an array with the data splitted by a separator
        # a=Vector.new(["a,b","c,d","a,b","d"])
        # a.splitted
        # [["a","b"],["c","d"],["a","b"],["d"]]
        def splitted(sep=Statsample::SPLIT_TOKEN)
            @data.collect{|x|
                if x.nil?
                    nil
                elsif (x.respond_to? :split)
                    x.split(sep)
                else
                    [x]
                end
            }
        end
        # Returns a hash of Vectors, defined by the different values
        # defined on the fields
        # Example:
        #
        # a=Vector.new(["a,b","c,d","a,b"])
        #  a.split_by_separator
        #    {"a"=>#<Statsample::Type::Nominal:0x7f2dbcc09d88 @data=[1, 0, 1]>,
        #     "b"=>#<Statsample::Type::Nominal:0x7f2dbcc09c48 @data=[1, 1, 0]>,
        #     "c"=>#<Statsample::Type::Nominal:0x7f2dbcc09b08 @data=[0, 1, 1]>}
        #
        def split_by_separator(sep=Statsample::SPLIT_TOKEN)
            split_data=splitted(sep)
            factors=split_data.flatten.uniq.compact
            out=factors.inject({}) {|a,x|
                a[x]=[]
                a
            }
            split_data.each{|r|
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
        def split_by_separator_freq(sep=Statsample::SPLIT_TOKEN)
            split_by_separator(sep).inject({}) {|a,v|
                a[v[0]]=v[1].inject {|s,x| s+x.to_i}
                a
            }
        end
        
        # Returns an random sample of size n, with replacement,
        # only with valid data.
        #
        # In all the trails, every item have the same probability
        # of been selected
		def sample_with_replacement(sample=1)
            Vector.new(@delegate.sample_with_replacement(sample) ,@type)
        end
        # Returns an random sample of size n, without replacement,
        # only with valid data.
        #
        # Every element could only be selected once
        # A sample of the same size of the vector is the vector itself
            
        def sample_without_replacement(sample=1)
            Vector.new(@delegate.sample_without_replacement(sample),@type)
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
        # returns the real type for the vector, according to its content
        def db_type(dbs='mysql')
            # first, detect any character not number
            if @data.find {|v|  v.to_s=~/\d{2,2}-\d{2,2}-\d{4,4}/} or @data.find {|v|  v.to_s=~/\d{4,4}-\d{2,2}-\d{2,2}/}
                return "DATE"
            elsif @data.find {|v|  v.to_s=~/[^0-9e.-]/ }
                return "VARCHAR (255)"
            elsif @data.find {|v| v.to_s=~/\./}
                return "DOUBLE"
            else
                return "INTEGER"
            end
        end
        def summary(out="")
            @delegate.summary(@labels,out)
        end
        def to_s
            sprintf("Vector(type:%s, n:%d)[%s]",@type.to_s,@data.size, @data.collect{|d| d.nil? ? "nil":d}.join(","))
        end
		def inspect
			self.to_s
		end
        
    end
        
	
	
	class Nominal
		def initialize(data)
            @data=data
           # @factors=data.uniq
		end
        def delegate_data
            @data
        end
                    # Return an array of the different values of the data
        def factors
            @data.uniq.sort
        end
		# Returns a hash with the distribution of frecuencies of
		# the sample                
		def frequencies_slow
			@data.inject(Hash.new) {|a,x|
				a[x]||=0
				a[x]=a[x]+1
				a
			}
		end
		# Plot frequencies on a chart, using gnuplot
        def plot_frequencies
                require 'gnuplot'
                x=[]
                y=[]
                self.frequencies.sort.each{|k,v|
                    x.push(k)
                    y.push(v) 
                }
		Gnuplot.open do |gp|
			Gnuplot::Plot.new( gp ) do |plot|
			plot.boxwidth("0.9 absolute")
			plot.yrange("[0:#{y.max}]")
			plot.style("fill  solid 1.00 border -1")
			plot.set("xtics border in scale 1,0.5 nomirror rotate by -45  offset character 0, 0, 0")
			plot.style("histogram")
			plot.style("data histogram")
			i=-1
			plot.set("xtics","("+x.collect{|v| i+=1; sprintf("\"%s\" %d",v,i)}.join(",")+")")
			plot.data << Gnuplot::DataSet.new( [y] ) do |ds|
				end
			end
		end
		
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
                    a[v[0]] = v[1].quo(@data.size)
                    a
                }
            end
            # Proportion of a given value.
            def proportion(v=1)
                frequencies[v].quo(@data.size)
            end
            def summary(labels,out="")
                out << sprintf("n valid:%d\n",n_valid)
                out <<  sprintf("factors:%s\n",factors.join(","))
                out <<  "mode:"+mode.to_s+"\n"
                out <<  "Distribution:\n"
                frequencies.sort.each{|k,v|
                    key=labels.has_key?(k) ? labels[k]:k
                    out <<  sprintf("%s : %s (%0.2f%%)\n",key,v, (v.quo(n_valid))*100)
                }
                out
            end
            
            # Returns an random sample of size n, with replacement,
            # only with valid data.
            #
            # In all the trails, every item have the same probability
            # of been selected
            def sample_with_replacement(sample)
                (0...sample).collect{ @data[rand(@data.size)] }
            end
            # Returns an random sample of size n, without replacement,
            # only with valid data.
            #
            # Every element could only be selected once
            # A sample of the same size of the vector is the vector itself
                
            def sample_without_replacement(sample)
                    raise ArgumentError, "Sample size couldn't be greater than n" if sample>@data.size
                    out=[]
                    size=@data.size
                    while out.size<sample
                        value=rand(size)
                        out.push(value) if !out.include?value
                    end
                    out.collect{|i|@data[i]}
             end
            
            
            # Variance of p, according to poblation size
            def variance_proportion(n_poblation, v=1)
                Statsample::proportion_variance_sample(self.proportion(v), @data.size, n_poblation)
            end
            def variance_total(n_poblation, v=1)
                Statsample::total_variance_sample(self.proportion(v), @data.size, n_poblation)
            end
            def proportion_confidence_interval_t(n_poblation,margin=0.95,v=1)
                Statsample::proportion_confidence_interval_t(proportion(v), @data.size, n_poblation, margin)
            end
            def proportion_confidence_interval_z(n_poblation,margin=0.95,v=1)
                Statsample::proportion_confidence_interval_z(proportion(v), @data.size, n_poblation, margin)
            end            
		self.instance_methods.find_all{|met| met=~/_slow$/}.each{|met|
			met_or=met.gsub("_slow","")
			if !self.method_defined?(met_or)
				alias_method met_or, met
			end
		}
	end
        
	class Ordinal <Nominal
        # Return the value of the percentil q
            def percentil(q)
                sorted=@data.sort
                v= (n_valid * q).quo(100)
                if(v.to_i!=v)
                    sorted[v.to_i]
                else
                    (sorted[(v-0.5).to_i].to_f + sorted[(v+0.5).to_i]).quo(2)
                end
            end
			# Returns a ranked vector
			def ranked(type=:ordinal)
				i=0
				r=frequencies.sort.inject({}){|a,v|
					a[v[0]]=(i+1 + i+v[1]).quo(2)
					i+=v[1]
					a
				}
				@data.collect {|c|
					r[c]
				}.to_vector(type)
			end
            # Return the median (percentil 50)
            def median
                percentil(50)
            end
            if HAS_GSL
                %w{median}.each{|m|
                    m_nuevo=(m+"_slow").intern
                    alias_method m_nuevo, m.intern
                }
                
                #def percentil(p)
                #    v=GSL::Vector.alloc(@data.sort)
                #    v.stats_quantile_from_sorted_data(p)
                #end
                def median # :nodoc:
                    GSL::Stats::median_from_sorted_data(GSL::Vector.alloc(@data.sort))
                end
            end
            # Minimun value
            def min; @data.min;end
                # Maximum value
            def max; @data.max; end
            
            
            def summary(labels,out="")
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
                # puts "Inicializando Scale..."
                super(data)
                
                set_gsl
            end
            
            def _dump(i)
                Marshal.dump(@data)
            end
            def _load(data)
                @data=Marshal.restore(data)
                set_gsl
            end
            def set_gsl # :nodoc
                data = @data.collect!{|x|
                    if x.is_a? Numeric
                        x
                    elsif x.is_a? String and x.to_i==x.to_f
                        x.to_i
                    else
                        x.to_f
                    end
                }
                if HAS_GSL
                    @gsl=GSL::Vector.alloc(@data) if @data.size>0
				end
            end
            # The range of the data (max - min)
			def range; @data.max - @data.min; end
            # The sum of values for the data
            def sum
                @data.inject(0){|a,x|x+a} ; end
            # The arithmetical mean of data
			def mean
					sum.to_f.quo(n_valid)
			end
            def sum_of_squares(m=nil)
                m||=mean
                @data.inject(0){|a,x| a+(x-m).square}
            end
            
			# Sum of squared deviation
			def sum_of_squared_deviation
				@data.inject(0) {|a,x| x.square+a} - (sum.square.quo(n_valid))
			end
            
            # Population variance (divided by n)
            def variance_population(m=nil)
                m||=mean
				squares=@data.inject(0){|a,x| x.square+a}
                squares.quo(n_valid) - m.square
            end
			
		
            # Population Standard deviation (divided by n)
            def standard_deviation_population(m=nil)
                Math::sqrt( variance_population(m) )
            end
            # Sample Variance (divided by n-1)
            
			def variance_sample(m=nil)
				m||=mean
				sum_of_squares(m).quo(n_valid - 1)
			end

            # Sample Standard deviation (divided by n-1)
            
			def standard_deviation_sample(m=nil)
				m||=m
				Math::sqrt(variance_sample(m))
			end
			def skew
				m=mean
				thirds=@data.inject(0){|a,x| a+((x-mean)**3)}
				thirds.quo((@data.size-1)*sd**3)
			end
			def kurtosis
				m=mean
				thirds=@data.inject(0){|a,x| a+((x-mean)**4)}
				thirds.quo((@data.size-1)*sd**4)
				
			end
			
			if HAS_GSL
                %w{skew kurtosis variance_sample standard_deviation_sample variance_population standard_deviation_population mean sum}.each{|m|
                    m_nuevo=(m+"_slow").intern
                    alias_method m_nuevo, m.intern
                }
				def sum # :nodoc:
					@gsl.sum
				end
				def mean # :nodoc:
					@gsl.mean
				end				
				def variance_sample(m=nil) # :nodoc:
					m||=mean
					@gsl.variance_m
				end
				def standard_deviation_sample(m=nil) # :nodoc:
					m||=mean
					@gsl.sd(m)
				end
				
				def variance_population(m=nil) # :nodoc:
					m||=mean
					@gsl.variance_with_fixed_mean(m)
				end
				def standard_deviation_population(m=nil) # :nodoc:
					m||=mean
					@gsl.sd_with_fixed_mean(m)
				end
				def skew
					@gsl.skew
				end
				def kurtosis
					@gsl.kurtosis
				end
                # Create a GSL::Histogram
                # With a fixnum, creates X bins within the range of data
                # With an Array, each value will be a cut point
                def histogram(bins=10)
                    if bins.is_a? Array
                        h=GSL::Histogram.alloc(bins)                        
                    else
                        # ugly patch. The upper limit for a bin has the form
                        # x < range
                        h=GSL::Histogram.alloc(bins,[@data.min,@data.max+0.0001])
                    end
                    h.increment(@gsl)
					 h
                end
                def plot_histogram(bins=10,options="")
                    self.histogram(bins).graph(options)
                end
                def sample_with_replacement(k)
                    r = GSL::Rng.alloc(GSL::Rng::MT19937,rand(10000))
                    r.sample(@gsl, k).to_a
                end
                def sample_without_replacement(k)
                    r = GSL::Rng.alloc(GSL::Rng::MT19937,rand(10000))
                    r.choose(@gsl, k).to_a
                end
			end
			
            # Coefficient of variation
            # Calculed with the sample standard deviation
			def coefficient_of_variation
				standard_deviation_sample.quo(mean)
			end
            def summary(labels,out="")
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
            alias_method :variance, :variance_sample
            alias_method :sd, :standard_deviation_sample
            alias_method :ss, :sum_of_squares
		end
end
