unless 0.respond_to?(:fdiv)
  class Numeric
    def fdiv(other)
      to_f / other
    end
  end
end