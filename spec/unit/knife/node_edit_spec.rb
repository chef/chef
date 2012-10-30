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
Chef::Knife::NodeEdit.load_deps

describe Chef::Knife::NodeEdit do
  before(:each) do
    Chef::Config[:node_name]  = "webmonkey.example.com"
    @knife = Chef::Knife::NodeEdit.new
    @knife.config = {
      :editor => 'cat',
      :attribute => nil,
      :print_after => nil
    }
    @knife.name_args = [ "adam" ]
    @node = Chef::Node.new()
  end

  it "should load the node" do
    Chef::Node.should_receive(:load).with("adam").and_return(@node)
    @knife.node
  end

  describe "after loading the node" do
    before do
      @knife.stub!(:node).and_return(@node)
      @node.automatic_attrs = {:go => :away}
      @node.default_attrs = {:hide => :me}
      @node.override_attrs = {:dont => :show}
      @node.normal_attrs = {:do_show => :these}
      @node.chef_environment("prod")
      @node.run_list("recipe[foo]")
    end

    it "creates a view of the node without attributes from roles or ohai" do
      actual = Chef::JSONCompat.from_json(@knife.node_editor.view)
      actual.should_not have_key("automatic")
      actual.should_not have_key("override")
      actual.should_not have_key("default")
      actual["normal"].should == {"do_show" => "these"}
      actual["run_list"].should == ["recipe[foo]"]
      actual["chef_environment"].should == "prod"
    end

    it "shows the extra attributes when given the --all option" do
      @knife.config[:all_attributes] = true

      actual = Chef::JSONCompat.from_json(@knife.node_editor.view)
      actual["automatic"].should == {"go" => "away"}
      actual["override"].should == {"dont" => "show"}
      actual["default"].should == {"hide" => "me"}
      actual["normal"].should == {"do_show" => "these"}
      actual["run_list"].should == ["recipe[foo]"]
      actual["chef_environment"].should == "prod"
    end

    it "does not consider unedited data updated" do
      view = Chef::JSONCompat.from_json( @knife.node_editor.view )
      @knife.node_editor.apply_updates(view)
      @knife.node_editor.should_not be_updated
    end

    it "considers edited data updated" do
      view = Chef::JSONCompat.from_json( @knife.node_editor.view )
      view["run_list"] << "role[fuuu]"
      @knife.node_editor.apply_updates(view)
      @knife.node_editor.should be_updated
    end

  end
end

