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

describe Chef::Knife::NodeRunListRemove do
  before(:each) do
    Chef::Config[:node_name] = "webmonkey.example.com"
    @knife = Chef::Knife::NodeRunListRemove.new
    @knife.config[:print_after] = nil
    @knife.name_args = [ "adam", "role[monkey]" ]
    @node = Chef::Node.new
    @node.name("knifetest-node")
    @node.run_list << "role[monkey]"
    allow(@node).to receive(:save).and_return(true)

    allow(@knife.ui).to receive(:output).and_return(true)
    allow(@knife.ui).to receive(:confirm).and_return(true)

    allow(Chef::Node).to receive(:load).and_return(@node)
  end

  describe "run" do
    it "should load the node" do
      expect(Chef::Node).to receive(:load).with("adam").and_return(@node)
      @knife.run
    end

    it "should remove the item from the run list" do
      @knife.run
      expect(@node.run_list[0]).not_to eq("role[monkey]")
    end

    it "should save the node" do
      expect(@node).to receive(:save).and_return(true)
      @knife.run
    end

    it "should print the run list" do
      @knife.config[:print_after] = true
      expect(@knife.ui).to receive(:output).with({ "knifetest-node" => { "run_list" => [] } })
      @knife.run
    end

    describe "run with a list of roles and recipes" do
      it "should remove the items from the run list" do
        @node.run_list << "role[monkey]"
        @node.run_list << "recipe[duck::type]"
        @knife.name_args = [ "adam", "role[monkey],recipe[duck::type]" ]
        @knife.run
        expect(@node.run_list).not_to include("role[monkey]")
        expect(@node.run_list).not_to include("recipe[duck::type]")
      end

      it "should remove the items from the run list when name args contains whitespace" do
        @node.run_list << "role[monkey]"
        @node.run_list << "recipe[duck::type]"
        @knife.name_args = [ "adam", "role[monkey], recipe[duck::type]" ]
        @knife.run
        expect(@node.run_list).not_to include("role[monkey]")
        expect(@node.run_list).not_to include("recipe[duck::type]")
      end

      it "should remove the items from the run list when name args contains multiple run lists" do
        @node.run_list << "role[blah]"
        @node.run_list << "recipe[duck::type]"
        @knife.name_args = [ "adam", "role[monkey], recipe[duck::type]", "role[blah]" ]
        @knife.run
        expect(@node.run_list).not_to include("role[monkey]")
        expect(@node.run_list).not_to include("recipe[duck::type]")
      end

      it "should warn when the thing to remove is not in the runlist" do
        @node.run_list << "role[blah]"
        @node.run_list << "recipe[duck::type]"
        @knife.name_args = [ "adam", "role[blork]" ]
        expect(@knife.ui).to receive(:warn).with("role[blork] is not in the run list")
        @knife.run
      end

      it "should warn even more when the thing to remove is not in the runlist and unqualified" do
        @node.run_list << "role[blah]"
        @node.run_list << "recipe[duck::type]"
        @knife.name_args = %w{adam blork}
        expect(@knife.ui).to receive(:warn).with("blork is not in the run list")
        expect(@knife.ui).to receive(:warn).with(/did you forget recipe\[\] or role\[\]/)
        @knife.run
      end
    end
  end
end
