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

###
# When
###
When /^I run the chef\-client$/ do
  log_level = ENV["LOG_LEVEL"] ? ENV["LOG_LEVEL"] : "error"
  status = Chef::Mixin::Command.popen4(
    "chef-client -l #{log_level} -c #{File.expand_path(File.join(File.dirname(__FILE__), '..', 'data', 'config', 'client.rb'))}", :waitlast => true) do |p, i, o, e|
    i.close
    @stdout = o.gets(nil)
    @stderr = e.gets(nil)
  end
  @status = status
end

###
# Then
###
Then /^the run should exit '(.+)'$/ do |exit_code|
  begin
    @status.exitstatus.should eql(exit_code.to_i)
  rescue 
    print_output
    raise
  end
  print_output if ENV["LOG_LEVEL"] == "debug"
end

def print_output
  puts "--- run stdout:"
  puts @stdout
  puts "--- run stderr"
  puts @stderr
end

Then /^stdout should have '(.+)'$/ do |to_match|
  @stdout.should match(/#{to_match}/m)
end
