#
# Author:: Prajakta Purohit (<prajakta@opscode.com>)
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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
require 'chef/win32/registry'

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

describe 'Chef::Win32::Registry', :windows_only do

  before(:all) do
    #Create a registry item
    ::Win32::Registry::HKEY_CURRENT_USER.create "Software\\Root"
    ::Win32::Registry::HKEY_CURRENT_USER.create "Software\\Root\\Branch"
    ::Win32::Registry::HKEY_CURRENT_USER.create "Software\\Root\\Branch\\Flower"
    ::Win32::Registry::HKEY_CURRENT_USER.open('Software\\Root', Win32::Registry::KEY_ALL_ACCESS) do |reg|
      reg['RootType1', Win32::Registry::REG_SZ] = 'fibrous'
      reg.write('Roots', Win32::Registry::REG_MULTI_SZ, ["strong roots", "healthy tree"])
    end
    ::Win32::Registry::HKEY_CURRENT_USER.open('Software\\Root\\Branch', Win32::Registry::KEY_ALL_ACCESS) do |reg|
      reg['Strong', Win32::Registry::REG_SZ] = 'bird nest'
    end
    ::Win32::Registry::HKEY_CURRENT_USER.open('Software\\Root\\Branch\\Flower', Win32::Registry::KEY_ALL_ACCESS) do |reg|
      reg['Petals', Win32::Registry::REG_MULTI_SZ] = ["Pink", "Delicate"]
    end

    #Create the node with ohai data
    events = Chef::EventDispatch::Dispatcher.new
    @node = Chef::Node.new
    ohai = Ohai::System.new
    ohai.all_plugins
    @node.consume_external_attrs(ohai.data,{})
    @run_context = Chef::RunContext.new(@node, {}, events)

    #Create a registry object that has access ot the node previously created
    @registry = Chef::Win32::Registry.new(@run_context)
  end

  #Delete what is left of the registry key-values previously created
  after(:all) do
    ::Win32::Registry::HKEY_CURRENT_USER.open("Software") do |reg|
      reg.delete_key("Root", true)
    end
  end

  # Server Versions
  # it "succeeds if server versiion is 2003R2, 2008, 2008R2, 2012" do
  # end
  # it "falis if the server versions are anything else" do
  # end

  describe "hive_exists?" do
    it "returns true if the hive exists" do
      @registry.hive_exists?("HKCU\\Software\\Root").should == true
    end

    it "returns false if the hive does not exist" do
      hive = @registry.hive_exists?("LYRU\\Software\\Root").should == false
    end
  end

  describe "key_exists?" do
    it "returns true if the key path exists" do
      @registry.key_exists?("HKCU\\Software\\Root\\Branch\\Flower").should == true
    end

    it "returns false if the key path does not exist" do
      @registry.key_exists?("HKCU\\Software\\Branch\\Flower").should == false
    end

    it "throws an exception if the hive does not exist" do
      lambda {@registry.key_exists?("JKLM\\Software\\Branch\\Flower")}.should raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end
  end

  describe "key_exists!" do
    it "returns true if the key path exists" do
      @registry.key_exists!("HKCU\\Software\\Root\\Branch\\Flower").should == true
    end

    it "throws an exception if the key path does not exist" do
      lambda {@registry.key_exists!("HKCU\\Software\\Branch\\Flower")}.should raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end

    it "throws an exception if the hive does not exist" do
      lambda {@registry.key_exists!("JKLM\\Software\\Branch\\Flower")}.should raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end
  end

  describe "value_exists?" do
    it "throws an exception if the hive does not exist" do
      lambda {@registry.value_exists?("JKLM\\Software\\Branch\\Flower", {:name=>"Petals"})}.should raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end
    it "throws an exception if the key does not exist" do
      lambda {@registry.value_exists?("HKCU\\Software\\Branch\\Flower", {:name=>"Petals"})}.should raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end
    it "returns true if the value exists" do
      @registry.value_exists?("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"Petals"}).should == true
    end
    it "returns false if the value does not exist" do
      @registry.value_exists?("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"FOOBAR"}).should == false
    end
  end

  describe "value_exists!" do
    it "throws an exception if the hive does not exist" do
      lambda {@registry.value_exists!("JKLM\\Software\\Branch\\Flower", {:name=>"Petals"})}.should raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end
    it "throws an exception if the key does not exist" do
      lambda {@registry.value_exists!("HKCU\\Software\\Branch\\Flower", {:name=>"Petals"})}.should raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end
    it "returns true if the value exists" do
      @registry.value_exists!("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"Petals"}).should == true
    end
    it "throws an exception if the value does not exist" do
      lambda {@registry.value_exists!("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"FOOBAR"})}.should raise_error(Chef::Exceptions::Win32RegValueMissing)
    end
  end

  describe "data_exists?" do
    it "throws an exception if the hive does not exist" do
      lambda {@registry.data_exists?("JKLM\\Software\\Branch\\Flower", {:name=>"Petals", :type=>:multi_string, :data=>["Pink", "Delicate"]})}.should raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end
    it "throws an exception if the key does not exist" do
      lambda {@registry.data_exists?("HKCU\\Software\\Branch\\Flower", {:name=>"Petals", :type=>:multi_string, :data=>["Pink", "Delicate"]})}.should raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end
    it "returns true if all the data matches" do
      @registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"Petals", :type=>:multi_string, :data=>["Pink", "Delicate"]}).should == true
    end
    it "returns false if the name does not exist" do
      @registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"slateP", :type=>:multi_string, :data=>["Pink", "Delicate"]}).should == false
    end
    it "returns false if the types do not match" do
      @registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"Petals", :type=>:string, :data=>"Pink"}).should == false
    end
    it "returns false if the data does not match" do
      @registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"Petals", :type=>:multi_string, :data=>["Mauve", "Delicate"]}).should == false
    end
  end

  describe "data_exists!" do
    it "throws an exception if the hive does not exist" do
      lambda {@registry.data_exists!("JKLM\\Software\\Branch\\Flower", {:name=>"Petals", :type=>:multi_string, :data=>["Pink", "Delicate"]})}.should raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end
    it "throws an exception if the key does not exist" do
      lambda {@registry.data_exists!("HKCU\\Software\\Branch\\Flower", {:name=>"Petals", :type=>:multi_string, :data=>["Pink", "Delicate"]})}.should raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end
    it "returns true if all the data matches" do
      @registry.data_exists!("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"Petals", :type=>:multi_string, :data=>["Pink", "Delicate"]}).should == true
    end
    it "throws an exception if the name does not exist" do
      lambda {@registry.data_exists!("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"slateP", :type=>:multi_string, :data=>["Pink", "Delicate"]})}.should raise_error(Chef::Exceptions::Win32RegDataMissing)
    end
    it "throws an exception if the types do not match" do
      lambda {@registry.data_exists!("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"Petals", :type=>:string, :data=>"Pink"})}.should raise_error(Chef::Exceptions::Win32RegDataMissing)
    end
    it "throws an exception if the data does not match" do
      lambda {@registry.data_exists!("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"Petals", :type=>:multi_string, :data=>["Mauve", "Delicate"]})}.should raise_error(Chef::Exceptions::Win32RegDataMissing)
    end
  end

  describe "get_values" do
    it "returns all values for a key if it exists" do
      values = @registry.get_values("HKCU\\Software\\Root")
      values.should be_an_instance_of Array
      values.should == [{:name=>"RootType1", :type=>:string, :data=>"fibrous"},
                        {:name=>"Roots", :type=>:multi_string, :data=>["strong roots", "healthy tree"]}]
    end

    it "throws an exception if the key does not exist" do
      lambda {@registry.get_values("HKCU\\Software\\Branch\\Flower")}.should raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end

    it "throws an exception if the hive does not exist" do
      lambda {@registry.get_values("JKLM\\Software\\Branch\\Flower")}.should raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end
  end

  describe "set_value" do
    it "updates a value if the key, value exist and type matches and value different" do
      @registry.set_value("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"Petals", :type=>:multi_string, :data=>["Yellow", "Changed Color"]}).should == true
      @registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"Petals", :type=>:multi_string, :data=>["Yellow", "Changed Color"]}).should == true
    end

    it "updates a value if the type does match and the values are different" do
      @registry.set_value("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"Petals", :type=>:string, :data=>"Yellow"}).should == true
      @registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"Petals", :type=>:string, :data=>"Yellow"}).should == true
      @registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"Petals", :type=>:multi_string, :data=>["Yellow", "Changed Color"]}).should == false
    end

    it "creates a value if key exists and value does not" do
      @registry.set_value("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"Stamen", :type=>:multi_string, :data=>["Yellow", "Changed Color"]}).should == true
      @registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"Stamen", :type=>:multi_string, :data=>["Yellow", "Changed Color"]}).should == true
    end

    it "does nothing if data,type and name parameters for the value are same" do
      @registry.set_value("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"Stamen", :type=>:multi_string, :data=>["Yellow", "Changed Color"]}).should == false
      @registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"Stamen", :type=>:multi_string, :data=>["Yellow", "Changed Color"]}).should == true
    end

    it "throws an exception if the key does not exist" do
      lambda {@registry.set_value("HKCU\\Software\\Branch\\Flower", {:name=>"Petals", :type=>:multi_string, :data=>["Yellow", "Changed Color"]})}.should raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end

    it "throws an exception if the hive does not exist" do
      lambda {@registry.set_value("JKLM\\Software\\Root\\Branch\\Flower", {:name=>"Petals", :type=>:multi_string, :data=>["Yellow", "Changed Color"]})}.should raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end

    # we are validating that the data gets .to_i called on it when type is a :dword

    it "casts an integer string given as a dword into an integer" do
      @registry.set_value("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"ShouldBe32767", :type=>:dword, :data=>"32767"}).should == true
      @registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"ShouldBe32767", :type=>:dword, :data=>32767}).should == true
    end

    it "casts a nonsense string given as a dword into zero" do
      @registry.set_value("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"ShouldBeZero", :type=>:dword, :data=>"whatdoesthisdo"}).should == true
      @registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"ShouldBeZero", :type=>:dword, :data=>0}).should == true
    end

    it "throws an exception when trying to cast an array to an int for a dword" do
      lambda {@registry.set_value("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"ShouldThrow", :type=>:dword, :data=>["one","two"]})}.should raise_error
    end

    # we are validating that the data gets .to_s called on it when type is a :string

    it "stores the string representation of an array into a string if you pass it an array" do
      @registry.set_value("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"ShouldBePainful", :type=>:string, :data=>["one","two"]}).should == true
      @registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"ShouldBePainful", :type=>:string, :data=>'["one", "two"]'}).should == true
    end

    it "stores the string representation of a number into a string if you pass it an number" do
      @registry.set_value("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"ShouldBe65535", :type=>:string, :data=>65535}).should == true
      @registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"ShouldBe65535", :type=>:string, :data=>"65535"}).should == true
    end

    # we are validating that the data gets .to_a called on it when type is a :multi_string

    it "throws an exception when a multi-string is passed a number" do
      lambda {@registry.set_value("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"ShouldThrow", :type=>:multi_string, :data=>65535})}.should raise_error
    end

    it "throws an exception when a multi-string is passed a string" do
      lambda {@registry.set_value("HKCU\\Software\\Root\\Branch\\Flower", {:name=>"ShouldBeWat", :type=>:multi_string, :data=>"foo"})}.should raise_error
    end
  end

  describe "create_key" do
    before(:all) do
      ::Win32::Registry::HKEY_CURRENT_USER.open("Software\\Root") do |reg|
        begin
          reg.delete_key("Trunk", true)
        rescue
        end
      end
    end

    it "throws an exception if the path has missing keys but recursive set to false" do
      lambda {@registry.create_key("HKCU\\Software\\Root\\Trunk\\Peck\\Woodpecker", false)}.should raise_error(Chef::Exceptions::Win32RegNoRecursive)
      @registry.key_exists?("HKCU\\Software\\Root\\Trunk\\Peck\\Woodpecker").should == false
    end

    it "creates the key_path if the keys were missing but recursive was set to true" do
      @registry.create_key("HKCU\\Software\\Root\\Trunk\\Peck\\Woodpecker", true).should == true
      @registry.key_exists?("HKCU\\Software\\Root\\Trunk\\Peck\\Woodpecker").should == true
    end

    it "does nothing if the key already exists" do
      @registry.create_key("HKCU\\Software\\Root\\Trunk\\Peck\\Woodpecker", false).should == true
      @registry.key_exists?("HKCU\\Software\\Root\\Trunk\\Peck\\Woodpecker").should == true
    end

    it "throws an exception of the hive does not exist" do
      lambda {@registry.create_key("JKLM\\Software\\Root\\Trunk\\Peck\\Woodpecker", false)}.should raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end
  end

  describe "delete_value" do
    before(:all) do
      ::Win32::Registry::HKEY_CURRENT_USER.create "Software\\Root\\Trunk\\Peck\\Woodpecker"
      ::Win32::Registry::HKEY_CURRENT_USER.open('Software\\Root\\Trunk\\Peck\\Woodpecker', Win32::Registry::KEY_ALL_ACCESS) do |reg|
        reg['Peter', Win32::Registry::REG_SZ] = 'Tiny'
      end
    end

    it "deletes values if the value exists" do
      @registry.delete_value("HKCU\\Software\\Root\\Trunk\\Peck\\Woodpecker", {:name=>"Peter", :type=>:string, :data=>"Tiny"}).should == true
      @registry.value_exists?("HKCU\\Software\\Root\\Trunk\\Peck\\Woodpecker", {:name=>"Peter", :type=>:string, :data=>"Tiny"}).should == false
    end

    it "does nothing if value does not exist" do
      @registry.delete_value("HKCU\\Software\\Root\\Trunk\\Peck\\Woodpecker", {:name=>"Peter", :type=>:string, :data=>"Tiny"}).should == true
      @registry.value_exists?("HKCU\\Software\\Root\\Trunk\\Peck\\Woodpecker", {:name=>"Peter", :type=>:string, :data=>"Tiny"}).should == false
    end

    it "throws an exception if the key does not exist?" do
      lambda {@registry.delete_value("HKCU\\Software\\Trunk\\Peck\\Woodpecker", {:name=>"Peter", :type=>:string, :data=>"Tiny"})}.should raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end

    it "throws an exception if the hive does not exist" do
      lambda {@registry.delete_value("JKLM\\Software\\Root\\Trunk\\Peck\\Woodpecker", {:name=>"Peter", :type=>:string, :data=>"Tiny"})}.should raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end
  end

  describe "delete_key" do
    before (:all) do
      ::Win32::Registry::HKEY_CURRENT_USER.create "Software\\Root\\Branch\\Fruit"
      ::Win32::Registry::HKEY_CURRENT_USER.open('Software\\Root\\Branch\\Fruit', Win32::Registry::KEY_ALL_ACCESS) do |reg|
        reg['Apple', Win32::Registry::REG_MULTI_SZ] = ["Red", "Juicy"]
      end
      ::Win32::Registry::HKEY_CURRENT_USER.create "Software\\Root\\Trunk\\Peck\\Woodpecker"
      ::Win32::Registry::HKEY_CURRENT_USER.open('Software\\Root\\Trunk\\Peck\\Woodpecker', Win32::Registry::KEY_ALL_ACCESS) do |reg|
        reg['Peter', Win32::Registry::REG_SZ] = 'Tiny'
      end
    end

    it "deletes a key if it has no subkeys" do
      @registry.delete_key("HKCU\\Software\\Root\\Branch\\Fruit", false).should == true
      @registry.key_exists?("HKCU\\Software\\Root\\Branch\\Fruit").should == false
    end

    it "throws an exception if key to delete has subkeys and recursive is false" do
      lambda { @registry.delete_key("HKCU\\Software\\Root\\Trunk", false) }.should raise_error(Chef::Exceptions::Win32RegNoRecursive)
      @registry.key_exists?("HKCU\\Software\\Root\\Trunk\\Peck\\Woodpecker").should == true
    end

    it "deletes a key if it has subkeys and recursive true" do
      @registry.delete_key("HKCU\\Software\\Root\\Trunk", true).should == true
      @registry.key_exists?("HKCU\\Software\\Root\\Trunk").should == false
    end

    it "does nothing if the key does not exist" do
      @registry.delete_key("HKCU\\Software\\Root\\Trunk", true).should == true
      @registry.key_exists?("HKCU\\Software\\Root\\Trunk").should == false
    end

    it "throws an exception if the hive does not exist" do
      lambda {@registry.delete_key("JKLM\\Software\\Root\\Branch\\Flower", false)}.should raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end
  end

  describe "has_subkeys?" do
    before(:all) do
      ::Win32::Registry::HKEY_CURRENT_USER.create "Software\\Root\\Trunk"
      ::Win32::Registry::HKEY_CURRENT_USER.open("Software\\Root\\Trunk") do |reg|
        begin
          reg.delete_key("Red", true)
        rescue
        end
      end
    end

    it "throws an exception if the hive was missing" do
      lambda {@registry.has_subkeys?("LMNO\\Software\\Root")}.should raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end

    it "throws an exception if the key is missing" do
      lambda {@registry.has_subkeys?("HKCU\\Software\\Root\\Trunk\\Red")}.should raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end

    it "returns true if the key has subkeys" do
      @registry.has_subkeys?("HKCU\\Software\\Root").should == true
    end

    it "returns false if the key has no subkeys" do
      ::Win32::Registry::HKEY_CURRENT_USER.create "Software\\Root\\Trunk\\Red"
      @registry.has_subkeys?("HKCU\\Software\\Root\\Trunk\\Red").should == false
    end
  end

  describe "get_subkeys" do
    it "throws an exception if the key is missing" do
      lambda {@registry.get_subkeys("HKCU\\Software\\Trunk\\Red")}.should raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end
    it "throws an exception if the hive does not exist" do
      lambda {@registry.get_subkeys("JKLM\\Software\\Root")}.should raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end
    it "returns the array of subkeys for a given key" do
      subkeys = @registry.get_subkeys("HKCU\\Software\\Root")
      reg_subkeys = []
      ::Win32::Registry::HKEY_CURRENT_USER.open("Software\\Root", Win32::Registry::KEY_ALL_ACCESS) do |reg|
        reg.each_key{|name| reg_subkeys << name}
      end
      reg_subkeys.should == subkeys
    end
  end

  describe "architecture" do
    describe "on 32-bit" do
      before(:all) do
        @saved_kernel_machine = @node.automatic_attrs[:kernel][:machine]
        @node.automatic_attrs[:kernel][:machine] = :i386
      end

      after(:all) do
        @node.automatic_attrs[:kernel][:machine] = @saved_kernel_machine
      end

      context "registry constructor" do
        it "throws an exception if requested architecture is 64bit but running on 32bit" do
          lambda {Chef::Win32::Registry.new(@run_context, :x86_64)}.should raise_error(Chef::Exceptions::Win32RegArchitectureIncorrect)
        end

        it "can correctly set the requested architecture to 32-bit" do
          @r = Chef::Win32::Registry.new(@run_context, :i386)
          @r.architecture.should == :i386
          @r.registry_system_architecture.should == 0x0200
        end

        it "can correctly set the requested architecture to :machine" do
          @r = Chef::Win32::Registry.new(@run_context, :machine)
          @r.architecture.should == :machine
          @r.registry_system_architecture.should == 0x0200
        end
      end

      context "architecture setter" do
        it "throws an exception if requested architecture is 64bit but running on 32bit" do
          lambda {@registry.architecture = :x86_64}.should raise_error(Chef::Exceptions::Win32RegArchitectureIncorrect)
        end

        it "sets the requested architecture to :machine if passed :machine" do
          @registry.architecture = :machine
          @registry.architecture.should == :machine
          @registry.registry_system_architecture.should == 0x0200
        end

        it "sets the requested architecture to 32-bit if passed i386 as a string" do
          @registry.architecture = :i386
          @registry.architecture.should == :i386
          @registry.registry_system_architecture.should == 0x0200
        end
      end
    end

    describe "on 64-bit" do
      before(:all) do
        @saved_kernel_machine = @node.automatic_attrs[:kernel][:machine]
        @node.automatic_attrs[:kernel][:machine] = :x86_64
      end

      after(:all) do
        @node.automatic_attrs[:kernel][:machine] = @saved_kernel_machine
      end

      context "registry constructor" do
        it "can correctly set the requested architecture to 32-bit" do
          @r = Chef::Win32::Registry.new(@run_context, :i386)
          @r.architecture.should == :i386
          @r.registry_system_architecture.should == 0x0200
        end

        it "can correctly set the requested architecture to 64-bit" do
          @r = Chef::Win32::Registry.new(@run_context, :x86_64)
          @r.architecture.should == :x86_64
          @r.registry_system_architecture.should == 0x0100
        end

        it "can correctly set the requested architecture to :machine" do
          @r = Chef::Win32::Registry.new(@run_context, :machine)
          @r.architecture.should == :machine
          @r.registry_system_architecture.should == 0x0100
        end
      end

      context "architecture setter" do
        it "sets the requested architecture to 64-bit if passed 64-bit" do
          @registry.architecture = :x86_64
          @registry.architecture.should == :x86_64
          @registry.registry_system_architecture.should == 0x0100
        end

        it "sets the requested architecture to :machine if passed :machine" do
          @registry.architecture = :machine
          @registry.architecture.should == :machine
          @registry.registry_system_architecture.should == 0x0100
        end

        it "sets the requested architecture to 32-bit if passed 32-bit" do
          @registry.architecture = :i386
          @registry.architecture.should == :i386
          @registry.registry_system_architecture.should == 0x0200
        end
      end
    end

    describe "when running on an actual 64-bit server", :windows64_only do
      before(:all) do
        begin
          ::Win32::Registry::HKEY_LOCAL_MACHINE.open("Software\\Root", ::Win32::Registry::KEY_ALL_ACCESS | 0x0100) do |reg|
            reg.delete_key("Trunk", true)
          end
        rescue
        end
        begin
          ::Win32::Registry::HKEY_LOCAL_MACHINE.open("Software\\Root", ::Win32::Registry::KEY_ALL_ACCESS | 0x0200) do |reg|
            reg.delete_key("Trunk", true)
          end
        rescue
        end
        # 64-bit
        ::Win32::Registry::HKEY_LOCAL_MACHINE.create("Software\\Root\\Mauve", ::Win32::Registry::KEY_ALL_ACCESS | 0x0100)
        ::Win32::Registry::HKEY_LOCAL_MACHINE.open('Software\\Root\\Mauve', Win32::Registry::KEY_ALL_ACCESS | 0x0100) do |reg|
          reg['Alert', Win32::Registry::REG_SZ] = 'Universal'
        end
        # 32-bit
        ::Win32::Registry::HKEY_LOCAL_MACHINE.create("Software\\Root\\Poosh", ::Win32::Registry::KEY_ALL_ACCESS | 0x0200)
        ::Win32::Registry::HKEY_LOCAL_MACHINE.open('Software\\Root\\Poosh', Win32::Registry::KEY_ALL_ACCESS | 0x0200) do |reg|
          reg['Status', Win32::Registry::REG_SZ] = 'Lost'
        end
      end

      after(:all) do
        ::Win32::Registry::HKEY_LOCAL_MACHINE.open("Software\\Root", ::Win32::Registry::KEY_ALL_ACCESS | 0x0100) do |reg|
          reg.delete_key("Trunk", true)
        end
        ::Win32::Registry::HKEY_LOCAL_MACHINE.open("Software\\Root", ::Win32::Registry::KEY_ALL_ACCESS | 0x0200) do |reg|
          reg.delete_key("Trunk", true)
        end
      end

      describe "key_exists?" do
        it "does not find 64-bit keys in the 32-bit registry" do
          @registry.architecture=:i386
          @registry.key_exists?("HKLM\\Software\\Root\\Mauve").should == false
        end
        it "finds 32-bit keys in the 32-bit registry" do
          @registry.architecture=:i386
          @registry.key_exists?("HKLM\\Software\\Root\\Poosh").should == true
        end
        it "does not find 32-bit keys in the 64-bit registry" do
          @registry.architecture=:x86_64
          @registry.key_exists?("HKLM\\Software\\Root\\Mauve").should == true
        end
        it "finds 64-bit keys in the 64-bit registry" do
          @registry.architecture=:x86_64
          @registry.key_exists?("HKLM\\Software\\Root\\Poosh").should == false
        end
      end

      describe "value_exists?" do
        it "does not find 64-bit values in the 32-bit registry" do
          @registry.architecture=:i386
          lambda{@registry.value_exists?("HKLM\\Software\\Root\\Mauve", {:name=>"Alert"})}.should raise_error(Chef::Exceptions::Win32RegKeyMissing)
        end
        it "finds 32-bit values in the 32-bit registry" do
          @registry.architecture=:i386
          @registry.value_exists?("HKLM\\Software\\Root\\Poosh", {:name=>"Status"}).should == true
        end
        it "does not find 32-bit values in the 64-bit registry" do
          @registry.architecture=:x86_64
          @registry.value_exists?("HKLM\\Software\\Root\\Mauve", {:name=>"Alert"}).should == true
        end
        it "finds 64-bit values in the 64-bit registry" do
          @registry.architecture=:x86_64
          lambda{@registry.value_exists?("HKLM\\Software\\Root\\Poosh", {:name=>"Status"})}.should raise_error(Chef::Exceptions::Win32RegKeyMissing)
        end
      end

      describe "data_exists?" do
        it "does not find 64-bit keys in the 32-bit registry" do
          @registry.architecture=:i386
          lambda{@registry.data_exists?("HKLM\\Software\\Root\\Mauve", {:name=>"Alert", :type=>:string, :data=>"Universal"})}.should raise_error(Chef::Exceptions::Win32RegKeyMissing)
        end
        it "finds 32-bit keys in the 32-bit registry" do
          @registry.architecture=:i386
          @registry.data_exists?("HKLM\\Software\\Root\\Poosh", {:name=>"Status", :type=>:string, :data=>"Lost"}).should == true
        end
        it "does not find 32-bit keys in the 64-bit registry" do
          @registry.architecture=:x86_64
          @registry.data_exists?("HKLM\\Software\\Root\\Mauve", {:name=>"Alert", :type=>:string, :data=>"Universal"}).should == true
        end
        it "finds 64-bit keys in the 64-bit registry" do
          @registry.architecture=:x86_64
          lambda{@registry.data_exists?("HKLM\\Software\\Root\\Poosh", {:name=>"Status", :type=>:string, :data=>"Lost"})}.should raise_error(Chef::Exceptions::Win32RegKeyMissing)
        end
      end

      describe "create_key" do
        it "can create a 32-bit only registry key" do
          @registry.architecture = :i386
          @registry.create_key("HKLM\\Software\\Root\\Trunk\\Red", true).should == true
          @registry.key_exists?("HKLM\\Software\\Root\\Trunk\\Red").should == true
          @registry.architecture = :x86_64
          @registry.key_exists?("HKLM\\Software\\Root\\Trunk\\Red").should == false
        end

        it "can create a 64-bit only registry key" do
          @registry.architecture = :x86_64
          @registry.create_key("HKLM\\Software\\Root\\Trunk\\Blue", true).should == true
          @registry.key_exists?("HKLM\\Software\\Root\\Trunk\\Blue").should == true
          @registry.architecture = :i386
          @registry.key_exists?("HKLM\\Software\\Root\\Trunk\\Blue").should == false
        end
      end

    end
  end
end
