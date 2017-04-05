#
# Copyright:: Copyright 2017, Noah Kantrowitz
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

require "spec_helper"

describe "root aliases" do
  let(:chef_repo_path) { File.expand_path(File.join(CHEF_SPEC_DATA, "cookbooks")) }
  let(:cookbook_collection) do
    cl = Chef::CookbookLoader.new(chef_repo_path)
    cl.load_cookbooks
    Chef::CookbookCollection.new(cl)
  end
  let(:node) do
    node = Chef::Node.new
    node.run_list << "aliased"
    node.automatic[:recipes] = []
    node
  end
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, cookbook_collection, events) }
  before do
    node.run_context = run_context
  end

  describe "attributes root aliases" do
    it "should load attributes.rb when included directly" do
      node.include_attribute("aliased")
      expect(node["aliased"]["attr"]).to eq "value"
    end

    it "should load attributes.rb when loading a cookbook" do
      run_context.load(node.run_list.expand("_default"))
      expect(node["aliased"]["attr"]).to eq "value"
    end
  end

  describe "recipe root aliased" do
    it "should load recipe.rb" do
      run_context.load(node.run_list.expand("_default"))
      run_context.include_recipe("aliased")
      expect(run_context.resource_collection.map(&:to_s)).to eq ["ruby_block[root alias]"]
    end
  end
end
