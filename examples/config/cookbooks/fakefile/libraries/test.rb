class Testit
  class << self
    def bork
      Chef::Log.error("Bork bork bork")
    end
  end
end