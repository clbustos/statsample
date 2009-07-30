module RubySS
    class DominanceAnalysis
        def initialize(ds,y_var)
            @y_var=y_var
            @dy=ds[@y_var]
            @ds=ds
            @ds_indep=ds.dup(ds.fields-[y_var])
            @fields=@ds_indep.fields
            create_models
            fill_models
        end
        def fill_models
            @models.each{|m|
                @fields.each{|f|
                    next if m.include? f
                    base_model=md(m)
                    comp_model=md(m+[f])
                    base_model.add_contribution(f,comp_model.r2)
                }
            }
        end
        def md(m)
            @models_data[m.sort]
        end
        # Get all model of size k
        def md_k(k)
            out=[]
            models=@models.each{|m|
                out.push(md(m)) if m.size==k
            }
            out
        end
        def average_k(k)
            return nil if k==@fields.size
            models=md_k(k)
            averages=@fields.inject({}) {|a,v| a[v]=[];a}
            models.each{|m|
                @fields.each{|f|
                    averages[f].push(m.contributions[f]) unless m.contributions[f].nil?
                }
            }
            out={}
            averages.each{|k,v|
                out[k]=v.to_vector(:scale).mean
            }
            out
        end
        def general_averages
            
            averages=@fields.inject({}) {|a,v| a[v]=[md(v).r2];a}
            for k in 1...@fields.size
                ak=average_k(k)
                @fields.each{|f|
                    averages[f].push(ak[f])
                }
            end
            out={}
            averages.each{|k,v|
                out[k]=v.to_vector(:scale).mean
            }
            out
        end
        def create_models
            @models=[]
            @models_data={}
            for i in 1..@fields.size
            c = GSL::Combination.calloc(5, i);
            begin
                convert=c.data.to_a.collect {|i|
                    @fields[i]
                }
                @models.push(convert)
                ds_prev=@ds.dup(convert+[@y_var])
                modeldata=ModelData.new(convert,ds_prev,@y_var,@fields)
                
                @models_data[convert.sort]=modeldata
            end while c.next == GSL::SUCCESS
            end
        end
        def summary
            out=""
            for i in 1..@fields.size
                out << "*********************************\n"
                out << "Model k=#{i}\n"
                out << "*********************************\n"
                
                mk=md_k(i)
                mk.each{|m|
                    out << m.summary+"\n"
                }
                # Report averages
                out << "_______________________\n"
                a=average_k(i)
                if !a.nil?
                    out << @fields.collect{|f|
                        sprintf("%s=%0.3f",f,a[f])
                    }.join(" | ")
                    out << "\n"
                end
                out << "_______________________\n"
            end
            out << "General\n"
            out << "_______________________\n"
            g=general_averages
            out << @fields.collect{|f|
                        sprintf("%s=%0.3f",f,g[f])
                    }.join(" | ")
                    out << "\n"
            return out
        end
    end
    class ModelData
        attr_reader :contributions
        def initialize(name,ds,y_var,fields)
            @name=name
            @fields=fields
            @contributions=@fields.inject({}){|a,v| a[v]=nil;a}
            @lr=Regression::MultipleRegressionPairwise.new(ds,y_var)
        end
        def add_contribution(f,v)
            @contributions[f]=v-r2
        end
        def r2
            @lr.r2
        end
        def summary
            out=sprintf("%s: r2=%0.3f(p=%0.2f)\n",@name.join("*"),r2,@lr.significance,@lr.sst)
            out << @fields.collect{|k|
                v=@contributions[k]
                if v.nil?
                    "--"
                else
                sprintf("%s=%0.3f",k,v)
                end
            }.join(" | ") 
            out << "\n"
            
            return out
        end
    end
end
