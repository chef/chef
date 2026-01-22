#
# Cookbook:: end_to_end
# Recipe:: tests
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
#

#
# this file is for random tests to check specific chef-client internal functionality
#

file "/tmp/chef-test-ümlauts" do
  content "testing UTF-8 char in the filename"
end

# this caught a regression in 12.14.70 before it was released when i
# ran it in lamont-ci, so added the test here so everyone else other than
# me gets coverage for this as well.
# cspell:disable-next-line
file "/tmp/chef-test-\xFCmlaut" do
  content "testing illegal UTF-8 char in the filename"
end

node["network"]["interfaces"].each do |interface_data|
  interface = interface_data[0]
  sysctl_param "net/ipv4/conf/#{interface}/rp_filter" do
    value 0
    ignore_failure true
  end
end
