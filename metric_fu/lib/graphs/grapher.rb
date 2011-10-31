module MetricFu
  class Grapher
    def initialize
      self.class.require_graphing_gem
    end

    def self.require_graphing_gem
      # to be overridden by charting engines
    end
  end
end