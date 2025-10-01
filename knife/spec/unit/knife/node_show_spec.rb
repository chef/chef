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

describe Chef::Knife::NodeShow do

  let(:node) do
    node = Chef::Node.new
    node.name("adam")
    node.run_list = ["role[base]"]
    node
  end

  let(:knife) do
    knife = Chef::Knife::NodeShow.new
    knife.name_args = [ "adam" ]
    knife
  end

  before(:each) do
    Chef::Config[:node_name] = "webmonkey.example.com"
  end

  describe "run" do
    it "should load the node" do
      expect(Chef::Node).to receive(:load).with("adam").and_return(node)
      allow(knife).to receive(:output).and_return(true)
      knife.run
    end

    it "should pretty print the node, formatted for display" do
      knife.config[:format] = nil
      stdout = StringIO.new
      allow(knife.ui).to receive(:stdout).and_return(stdout)
      allow(Chef::Node).to receive(:load).and_return(node)
      knife.run
      expect(stdout.string).to eql("Node Name:   adam\nEnvironment: _default\nFQDN:        \nIP:          \nRun List:    \nRoles:       \nRecipes:     \nPlatform:     \nTags:        \n")
    end

    it "should pretty print json" do
      knife.config[:format] = "json"
      stdout = StringIO.new
      allow(knife.ui).to receive(:stdout).and_return(stdout)
      expect(Chef::Node).to receive(:load).with("adam").and_return(node)
      knife.run
      expect(stdout.string).to eql("{\n  \"name\": \"adam\",\n  \"chef_environment\": \"_default\",\n  \"run_list\": [\n\n]\n,\n  \"normal\": {\n\n  }\n}\n")
    end
  end
end
