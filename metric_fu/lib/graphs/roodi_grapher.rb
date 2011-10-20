module MetricFu
  class RoodiGrapher < Grapher
    attr_accessor :roodi_count, :labels

    def initialize
      super
      @roodi_count = []
      @labels = {}
    end

    def get_metrics(metrics, date)
      if metrics && metrics[:roodi]
        @roodi_count.push(metrics[:roodi][:problems].size)
        @labels.update( { @labels.size => date })
      end
    end
  end
end
