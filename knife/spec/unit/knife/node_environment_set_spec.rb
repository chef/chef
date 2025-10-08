#
# Author:: Jimmy McCrory (<jimmy.mccrory@gmail.com>)
# Copyright:: Copyright 2014-2016, Jimmy McCrory
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

describe Chef::Knife::NodeEnvironmentSet do
  before(:each) do
    Chef::Config[:node_name] = "webmonkey.example.com"
    @knife = Chef::Knife::NodeEnvironmentSet.new
    @knife.name_args = %w{adam bar}
    allow(@knife).to receive(:output).and_return(true)
    @node = Chef::Node.new
    @node.name("knifetest-node")
    @node.chef_environment << "foo"
    allow(@node).to receive(:save).and_return(true)
    allow(Chef::Node).to receive(:load).and_return(@node)
  end

  describe "run" do
    it "should load the node" do
      expect(Chef::Node).to receive(:load).with("adam")
      @knife.run
    end

    it "should update the environment" do
      @knife.run
      expect(@node.chef_environment).to eq("bar")
    end

    it "should save the node" do
      expect(@node).to receive(:save)
      @knife.run
    end

    it "sets the environment to config for display" do
      @knife.run
      expect(@knife.config[:environment]).to eq("bar")
    end

    it "should print the environment" do
      expect(@knife).to receive(:output).and_return(true)
      @knife.run
    end

  end
end
