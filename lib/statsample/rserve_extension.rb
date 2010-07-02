# Several additions to Statsample objects, to support
# rserve-client

module Statsample
  class Vector
    def to_REXP
      Rserve::REXP::Wrapper.wrap(data_with_nils)
    end
  end
  class Dataset
    def to_REXP
      names=@fields
      data=@fields.map {|f|
        Rserve::REXP::Wrapper.wrap(@vectors[f].data_with_nils)
      }
      l=Rserve::Rlist.new(data,names)
      Rserve::REXP.create_data_frame(l)
    end
  end
end