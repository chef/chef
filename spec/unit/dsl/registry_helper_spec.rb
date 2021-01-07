#
# Author:: Prajakta Purohit (<prajakta@chef.io>)
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

require "chef/dsl/registry_helper"
require "spec_helper"

describe Chef::Resource::RegistryKey do

  before(:all) do
    events = Chef::EventDispatch::Dispatcher.new
    node = Chef::Node.new
    node.consume_external_attrs(OHAI_SYSTEM.data, {})
    run_context = Chef::RunContext.new(node, {}, events)
    @resource = Chef::Resource.new("foo", run_context)
  end

  context "tests registry dsl" do
    it "resource can access registry_helper method registry_key_exists" do
      expect(@resource.respond_to?("registry_key_exists?")).to eq(true)
    end
    it "resource can access registry_helper method registry_get_values" do
      expect(@resource.respond_to?("registry_get_values")).to eq(true)
    end
    it "resource can access registry_helper method registry_has_subkey" do
      expect(@resource.respond_to?("registry_has_subkeys?")).to eq(true)
    end
    it "resource can access registry_helper method registry_get_subkeys" do
      expect(@resource.respond_to?("registry_get_subkeys")).to eq(true)
    end
    it "resource can access registry_helper method registry_value_exists" do
      expect(@resource.respond_to?("registry_value_exists?")).to eq(true)
    end
    it "resource can access registry_helper method data_value_exists" do
      expect(@resource.respond_to?("registry_data_exists?")).to eq(true)
    end
  end
end
