#
# Author:: Stephen Delano (<stephen@ospcode.com>)
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

require "knife_spec_helper"

describe Chef::Knife::EnvironmentEdit do
  before(:each) do
    @knife = Chef::Knife::EnvironmentEdit.new
    allow(@knife.ui).to receive(:msg).and_return true
    allow(@knife.ui).to receive(:output).and_return true
    allow(@knife.ui).to receive(:show_usage).and_return true
    @knife.name_args = [ "production" ]

    @environment = Chef::Environment.new
    @environment.name("production")
    @environment.description("Please edit me")
    allow(@environment).to receive(:save).and_return true
    allow(Chef::Environment).to receive(:load).and_return @environment
    allow(@knife.ui).to receive(:edit_data).and_return @environment
  end

  it "should load the environment" do
    expect(Chef::Environment).to receive(:load).with("production")
    @knife.run
  end

  it "should let you edit the environment" do
    expect(@knife.ui).to receive(:edit_data).with(@environment, object_class: Chef::Environment)
    @knife.run
  end

  it "should save the edited environment data" do
    pansy = Chef::Environment.new

    @environment.name("new_environment_name")
    expect(@knife.ui).to receive(:edit_data).with(@environment, object_class: Chef::Environment).and_return(pansy)
    expect(pansy).to receive(:save)
    @knife.run
  end

  it "should not save the unedited environment data" do
    expect(@environment).not_to receive(:save)
    @knife.run
  end

  it "should not print the environment" do
    expect(@knife).not_to receive(:output)
    @knife.run
  end

  it "should show usage and exit when no environment name is provided" do
    @knife.name_args = []
    expect(@knife).to receive(:show_usage)
    expect { @knife.run }.to raise_error(SystemExit)
  end

  describe "with --print-after" do
    it "should pretty print the environment, formatted for display" do
      @knife.config[:print_after] = true
      expect(@knife.ui).to receive(:output).with(@environment)
      @knife.run
    end
  end
end
