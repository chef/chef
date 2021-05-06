#
# Author:: Adam Jacob (<adam@chef.io>)
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

describe Chef::Knife::RoleCreate do
  before(:each) do
    Chef::Config[:node_name] = "webmonkey.example.com"
    @knife = Chef::Knife::RoleCreate.new
    @knife.config = {
      description: nil,
    }
    @knife.name_args = [ "adam" ]
    allow(@knife).to receive(:output).and_return(true)
    @role = Chef::Role.new
    allow(@role).to receive(:save)
    allow(Chef::Role).to receive(:new).and_return(@role)
    allow(@knife).to receive(:edit_data).and_return(@role)
    @stdout = StringIO.new
    allow(@knife.ui).to receive(:stdout).and_return(@stdout)
  end

  describe "run" do
    it "should create a new role" do
      expect(Chef::Role).to receive(:new).and_return(@role)
      @knife.run
    end

    it "should set the role name" do
      expect(@role).to receive(:name).with("adam")
      @knife.run
    end

    it "should not print the role" do
      expect(@knife).not_to receive(:output)
      @knife.run
    end

    it "should allow you to edit the data" do
      expect(@knife).to receive(:edit_data).with(@role, object_class: Chef::Role)
      @knife.run
    end

    it "should save the role" do
      expect(@role).to receive(:save)
      @knife.run
    end

    describe "with -d or --description" do
      it "should set the description" do
        @knife.config[:description] = "All is bob"
        expect(@role).to receive(:description).with("All is bob")
        @knife.run
      end
    end

    describe "with -p or --print-after" do
      it "should pretty print the node, formatted for display" do
        @knife.config[:print_after] = true
        expect(@knife).to receive(:output).with(@role)
        @knife.run
      end
    end
  end
end
