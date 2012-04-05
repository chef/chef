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

describe Chef::Knife::EnvironmentCreate do
  before(:each) do
    @knife = Chef::Knife::EnvironmentCreate.new
    @knife.stub!(:msg).and_return true
    @knife.stub!(:output).and_return true
    @knife.stub!(:show_usage).and_return true
    @knife.name_args = [ "production" ]

    @environment = Chef::Environment.new
    @environment.stub!(:save)

    Chef::Environment.stub!(:new).and_return @environment
    @knife.stub!(:edit_data).and_return @environment
  end

  describe "run" do
    it "should create a new environment" do
      Chef::Environment.should_receive(:new)
      @knife.run
    end

    it "should set the environment name" do
      @environment.should_receive(:name).with("production")
      @knife.run
    end

    it "should not print the environment" do
      @knife.should_not_receive(:output)
      @knife.run
    end

    it "should prompt you to edit the data" do
      @knife.should_receive(:edit_data).with(@environment)
      @knife.run
    end

    it "should save the environment" do
      @environment.should_receive(:save)
      @knife.run
    end

    it "should show usage and exit when no environment name is provided" do
      @knife.name_args = [ ]
      @knife.ui.should_receive(:fatal)
      @knife.should_receive(:show_usage)
      lambda { @knife.run }.should raise_error(SystemExit)
    end

    describe "with --description" do
      before(:each) do
        @knife.config[:description] = "This is production"
      end

      it "should set the description" do
        @environment.should_receive(:description).with("This is production")
        @knife.run
      end
    end

    describe "with --print-after" do
      before(:each) do
        @knife.config[:print_after] = true
      end

      it "should pretty print the environment, formatted for display" do
        @knife.should_receive(:output).with(@environment)
        @knife.run
      end
    end
  end
end
