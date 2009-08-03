module Statsample
class DominanceAnalysis
    class Bootstrap
        include Writable
        attr_reader :samples_td,:samples_cd,:samples_gd,:samples_ga, :fields
        attr_writer :lr_class
        def initialize(ds,y_var)
            @ds=ds
            @y_var=y_var
            @n=ds.cases
            @fields=ds.fields-[y_var]
            @samples_ga=@fields.inject({}){|a,v| a[v]=[];a}
            @n_samples=0
            @lr_class=Regression::Multiple::RubyEngine
            create_samples_pairs            
        end
        def lr_class=(lr)
            @lr_class=lr
        end
        def da
            if @da.nil?
                @da=DominanceAnalysis.new(@ds,@y_var,@lr_class)
            end
            @da
        end
        def bootstrap(number_samples,n=nil)
                number_samples.times{ |t|
                    @n_samples+=1
                    puts "Bootstrap #{t+1} of #{number_samples}"
                    ds_boot=@ds.bootstrap(n)
                    da_1=DominanceAnalysis.new(ds_boot,@y_var,@lr_class)
                    da_1.total_dominance.each{|k,v|
                        @samples_td[k].push(v)
                    }
                    da_1.conditional_dominance.each{|k,v|
                        @samples_cd[k].push(v)
                    }
                    da_1.general_dominance.each{|k,v|
                        @samples_gd[k].push(v)
                    }
                    da_1.general_averages.each{|k,v|
                        @samples_ga[k].push(v)
                    }
                }
        end
        def create_samples_pairs
            @samples_td={}
            @samples_cd={}
            @samples_gd={}
            @pairs=[]
            c = GSL::Combination.calloc(@fields.size, 2);
            begin
                convert=c.data.to_a.collect {|i|
                    @fields[i]
                }
                @pairs.push(convert)
                [@samples_td,@samples_cd,@samples_gd].each{|s|
                    s[convert]=[]
                }
            end while c.next == GSL::SUCCESS
        end
        def summary(report_type=ConsoleSummary)
            out =""
            raise "You should bootstrap first" if @n_samples==0
            alfa=0.95
            t=GSL::Cdf.tdist_Pinv(1-((1-alfa) / 2),@n_samples - 1)
            out.extend report_type
            out.add "Summary for Bootstrap Dominance Analysis of "+@fields.join(", ")+" over "+@y_var+"\n"
            out.add "Size of sample: #{@n_samples}\n"
            out.add "t:#{t}\n"
            out.add "Linear Regression Engine: #{@lr_class.name}"
            out.nl
            table=ReportTable.new
            header=["pairs","sD","Dij","SE(Dij)","Pij","Pji","Pno","Reprod"]
            table.header=header
            table.add_row(["Complete dominance"])
            table.add_horizontal_line
            @pairs.each{|pair|
                std=@samples_td[pair].to_vector(:scale)
                ttd=da.total_dominance_pairwise(pair[0],pair[1])
                table.add_row(summary_pairs(pair,std,ttd))
            }
            table.add_horizontal_line
            table.add_row(["Conditional dominance"])
            table.add_horizontal_line
            @pairs.each{|pair|
                std=@samples_cd[pair].to_vector(:scale)
                ttd=da.conditional_dominance_pairwise(pair[0],pair[1])
                table.add_row(summary_pairs(pair,std,ttd))

            }
            table.add_horizontal_line
            table.add_row(["General Dominance"])
            table.add_horizontal_line
            @pairs.each{|pair|
                std=@samples_gd[pair].to_vector(:scale)
                ttd=da.general_dominance_pairwise(pair[0],pair[1])
                table.add_row(summary_pairs(pair,std,ttd))
            }
            out.parse_table(table)
            out.add("General averages")
            table=Statsample::ReportTable.new
            table.header=["var","mean","se","p.5","p.95"]
            @fields.each{|f|
                v=@samples_ga[f].to_vector(:scale)
                row=[f, sprintf("%0.3f",v.mean), sprintf("%0.3f",v.sd), sprintf("%0.3f",v.percentil(5)),sprintf("%0.3f",v.percentil(95))]
                table.add_row(row)

            }
            out.parse_table(table)
            out
        end
        def summary_pairs(pair,std,ttd)
            freqs=std.proportions
            [0,0.5,1].each{|n|
                freqs[n]=0 if freqs[n].nil?
            }
            name=pair[0]+" - "+pair[1]
            [name,f(ttd,1),f(std.mean,4),f(std.sd),f(freqs[1]), f(freqs[0]), f(freqs[0.5]), f(freqs[ttd])]
        end
        def f(v,n=3)
            prec="%0.#{n}f"
            sprintf(prec,v)
        end
    end
end
end
