require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))

class StatsampleMultisetTestCase < Minitest::Test
  def setup
    @x = Daru::Vector.new(%w(a a a a b b b b))
    @y = Daru::Vector.new([1, 2, 3, 4, 5, 6, 7, 8])
    @z = Daru::Vector.new([10, 11, 12, 13, 14, 15, 16, 17])
    @ds = Daru::DataFrame.new({ :x => @x, :y => @y, :z => @z })
    @ms = @ds.to_multiset_by_split(:x)
  end

  def test_creation
    v1a = Daru::Vector.new([1, 2, 3, 4, 5])
    v2b = Daru::Vector.new([11, 21, 31, 41, 51])
    v3c = Daru::Vector.new([21, 23, 34, 45, 56])
    ds1 = Daru::DataFrame.new({ :v1 => v1a, :v2 => v2b, :v3 => v3c })
    v1b = Daru::Vector.new([15, 25, 35, 45, 55])
    v2b = Daru::Vector.new([11, 21, 31, 41, 51])
    v3b = Daru::Vector.new([21, 23, 34, 45, 56])
    ds2 = Daru::DataFrame.new({ :v1 => v1b, :v2 => v2b, :v3 => v3b })
    ms = Statsample::Multiset.new([:v1, :v2, :v3])
    ms.add_dataset(:ds1, ds1)
    ms.add_dataset(:ds2, ds2)
    assert_equal(ds1, ms[:ds1])
    assert_equal(ds2, ms[:ds2])
    assert_equal(v1a, ms[:ds1][:v1])
    assert_not_equal(v1b, ms[:ds1][:v1])
    ds3 = Daru::DataFrame.new({ :v1 => v1b, :v2 => v2b })
    assert_raise ArgumentError do
      ms.add_dataset(ds3)
    end
  end

  def test_creation_empty
    ms = Statsample::Multiset.new_empty_vectors([:id, :age, :name], [:male, :female])
    ds_male   = Daru::DataFrame.new({ 
      :id => Daru::Vector.new([]), 
      :age => Daru::Vector.new([]), 
      :name => Daru::Vector.new([])
      }, order: [:id, :age, :name])

    ds_female = Daru::DataFrame.new({ 
      :id => Daru::Vector.new([]), 
      :age => Daru::Vector.new([]), 
      :name => Daru::Vector.new([])
      }, order: [:id, :age, :name])

    ms2 = Statsample::Multiset.new([:id, :age, :name])
    ms2.add_dataset(:male, ds_male)
    ms2.add_dataset(:female, ds_female)
    assert_equal(ms2.fields, ms.fields)
    assert_equal(ms2[:male], ms[:male])
    assert_equal(ms2[:female], ms[:female])
  end

  def test_to_multiset_by_split_one
    sex  = Daru::Vector.new(%w(m m m m m f f f f m))
    city = Daru::Vector.new(%w(London Paris NY London Paris NY London Paris NY Tome))
    age  = Daru::Vector.new([10, 10, 20, 30, 34, 34, 33, 35, 36, 40])
    ds   = Daru::DataFrame.new({ :sex => sex, :city => city, :age => age })
    ms = ds.to_multiset_by_split(:sex)
    assert_equal(2, ms.n_datasets)
    assert_equal(%w(f m), ms.datasets.keys.sort)
    assert_equal(6, ms['m'].nrows)
    assert_equal(4, ms['f'].nrows)
    assert_equal(%w(London Paris NY London Paris Tome), ms['m'][:city].to_a)
    assert_equal([34, 33, 35, 36], ms['f'][:age].to_a)
  end

  def test_to_multiset_by_split_multiple
    sex = Daru::Vector.new(%w(m m m m m m m m m m f f f f f f f f f f))
    city = Daru::Vector.new(%w(London London London Paris Paris London London London Paris Paris London London London Paris Paris London London London Paris Paris))
    hair = Daru::Vector.new(%w(blonde blonde black black blonde blonde black black blonde blonde black black blonde blonde black black blonde blonde black black))
    age = Daru::Vector.new([10, 10, 20, 30, 34, 34, 33, 35, 36, 40, 10, 10, 20, 30, 34, 34, 33, 35, 36, 40])
    ds = Daru::DataFrame.new({ 
      :sex => sex, :city => city, :hair => hair, :age => age 
      }, order: [:sex, :city, :hair, :age])
    ms = ds.to_multiset_by_split(:sex, :city, :hair)
    assert_equal(8, ms.n_datasets)
    assert_equal(3, ms[%w(m London blonde)].nrows)
    assert_equal(3, ms[%w(m London blonde)].nrows)
    assert_equal(1, ms[%w(m Paris black)].nrows)
  end

  def test_stratum_proportion
    ds1 = Daru::DataFrame.new({ :q1 => Daru::Vector.new([1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0]) })
    ds2 = Daru::DataFrame.new({ :q1 => Daru::Vector.new([1, 1, 1, 1, 1, 1, 1, 0, 0]) })
    assert_equal(5.0 / 12, ds1[:q1].proportion)
    assert_equal(7.0 / 9, ds2[:q1].proportion)
    ms = Statsample::Multiset.new([:q1])
    ms.add_dataset(:d1, ds1)
    ms.add_dataset(:d2, ds2)
    ss = Statsample::StratifiedSample.new(ms, :d1 => 50, :d2 => 100)
    assert_in_delta(0.655, ss.proportion(:q1), 0.01)
    assert_in_delta(0.345, ss.proportion(:q1, 0), 0.01)
  end

  def test_stratum_scale
    boys = Daru::DataFrame.new({ :test => Daru::Vector.new([50, 55, 60, 62, 62, 65, 67, 67, 70, 70, 73, 73, 75, 78, 78, 80, 85, 90]) })
    girls =Daru::DataFrame.new({ :test => Daru::Vector.new( [70, 70, 72, 72, 75, 75, 78, 78, 80, 80, 82, 82, 85, 85, 88, 88, 90, 90]) })
    ms = Statsample::Multiset.new([:test])
    ms.add_dataset(:boys, boys)
    ms.add_dataset(:girls, girls)
    ss = Statsample::StratifiedSample.new(ms, :boys => 10_000, :girls => 10_000)
    assert_equal(2, ss.strata_number)
    assert_equal(20_000, ss.population_size)
    assert_equal(10_000, ss.stratum_size(:boys))
    assert_equal(10_000, ss.stratum_size(:girls))
    assert_equal(36, ss.sample_size)
    assert_equal(75, ss.mean(:test))
    assert_in_delta(1.45, ss.standard_error_wor(:test), 0.01)
    assert_in_delta(ss.standard_error_wor(:test), ss.standard_error_wor_2(:test), 0.00001)
  end

  def test_each
    xpe = {
      'a' => Daru::Vector.new(%w(a a a a)),
      'b' => Daru::Vector.new(%w(b b b b))
    }
    ype = {
      'a' => Daru::Vector.new([1, 2, 3, 4]),
      'b' => Daru::Vector.new([5, 6, 7, 8])
    }
    zpe = {
      'a' => Daru::Vector.new([10, 11, 12, 13]),
      'b' => Daru::Vector.new([14, 15, 16, 17])
    }
    xp, yp, zp = {}, {}, {}
    @ms.each {|k, ds|
      xp[k] = ds[:x]
      yp[k] = ds[:y]
      zp[k] = ds[:z]
    }
    assert_equal(xpe, xp)
    assert_equal(ype, yp)
    assert_equal(zpe, zp)
  end

  def test_multiset_union_with_block
    r1 = rand
    r2 = rand
    ye = Daru::Vector.new([1 * r1, 2 * r1, 3 * r1, 4 * r1, 5 * r2, 6 * r2, 7 * r2, 8 * r2])

    ze = Daru::Vector.new([10 * r1, 11 * r1, 12 * r1, 13 * r1, 14 * r2, 15 * r2, 16 * r2, 17 * r2])

    ds2 = @ms.union {|k, ds|
      ds[:y].recode!{|v|
        k == 'a' ? v * r1 : v * r2
      }
      ds[:z].recode!{|v|
        k == 'a' ? v * r1 : v * r2
      }
    }
    assert_equal(ye, ds2[:y])
    assert_equal(ze, ds2[:z])
  end

  def test_multiset_union
    r1 = rand
    r2 = rand
    ye = Daru::Vector.new([1 * r1, 2 * r1, 3 * r1, 4 * r1, 5 * r2, 6 * r2, 7 * r2, 8 * r2])
    ze = Daru::Vector.new([10 * r1, 11 * r1, 12 * r1, 13 * r1, 14 * r2, 15 * r2, 16 * r2, 17 * r2])

    @ms.each do |k, ds|
      ds[:y].recode! { |v|
        k == 'a' ? v * r1 : v * r2
      }
      ds[:z].recode! {|v|
        k == 'a' ? v * r1 : v * r2
      }
    end
    ds2 = @ms.union
    assert_equal(ye, ds2[:y])
    assert_equal(ze, ds2[:z])
  end
end
