module Statsample
  # This class recognizes what terms are numeric
  # and accordingly forms groups which are fed to Formula
  # Once they are parsed with Formula, they are combined back
  class FormulaWrapper
    attr_reader :tokens, :y, :canonical_tokens

    def initialize(formula, df)
      @df = df
      # @y store the LHS term that is name of vector to be predicted
      # @tokens store the RHS terms of the formula
      @y, *@tokens = split_to_tokens(formula)
      @tokens = @tokens.uniq.sort
      manage_constant_term
      @canonical_tokens = parse_formula
    end

    def canonical_to_s
      canonical_tokens.join '+'
    end

    def parse_formula
      groups = split_to_groups
      # TODO: An enhancement
      # Right now x:c appears as c:x
      groups.each { |k, v| groups[k] = strip_numeric v, k }
      groups.each { |k, v| groups[k] = Formula.new(v).canonical_tokens }
      groups.flat_map { |k, v| add_numeric v, k }
    end

    private

    def manage_constant_term
      @tokens.unshift Token.new('1') unless
        @tokens.include?(Token.new('1')) ||
        @tokens.include?(Token.new('0'))
      @tokens.delete Token.new('0')
    end

    def split_to_groups
      @tokens.group_by { |t| extract_numeric t }
    end

    def add_numeric(tokens, numeric)
      tokens.map do |t|
        terms = t.interact_terms + numeric
        if terms == ['1']
          Token.new('1')
        else
          terms = terms.reject { |i| i == '1' }
          Token.new terms.join(':'), t.full
        end
      end
    end

    def strip_numeric(tokens, numeric)
      tokens.map do |t|
        terms = t.interact_terms - numeric
        terms = ['1'] if terms.empty?
        Token.new terms.join(':')
      end
    end

    def extract_numeric(token)
      terms = token.interact_terms
      return [] if terms == ['1']
      terms.reject { |t| @df[t].category? }
    end

    def split_to_tokens(formula)
      formula = formula.gsub(/\s+/, '')
      lhs_term, rhs = formula.split '~'
      rhs_terms = rhs.split '+'
      ([lhs_term] + rhs_terms).map { |t| Token.new t }
    end
  end

  # To process formula language
  class Formula
    attr_reader :tokens, :canonical_tokens

    def initialize(tokens)
      @tokens = tokens
      @canonical_tokens = parse_formula
    end

    def canonical_to_s
      canonical_tokens.join '+'
    end

    # private
    # TODO: Uncomment private after debuggin

    def parse_formula
      @tokens.inject([]) do |acc, token|
        acc + add_non_redundant_elements(token, acc)
      end
    end

    def add_non_redundant_elements(token, result_so_far)
      return [token] if token.value == '1'
      tokens = token.expand
      result_so_far = result_so_far.flat_map(&:expand)
      tokens -= result_so_far
      contract_if_possible tokens
    end

    def contract_if_possible(tokens)
      tokens.combination(2).each do |a, b|
        result = a.add b
        next unless result
        tokens.delete a
        tokens.delete b
        tokens << result
        return contract_if_possible tokens
      end
      tokens.sort
    end
  end

  # To encapsulate interaction as well as non-interaction terms
  class Token
    attr_reader :value, :full, :interact_terms

    def initialize(value, full = true)
      @interact_terms = value.include?(':') ? value.split(':') : [value]
      @full = coerce_full full
    end

    def value
      interact_terms.join(':')
    end

    def size
      # TODO: Return size 1 for value '1' also
      # CAn't do this at the moment because have to make
      # changes in sorting first
      value == '1' ? 0 : interact_terms.size
    end

    def add(other)
      # ANYTHING + FACTOR- : ANYTHING = FACTOR : ANYTHING
      # ANYTHING + ANYTHING : FACTOR- = ANYTHING : FACTOR
      if size > other.size
        other.add self

      elsif other.size == 2 &&
            size == 1 &&
            other.interact_terms.last == value &&
            other.full.last == full.first &&
            other.full.first == false
        Token.new(
          "#{other.interact_terms.first}:#{value}",
          [true, other.full.last]
        )

      elsif other.size == 2 &&
            size == 1 &&
            other.interact_terms.first == value &&
            other.full.first == full.first &&
            other.full.last == false
        Token.new(
          "#{value}:#{other.interact_terms.last}",
          [other.full.first, true]
        )

      elsif value == '1' &&
            other.size == 1
        Token.new(other.value, true)
      end
    end

    def ==(other)
      value == other.value &&
        full == other.full
    end

    alias eql? ==

    def hash
      value.hash ^ full.hash
    end

    def <=>(other)
      size <=> other.size
    end

    def to_s
      interact_terms
        .zip(full)
        .map { |t, f| f ? t : t + '(-)' }
        .join ':'
    end

    def expand
      case size
      when 0
        [self]
      when 1
        [Token.new('1'), Token.new(value, false)]
      when 2
        a, b = interact_terms
        [Token.new('1'), Token.new(a, false), Token.new(b, false),
         Token.new(a + ':' + b, [false, false])]
      end
    end

    def to_df(df)
      case size
      when 1
        if df[value].category?
          df[value].contrast_code full: full.first
        else
          Daru::DataFrame.new value => df[value].to_a
        end
      when 2
        to_df_when_interaction(df)
      end
    end

    private

    def coerce_full(value)
      if value.is_a? Array
        value + Array.new((@interact_terms.size - value.size), true)
      else
        [value] * @interact_terms.size
      end
    end

    def to_df_when_interaction(df)
      case interact_terms.map { |t| df[t].category? }
      when [true, true]
        df.interact_code(interact_terms, full)
      when [false, false]
        to_df_numeric_interact_with_numeric df
      when [true, false]
        to_df_category_interact_with_numeric df
      when [false, true]
        to_df_numeric_interact_with_category df
      end
    end

    def to_df_numeric_interact_with_numeric(df)
      Daru::DataFrame.new value => (df[interact_terms.first] *
        df[interact_terms.last]).to_a
    end

    def to_df_category_interact_with_numeric(df)
      a, b = interact_terms
      Daru::DataFrame.new(
        df[a].contrast_code(full: full.first)
          .map { |dv| ["#{dv.name}:#{b}", (dv * df[b]).to_a] }
          .to_h
      )
    end

    def to_df_numeric_interact_with_category(df)
      a, b = interact_terms
      Daru::DataFrame.new(
        df[b].contrast_code(full: full.last)
          .map { |dv| ["#{a}:#{dv.name}", (dv * df[a]).to_a] }
          .to_h
      )
    end
  end
end
