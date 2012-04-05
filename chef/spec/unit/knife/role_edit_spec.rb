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

require 'spec_helper'

describe Chef::Knife::RoleEdit do
  before(:each) do
    Chef::Config[:node_name]  = "webmonkey.example.com"
    @knife = Chef::Knife::RoleEdit.new
    @knife.config[:print_after] = nil
    @knife.name_args = [ "adam" ]
    @knife.ui.stub!(:output).and_return(true)
    @role = Chef::Role.new()
    @role.stub!(:save)
    Chef::Role.stub!(:load).and_return(@role)
    @knife.ui.stub!(:edit_data).and_return(@role)
    @knife.ui.stub!(:msg)
  end

  describe "run" do
    it "should load the role" do
      Chef::Role.should_receive(:load).with("adam").and_return(@role)
      @knife.run
    end

    it "should edit the role data" do
      @knife.ui.should_receive(:edit_data).with(@role)
      @knife.run
    end

    it "should save the edited role data" do
      pansy = Chef::Role.new

      @role.name("new_role_name")
      @knife.ui.should_receive(:edit_data).with(@role).and_return(pansy)
      pansy.should_receive(:save)
      @knife.run
    end

    it "should not save the unedited role data" do
      pansy = Chef::Role.new

      @knife.ui.should_receive(:edit_data).with(@role).and_return(pansy)
      pansy.should_not_receive(:save)
      @knife.run

    end

    it "should not print the role" do
      @knife.ui.should_not_receive(:output)
      @knife.run
    end

    describe "with -p or --print-after" do
      it "should pretty print the role, formatted for display" do
        @knife.config[:print_after] = true
        @knife.ui.should_receive(:output).with(@role)
        @knife.run
      end
    end
  end
end


