#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'etc'

###
# Given
###

Given /^we have an empty file named '(.+)'$/ do |filename|
  filename = File.new(File.join(tmpdir, filename), 'w')
  filename.close
end

Given /^we have an empty file named '(.+)' in the client cache$/ do |filename|
  cache_dir = File.expand_path(File.join(File.dirname(__FILE__), "..", "data", "tmp", "cache"))
  filename = File.new(File.join(cache_dir, filename), 'w')
  filename.close
end

Given /^we have the atime\/mtime of '(.+)'$/ do |filename|
  @mtime = File.mtime(File.join(tmpdir, filename))
  @atime = File.atime(File.join(tmpdir, filename))
end

####
# Then
####

Then /^a file named '(.+)' should exist$/ do |filename|
  File.exists?(File.join(tmpdir, filename)).should be(true)
end

Then /^a file named '(.+)' should not exist$/ do |filename|
  File.exists?(File.join(tmpdir, filename)).should be(false)
end

#currently using absolute path (specified in recipe execute_commands/recipes/umask.rb)
Then /^'(.+)' should exist and raise error when copying$/ do |filename|
  File.exists?(filename).should be(true)
  lambda{copy(filename, filename + "_copy", false)}.should raise_error()
  File.delete(filename)
end


Then /^the (.)time of '(.+)' should be different$/ do |time_type, filename|
  case time_type
  when "m"
    current_mtime = File.mtime(File.join(tmpdir, filename))
    current_mtime.should_not == @mtime
  when "a"
    current_atime = File.atime(File.join(tmpdir, filename))
    current_atime.should_not == @atime
  end
end

Then /^a file named '(.+)' should contain '(.+)'$/ do |filename, contents|
  file = IO.read(File.join(tmpdir, filename))
  file.should =~ /#{contents}/m
end

Then /^a file named '(.+)' should be from the '(.+)' specific directory$/ do |filename, specificity|
  file = IO.read(File.join(tmpdir, filename))
  file.should == "#{specificity}\n"
end

Then /^a file named '(.+)' should contain '(.+)' only '(.+)' time$/ do |filename, string, count|
  seen_count = 0
  IO.foreach(File.join(tmpdir, filename)) do |line|
    if line =~ /#{string}/
      seen_count += 1
    end
  end
  seen_count.should == count.to_i
end

Then /^the file named '(.+)' should be owned by '(.+)'$/ do |filename, owner|
  uid = Etc.getpwnam(owner).uid
  cstats = File.stat(File.join(tmpdir, filename))
  cstats.uid.should == uid
end

Then /^the file named '(.+)' should have octal mode '(.+)'$/ do |filename, expected_mode|
  cstats = File.stat(File.join(tmpdir, filename))
  (cstats.mode & 007777).should == expected_mode.oct
end

Then /^the file named '(.+)' should have decimal mode '(.+)'$/ do |filename, expected_mode|
  cstats = File.stat(File.join(tmpdir, filename))
  (cstats.mode & 007777).should == expected_mode.to_i
end

