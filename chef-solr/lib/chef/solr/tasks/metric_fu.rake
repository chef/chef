begin
    require 'metric_fu'
	MetricFu::Configuration.run do |config|
        #define which metrics you want to use
        config.metrics  = [:churn, :saikuro, :stats, :flog, :flay]
        config.graphs   = [:flog, :flay, :stats]
        # ...
    end
rescue LoadError
end
