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

describe Chef::Knife::EnvironmentCreate do
  before(:each) do
    @knife = Chef::Knife::EnvironmentCreate.new
    allow(@knife).to receive(:msg).and_return true
    allow(@knife).to receive(:output).and_return true
    allow(@knife).to receive(:show_usage).and_return true
    @knife.name_args = [ "production" ]

    @environment = Chef::Environment.new
    allow(@environment).to receive(:save)

    allow(Chef::Environment).to receive(:new).and_return @environment
    allow(@knife).to receive(:edit_data).and_return @environment
  end

  describe "run" do
    it "should create a new environment" do
      expect(Chef::Environment).to receive(:new)
      @knife.run
    end

    it "should set the environment name" do
      expect(@environment).to receive(:name).with("production")
      @knife.run
    end

    it "should not print the environment" do
      expect(@knife).not_to receive(:output)
      @knife.run
    end

    it "should prompt you to edit the data" do
      expect(@knife).to receive(:edit_data).with(@environment, object_class: Chef::Environment)
      @knife.run
    end

    it "should save the environment" do
      expect(@environment).to receive(:save)
      @knife.run
    end

    it "should show usage and exit when no environment name is provided" do
      @knife.name_args = [ ]
      expect(@knife.ui).to receive(:fatal)
      expect(@knife).to receive(:show_usage)
      expect { @knife.run }.to raise_error(SystemExit)
    end

    describe "with --description" do
      before(:each) do
        @knife.config[:description] = "This is production"
      end

      it "should set the description" do
        expect(@environment).to receive(:description).with("This is production")
        @knife.run
      end
    end

    describe "with --print-after" do
      before(:each) do
        @knife.config[:print_after] = true
      end

      it "should pretty print the environment, formatted for display" do
        expect(@knife).to receive(:output).with(@environment)
        @knife.run
      end
    end
  end
end
