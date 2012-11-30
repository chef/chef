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

require "chef/win32/registry"
require "spec_helper"

describe Chef::Resource::RegistryKey, :windows_only do

  before(:all) do
    events = Chef::EventDispatch::Dispatcher.new
    @node = Chef::Node.new
    ohai = Ohai::System.new
    ohai.all_plugins
    @node.consume_external_attrs(ohai.data,{})
    @run_context = Chef::RunContext.new(@node, {}, events)
    @resource = Chef::Resource::RegistryKey.new("HKCU\\Software", @run_context)
    @registry = Chef::Win32::Registry.new(@run_context)
  end

  context "when action is create" do
    before (:all) do
      ::Win32::Registry::HKEY_CURRENT_USER.open("Software", Win32::Registry::KEY_WRITE) do |reg|
        begin
          reg.delete_key("Opscode", true)
          reg.delete_key("MissingKey1", true)
        rescue
        end
      end
    end
    after (:all) do
      ::Win32::Registry::HKEY_CURRENT_USER.open("Software", Win32::Registry::KEY_WRITE) do |reg|
        begin
          reg.delete_key("Opscode", true)
          reg.delete_key("MissingKey1", true)
        rescue
        end
      end
    end
    it "creates registry key, value if the key is missing" do
      @resource.key("HKCU\\Software\\Opscode")
      @resource.values([{:name=>"Color", :type=>:string, :data=>"Orange"}])
      @resource.run_action(:create)

      @registry.key_exists?("HKCU\\Software\\Opscode").should == true
      @registry.data_exists?("HKCU\\Software\\Opscode", {:name=>"Color", :type=>:string, :data=>"Orange"}).should == true
    end

    it "does not create the key if it already exists with same value, type and data" do
      @resource.key("HKCU\\Software\\Opscode")
      @resource.values([{:name=>"Color", :type=>:string, :data=>"Orange"}])
      @resource.run_action(:create)

      @registry.key_exists?("HKCU\\Software\\Opscode").should == true
      @registry.data_exists?("HKCU\\Software\\Opscode", {:name=>"Color", :type=>:string, :data=>"Orange"}).should == true
    end

    it "creates a value if it does not exist" do
      @resource.key("HKCU\\Software\\Opscode")
      @resource.values([{:name=>"Mango", :type=>:string, :data=>"Yellow"}])
      @resource.run_action(:create)

      @registry.data_exists?("HKCU\\Software\\Opscode", {:name=>"Mango", :type=>:string, :data=>"Yellow"}).should == true
    end

    it "modifys the data if the key and value exist and type matches" do
      @resource.key("HKCU\\Software\\Opscode")
      @resource.values([{:name=>"Color", :type=>:string, :data=>"Not just Orange - OpscodeOrange!"}])
      @resource.run_action(:create)

      @registry.data_exists?("HKCU\\Software\\Opscode", {:name=>"Color", :type=>:string, :data=>"Not just Orange - OpscodeOrange!"}).should == true
    end

    it "gives an error if the key and value exist and the type does not match" do
      @resource.key("HKCU\\Software\\Opscode")
      @resource.values([{:name=>"Color", :type=>:multi_string, :data=>["Not just Orange - OpscodeOrange!"]}])
      lambda{@resource.run_action(:create)}.should raise_error(Chef::Exceptions::Win32RegTypesMismatch)
    end

    it "creates subkey if parent exists" do
      @resource.key("HKCU\\Software\\Opscode\\OpscodeTest")
      @resource.values([{:name=>"Chef", :type=>:multi_string, :data=>["OpscodeOrange", "Rules"]}])
      @resource.recursive(false)
      @resource.run_action(:create)

      @registry.key_exists?("HKCU\\Software\\Opscode\\OpscodeTest").should == true
      @registry.value_exists?("HKCU\\Software\\Opscode\\OpscodeTest", {:name=>"Chef", :type=>:multi_string, :data=>["OpscodeOrange", "Rules"]}).should == true
    end

    it "gives error if action create and parent does not exist and recursive is set to false" do
      @resource.key("HKCU\\Software\\MissingKey1\\MissingKey2\\Opscode")
      @resource.values([{:name=>"OC", :type=>:string, :data=>"MissingData"}])
      @resource.recursive(false)
      lambda{@resource.run_action(:create)}.should raise_error(Chef::Exceptions::Win32RegNoRecursive)
    end

    it "creates missing keys if action create and parent does not exist and recursive is set to true" do
      @resource.key("HKCU\\Software\\MissingKey1\\MissingKey2\\Opscode")
      @resource.values([{:name=>"OC", :type=>:string, :data=>"MissingData"}])
      @resource.recursive(true)
      @resource.run_action(:create)

      @registry.key_exists?("HKCU\\Software\\MissingKey1\\MissingKey2\\Opscode").should == true
      @registry.value_exists?("HKCU\\Software\\MissingKey1\\MissingKey2\\Opscode", {:name=>"OC", :type=>:string, :data=>"MissingData"}).should == true
    end

    it "creates key with multiple value as specified" do
      @resource.key("HKCU\\Software\\MissingKey1\\MissingKey2\\Opscode")
      @resource.values([{:name=>"one", :type=>:string, :data=>"1"},{:name=>"two", :type=>:string, :data=>"2"},{:name=>"three", :type=>:string, :data=>"3"}])
      @resource.recursive(true)
      @resource.run_action(:create)

      @resource.values.each do |value|
        @registry.value_exists?("HKCU\\Software\\MissingKey1\\MissingKey2\\Opscode", value).should == true
      end
    end
  end

  context "when action is create_if_missing" do
    before (:all) do
      ::Win32::Registry::HKEY_CURRENT_USER.open("Software", Win32::Registry::KEY_WRITE) do |reg|
        begin
          reg.delete_key("Opscode", true)
          reg.delete_key("MissingKey1", true)
        rescue
        end
      end
    end
    after (:all) do
      ::Win32::Registry::HKEY_CURRENT_USER.open("Software", Win32::Registry::KEY_WRITE) do |reg|
        begin
          reg.delete_key("Opscode", true)
          reg.delete_key("MissingKey1", true)
        rescue
        end
      end
    end
    it "creates registry key, value if the key is missing" do
      @resource.key("HKCU\\Software\\Opscode")
      @resource.values([{:name=>"Color", :type=>:string, :data=>"Orange"}])
      @resource.run_action(:create_if_missing)

      @registry.key_exists?("HKCU\\Software\\Opscode").should == true
      @registry.data_exists?("HKCU\\Software\\Opscode", {:name=>"Color", :type=>:string, :data=>"Orange"}).should == true
    end

    it "does not create the key if it already exists with same value, type and data" do
      @resource.key("HKCU\\Software\\Opscode")
      @resource.values([{:name=>"Color", :type=>:string, :data=>"Orange"}])
      @resource.run_action(:create_if_missing)

      @registry.key_exists?("HKCU\\Software\\Opscode").should == true
      @registry.data_exists?("HKCU\\Software\\Opscode", {:name=>"Color", :type=>:string, :data=>"Orange"}).should == true
    end

    it "creates a value if it does not exist" do
      @resource.key("HKCU\\Software\\Opscode")
      @resource.values([{:name=>"Mango", :type=>:string, :data=>"Yellow"}])
      @resource.run_action(:create_if_missing)

      @registry.data_exists?("HKCU\\Software\\Opscode", {:name=>"Mango", :type=>:string, :data=>"Yellow"}).should == true
    end

     it "creates subkey if parent exists" do
      @resource.key("HKCU\\Software\\Opscode\\OpscodeTest")
      @resource.values([{:name=>"Chef", :type=>:multi_string, :data=>["OpscodeOrange", "Rules"]}])
      @resource.recursive(false)
      @resource.run_action(:create_if_missing)

      @registry.key_exists?("HKCU\\Software\\Opscode\\OpscodeTest").should == true
      @registry.value_exists?("HKCU\\Software\\Opscode\\OpscodeTest", {:name=>"Chef", :type=>:multi_string, :data=>["OpscodeOrange", "Rules"]}).should == true
    end

    it "gives error if action create and parent does not exist and recursive is set to false" do
      @resource.key("HKCU\\Software\\MissingKey1\\MissingKey2\\Opscode")
      @resource.values([{:name=>"OC", :type=>:string, :data=>"MissingData"}])
      @resource.recursive(false)
      lambda{@resource.run_action(:create_if_missing)}.should raise_error(Chef::Exceptions::Win32RegNoRecursive)
    end

    it "creates missing keys if action create and parent does not exist and recursive is set to true" do
      @resource.key("HKCU\\Software\\MissingKey1\\MissingKey2\\Opscode")
      @resource.values([{:name=>"OC", :type=>:string, :data=>"MissingData"}])
      @resource.recursive(true)
      @resource.run_action(:create_if_missing)

      @registry.key_exists?("HKCU\\Software\\MissingKey1\\MissingKey2\\Opscode").should == true
      @registry.value_exists?("HKCU\\Software\\MissingKey1\\MissingKey2\\Opscode", {:name=>"OC", :type=>:string, :data=>"MissingData"}).should == true
    end

    it "creates key with multiple value as specified" do
      @resource.key("HKCU\\Software\\MissingKey1\\MissingKey2\\Opscode")
      @resource.values([{:name=>"one", :type=>:string, :data=>"1"},{:name=>"two", :type=>:string, :data=>"2"},{:name=>"three", :type=>:string, :data=>"3"}])
      @resource.recursive(true)
      @resource.run_action(:create_if_missing)

      @resource.values.each do |value|
        @registry.value_exists?("HKCU\\Software\\MissingKey1\\MissingKey2\\Opscode", value).should == true
      end
    end
  end

  context "when the action is delete" do
    before(:all) do
      ::Win32::Registry::HKEY_CURRENT_USER.open("Software", Win32::Registry::KEY_WRITE) do |reg|
        begin
          reg.delete_key("MissingKey1", true)
        rescue
        end
      end
      ::Win32::Registry::HKEY_CURRENT_USER.create "Software\\Opscode"
      ::Win32::Registry::HKEY_CURRENT_USER.open("Software\\Opscode", Win32::Registry::KEY_ALL_ACCESS) do |reg|
        reg["Color", Win32::Registry::REG_SZ] = "Orange"
        reg.write("Opscode", Win32::Registry::REG_MULTI_SZ, ["Seattle", "Washington"])
        reg["AKA", Win32::Registry::REG_SZ] = "OC"
      end
    end

    after(:all) do
      ::Win32::Registry::HKEY_CURRENT_USER.open("Software", Win32::Registry::KEY_WRITE) do |reg|
        begin
          reg.delete_key("Opscode", true)
        rescue
        end
      end
    end
    it "takes no action if the specified key path does not exist in the system" do
      @registry.key_exists?("HKCU\\Software\\MissingKey1\\MissingKey2\\Opscode").should == false

      @resource.key("HKCU\\Software\\MissingKey1\\MissingKey2\\Opscode")
      @resource.recursive(false)
      @resource.run_action(:delete)

      @registry.key_exists?("HKCU\\Software\\MissingKey1\\MissingKey2\\Opscode").should == false
    end

    it "takes no action if the key exists but the value does not" do
      @resource.key("HKCU\\Software\\Opscode")
      @resource.values([{:name=>"LooksLike", :type=>:multi_string, :data=>["SeattleGrey", "OCOrange"]}])
      @resource.recursive(false)
      @resource.run_action(:delete)

      @registry.data_exists?("HKCU\\Software\\Opscode", {:name=>"Color", :type=>:string, :data=>"Orange"}).should == true
    end

    it "deletes only specified values under a key path" do
      @resource.key("HKCU\\Software\\Opscode")
      @resource.values([{:name=>"Opscode", :type=>:multi_string, :data=>["Seattle", "Washington"]}, {:name=>"AKA", :type=>:string, :data=>"OC"}])
      @resource.recursive(false)
      @resource.run_action(:delete)

      @registry.data_exists?("HKCU\\Software\\Opscode", {:name=>"Color", :type=>:string, :data=>"Orange"}).should == true
      @registry.value_exists?("HKCU\\Software\\Opscode", {:name=>"AKA", :type=>:string, :data=>"OC"}).should == false
      @registry.value_exists?("HKCU\\Software\\Opscode", {:name=>"Opscode", :type=>:multi_string, :data=>["Seattle", "Washington"]}).should == false
    end

    it "it deletes the values with the same name irrespective of it type and data" do
      @resource.key("HKCU\\Software\\Opscode")
      @resource.values([{:name=>"Color", :type=>:multi_string, :data=>["Black", "Orange"]}])
      @resource.recursive(false)
      @resource.run_action(:delete)

       @registry.value_exists?("HKCU\\Software\\Opscode", {:name=>"Color", :type=>:string, :data=>"Orange"}).should == false
    end
  end

  context "when the action is delete_key" do
    before (:all) do
      ::Win32::Registry::HKEY_CURRENT_USER.create "Software\\Opscode"
        ::Win32::Registry::HKEY_CURRENT_USER.open("Software\\Opscode", Win32::Registry::KEY_ALL_ACCESS) do |reg|
          reg["Color", Win32::Registry::REG_SZ] = "Orange"
          reg.write("Opscode", Win32::Registry::REG_MULTI_SZ, ["Seattle", "Washington"])
          reg["AKA", Win32::Registry::REG_SZ] = "OC"
        end
      ::Win32::Registry::HKEY_CURRENT_USER.create "Software\\Opscode\\OpscodeTest"
      ::Win32::Registry::HKEY_CURRENT_USER.open("Software\\Opscode\\OpscodeTest", Win32::Registry::KEY_ALL_ACCESS) do |reg|
          reg["ColorTest", Win32::Registry::REG_SZ] = "OrangeTest"
      end
      ::Win32::Registry::HKEY_CURRENT_USER.create "Software\\Opscode\\OpscodeIgnoredValues"
      ::Win32::Registry::HKEY_CURRENT_USER.open("Software\\Opscode\\OpscodeIgnoredValues", Win32::Registry::KEY_ALL_ACCESS) do |reg|
          reg["ColorIgnored", Win32::Registry::REG_SZ] = "OrangeIgnored"
      end
    end
    after(:all) do
      ::Win32::Registry::HKEY_CURRENT_USER.open("Software", Win32::Registry::KEY_WRITE) do |reg|
        begin
          reg.delete_key("Opscode", true)
        rescue
        end
      end
    end
    it "takes no action if the specified key path does not exist in the system" do
      @registry.key_exists?("HKCU\\Software\\Missing1\\Missing2\\Opscode").should == false

      @resource.key("HKCU\\Software\\Missing1\\Missing2\\Opscode")
      @resource.recursive(false)
      @resource.run_action(:delete_key)

      @registry.key_exists?("HKCU\\Software\\Missing1\\Missing2\\Opscode").should == false
    end

    it "deletes key if it has no subkeys and recursive == false" do
      @resource.key("HKCU\\Software\\Opscode\\OpscodeTest")
      @resource.recursive(false)
      @resource.run_action(:delete_key)

      @registry.key_exists?("HKCU\\Software\\Opscode\\OpscodeTest").should == false
    end

    it "raises an exception if the the key has subkeys and recursive == false" do
      @resource.key("HKCU\\Software\\Opscode")
      @resource.recursive(false)
      lambda{@resource.run_action(:delete_key)}.should raise_error(Chef::Exceptions::Win32RegNoRecursive)
    end

    it "ignores the values under a key" do
      @resource.key("HKCU\\Software\\Opscode\\OpscodeIgnoredValues")
      @resource.values([{:name=>"DontExist", :type=>:string, :data=>"These will be ignore anyways"}])
      @resource.recursive(true)
      @resource.run_action(:delete_key)
    end

    it "deletes the key if it has subkeys and recursive == true" do
      @resource.key("HKCU\\Software\\Opscode")
      @resource.recursive(true)
      @resource.run_action(:delete_key)

      @registry.key_exists?("HKCU\\Software\\Opscode").should == false
    end
  end
end
