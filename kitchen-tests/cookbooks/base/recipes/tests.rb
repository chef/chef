#
# Cookbook Name:: webapp
# Recipe:: default
#
# Copyright (C) 2014
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
file "/tmp/chef-test-\xFDmlaut" do
  content "testing illegal UTF-8 char in the filename"
end
