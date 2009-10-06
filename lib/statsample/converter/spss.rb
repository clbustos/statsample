module Statsample
  module SPSS
    class << self
      # Export a SPSS Matrix with tetrachoric correlations .
      #
      # Use: 
      #   ds=Statsample::Excel.read("my_data.xls")
      #   puts Statsample::SPSS.tetrachoric_correlation_matrix(ds)
      def tetrachoric_correlation_matrix(ds)
        dsv=ds.dup_only_valid
        # Delete all vectors doesn't have variation
        dsv.fields.each{|f|
          if dsv[f].factors.size==1
            dsv.delete_vector(f) 
          else
            dsv[f]=dsv[f].dichotomize
          end
        }
        tcm=Statsample::Bivariate.tetrachoric_correlation_matrix(dsv)
        n=dsv.fields.collect {|f|
          sprintf("%d",dsv[f].size)
        }
        meanlist=dsv.fields.collect{|f|
          sprintf("%0.3f", dsv[f].mean)
        }
        stddevlist=dsv.fields.collect{|f|
          sprintf("%0.3f", dsv[f].sd)
        }
        out=<<-HEREDOC
MATRIX DATA VARIABLES=ROWTYPE_ #{dsv.fields.join(",")}.
BEGIN DATA
N #{n.join(" ")}
MEAN	#{meanlist.join(" ")}
STDDEV #{stddevlist.join(" ")}
HEREDOC
tcm.row_size.times {|i|
  out +="CORR "
  (i+1).times {|j|
    out+=sprintf("%0.3f",tcm[i,j])+" "
  }
  out +="\n"
}
out+="END DATA.\nEXECUTE.\n"
      end
    end
  end
end
