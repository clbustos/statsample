require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))

$reliability_icc = nil

class StatsampleReliabilityIccTestCase < Minitest::Test
  context Statsample::Reliability::ICC do
    setup do
      a = Daru::Vector.new([9, 6, 8, 7, 10, 6])
      b = Daru::Vector.new([2, 1, 4, 1, 5, 2])
      c = Daru::Vector.new([5, 3, 6, 2, 6, 4])
      d = Daru::Vector.new([8, 2, 8, 6, 9, 7])
      @ds = Daru::DataFrame.new({ :a => a, :b => b, :c => c, :d => d })
      @icc = Statsample::Reliability::ICC.new(@ds)
    end
    should 'basic method be correct' do
      assert_equal(6, @icc.n)
      assert_equal(4, @icc.k)
    end
    should 'total mean be correct' do
      assert_in_delta(5.291, @icc.total_mean, 0.001)
    end
    should 'df methods be correct' do
      assert_equal(5,  @icc.df_bt)
      assert_equal(18, @icc.df_wt)
      assert_equal(3,  @icc.df_bj)
      assert_equal(15, @icc.df_residual)
    end
    should 'ms between targets be correct' do
      assert_in_delta(11.24, @icc.ms_bt, 0.01)
    end
    should 'ms within targets be correct' do
      assert_in_delta(6.26,  @icc.ms_wt, 0.01)
    end
    should 'ms between judges be correct' do
      assert_in_delta(32.49, @icc.ms_bj, 0.01)
    end
    should 'ms residual be correct' do
      assert_in_delta(1.02,  @icc.ms_residual, 0.01)
    end
    context 'with McGraw and Wong denominations,' do
    end
    context 'with Shrout & Fleiss denominations, ' do
      should 'icc(1,1) method be correct' do
        assert_in_delta(0.17, @icc.icc_1_1, 0.01)
      end
      # Verified on SPSS and R
      should 'icc(2,1) method be correct' do
        assert_in_delta(0.29, @icc.icc_2_1, 0.01)
      end
      should 'icc(3,1) method be correct' do
        assert_in_delta(0.71, @icc.icc_3_1, 0.01)
      end
      should 'icc(1,k) method be correct' do
        assert_in_delta(0.44, @icc.icc_1_k, 0.01)
      end
      # Verified on SPSS and R
      should 'icc(2,k) method be correct' do
        assert_in_delta(0.62, @icc.icc_2_k, 0.01)
      end
      should 'icc(3,k) method be correct' do
        assert_in_delta(0.91, @icc.icc_3_k, 0.01)
      end

      should 'icc(1,1) F be correct' do
        assert_in_delta(1.795, @icc.icc_1_f.f)
      end
      should 'icc(1,1) confidence interval should be correct' do
        assert_in_delta(-0.133, @icc.icc_1_1_ci[0], 0.001)
        assert_in_delta(0.723, @icc.icc_1_1_ci[1], 0.001)
      end
      should 'icc(1,k) confidence interval should be correct' do
        assert_in_delta(-0.884, @icc.icc_1_k_ci[0], 0.001)
        assert_in_delta(0.912, @icc.icc_1_k_ci[1], 0.001)
      end

      should 'icc(2,1) F be correct' do
        assert_in_delta(11.027, @icc.icc_2_f.f)
      end
      should 'icc(2,1) confidence interval should be correct' do
        # skip("Not yet operational")
        assert_in_delta(0.019, @icc.icc_2_1_ci[0], 0.001)
        assert_in_delta(0.761, @icc.icc_2_1_ci[1], 0.001)
      end

      # Verified on SPSS and R
      should 'icc(2,k) confidence interval should be correct' do
        # skip("Not yet operational")
        # p @icc.icc_2_k_ci
        assert_in_delta(0.039, @icc.icc_2_k_ci[0], 0.001)
        assert_in_delta(0.929, @icc.icc_2_k_ci[1], 0.001)
      end
      # should "Shrout icc(2,k) and McGraw icc(a,k) ci be equal" do
      #  assert_in_delta(@icc.icc_2_k_ci_shrout[0], @icc.icc_2_k_ci_mcgraw[0], 10e-5)
      # end

      should 'icc(3,1) F be correct' do
        assert_in_delta(11.027, @icc.icc_3_f.f)
      end

      should 'icc(3,1) confidence interval should be correct' do
        assert_in_delta(0.342, @icc.icc_3_1_ci[0], 0.001)
        assert_in_delta(0.946, @icc.icc_3_1_ci[1], 0.001)
      end
      should 'icc(3,k) confidence interval should be correct' do
        assert_in_delta(0.676, @icc.icc_3_k_ci[0], 0.001)
        assert_in_delta(0.986, @icc.icc_3_k_ci[1], 0.001)
      end
      should 'incorrect type raises an error' do
        assert_raise(::RuntimeError) do
          @icc.type = :nonexistant_type
        end
      end
    end

    begin
      require 'rserve'
      require 'daru/extensions/rserve'
      context 'McGraw and Wong' do
        teardown do
          @r = $reliability_icc[:r].close unless $reliability_icc[:r].nil?
        end
        setup do
          if $reliability_icc.nil?
            size = 100
            a = Daru::Vector.new(size.times.map { rand(10) })
            b = a.recode { |i| i + rand(4) - 2 }
            c = a.recode { |i| i + rand(4) - 2 }
            d = a.recode { |i| i + rand(4) - 2 }
            @ds = Daru::DataFrame.new({ :a => a, :b => b, :c => c, :d => d })

            @icc = Statsample::Reliability::ICC.new(@ds)
            @r = Rserve::Connection.new

            @r.assign('ds', @ds)

            @r.void_eval("library(irr);
              iccs=list(
              icc_1=icc(ds,'o','c','s'),
              icc_k=icc(ds,'o','c','a'),
              icc_c_1=icc(ds,'t','c','s'),
              icc_c_k=icc(ds,'t','c','a'),
              icc_a_1=icc(ds,'t','a','s'),
              icc_a_k=icc(ds,'t','a','a'))
              ")
            @iccs = @r.eval('iccs').to_ruby
            $reliability_icc = { icc: @icc, iccs: @iccs, r: @r
            }

          end
          @icc = $reliability_icc[:icc]
          @iccs = $reliability_icc[:iccs]
          @r = $reliability_icc[:r]
        end
        [:icc_1, :icc_k, :icc_c_1, :icc_c_k, :icc_a_1, :icc_a_k].each do |t|
          context "ICC Type #{t} " do
            should 'value be correct' do
              @icc.type = t
              @r_icc = @iccs[t.to_s]
              assert_in_delta(@r_icc['value'], @icc.r)
            end
            should 'fvalue be correct' do
              @icc.type = t
              @r_icc = @iccs[t.to_s]
              assert_in_delta(@r_icc['Fvalue'], @icc.f.f)
            end
            should 'num df be correct' do
              @icc.type = t
              @r_icc = @iccs[t.to_s]
              assert_in_delta(@r_icc['df1'], @icc.f.df_num)
            end
            should 'den df be correct' do
              @icc.type = t
              @r_icc = @iccs[t.to_s]
              assert_in_delta(@r_icc['df2'], @icc.f.df_den)
            end

            should 'f probability be correct' do
              @icc.type = t
              @r_icc = @iccs[t.to_s]
              assert_in_delta(@r_icc['p.value'], @icc.f.probability)
            end
            should 'bounds be equal' do
              @icc.type = t
              @r_icc = @iccs[t.to_s]
              assert_in_delta(@r_icc['lbound'], @icc.lbound, 0.1)
              assert_in_delta(@r_icc['ubound'], @icc.ubound, 0.1)
            end
            should 'summary generated' do
              assert(@icc.summary.size > 0)
            end
          end
        end
      end
    rescue
      puts 'requires rserve'
    end
  end
end
