module MetricFu
  class StatsGrapher < Grapher
    attr_accessor :loc_counts, :lot_counts, :labels

    def initialize
      super
      self.loc_counts = []
      self.lot_counts = []
      self.labels = {}
    end

    def get_metrics(metrics, date)
      if metrics && metrics[:stats]
        self.loc_counts.push(metrics[:stats][:codeLOC].to_i)
        self.lot_counts.push(metrics[:stats][:testLOC].to_i)
        self.labels.update( { self.labels.size => date })
      end
    end
  end
end
