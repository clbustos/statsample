require 'statsample/dominanceanalysis/bootstrap'
module Statsample
    class DominanceAnalysis
        include GetText
        bindtextdomain("statsample")
        def initialize(ds,y_var, r_class = Regression::Multiple::RubyEngine)
            @y_var=y_var
            @dy=ds[@y_var]
            @ds=ds
            @r_class=r_class
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
        def dominance_for_nil_model(i,j)
            if md(i).r2>md(j).r2
                1
            elsif md(i).r2<md(j).r2
                0
            else
                0.5
            end           
        end
        # Returns 1 if i D k, 0 if j dominates i and 0.5 if undetermined
        def total_dominance_pairwise(i,j)
            dm=dominance_for_nil_model(i,j)
            return 0.5 if dm==0.5
            dominances=[dm]
            @models_data.each{|k,m|
                if !m.contributions[i].nil? and !m.contributions[j].nil?
                    if m.contributions[i]>m.contributions[j]
                        dominances.push(1)
                    elsif m.contributions[i]<m.contributions[j]
                        dominances.push(0)
                    else
                        dominances.push(0.5)
                    end
                end
            }
            final=dominances.uniq
            final.size>1 ? 0.5 : final[0]
        end
        
        # Returns 1 if i cD k, 0 if j cD i and 0.5 if undetermined
        def conditional_dominance_pairwise(i,j)
            dm=dominance_for_nil_model(i,j)
            return 0.5 if dm==0.5
            dominances=[dm]
            for k in 1...@fields.size
                a=average_k(k)
                if a[i]>a[j]
                    dominances.push(1)
                elsif a[i]<a[j]
                    dominances.push(0)
                else
                    a(0.5)
                end                 
            end
            final=dominances.uniq
            final.size>1 ? 0.5 : final[0]            
        end
        # Returns 1 if i gD k, 0 if j gD i and 0.5 if undetermined        
        def general_dominance_pairwise(i,j)
            ga=general_averages
            if ga[i]>ga[j]
                1
            elsif ga[i]<ga[j]
                0
            else
                0.5
            end                 
        end
        def pairs
            @models.find_all{|m| m.size==2}
        end
        def total_dominance
            pairs.inject({}){|a,pair|
                a[pair]=total_dominance_pairwise(pair[0], pair[1])
                a
            }
        end
        def conditional_dominance
            pairs.inject({}){|a,pair|
                a[pair]=conditional_dominance_pairwise(pair[0], pair[1])
                a
            }
        end
        def general_dominance
            pairs.inject({}){|a,pair|
                a[pair]=general_dominance_pairwise(pair[0], pair[1])
                a
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
        def get_averages(averages)
          out={}
          averages.each{|key,val| out[key]=val.to_vector(:scale).mean }
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
            get_averages(averages)
        end
        def general_averages
            if @general_averages.nil?
                averages=@fields.inject({}) {|a,v| a[v]=[md(v).r2];a}
                for k in 1...@fields.size
                    ak=average_k(k)
                    @fields.each{|f|
                        averages[f].push(ak[f])
                    }
                end
                @general_averages=get_averages(averages)
            end
            @general_averages
        end
        def create_models
            @models=[]
            @models_data={}
            for i in 1..@fields.size
                c=Statsample::Combination.new(i,@fields.size)
                c.each{|data|
                    convert=data.collect {|i1|
                        @fields[i1]
                    }
                    @models.push(convert)
                    ds_prev=@ds.dup(convert+[@y_var])
                    modeldata=ModelData.new(convert,ds_prev, @y_var, @fields, @r_class)
                    @models_data[convert.sort]=modeldata
                }
            end
        end
        def summary(report_type=ConsoleSummary)
            out=""
            out.extend report_type
            out << _("Summary for Dominance Analysis of %s on %s\n") % [@fields.join(", "),@y_var]
                t=Statsample::ReportTable.new
                t.header=["","r2","sign"]+@fields
                row=[_("Model 0"),"",""]+@fields.collect{|f|
                    sprintf("%0.3f",md(f).r2)
                }
                t.add_row(row)
                t.add_horizontal_line
            for i in 1..@fields.size
                mk=md_k(i)
                mk.each{|m|
                    t.add_row(m.add_table_row)
                }
                # Report averages
                a=average_k(i)
                if !a.nil?
                    t.add_horizontal_line
                    row=[_("k=%d Average") % i,"",""] + @fields.collect{|f|
                        sprintf("%0.3f",a[f])
                    }
                    t.add_row(row)
                    t.add_horizontal_line
                    
                end
                
            end
            
            g=general_averages
	     t.add_horizontal_line
            
            row=[_("Overall averages"),"",""]+@fields.collect{|f|
                        sprintf("%0.3f",g[f])
            }
            t.add_row(row)
            out.parse_table(t)
                    
            out.nl
            out << _("Pairwise")+"\n"
            td=total_dominance
            cd=conditional_dominance
            gd=general_dominance
            t=Statsample::ReportTable.new([_("Pairs"),"T","C","G"])
            pairs.each{|p|
                name=p.join(" - ")
                row=[name, sprintf("%0.1f",td[p]), sprintf("%0.1f",cd[p]), sprintf("%0.1f",gd[p])]
                t.add_row(row)
            }
            out.parse_table(t)
            return out
        end
            class ModelData
            attr_reader :contributions
            def initialize(name,ds,y_var,fields,r_class)
                @name=name
                @fields=fields
                @contributions=@fields.inject({}){|a,v| a[v]=nil;a}
                r_class=Regression::Multiple::RubyEngine if r_class.nil?
                @lr=r_class.new(ds,y_var)
            end
            def add_contribution(f,v)
                @contributions[f]=v-r2
            end
            def r2
                @lr.r2
            end
            def add_table_row
                begin
                sign=sprintf("%0.3f", @lr.significance)
                rescue RuntimeError
                    sign="???"
                end
                [@name.join("*"), sprintf("%0.3f",r2), sign] + @fields.collect{|k|
                    v=@contributions[k]
                    if v.nil?
                        "--"
                    else
                    sprintf("%0.3f",v)
                    end
                }
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
    
end
