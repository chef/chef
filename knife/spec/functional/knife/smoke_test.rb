#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require "spec_helper"

describe "knife smoke tests" do

  # Since our specs load all code, there could be a case where knife does not
  # run correctly b/c of a missing require, but is not caught by other tests.
  #
  # We run `knife -v` to verify that knife at least loads all its code.
  it "can run and print its version" do
    knife_path = File.expand_path("../../bin/knife", CHEF_SPEC_DATA)
    knife_cmd = Mixlib::ShellOut.new("#{knife_path} -v")
    knife_cmd.run_command
    knife_cmd.error!
    expect(knife_cmd.stdout).to include(Chef::VERSION)
  end

  it "can run and show help" do
    knife_path = File.expand_path("../../bin/knife", CHEF_SPEC_DATA)
    knife_cmd = Mixlib::ShellOut.new("#{knife_path} --help")
    knife_cmd.run_command
    knife_cmd.error!
    expect(knife_cmd.stdout).to include("Usage")
  end
end
