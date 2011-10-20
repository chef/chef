module MetricFu
  class ReekGrapher < Grapher
    attr_accessor :reek_count, :labels

    def initialize
      super
      @reek_count = {}
      @labels = {}
    end

    def get_metrics(metrics, date)
      if metrics && metrics[:reek]
        counter = @labels.size
        @labels.update( { @labels.size => date })

        metrics[:reek][:matches].each do |reek_chunk|
          reek_chunk[:code_smells].each do |code_smell|
            # speaking of code smell...
            @reek_count[code_smell[:type]] = [] if @reek_count[code_smell[:type]].nil?
            if @reek_count[code_smell[:type]][counter].nil?
              @reek_count[code_smell[:type]][counter] = 1
            else
              @reek_count[code_smell[:type]][counter] += 1
            end
          end
        end
      end
    end
  end
end
