#
# Author:: Prajakta Purohit (<prajakta@chef.io>)
# Author:: Lamont Granquist (<lamont@chef.io>)
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

require "spec_helper"
require "chef/win32/registry"

describe "Chef::Win32::Registry", :windows_only do

  before(:all) do
    # Create a registry item
    ::Win32::Registry::HKEY_CURRENT_USER.create "Software\\Root"
    ::Win32::Registry::HKEY_CURRENT_USER.create "Software\\Root\\Branch"
    ::Win32::Registry::HKEY_CURRENT_USER.create "Software\\Root\\B®anch"
    ::Win32::Registry::HKEY_CURRENT_USER.create "Software\\Root\\Branch\\Flower"
    ::Win32::Registry::HKEY_CURRENT_USER.open('Software\\Root', Win32::Registry::KEY_ALL_ACCESS) do |reg|
      reg["RootType1", Win32::Registry::REG_SZ] = "fibrous"
      reg.write("Roots", Win32::Registry::REG_MULTI_SZ, ["strong roots", "healthy tree"])
    end
    ::Win32::Registry::HKEY_CURRENT_USER.open('Software\\Root\\Branch', Win32::Registry::KEY_ALL_ACCESS) do |reg|
      reg["Strong", Win32::Registry::REG_SZ] = "bird nest"
    end
    ::Win32::Registry::HKEY_CURRENT_USER.open('Software\\Root\\Branch\\Flower', Win32::Registry::KEY_ALL_ACCESS) do |reg|
      reg["Petals", Win32::Registry::REG_MULTI_SZ] = %w{Pink Delicate}
    end

    # Create the node with ohai data
    events = Chef::EventDispatch::Dispatcher.new
    @node = Chef::Node.new
    @node.consume_external_attrs(OHAI_SYSTEM.data, {})
    @run_context = Chef::RunContext.new(@node, {}, events)

    # Create a registry object that has access ot the node previously created
    @registry = Chef::Win32::Registry.new(@run_context)
  end

  # Delete what is left of the registry key-values previously created
  after(:all) do
    ::Win32::Registry::HKEY_CURRENT_USER.open("Software") do |reg|
      reg.delete_key("Root", true)
    end
  end

  describe "hive_exists?" do
    it "returns true if the hive exists" do
      expect(@registry.hive_exists?("HKCU\\Software\\Root")).to eq(true)
    end

    it "returns false if the hive does not exist" do
      hive = expect(@registry.hive_exists?("LYRU\\Software\\Root")).to eq(false)
    end
  end

  describe "key_exists?" do
    it "returns true if the key path exists" do
      expect(@registry.key_exists?("HKCU\\Software\\Root\\Branch\\Flower")).to eq(true)
    end

    it "returns false if the key path does not exist" do
      expect(@registry.key_exists?("HKCU\\Software\\Branch\\Flower")).to eq(false)
    end

    it "throws an exception if the hive does not exist" do
      expect { @registry.key_exists?("JKLM\\Software\\Branch\\Flower") }.to raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end
  end

  describe "key_exists!" do
    it "returns true if the key path exists" do
      expect(@registry.key_exists!("HKCU\\Software\\Root\\Branch\\Flower")).to eq(true)
    end

    it "throws an exception if the key path does not exist" do
      expect { @registry.key_exists!("HKCU\\Software\\Branch\\Flower") }.to raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end

    it "throws an exception if the hive does not exist" do
      expect { @registry.key_exists!("JKLM\\Software\\Branch\\Flower") }.to raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end
  end

  describe "value_exists?" do
    it "throws an exception if the hive does not exist" do
      expect { @registry.value_exists?("JKLM\\Software\\Branch\\Flower", { name: "Petals" }) }.to raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end
    it "throws an exception if the key does not exist" do
      expect { @registry.value_exists?("HKCU\\Software\\Branch\\Flower", { name: "Petals" }) }.to raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end
    it "returns true if the value exists" do
      expect(@registry.value_exists?("HKCU\\Software\\Root\\Branch\\Flower", { name: "Petals" })).to eq(true)
    end
    it "returns true if the value exists with a case mismatch on the value name" do
      expect(@registry.value_exists?("HKCU\\Software\\Root\\Branch\\Flower", { name: "petals" })).to eq(true)
    end
    it "returns false if the value does not exist" do
      expect(@registry.value_exists?("HKCU\\Software\\Root\\Branch\\Flower", { name: "FOOBAR" })).to eq(false)
    end
  end

  describe "value_exists!" do
    it "throws an exception if the hive does not exist" do
      expect { @registry.value_exists!("JKLM\\Software\\Branch\\Flower", { name: "Petals" }) }.to raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end
    it "throws an exception if the key does not exist" do
      expect { @registry.value_exists!("HKCU\\Software\\Branch\\Flower", { name: "Petals" }) }.to raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end
    it "returns true if the value exists" do
      expect(@registry.value_exists!("HKCU\\Software\\Root\\Branch\\Flower", { name: "Petals" })).to eq(true)
    end
    it "returns true if the value exists with a case mismatch on the value name" do
      expect(@registry.value_exists!("HKCU\\Software\\Root\\Branch\\Flower", { name: "petals" })).to eq(true)
    end
    it "throws an exception if the value does not exist" do
      expect { @registry.value_exists!("HKCU\\Software\\Root\\Branch\\Flower", { name: "FOOBAR" }) }.to raise_error(Chef::Exceptions::Win32RegValueMissing)
    end
  end

  describe "data_exists?" do
    it "throws an exception if the hive does not exist" do
      expect { @registry.data_exists?("JKLM\\Software\\Branch\\Flower", { name: "Petals", type: :multi_string, data: %w{Pink Delicate} }) }.to raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end
    it "throws an exception if the key does not exist" do
      expect { @registry.data_exists?("HKCU\\Software\\Branch\\Flower", { name: "Petals", type: :multi_string, data: %w{Pink Delicate} }) }.to raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end
    it "returns true if all the data matches" do
      expect(@registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", { name: "Petals", type: :multi_string, data: %w{Pink Delicate} })).to eq(true)
    end
    it "returns true if all the data matches with a case mismatch on the data name" do
      expect(@registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", { name: "petals", type: :multi_string, data: %w{Pink Delicate} })).to eq(true)
    end
    it "returns false if the name does not exist" do
      expect(@registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", { name: "slateP", type: :multi_string, data: %w{Pink Delicate} })).to eq(false)
    end
    it "returns false if the types do not match" do
      expect(@registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", { name: "Petals", type: :string, data: "Pink" })).to eq(false)
    end
    it "returns false if the data does not match" do
      expect(@registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", { name: "Petals", type: :multi_string, data: %w{Mauve Delicate} })).to eq(false)
    end
  end

  describe "data_exists!" do
    it "throws an exception if the hive does not exist" do
      expect { @registry.data_exists!("JKLM\\Software\\Branch\\Flower", { name: "Petals", type: :multi_string, data: %w{Pink Delicate} }) }.to raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end
    it "throws an exception if the key does not exist" do
      expect { @registry.data_exists!("HKCU\\Software\\Branch\\Flower", { name: "Petals", type: :multi_string, data: %w{Pink Delicate} }) }.to raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end
    it "returns true if all the data matches" do
      expect(@registry.data_exists!("HKCU\\Software\\Root\\Branch\\Flower", { name: "Petals", type: :multi_string, data: %w{Pink Delicate} })).to eq(true)
    end
    it "returns true if all the data matches with a case mismatch on the data name" do
      expect(@registry.data_exists!("HKCU\\Software\\Root\\Branch\\Flower", { name: "petals", type: :multi_string, data: %w{Pink Delicate} })).to eq(true)
    end
    it "throws an exception if the name does not exist" do
      expect { @registry.data_exists!("HKCU\\Software\\Root\\Branch\\Flower", { name: "slateP", type: :multi_string, data: %w{Pink Delicate} }) }.to raise_error(Chef::Exceptions::Win32RegDataMissing)
    end
    it "throws an exception if the types do not match" do
      expect { @registry.data_exists!("HKCU\\Software\\Root\\Branch\\Flower", { name: "Petals", type: :string, data: "Pink" }) }.to raise_error(Chef::Exceptions::Win32RegDataMissing)
    end
    it "throws an exception if the data does not match" do
      expect { @registry.data_exists!("HKCU\\Software\\Root\\Branch\\Flower", { name: "Petals", type: :multi_string, data: %w{Mauve Delicate} }) }.to raise_error(Chef::Exceptions::Win32RegDataMissing)
    end
  end

  describe "get_values" do
    it "returns all values for a key if it exists" do
      values = @registry.get_values("HKCU\\Software\\Root")
      expect(values).to be_an_instance_of Array
      expect(values).to eq([{ name: "RootType1", type: :string, data: "fibrous" },
                        { name: "Roots", type: :multi_string, data: ["strong roots", "healthy tree"] }])
    end

    it "throws an exception if the key does not exist" do
      expect { @registry.get_values("HKCU\\Software\\Branch\\Flower") }.to raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end

    it "throws an exception if the hive does not exist" do
      expect { @registry.get_values("JKLM\\Software\\Branch\\Flower") }.to raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end
  end

  describe "set_value" do
    it "updates a value if the key, value exist and type matches and value different" do
      expect(@registry.set_value("HKCU\\Software\\Root\\Branch\\Flower", { name: "Petals", type: :multi_string, data: ["Yellow", "Changed Color"] })).to eq(true)
      expect(@registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", { name: "Petals", type: :multi_string, data: ["Yellow", "Changed Color"] })).to eq(true)
    end

    it "updates a value if the type does match and the values are different" do
      expect(@registry.set_value("HKCU\\Software\\Root\\Branch\\Flower", { name: "Petals", type: :string, data: "Yellow" })).to eq(true)
      expect(@registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", { name: "Petals", type: :string, data: "Yellow" })).to eq(true)
      expect(@registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", { name: "Petals", type: :multi_string, data: ["Yellow", "Changed Color"] })).to eq(false)
    end

    it "creates a value if key exists and value does not" do
      expect(@registry.set_value("HKCU\\Software\\Root\\Branch\\Flower", { name: "Stamen", type: :multi_string, data: ["Yellow", "Changed Color"] })).to eq(true)
      expect(@registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", { name: "Stamen", type: :multi_string, data: ["Yellow", "Changed Color"] })).to eq(true)
    end

    it "does nothing if data,type and name parameters for the value are same" do
      expect(@registry.set_value("HKCU\\Software\\Root\\Branch\\Flower", { name: "Stamen", type: :multi_string, data: ["Yellow", "Changed Color"] })).to eq(false)
      expect(@registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", { name: "Stamen", type: :multi_string, data: ["Yellow", "Changed Color"] })).to eq(true)
    end

    it "throws an exception if the key does not exist" do
      expect { @registry.set_value("HKCU\\Software\\Branch\\Flower", { name: "Petals", type: :multi_string, data: ["Yellow", "Changed Color"] }) }.to raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end

    it "throws an exception if the hive does not exist" do
      expect { @registry.set_value("JKLM\\Software\\Root\\Branch\\Flower", { name: "Petals", type: :multi_string, data: ["Yellow", "Changed Color"] }) }.to raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end

    # we are validating that the data gets .to_i called on it when type is a :dword

    it "casts an integer string given as a dword into an integer" do
      expect(@registry.set_value("HKCU\\Software\\Root\\Branch\\Flower", { name: "ShouldBe32767", type: :dword, data: "32767" })).to eq(true)
      expect(@registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", { name: "ShouldBe32767", type: :dword, data: 32767 })).to eq(true)
    end

    it "casts a nonsense string given as a dword into zero" do
      expect(@registry.set_value("HKCU\\Software\\Root\\Branch\\Flower", { name: "ShouldBeZero", type: :dword, data: "whatdoesthisdo" })).to eq(true)
      expect(@registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", { name: "ShouldBeZero", type: :dword, data: 0 })).to eq(true)
    end

    it "throws an exception when trying to cast an array to an int for a dword" do
      expect { @registry.set_value("HKCU\\Software\\Root\\Branch\\Flower", { name: "ShouldThrow", type: :dword, data: %w{one two} }) }.to raise_error NoMethodError
    end

    # we are validating that the data gets .to_s called on it when type is a :string

    it "stores the string representation of an array into a string if you pass it an array" do
      expect(@registry.set_value("HKCU\\Software\\Root\\Branch\\Flower", { name: "ShouldBePainful", type: :string, data: %w{one two} })).to eq(true)
      expect(@registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", { name: "ShouldBePainful", type: :string, data: '["one", "two"]' })).to eq(true)
    end

    it "stores the string representation of a number into a string if you pass it an number" do
      expect(@registry.set_value("HKCU\\Software\\Root\\Branch\\Flower", { name: "ShouldBe65535", type: :string, data: 65535 })).to eq(true)
      expect(@registry.data_exists?("HKCU\\Software\\Root\\Branch\\Flower", { name: "ShouldBe65535", type: :string, data: "65535" })).to eq(true)
    end

    # we are validating that the data gets .to_a called on it when type is a :multi_string

    it "throws an exception when a multi-string is passed a number" do
      expect { @registry.set_value("HKCU\\Software\\Root\\Branch\\Flower", { name: "ShouldThrow", type: :multi_string, data: 65535 }) }.to raise_error NoMethodError
    end

    it "throws an exception when a multi-string is passed a string" do
      expect { @registry.set_value("HKCU\\Software\\Root\\Branch\\Flower", { name: "ShouldBeWat", type: :multi_string, data: "foo" }) }.to raise_error NoMethodError
    end
  end

  describe "create_key" do
    before(:all) do
      ::Win32::Registry::HKEY_CURRENT_USER.open("Software\\Root") do |reg|

        reg.delete_key("Trunk", true)
      rescue

      end
    end

    it "throws an exception if the path has missing keys but recursive set to false" do
      expect { @registry.create_key("HKCU\\Software\\Root\\Trunk\\Peck\\Woodpecker", false) }.to raise_error(Chef::Exceptions::Win32RegNoRecursive)
      expect(@registry.key_exists?("HKCU\\Software\\Root\\Trunk\\Peck\\Woodpecker")).to eq(false)
    end

    it "creates the key_path if the keys were missing but recursive was set to true" do
      expect(@registry.create_key("HKCU\\Software\\Root\\Trunk\\Peck\\Woodpecker", true)).to eq(true)
      expect(@registry.key_exists?("HKCU\\Software\\Root\\Trunk\\Peck\\Woodpecker")).to eq(true)
    end

    it "does nothing if the key already exists" do
      expect(@registry.create_key("HKCU\\Software\\Root\\Trunk\\Peck\\Woodpecker", false)).to eq(true)
      expect(@registry.key_exists?("HKCU\\Software\\Root\\Trunk\\Peck\\Woodpecker")).to eq(true)
    end

    it "throws an exception of the hive does not exist" do
      expect { @registry.create_key("JKLM\\Software\\Root\\Trunk\\Peck\\Woodpecker", false) }.to raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end
  end

  describe "delete_value" do
    before(:all) do
      ::Win32::Registry::HKEY_CURRENT_USER.create "Software\\Root\\Trunk\\Peck\\Woodpecker"
      ::Win32::Registry::HKEY_CURRENT_USER.open('Software\\Root\\Trunk\\Peck\\Woodpecker', Win32::Registry::KEY_ALL_ACCESS) do |reg|
        reg["Peter", Win32::Registry::REG_SZ] = "Tiny"
      end
    end

    it "deletes values if the value exists" do
      expect(@registry.delete_value("HKCU\\Software\\Root\\Trunk\\Peck\\Woodpecker", { name: "Peter", type: :string, data: "Tiny" })).to eq(true)
      expect(@registry.value_exists?("HKCU\\Software\\Root\\Trunk\\Peck\\Woodpecker", { name: "Peter", type: :string, data: "Tiny" })).to eq(false)
    end

    it "does nothing if value does not exist" do
      expect(@registry.delete_value("HKCU\\Software\\Root\\Trunk\\Peck\\Woodpecker", { name: "Peter", type: :string, data: "Tiny" })).to eq(true)
      expect(@registry.value_exists?("HKCU\\Software\\Root\\Trunk\\Peck\\Woodpecker", { name: "Peter", type: :string, data: "Tiny" })).to eq(false)
    end

    it "throws an exception if the key does not exist?" do
      expect { @registry.delete_value("HKCU\\Software\\Trunk\\Peck\\Woodpecker", { name: "Peter", type: :string, data: "Tiny" }) }.to raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end

    it "throws an exception if the hive does not exist" do
      expect { @registry.delete_value("JKLM\\Software\\Root\\Trunk\\Peck\\Woodpecker", { name: "Peter", type: :string, data: "Tiny" }) }.to raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end
  end

  describe "delete_key" do
    before(:all) do
      ::Win32::Registry::HKEY_CURRENT_USER.create "Software\\Root\\Branch\\Fruit"
      ::Win32::Registry::HKEY_CURRENT_USER.open('Software\\Root\\Branch\\Fruit', Win32::Registry::KEY_ALL_ACCESS) do |reg|
        reg["Apple", Win32::Registry::REG_MULTI_SZ] = %w{Red Juicy}
      end
      ::Win32::Registry::HKEY_CURRENT_USER.create "Software\\Root\\Trunk\\Peck\\Woodpecker"
      ::Win32::Registry::HKEY_CURRENT_USER.open('Software\\Root\\Trunk\\Peck\\Woodpecker', Win32::Registry::KEY_ALL_ACCESS) do |reg|
        reg["Peter", Win32::Registry::REG_SZ] = "Tiny"
      end
    end

    it "deletes a key if it has no subkeys" do
      expect(@registry.delete_key("HKCU\\Software\\Root\\Branch\\Fruit", false)).to eq(true)
      expect(@registry.key_exists?("HKCU\\Software\\Root\\Branch\\Fruit")).to eq(false)
    end

    it "throws an exception if key to delete has subkeys and recursive is false" do
      expect { @registry.delete_key("HKCU\\Software\\Root\\Trunk", false) }.to raise_error(Chef::Exceptions::Win32RegNoRecursive)
      expect(@registry.key_exists?("HKCU\\Software\\Root\\Trunk\\Peck\\Woodpecker")).to eq(true)
    end

    it "deletes a key if it has subkeys and recursive true" do
      expect(@registry.delete_key("HKCU\\Software\\Root\\Trunk", true)).to eq(true)
      expect(@registry.key_exists?("HKCU\\Software\\Root\\Trunk")).to eq(false)
    end

    it "does nothing if the key does not exist" do
      expect(@registry.delete_key("HKCU\\Software\\Root\\Trunk", true)).to eq(true)
      expect(@registry.key_exists?("HKCU\\Software\\Root\\Trunk")).to eq(false)
    end

    it "throws an exception if the hive does not exist" do
      expect { @registry.delete_key("JKLM\\Software\\Root\\Branch\\Flower", false) }.to raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end
  end

  describe "has_subkeys?" do
    before(:all) do
      ::Win32::Registry::HKEY_CURRENT_USER.create "Software\\Root\\Trunk"
      ::Win32::Registry::HKEY_CURRENT_USER.open("Software\\Root\\Trunk") do |reg|

        reg.delete_key("Red", true)
      rescue

      end
    end

    it "throws an exception if the hive was missing" do
      expect { @registry.has_subkeys?("LMNO\\Software\\Root") }.to raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end

    it "throws an exception if the key is missing" do
      expect { @registry.has_subkeys?("HKCU\\Software\\Root\\Trunk\\Red") }.to raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end

    it "returns true if the key has subkeys" do
      expect(@registry.has_subkeys?("HKCU\\Software\\Root")).to eq(true)
    end

    it "returns false if the key has no subkeys" do
      ::Win32::Registry::HKEY_CURRENT_USER.create "Software\\Root\\Trunk\\Red"
      expect(@registry.has_subkeys?("HKCU\\Software\\Root\\Trunk\\Red")).to eq(false)
    end
  end

  describe "get_subkeys" do
    it "throws an exception if the key is missing" do
      expect { @registry.get_subkeys("HKCU\\Software\\Trunk\\Red") }.to raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end
    it "throws an exception if the hive does not exist" do
      expect { @registry.get_subkeys("JKLM\\Software\\Root") }.to raise_error(Chef::Exceptions::Win32RegHiveMissing)
    end
    it "returns the array of subkeys for a given key" do
      subkeys = @registry.get_subkeys("HKCU\\Software\\Root")
      reg_subkeys = []
      ::Win32::Registry::HKEY_CURRENT_USER.open("Software\\Root", Win32::Registry::KEY_ALL_ACCESS) do |reg|
        reg.each_key { |name| reg_subkeys << name }
      end
      expect(reg_subkeys).to eq(subkeys)
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
          expect { Chef::Win32::Registry.new(@run_context, :x86_64) }.to raise_error(Chef::Exceptions::Win32RegArchitectureIncorrect)
        end

        it "can correctly set the requested architecture to 32-bit" do
          @r = Chef::Win32::Registry.new(@run_context, :i386)
          expect(@r.architecture).to eq(:i386)
          expect(@r.registry_system_architecture).to eq(0x0200)
        end

        it "can correctly set the requested architecture to :machine" do
          @r = Chef::Win32::Registry.new(@run_context, :machine)
          expect(@r.architecture).to eq(:machine)
          expect(@r.registry_system_architecture).to eq(0x0200)
        end
      end

      context "architecture setter" do
        it "throws an exception if requested architecture is 64bit but running on 32bit" do
          expect { @registry.architecture = :x86_64 }.to raise_error(Chef::Exceptions::Win32RegArchitectureIncorrect)
        end

        it "sets the requested architecture to :machine if passed :machine" do
          @registry.architecture = :machine
          expect(@registry.architecture).to eq(:machine)
          expect(@registry.registry_system_architecture).to eq(0x0200)
        end

        it "sets the requested architecture to 32-bit if passed i386 as a string" do
          @registry.architecture = :i386
          expect(@registry.architecture).to eq(:i386)
          expect(@registry.registry_system_architecture).to eq(0x0200)
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
          expect(@r.architecture).to eq(:i386)
          expect(@r.registry_system_architecture).to eq(0x0200)
        end

        it "can correctly set the requested architecture to 64-bit" do
          @r = Chef::Win32::Registry.new(@run_context, :x86_64)
          expect(@r.architecture).to eq(:x86_64)
          expect(@r.registry_system_architecture).to eq(0x0100)
        end

        it "can correctly set the requested architecture to :machine" do
          @r = Chef::Win32::Registry.new(@run_context, :machine)
          expect(@r.architecture).to eq(:machine)
          expect(@r.registry_system_architecture).to eq(0x0100)
        end
      end

      context "architecture setter" do
        it "sets the requested architecture to 64-bit if passed 64-bit" do
          @registry.architecture = :x86_64
          expect(@registry.architecture).to eq(:x86_64)
          expect(@registry.registry_system_architecture).to eq(0x0100)
        end

        it "sets the requested architecture to :machine if passed :machine" do
          @registry.architecture = :machine
          expect(@registry.architecture).to eq(:machine)
          expect(@registry.registry_system_architecture).to eq(0x0100)
        end

        it "sets the requested architecture to 32-bit if passed 32-bit" do
          @registry.architecture = :i386
          expect(@registry.architecture).to eq(:i386)
          expect(@registry.registry_system_architecture).to eq(0x0200)
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
          reg["Alert", Win32::Registry::REG_SZ] = "Universal"
        end
        # 32-bit
        ::Win32::Registry::HKEY_LOCAL_MACHINE.create("Software\\Root\\Poosh", ::Win32::Registry::KEY_ALL_ACCESS | 0x0200)
        ::Win32::Registry::HKEY_LOCAL_MACHINE.open('Software\\Root\\Poosh', Win32::Registry::KEY_ALL_ACCESS | 0x0200) do |reg|
          reg["Status", Win32::Registry::REG_SZ] = "Lost"
        end
      end

      after(:all) do
        ::Win32::Registry::HKEY_LOCAL_MACHINE.open("Software", ::Win32::Registry::KEY_ALL_ACCESS | 0x0100) do |reg|
          reg.delete_key("Root", true)
        end
        ::Win32::Registry::HKEY_LOCAL_MACHINE.open("Software", ::Win32::Registry::KEY_ALL_ACCESS | 0x0200) do |reg|
          reg.delete_key("Root", true)
        end
      end

      describe "key_exists?" do
        it "does not find 64-bit keys in the 32-bit registry" do
          @registry.architecture = :i386
          expect(@registry.key_exists?("HKLM\\Software\\Root\\Mauve")).to eq(false)
        end
        it "finds 32-bit keys in the 32-bit registry" do
          @registry.architecture = :i386
          expect(@registry.key_exists?("HKLM\\Software\\Root\\Poosh")).to eq(true)
        end
        it "does not find 32-bit keys in the 64-bit registry" do
          @registry.architecture = :x86_64
          expect(@registry.key_exists?("HKLM\\Software\\Root\\Mauve")).to eq(true)
        end
        it "finds 64-bit keys in the 64-bit registry" do
          @registry.architecture = :x86_64
          expect(@registry.key_exists?("HKLM\\Software\\Root\\Poosh")).to eq(false)
        end
      end

      describe "value_exists?" do
        it "does not find 64-bit values in the 32-bit registry" do
          @registry.architecture = :i386
          expect { @registry.value_exists?("HKLM\\Software\\Root\\Mauve", { name: "Alert" }) }.to raise_error(Chef::Exceptions::Win32RegKeyMissing)
        end
        it "finds 32-bit values in the 32-bit registry" do
          @registry.architecture = :i386
          expect(@registry.value_exists?("HKLM\\Software\\Root\\Poosh", { name: "Status" })).to eq(true)
        end
        it "does not find 32-bit values in the 64-bit registry" do
          @registry.architecture = :x86_64
          expect(@registry.value_exists?("HKLM\\Software\\Root\\Mauve", { name: "Alert" })).to eq(true)
        end
        it "finds 64-bit values in the 64-bit registry" do
          @registry.architecture = :x86_64
          expect { @registry.value_exists?("HKLM\\Software\\Root\\Poosh", { name: "Status" }) }.to raise_error(Chef::Exceptions::Win32RegKeyMissing)
        end
      end

      describe "data_exists?" do
        it "does not find 64-bit keys in the 32-bit registry" do
          @registry.architecture = :i386
          expect { @registry.data_exists?("HKLM\\Software\\Root\\Mauve", { name: "Alert", type: :string, data: "Universal" }) }.to raise_error(Chef::Exceptions::Win32RegKeyMissing)
        end
        it "finds 32-bit keys in the 32-bit registry" do
          @registry.architecture = :i386
          expect(@registry.data_exists?("HKLM\\Software\\Root\\Poosh", { name: "Status", type: :string, data: "Lost" })).to eq(true)
        end
        it "does not find 32-bit keys in the 64-bit registry" do
          @registry.architecture = :x86_64
          expect(@registry.data_exists?("HKLM\\Software\\Root\\Mauve", { name: "Alert", type: :string, data: "Universal" })).to eq(true)
        end
        it "finds 64-bit keys in the 64-bit registry" do
          @registry.architecture = :x86_64
          expect { @registry.data_exists?("HKLM\\Software\\Root\\Poosh", { name: "Status", type: :string, data: "Lost" }) }.to raise_error(Chef::Exceptions::Win32RegKeyMissing)
        end
      end

      describe "create_key" do
        it "can create a 32-bit only registry key" do
          @registry.architecture = :i386
          expect(@registry.create_key("HKLM\\Software\\Root\\Trunk\\Red", true)).to eq(true)
          expect(@registry.key_exists?("HKLM\\Software\\Root\\Trunk\\Red")).to eq(true)
          @registry.architecture = :x86_64
          expect(@registry.key_exists?("HKLM\\Software\\Root\\Trunk\\Red")).to eq(false)
        end

        it "can create a 64-bit only registry key" do
          @registry.architecture = :x86_64
          expect(@registry.create_key("HKLM\\Software\\Root\\Trunk\\Blue", true)).to eq(true)
          expect(@registry.key_exists?("HKLM\\Software\\Root\\Trunk\\Blue")).to eq(true)
          @registry.architecture = :i386
          expect(@registry.key_exists?("HKLM\\Software\\Root\\Trunk\\Blue")).to eq(false)
        end
      end

    end
  end
end
