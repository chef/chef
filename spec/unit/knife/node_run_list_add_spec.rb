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

describe Chef::Knife::NodeRunListAdd do
  before(:each) do
    Chef::Config[:node_name] = "webmonkey.example.com"
    @knife = Chef::Knife::NodeRunListAdd.new
    @knife.config = {
      after: nil,
    }
    @knife.name_args = [ "adam", "role[monkey]" ]
    allow(@knife).to receive(:output).and_return(true)
    @node = Chef::Node.new
    allow(@node).to receive(:save).and_return(true)
    allow(Chef::Node).to receive(:load).and_return(@node)
  end

  describe "run" do
    it "should load the node" do
      expect(Chef::Node).to receive(:load).with("adam")
      @knife.run
    end

    it "should add to the run list" do
      @knife.run
      expect(@node.run_list[0]).to eq("role[monkey]")
    end

    it "should save the node" do
      expect(@node).to receive(:save)
      @knife.run
    end

    it "should print the run list" do
      expect(@knife).to receive(:output).and_return(true)
      @knife.run
    end

    describe "with -a or --after specified" do
      it "should add to the run list after the specified entry" do
        @node.run_list << "role[acorns]"
        @node.run_list << "role[barn]"
        @knife.config[:after] = "role[acorns]"
        @knife.run
        expect(@node.run_list[0]).to eq("role[acorns]")
        expect(@node.run_list[1]).to eq("role[monkey]")
        expect(@node.run_list[2]).to eq("role[barn]")
      end
    end

    describe "with -b or --before specified" do
      it "should add to the run list before the specified entry" do
        @node.run_list << "role[acorns]"
        @node.run_list << "role[barn]"
        @knife.config[:before] = "role[acorns]"
        @knife.run
        expect(@node.run_list[0]).to eq("role[monkey]")
        expect(@node.run_list[1]).to eq("role[acorns]")
        expect(@node.run_list[2]).to eq("role[barn]")
      end
    end

    describe "with both --after and --before specified" do
      it "exits with an error" do
        @node.run_list << "role[acorns]"
        @node.run_list << "role[barn]"
        @knife.config[:before] = "role[acorns]"
        @knife.config[:after]  = "role[acorns]"
        expect(@knife.ui).to receive(:fatal)
        expect { @knife.run }.to raise_error(SystemExit)
      end
    end

    describe "with more than one role or recipe" do
      it "should add to the run list all the entries" do
        @knife.name_args = [ "adam", "role[monkey],role[duck]" ]
        @node.run_list << "role[acorns]"
        @knife.run
        expect(@node.run_list[0]).to eq("role[acorns]")
        expect(@node.run_list[1]).to eq("role[monkey]")
        expect(@node.run_list[2]).to eq("role[duck]")
      end
    end

    describe "with more than one role or recipe with space between items" do
      it "should add to the run list all the entries" do
        @knife.name_args = [ "adam", "role[monkey], role[duck]" ]
        @node.run_list << "role[acorns]"
        @knife.run
        expect(@node.run_list[0]).to eq("role[acorns]")
        expect(@node.run_list[1]).to eq("role[monkey]")
        expect(@node.run_list[2]).to eq("role[duck]")
      end
    end

    describe "with more than one role or recipe as different arguments" do
      it "should add to the run list all the entries" do
        @knife.name_args = [ "adam", "role[monkey]", "role[duck]" ]
        @node.run_list << "role[acorns]"
        @knife.run
        expect(@node.run_list[0]).to eq("role[acorns]")
        expect(@node.run_list[1]).to eq("role[monkey]")
        expect(@node.run_list[2]).to eq("role[duck]")
      end
    end

    describe "with more than one role or recipe as different arguments and list separated by commas" do
      it "should add to the run list all the entries" do
        @knife.name_args = [ "adam", "role[monkey]", "role[duck],recipe[bird::fly]" ]
        @node.run_list << "role[acorns]"
        @knife.run
        expect(@node.run_list[0]).to eq("role[acorns]")
        expect(@node.run_list[1]).to eq("role[monkey]")
        expect(@node.run_list[2]).to eq("role[duck]")
      end
    end

    describe "with one role or recipe but with an extraneous comma" do
      it "should add to the run list one item" do
        @knife.name_args = [ "adam", "role[monkey]," ]
        @node.run_list << "role[acorns]"
        @knife.run
        expect(@node.run_list[0]).to eq("role[acorns]")
        expect(@node.run_list[1]).to eq("role[monkey]")
      end
    end
  end
end
