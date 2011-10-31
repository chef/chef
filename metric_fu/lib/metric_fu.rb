require 'rake'
require 'yaml'
begin
  require 'active_support/core_ext/object/to_json'
  require 'active_support/core_ext/object/blank'
  require 'active_support/inflector'
rescue LoadError
  require 'activesupport'
end

# Load a few things to make our lives easier elsewhere.
module MetricFu
  LIB_ROOT = File.dirname(__FILE__)
end
base_dir         = File.join(MetricFu::LIB_ROOT, 'base')
generator_dir    = File.join(MetricFu::LIB_ROOT, 'generators')
template_dir     = File.join(MetricFu::LIB_ROOT, 'templates')
graph_dir        = File.join(MetricFu::LIB_ROOT, 'graphs')

# We need to require these two things first because our other classes
# depend on them.
require File.join(base_dir, 'report')
require File.join(base_dir, 'generator')
require File.join(base_dir, 'graph')
require File.join(base_dir, 'scoring_strategies')

# prevent the task from being run multiple times.
unless Rake::Task.task_defined? "metrics:all"
  # Load the rakefile so users of the gem get the default metric_fu task
  load File.join(MetricFu::LIB_ROOT, '..', 'tasks', 'metric_fu.rake')
end

# Now load everything else that's in the directory
Dir[File.join(base_dir, '*.rb')].each{|l| require l }
Dir[File.join(generator_dir, '*.rb')].each {|l| require l }
Dir[File.join(template_dir, 'standard/*.rb')].each {|l| require l}
Dir[File.join(template_dir, 'awesome/*.rb')].each {|l| require l}
require graph_dir + "/grapher"
Dir[File.join(graph_dir, '*.rb')].each {|l| require l}
Dir[File.join(graph_dir, 'engines', '*.rb')].each {|l| require l}
