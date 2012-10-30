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

describe Chef::Knife::NodeRunListRemove do
  before(:each) do
    Chef::Config[:node_name]  = "webmonkey.example.com"
    @knife = Chef::Knife::NodeRunListRemove.new
    @knife.config[:print_after] = nil
    @knife.name_args = [ "adam", "role[monkey]" ]
    @node = Chef::Node.new()
    @node.name("knifetest-node")
    @node.run_list << "role[monkey]"
    @node.stub!(:save).and_return(true)

    @knife.ui.stub!(:output).and_return(true)
    @knife.ui.stub!(:confirm).and_return(true)

    Chef::Node.stub!(:load).and_return(@node)
  end

  describe "run" do
    it "should load the node" do
      Chef::Node.should_receive(:load).with("adam").and_return(@node)
      @knife.run
    end

    it "should remove the item from the run list" do
      @knife.run
      @node.run_list[0].should_not == 'role[monkey]'
    end

    it "should save the node" do
      @node.should_receive(:save).and_return(true)
      @knife.run
    end

    it "should print the run list" do
      @knife.config[:print_after] = true
      @knife.ui.should_receive(:output).with({ "knifetest-node" => { 'run_list' => [] } })
      @knife.run
    end

    describe "run with a list of roles and recipes" do
      it "should remove the items from the run list" do
        @node.run_list << 'role[monkey]'
        @node.run_list << 'recipe[duck::type]'
        @knife.name_args = [ 'adam', 'role[monkey],recipe[duck::type]' ]
        @knife.run
        @node.run_list.should_not include('role[monkey]')
        @node.run_list.should_not include('recipe[duck::type]')
      end
    end
  end
end



