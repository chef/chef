#
# Author:: Stephen Delano (<stephen@ospcode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

require 'spec_helper'

describe Chef::Knife::EnvironmentShow do
  before(:each) do
    @knife = Chef::Knife::EnvironmentShow.new
    @knife.stub!(:msg).and_return true
    @knife.stub!(:output).and_return true
    @knife.stub!(:show_usage).and_return true
    @knife.name_args = [ "production" ]

    @environment = Chef::Environment.new
    @environment.name("production")
    @environment.description("Look at me!")
    Chef::Environment.stub!(:load).and_return @environment
  end

  it "should load the environment" do
    Chef::Environment.should_receive(:load).with("production")
    @knife.run
  end

  it "should pretty print the environment, formatted for display" do
    @knife.should_receive(:format_for_display).with(@environment)
    @knife.should_receive(:output)
    @knife.run
  end

  it "should show usage and exit when no environment name is provided" do
    @knife.name_args = []
    @knife.ui.should_receive(:fatal)
    @knife.should_receive(:show_usage)
    lambda { @knife.run }.should raise_error(SystemExit)
  end
end
