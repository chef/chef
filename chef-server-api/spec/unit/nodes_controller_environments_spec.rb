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

describe "Nodes controller - environments" do
  before do
    Merb.logger.set_log(StringIO.new)

    # Node 'node1':
    #  contains 'role[role1]'
    #
    # Role 'role1':
    #  for env '_default', contains 'recipe[cb_for_default]'
    #  for env 'env1', contains 'recipe[cb_for_env1]'
    #  for env 'env_fallback', contains nothing (should fall back to _default).
    #
    # Check that the node returns the right expanded run list no matter the
    # environment it's in.
    @node1 = make_node("node1")
    @node1.run_list << "role[role1]"

    @role1 = make_role("role1")
    @role1.env_run_lists({"_default" => make_runlist("recipe[cb_for_default]"),
                          "env1" => make_runlist("recipe[cb_for_env1]")})

    @all_filtered_cookbook_list = 
      make_filtered_cookbook_hash(make_cookbook("cb_for_default", "1.0.0"),
                                  make_cookbook("cb_for_env1", "1.0.0"))
  end

  describe "when handling Node API calls" do
    it "should expand role and cookbook dependencies using the _default environment" do

      # Test that node@_default resolves to use cookbook cb_for_default
      Chef::Node.should_receive(:cdb_load).with("node1").and_return(@node1)
      Chef::Environment.should_receive(:cdb_load_filtered_cookbook_versions).with("_default").and_return(@all_filtered_cookbook_list)
      Chef::Role.should_receive(:cdb_load).with("role1", nil).and_return(@role1)

      response = get_json("/nodes/node1/cookbooks")
      response.should be_kind_of(Hash)
      response["cb_for_default"].should_not == nil
      response["cb_for_env1"].should == nil
    end

    it "should expand role and cookbook dependencies using the env1 environment" do
      # Test that node@env1 resolves to use cookbook cb_for_env1
      @node1.chef_environment("env1")
      Chef::Node.should_receive(:cdb_load).with("node1").and_return(@node1)
      Chef::Environment.should_receive(:cdb_load_filtered_cookbook_versions).with("env1").and_return(@all_filtered_cookbook_list)
      Chef::Role.should_receive(:cdb_load).with("role1", nil).and_return(@role1)

      response = get_json("/nodes/node1/cookbooks")
      response.should be_kind_of(Hash)
      response["cb_for_default"].should == nil
      response["cb_for_env1"].should_not == nil
    end


    it "should expand role and cookbook dependencies using the _default environment, when passed an empty environment" do
      # Test that node@env_fallback resolves to use cookbook cb_for_default
      # because env_fallback falls back to _default
      @node1.chef_environment("env_fallback")
      Chef::Node.should_receive(:cdb_load).with("node1").and_return(@node1)
      Chef::Environment.should_receive(:cdb_load_filtered_cookbook_versions).with("env_fallback").and_return(@all_filtered_cookbook_list)
      Chef::Role.should_receive(:cdb_load).with("role1", nil).and_return(@role1)

      response = get_json("/nodes/node1/cookbooks")
      response.should be_kind_of(Hash)
      response["cb_for_default"].should_not == nil
      response["cb_for_env1"].should == nil
    end

  end
end

