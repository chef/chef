#
# Author:: Prajakta Purohit (<prajakta@opscode.com>)
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

require "chef/dsl/registry_helper"
require "spec_helper"

describe Chef::Resource::RegistryKey, :unix_only do
  before(:all) do
    events = Chef::EventDispatch::Dispatcher.new
    node = Chef::Node.new
    ohai = Ohai::System.new
    ohai.all_plugins
    node.consume_external_attrs(ohai.data,{})
    run_context = Chef::RunContext.new(node, {}, events)
    @resource = Chef::Resource::RegistryKey.new("HKCU\\Software", run_context)
  end
  context "when load_current_resource is run on a non-windows node" do
    it "throws an exception because you don't have a windows registry (derp)" do
      @resource.key("HKCU\\Software\\Opscode")
      @resource.values([{:name=>"Color", :type=>:string, :data=>"Orange"}])
      lambda{@resource.run_action(:create)}.should raise_error(Chef::Exceptions::Win32NotWindows)
    end
  end
end

describe Chef::Resource::RegistryKey, :windows_only do
  include_context Chef::Resource::File

  let(:file_base) { "file_spec" }
  let(:expected_content) { "Don't fear the ruby." }

  before (:all) do
    events = Chef::EventDispatch::Dispatcher.new
    node = Chef::Node.new
    ohai = Ohai::System.new
    ohai.all_plugins
    node.consume_external_attrs(ohai.data,{})
    run_context = Chef::RunContext.new(node, {}, events)
    @resource = Chef::Resource::File.new(path, run_context)
    @resource.content(expected_content)
  end

  context "tests registry dsl" do
    it "creates file file if registry_key_exists" do
      @resource.respond_to?('registry_key_exists?').should == true
    end
    it "deletes file if registry has specified value" do
      @resource.respond_to?('registry_get_values').should == true
    end
    it "creates file if specified registry_has_subkey" do
      @resource.respond_to?('registry_has_subkeys?').should == true
    end
    it "deletes file if specified key has specified subkey" do
      @resource.respond_to?('registry_get_subkeys').should == true
    end
    it "creates file if registry_value_exists" do
      @resource.respond_to?('registry_value_exists?').should == true
    end
    it "deletes file if data_value_exists" do
      @resource.respond_to?('registry_data_exists?').should == true
    end
  end
end

