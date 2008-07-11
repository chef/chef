#!/usr/bin/env ruby
#
# Create a users index, based on /etc/passwd

require 'etc'
require File.join(File.dirname(__FILE__), "..", "lib", "chef")

Chef::Config[:log_level] = :info
r = Chef::REST.new("http://localhost:4000")

users = Array.new
Etc.passwd do |passwd|
  Chef::Log.info("Ensuring we have #{passwd.name}")
  r.post_rest("search/user/entries",
    {
      :id => passwd.name,
      :name => passwd.name,
      :uid => passwd.uid,
      :gid => passwd.gid,
      :gecos => passwd.gecos,
      :dir => passwd.dir,
      :shell => passwd.shell,
      :change => passwd.change,
      :expire => passwd.expire
    }
  )
end
