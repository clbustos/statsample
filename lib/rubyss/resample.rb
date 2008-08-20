module RubySS
    class Resample
        class << self
            def repeat_and_save(times,&action)
                (1..times).inject([]) {|a,x|
                    a.push(action.call)
                    a
                }
            end
            
            def generate (size,low,upper)
                range=upper-low+1
                Vector.new((0...size).collect {|x|
                    rand(range)+low
                },:scale)
            end
                    
        end
    end
end
