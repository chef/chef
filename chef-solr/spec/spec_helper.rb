require 'rubygems'
require 'spec'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', 'chef', 'lib'))
require 'chef'
require 'chef/solr'
require 'chef/solr/index'
require 'chef/solr/query'

CHEF_SOLR_SPEC_DATA = File.expand_path(File.dirname(__FILE__) + "/data/")

Spec::Runner.configure do |config|
  
end
