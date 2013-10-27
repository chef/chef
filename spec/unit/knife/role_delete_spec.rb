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

describe Chef::Knife::RoleDelete do
  before(:each) do
    Chef::Config[:node_name]  = "webmonkey.example.com"
    @knife = Chef::Knife::RoleDelete.new
    @knife.config = {
      :print_after => nil
    }
    @knife.name_args = [ "adam" ]
    @knife.stub!(:output).and_return(true)
    @knife.stub!(:confirm).and_return(true)
    @role = Chef::Role.new()
    @role.stub!(:destroy).and_return(true)
    Chef::Role.stub!(:load).and_return(@role)
    @stdout = StringIO.new
    @knife.ui.stub!(:stdout).and_return(@stdout)
  end

  describe "run" do
    it "should confirm that you want to delete" do
      @knife.should_receive(:confirm)
      @knife.run
    end

    it "should load the Role" do
      Chef::Role.should_receive(:load).with("adam").and_return(@role)
      @knife.run
    end

    it "should delete the Role" do
      @role.should_receive(:destroy).and_return(@role)
      @knife.run
    end

    it "should not print the Role" do
      @knife.should_not_receive(:output)
      @knife.run
    end

    describe "with -p or --print-after" do
      it "should pretty print the Role, formatted for display" do
        @knife.config[:print_after] = true
        @knife.should_receive(:output)
        @knife.run
      end
    end
  end
end
