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
Chef::Knife::NodeEdit.load_deps

describe Chef::Knife::NodeEdit do

  # helper to convert the view from Chef objects into Ruby objects representing JSON
  def deserialized_json_view
    Chef::JSONCompat.from_json(Chef::JSONCompat.to_json_pretty(@knife.node_editor.send(:view)))
  end

  before(:each) do
    Chef::Config[:node_name] = "webmonkey.example.com"
    @knife = Chef::Knife::NodeEdit.new
    @knife.config = {
      editor: "cat",
      attribute: nil,
      print_after: nil,
    }
    @knife.name_args = [ "adam" ]
    @node = Chef::Node.new
  end

  it "should load the node" do
    expect(Chef::Node).to receive(:load).with("adam").and_return(@node)
    @knife.node
  end

  describe "after loading the node" do
    before do
      @knife.config[:all_attributes] = false

      allow(@knife).to receive(:node).and_return(@node)
      @node.automatic_attrs = { go: :away }
      @node.default_attrs = { hide: :me }
      @node.override_attrs = { dont: :show }
      @node.normal_attrs = { do_show: :these }
      @node.chef_environment("prod")
      @node.run_list("recipe[foo]")
    end

    it "creates a view of the node without attributes from roles or ohai" do
      actual = deserialized_json_view
      expect(actual).not_to have_key("automatic")
      expect(actual).not_to have_key("override")
      expect(actual).not_to have_key("default")
      expect(actual["normal"]).to eq({ "do_show" => "these" })
      expect(actual["run_list"]).to eq(["recipe[foo]"])
      expect(actual["chef_environment"]).to eq("prod")
    end

    it "shows the extra attributes when given the --all option" do
      @knife.config[:all_attributes] = true

      actual = deserialized_json_view
      expect(actual["automatic"]).to eq({ "go" => "away" })
      expect(actual["override"]).to eq({ "dont" => "show" })
      expect(actual["default"]).to eq({ "hide" => "me" })
      expect(actual["normal"]).to eq({ "do_show" => "these" })
      expect(actual["run_list"]).to eq(["recipe[foo]"])
      expect(actual["chef_environment"]).to eq("prod")
    end

    it "does not consider unedited data updated" do
      view = deserialized_json_view
      @knife.node_editor.send(:apply_updates, view)
      expect(@knife.node_editor).not_to be_updated
    end

    it "considers edited data updated" do
      view = deserialized_json_view
      view["run_list"] << "role[fuuu]"
      @knife.node_editor.send(:apply_updates, view)
      expect(@knife.node_editor).to be_updated
    end

  end

  describe "edit_node" do

    before do
      allow(@knife).to receive(:node).and_return(@node)
    end

    let(:subject) { @knife.node_editor.edit_node }

    it "raises an exception when editing is disabled" do
      @knife.config[:disable_editing] = true
      expect { subject }.to raise_error(SystemExit)
    end

    it "raises an exception when the editor is not set" do
      @knife.config[:editor] = nil
      expect { subject }.to raise_error(SystemExit)
    end

  end

end
