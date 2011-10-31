require 'rake'
namespace :metrics do
  desc "Generate all metrics reports"
  task :all do
    MetricFu::Configuration.run {}
    MetricFu.metrics.each {|metric| MetricFu.report.add(metric) }
    MetricFu.report.save_output(MetricFu.report.to_yaml,
                                MetricFu.base_directory,
                                "report.yml")
    MetricFu.report.save_output(MetricFu.report.to_yaml,
                                MetricFu.data_directory,
                                "#{Time.now.strftime("%Y%m%d")}.yml")
    MetricFu.report.save_templatized_report

    MetricFu.graphs.each {|graph| MetricFu.graph.add(graph, MetricFu.graph_engine) }
    MetricFu.graph.generate

    if MetricFu.report.open_in_browser?
      MetricFu.report.show_in_browser(MetricFu.output_directory)
    end
  end
end
