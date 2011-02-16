#!/usr/bin/ruby
#
# A simple load test

$: << File.join(File.dirname(__FILE__), "..", "..", "chef", "lib")
$: << File.join(File.dirname(__FILE__), "..", "..", "chef-solr", "lib")

require 'chef'
require 'chef/client'
require 'tmpdir'

unless ARGV[0] && ARGV[1] && ARGV[2] 
  puts "USAGE: ./node-load-test.rb [nodes] [interval] [splay] (json_attribs)"
  exit 10
end

Chef::Config.from_file("/etc/chef/client.rb")
json_attrs = Hash.new
if ARGV[3]
  json_attrs = Chef::JSONCompat.from_json(IO.read(ARGV[3]))
end
Chef::Log.level = :info
processes = Array.new
STDOUT.sync = true
STDERR.sync = true

Kernel.srand

0.upto(ARGV[0].to_i) do |i|
  cid = Process.fork
  if cid
    puts "Spawned #{cid}"
    processes << cid 
  else
    dir = File.join(Dir.tmpdir, "chef-#{i.to_s}")
    Dir.mkdir(dir) unless File.exists?(dir)
    Chef::Config[:file_store_path] = File.join(dir, "file_store")
    Chef::Config[:file_cache_path] = File.join(dir, "cache")
    Chef::Config[:client_key] = File.join(dir, "client.pem")
    Chef::Config[:splay] = ARGV[2] 
    Chef::Config[:interval] = ARGV[1] 
    Chef::Config[:log_location] = File.join(dir, "client.log")
    Chef::Config[:node_name] = "test#{i}"
    Chef::Log.info("Starting test#{i}")
    loop do 
      begin
        c = Chef::Client.new
        c.node_name = "test#{i}"
        c.safe_name = "test#{i}"
        c.json_attribs = json_attrs
        c.run
        
        Chef::Log.info("Child #{i} is finished")
        Chef::Log.info("Sleeping for #{Chef::Config[:interval]} interval seconds")
        sleep Chef::Config[:interval].to_i

        splay = rand Chef::Config[:splay].to_i
        Chef::Log.info("Splay sleep #{splay} seconds")
        sleep splay
      rescue
        Chef::Log.info("Child #{i} died!")
        Chef::Log.info("Sleeping for #{Chef::Config[:interval]} interval seconds")
        sleep Chef::Config[:interval].to_i
        retry
      end
    end
    puts "Child #{i} is exiting!"
    exit 0
  end
end

Signal.trap("INT") do
  processes.each do |pid|
    Process.kill("INT", pid)
  end
  Process.waitall
  puts "Killed all children - Exiting!"
  exit 0
end

while(true) do
  sleep 1
end

