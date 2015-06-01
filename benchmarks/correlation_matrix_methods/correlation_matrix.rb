# This test create a database to adjust the best algorithm
# to use on correlation matrix
require(File.expand_path(File.dirname(__FILE__)+'/../helpers_benchmark.rb'))
require 'statsample'
require 'benchmark'

def create_dataset(vars,cases) 
  ran = Distribution::Normal.rng
  ds  = Daru::DataFrame.new(
    vars.times.inject({}) do |ac,v|
      ac["x#{v}".to_sym] = Daru::Vector.new_with_size(cases) {ran.call}
      ac
    end
  )
end

def prediction_pairwise(vars,cases)
	Statsample::Bivariate.prediction_pairwise(vars,cases) / 10
end
def prediction_optimized(vars,cases)
	Statsample::Bivariate.prediction_optimized(vars,cases) / 10
end

if !File.exists?("correlation_matrix.ds") or File.mtime(__FILE__) > File.mtime("correlation_matrix.ds")
reps=100 #number of repetitions
ds_sizes=[5,10,30,50,100,150,200,500,1000]
ds_vars=[3,4,5,10,20,30,40]
#ds_sizes=[5,10]
#ds_vars=[3,5,20]
rs = Daru::DataFrame.new({}, order: [:cases, :vars, :time_optimized, :time_pairwise])

ds_sizes.each do |cases|
  ds_vars.each do |vars|
      ds = create_dataset(vars,cases)
      time_optimized= Benchmark.realtime do
        reps.times { 
        Statsample::Bivariate.correlation_matrix_optimized(ds) 
        ds.clear_gsl
        }
      end
      
      time_pairwise= Benchmark.realtime do
        reps.times { Statsample::Bivariate.correlation_matrix_pairwise(ds) }
      end
      
      puts "Cases:#{cases}, vars:#{vars} -> opt:%0.3f (%0.3f) | pair: %0.3f (%0.3f)" % [time_optimized, prediction_optimized(vars,cases), time_pairwise, prediction_pairwise(vars,cases)]
      
      rs.add_row(Daru::Vector.new({
        :cases          => cases,
        :vars           => vars,
        :time_optimized => Math.sqrt(time_optimized*1000),
        :time_pairwise  =>Math.sqrt(time_pairwise*1000)
        })
      )
    end
  end 
else
  rs=Statsample.load("correlation_matrix.ds")
end

rs[:c_v] = rs.collect {|row| row[:cases]*row[:vars]}

rs.update
rs.save("correlation_matrix.ds")
Statsample::Excel.write(rs,"correlation_matrix.xls")

rb = ReportBuilder.new(:name=>"Correlation matrix analysis")

rb.add(Statsample::Regression.multiple(rs[:cases,:vars,:time_optimized,:c_v],:time_optimized, :digits=>6))
rb.add(Statsample::Regression.multiple(rs[:cases,:vars,:time_pairwise,:c_v],:time_pairwise, :digits=>6))

rb.save_html("correlation_matrix.html")
