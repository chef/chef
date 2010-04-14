#!/usr/bin/ruby
#
# A simple load test

$: << File.join(File.dirname(__FILE__), "..", "..", "chef", "lib")
$: << File.join(File.dirname(__FILE__), "..", "..", "chef-solr", "lib")

require 'chef'
require 'chef/client'

client = Chef::Client.new
client.run_ohai
301.upto(1000) do |i|
  client.node = nil
  client.build_node("node#{i}", true)
  puts "node#{i}"
  client.node.cdb_save
end
