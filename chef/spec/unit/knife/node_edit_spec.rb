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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Knife::NodeEdit do
  before(:each) do
    @knife = Chef::Knife::NodeEdit.new
    @knife.config = {
      :attribute => nil,
      :print_after => nil
    }
    @knife.name_args = [ "adam" ]
    @knife.stub!(:output).and_return(true)
    @node = Chef::Node.new() 
    @node.stub!(:save)
    Chef::Node.stub!(:load).and_return(@node)
    @knife.stub!(:edit_data).and_return(@node)
  end

  describe "run" do
    it "should load the node" do
      Chef::Node.should_receive(:load).with("adam").and_return(@node)
      @knife.run
    end

    it "should edit the node data" do
      @knife.should_receive(:edit_data).with(@node)
      @knife.run
    end

    it "should save the edited node data" do
      pansy = Chef::Node.new
      @knife.should_receive(:edit_data).with(@node).and_return(pansy)
      pansy.should_receive(:save)
      @knife.run
    end

    it "should not print the node" do
      @knife.should_not_receive(:output).with("poop")
      @knife.run
    end

    describe "with -p or --print-after" do
      it "should pretty print the node, formatted for display" do
        @knife.config[:print_after] = true
        @knife.should_receive(:format_for_display).with(@node).and_return("poop")
        @knife.should_receive(:output).with("poop")
        @knife.run
      end
    end
  end
end

