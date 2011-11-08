unless 0.respond_to?(:fdiv)
  class Numeric
    def fdiv(other)
      to_f / other
    end
  end
end

# String elements referenced with [] <= 1.8.6 return a Fixnum. Cheat to allow
# for the simpler "test"[2].ord construct
class Numeric 
  def ord
    return self
  end
end
