require 'rubygems'
require 'spec'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'chef'
require 'chef/solr'
require 'chef/solr/index'
require 'chef/solr/query'

Spec::Runner.configure do |config|
  
end
