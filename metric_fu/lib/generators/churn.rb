module MetricFu

  class Churn < Generator

    def initialize(options={})
      super
    end

    def emit
      @output = `churn --yaml`
      yaml_start = @output.index("---")
      @output = @output[yaml_start...@output.length] if yaml_start
    end

    def analyze
      if @output.match(/Churning requires a subversion or git repo/)
        @churn = [:churn => {}]
      else
        @churn = YAML::load(@output)
      end
    end

    def to_h
      {:churn => @churn[:churn]}
    end
  end

end
