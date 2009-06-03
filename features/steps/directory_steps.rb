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

Then /^a directory named '(.+)' should exist$/ do |dir|
  File.directory?(File.join(tmpdir, dir)).should be(true)  
end

Then /^a directory named '(.+)' should not exist$/ do |dir|
  File.directory?(File.join(tmpdir, dir)).should be(false)
end

Then /^the directory named '(.+)' should be owned by '(.+)'$/ do |dirname, owner|
  uid = Etc.getpwnam(owner).uid
  cstats = File.stat(File.join(tmpdir, dirname))
  cstats.uid.should == uid
end

Then /^the directory named '(.+)' should have octal mode '(.+)'$/ do |dirname, expected_mode|
  cstats = File.stat(File.join(tmpdir, dirname))
  (cstats.mode & 007777).should == expected_mode.oct
end

Then /^the directory named '(.+)' should have decimal mode '(.+)'$/ do |dirname, expected_mode|
  cstats = File.stat(File.join(tmpdir, dirname))
  (cstats.mode & 007777).should == expected_mode.to_i
end
