$:.unshift(File.expand_path("../lib", __FILE__))

require 'chef'

TEST_FILE = "/tmp/whyrun-test.txt"

Chef::Config[:why_run] = true

r = Chef::Resource::File.new(TEST_FILE)
r.content("#{Time.new}")
r.run_action(:create)
