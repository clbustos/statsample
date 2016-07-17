require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))
require 'minitest/autorun'

describe Statsample::FitModel do
  before do
    @df = Daru::DataFrame.from_csv 'test/fixtures/df.csv'
    @df.to_category 'c', 'd', 'e'
  end
  context '#df_for_regression' do
    context 'no interaction' do
      it { assert_vectors_from_formula 'y~a+e', %w[a e_B e_C y] }
    end

    context '2-way interaction' do
      context 'interaction of numerical with numerical' do
        context 'none reoccur' do
          it { assert_vectors_from_formula 'y~a:b', %w[a:b y] }
        end
        
        context 'one reoccur' do
          it { assert_vectors_from_formula 'y~a+a:b', %w[a a:b y] }
        end
  
        context 'both reoccur' do
          it { assert_vectors_from_formula 'y~a+b+a:b', %w[a a:b b y] }
        end        
      end
  
      context 'interaction of category with numerical' do
        context 'none reoccur' do
          it { assert_vectors_from_formula 'y~a:e', %w[e_A:a e_B:a e_C:a y] }
        end
  
        context 'one reoccur' do
          context 'numeric occur' do
            it { assert_vectors_from_formula 'y~a+a:e', %w[a e_B:a e_C:a y] }
          end
  
          context 'category occur' do
            it { assert_vectors_from_formula 'y~e+a:e',
              %w[e_B e_C e_A:a e_B:a e_C:a y] }
          end  
        end        
        
        context 'both reoccur' do
          it { assert_vectors_from_formula 'y~a+e+a:e',
            %w[a e_B e_C e_B:a e_C:a y] }
        end
      end
  
      context 'interaction of category with category' do
        context 'none reoccur' do
          it { assert_vectors_from_formula 'y~c:e',
            %w[e_B e_C c_yes:e_A c_yes:e_B c_yes:e_C y] }
        end
  
        context 'one reoccur' do
          it { assert_vectors_from_formula 'y~e+c:e',
            %w[e_B e_C c_yes:e_A c_yes:e_B c_yes:e_C y] }
        end
  
        context 'both reoccur' do
          it { assert_vectors_from_formula 'y~c+e+c:e',
            %w[c_yes e_B e_C c_yes:e_B c_yes:e_C y] }
        end        
      end
    end

    # TODO: Figure out how to perform multiple regression without intercept
    # context 'without intercept' do
    #   context 'no interaction' do
    #     include_context "formula checker", 'y~0+a+e' => %w[a e_A e_B e_C y]
    #   end
    
    #   context '2-way interaction' do
    #     context 'interaction of numerical with numerical' do
    #       context 'none reoccur' do
    #         include_context 'formula checker', 'y~0+a:b' =>
    #           %w[a:b y]
    #         end
          
    #       context 'one reoccur' do
    #         include_context 'formula checker', 'y~0+a+a:b' =>
    #           %w[a a:b y]
    #       end
    
    #       context 'both reoccur' do
    #         include_context 'formula checker', 'y~0+a+b+a:b' =>
    #           %w[a a:b b y]
    #       end        
    #     end
    
    #     context 'interaction of category with numerical' do
    #       context 'none reoccur' do
    #         include_context 'formula checker', 'y~0+a:e' =>
    #           %w[e_A:a e_B:a e_C:a y]
    #       end
    
    #       context 'one reoccur' do
    #         context 'numeric occur' do
    #           include_context 'formula checker', 'y~0+a+a:e' =>
    #             %w[a e_B:a e_C:a y]
    #         end
    
    #         context 'category occur' do
    #           include_context 'formula checker', 'y~0+e+a:e' =>
    #             %w[e_A e_B e_C e_A:a e_B:a e_C:a y]
    #         end  
    #       end        
          
    #       context 'both reoccur' do
    #         include_context 'formula checker', 'y~0+a+e+a:e' =>
    #           %w[a e_A e_B e_C e_B:a e_C:a y]
    #       end
    #     end
    
    #     context 'interaction of category with category' do
    #       context 'none reoccur' do
    #         include_context 'formula checker', 'y~0+c:e' =>
    #           %w[c_no:e_A c_no:e_B c_no:e_C c_yes:e_A c_yes:e_B c_yes:e_C y]
    #       end
    
    #       context 'one reoccur' do
    #         include_context 'formula checker', 'y~0+e+c:e' =>
    #           %w[e_A e_B e_C c_yes:e_A c_yes:e_B c_yes:e_C y]
    #       end
    
    #       context 'both reoccur' do
    #         include_context 'formula checker', 'y~0+c+e+c:e' =>
    #           %w[c_yes c_no e_B e_C c_yes:e_B c_yes:e_C y]
    #       end        
    #     end
    #   end      
    # end
  
    context 'corner case' do
      context 'example 1' do
        it { assert_vectors_from_formula 'y~d:a+d:e',
          %w[e_B e_C d_male:e_A d_male:e_B d_male:e_C d_female:a d_male:a y] }
      end
    
      # context 'example 2' do
      #   include_context 'formula checker', 'y~0+d:a+d:c' =>
      #     %w[d_female:c_no d_male:c_no d_female:c_yes d_male:c_yes d_female:a d_male:a y]
      # end
    end
    
    context 'complex examples' do
      context 'random example 1' do
        it { assert_vectors_from_formula 'y~a+e+c:d+e:d',
          %w[e_B e_C d_male c_yes:d_female c_yes:d_male e_B:d_male e_C:d_male a y] }
      end
      
      context 'random example 2' do
        it { assert_vectors_from_formula 'y~e+b+c+d:e+b:e+a:e+0',
          %w[e_A e_B e_C c_yes d_male:e_A d_male:e_B d_male:e_C b e_B:b e_C:b e_A:a e_B:a e_C:a y] }
      end
    end
  end
end
