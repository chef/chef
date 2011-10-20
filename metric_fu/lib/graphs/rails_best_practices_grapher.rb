module MetricFu
  class RailsBestPracticesGrapher < Grapher
    attr_accessor :rails_best_practices_count, :labels

    def initialize
      super
      @rails_best_practices_count = []
      @labels = {}
    end

    def get_metrics(metrics, date)
      if metrics && metrics[:rails_best_practices]
        size = (metrics[:rails_best_practices][:problems] || []).size
        @rails_best_practices_count.push(size)
        @labels.update( { @labels.size => date })
      end
    end
  end
end
