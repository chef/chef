begin
    require 'metric_fu'
	
    MetricFu::Configuration.run do |config|
        #define which metrics you want to use
        config.metrics  = [:churn, :saikuro, :flog, :flay, :reek, :roodi, :rcov]
        config.graphs   = [:flog, :flay, :stats, :reek, :roodi, :rcov] 
    end
rescue LoadError
end
