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

describe Chef::Knife::NodeDelete do
  before(:each) do
    Chef::Config[:node_name] = "webmonkey.example.com"
    @knife = Chef::Knife::NodeDelete.new
    @knife.config = {
      print_after: nil,
    }
    @knife.name_args = %w{ adam ben }
    allow(@knife).to receive(:output).and_return(true)
    allow(@knife).to receive(:confirm).and_return(true)

    @adam_node = Chef::Node.new
    @ben_node = Chef::Node.new
    allow(@ben_node).to receive(:destroy).and_return(true)
    allow(@adam_node).to receive(:destroy).and_return(true)
    allow(Chef::Node).to receive(:load).with("adam").and_return(@adam_node)
    allow(Chef::Node).to receive(:load).with("ben").and_return(@ben_node)

    @stdout = StringIO.new
    allow(@knife.ui).to receive(:stdout).and_return(@stdout)
  end

  describe "run" do
    it "should confirm that you want to delete" do
      expect(@knife).to receive(:confirm)
      @knife.run
    end

    it "should load the nodes" do
      expect(Chef::Node).to receive(:load).with("adam").and_return(@adam_node)
      expect(Chef::Node).to receive(:load).with("ben").and_return(@ben_node)
      @knife.run
    end

    it "should delete the nodes" do
      expect(@adam_node).to receive(:destroy).and_return(@adam_node)
      expect(@ben_node).to receive(:destroy).and_return(@ben_node)
      @knife.run
    end

    it "should not print the node" do
      expect(@knife).not_to receive(:output).with("poop")
      @knife.run
    end

    describe "with -p or --print-after" do
      it "should pretty print the node, formatted for display" do
        @knife.config[:print_after] = true
        expect(@knife).to receive(:format_for_display).with(@adam_node).and_return("adam")
        expect(@knife).to receive(:format_for_display).with(@ben_node).and_return("ben")
        expect(@knife).to receive(:output).with("adam")
        expect(@knife).to receive(:output).with("ben")
        @knife.run
      end
    end
  end
end
