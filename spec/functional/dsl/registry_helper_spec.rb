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

describe Chef::Resource::RegistryKey, :windows_only do

  before (:all) do
    ::Win32::Registry::HKEY_CURRENT_USER.create "Software\\Root"
    ::Win32::Registry::HKEY_CURRENT_USER.create "Software\\Root\\Branch"
    ::Win32::Registry::HKEY_CURRENT_USER.open('Software\\Root', Win32::Registry::KEY_ALL_ACCESS) do |reg|
      reg['RootType1', Win32::Registry::REG_SZ] = 'fibrous'
      reg.write('Roots', Win32::Registry::REG_MULTI_SZ, ["strong roots", "healthy tree"])
    end

    events = Chef::EventDispatch::Dispatcher.new
    node = Chef::Node.new
    ohai = Ohai::System.new
    ohai.all_plugins
    node.consume_external_attrs(ohai.data,{})
    run_context = Chef::RunContext.new(node, {}, events)
    @resource = Chef::Resource.new("foo", run_context)
  end

  context "tests registry dsl" do
    it "returns true if registry_key_exists" do
      @resource.registry_key_exists?("HKCU\\Software\\Root").should == true
    end
    it "returns true if registry has specified value" do
      values = @resource.registry_get_values("HKCU\\Software\\Root")
      values.include?({:name=>"RootType1",:type=>:string,:data=>"fibrous"}).should == true
    end
    it "returns true if specified registry_has_subkey" do
      @resource.registry_has_subkeys?("HKCU\\Software\\Root").should == true
    end
    it "returns true if specified key has specified subkey" do
      subkeys = @resource.registry_get_subkeys("HKCU\\Software\\Root")
      subkeys.include?("Branch").should == true
    end
    it "returns true if registry_value_exists" do
      @resource.registry_value_exists?("HKCU\\Software\\Root", {:name=>"RootType1", :type=>:string, :data=>"fibrous"}).should == true
    end
    it "returns true if data_value_exists" do
      @resource.registry_data_exists?("HKCU\\Software\\Root", {:name=>"RootType1", :type=>:string, :data=>"fibrous"}).should == true
    end
  end
end
