#
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../spec_model_helper')
require 'chef/node'
require 'pp'

describe "Nodes controller" do
  before do
    Merb.logger.set_log(StringIO.new)
  end

  describe "when handling Node API calls" do
    it "returns a list of nodes" do
      returned_node_list = ["node1", "node2"]
      Chef::Node.stub!(:cdb_list).and_return(returned_node_list)

      res = get_json("/nodes")

      expected_response = returned_node_list.inject({}) do |res,node_name|
        res[node_name] = "#{root_url}/nodes/#{node_name}"
        res
      end
      res.should == expected_response
    end

    it "returns an existing node" do
      returned_node = make_node("node1")
      Chef::Node.stub!(:cdb_load).and_return(returned_node)

      response = get_json("/nodes/node1")
      response.name.should == returned_node.name
    end

    it "returns a 404 when a non-existant node is shown" do
      Chef::Node.should_receive(:cdb_load).with("node1").and_raise(Chef::Exceptions::CouchDBNotFound)

      lambda {
        get_json("/nodes/node1")
      }.should raise_error(Merb::ControllerExceptions::NotFound)
    end

    it "creates a node if no same-named node exists" do
      create_node = make_node("node1")
      
      Chef::Node.should_receive(:cdb_load).with("node1").and_raise(Chef::Exceptions::CouchDBNotFound)
      create_node.should_receive(:cdb_save)

      response = post_json("/nodes", create_node)
      response.should == {"uri" => "#{root_url}/nodes/node1"}
    end

    it "raises a Conflict if you create a node whose name already exists" do
      create_node = make_node("node1")
      existing_node = make_node("node1")

      Chef::Node.should_receive(:cdb_load).with("node1").and_return(existing_node)

      lambda {
        post_json("/nodes", create_node)
      }.should raise_error(Merb::ControllerExceptions::Conflict)
    end
  end
end

