#
# Author:: Prajakta Purohit (prajakta@opscode.com)
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

describe Chef::Provider::RegistryKey do

  let(:value1) { { :name => "one", :type => :string, :data => "1" } }
  let(:key_path) { 'HKCU\Software\OpscodeNumbers' }
  let(:key) { 'Software\OpscodeNumbers' }
  let(:key_parent) { 'Software' }
  let(:key_to_delete) { 'OpscodeNumbers' }
  let(:sub_key) {'OpscodePrimes'}
  let(:missing_key_path) {'HKCU\Software'}

  before(:each) do
    Chef::Win32::Registry.any_instance.stub(:machine_architecture).and_return(:x86_64)
    @registry = Chef::Win32::Registry.new()

    #Making the values for registry constants available on unix
    Object.send(:remove_const, 'Win32') if defined?(Win32)
    Win32 = Module.new
    Win32::Registry = Class.new
    Win32::Registry::KEY_SET_VALUE = 0x0002
    Win32::Registry::KEY_QUERY_VALUE = 0x0001
    Win32::Registry::KEY_WRITE = 0x00020000 | 0x0002 | 0x0004
    Win32::Registry::KEY_READ = 0x00020000 | 0x0001 | 0x0008 | 0x0010

    Win32::Registry::Error = Class.new(RuntimeError)

    @hive_mock = mock("::Win32::Registry::HKEY_CURRENT_USER")
    @reg_mock = mock("reg")
  end

  describe "get_values" do
    it "gets all values for a key if the key exists" do
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key])
      @registry.should_receive(:key_exists!).with(key_path).and_return(true)
      @hive_mock.should_receive(:open).with(key, ::Win32::Registry::KEY_READ | @registry.registry_system_architecture).and_yield(@reg_mock)
      @reg_mock.should_receive(:map)
      @registry.get_values(key_path)
    end

    it "throws an exception if key does not exist" do
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key])
      @registry.should_receive(:key_exists!).with(key_path).and_raise(Chef::Exceptions::Win32RegKeyMissing)
      lambda{@registry.get_values(key_path)}.should raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end
  end

  describe "set_value" do
    it "does nothing if key and hive and value exist" do
      @registry.should_receive(:key_exists!).with(key_path).and_return(true)
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key])
      @registry.should_receive(:value_exists?).with(key_path, value1).and_return(true)
      @registry.should_receive(:data_exists?).with(key_path, value1).and_return(true)
      @registry.set_value(key_path, value1)
    end

    it "updates value if key and hive and value exist, but data is different" do
      @registry.should_receive(:key_exists!).with(key_path).and_return(true)
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key])
      @registry.should_receive(:value_exists?).with(key_path, value1).and_return(true)
      @registry.should_receive(:data_exists?).with(key_path, value1).and_return(false)
      @hive_mock.should_receive(:open).with(key, Win32::Registry::KEY_SET_VALUE | ::Win32::Registry::KEY_QUERY_VALUE | @registry.registry_system_architecture).and_yield(@reg_mock)
      @registry.should_receive(:get_type_from_name).with(:string).and_return(1)
      @reg_mock.should_receive(:write).with("one", 1, "1")
      @registry.set_value(key_path, value1)
    end

    it "creates value if the key exists and the value does not exist" do
      @registry.should_receive(:key_exists!).with(key_path).and_return(true)
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key])
      @registry.should_receive(:value_exists?).with(key_path, value1).and_return(false)
      @hive_mock.should_receive(:open).with(key, ::Win32::Registry::KEY_SET_VALUE | ::Win32::Registry::KEY_QUERY_VALUE | @registry.registry_system_architecture).and_yield(@reg_mock)
      @registry.should_receive(:get_type_from_name).with(:string).and_return(1)
      @reg_mock.should_receive(:write).with("one", 1, "1")
      @registry.set_value(key_path, value1)
    end

    it "should raise an exception if the key does not exist" do
      @registry.should_receive(:key_exists!).with(key_path).and_raise(Chef::Exceptions::Win32RegKeyMissing)
      lambda {@registry.set_value(key_path, value1)}.should raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end
  end

  describe "delete_value" do
    it "deletes value if value exists" do
      @registry.should_receive(:value_exists?).with(key_path, value1).and_return(true)
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key])
      @hive_mock.should_receive(:open).with(key, ::Win32::Registry::KEY_SET_VALUE | @registry.registry_system_architecture).and_yield(@reg_mock)
      @reg_mock.should_receive(:delete_value).with("one").and_return(true)
      @registry.delete_value(key_path, value1)
    end

    it "raises an exception if the key does not exist" do
      @registry.should_receive(:value_exists?).with(key_path, value1).and_return(true)
      @registry.should_receive(:get_hive_and_key).with(key_path).and_raise(Chef::Exceptions::Win32RegKeyMissing)
      @registry.delete_value(key_path, value1)
    end

    it "does nothing if the value does not exist" do
      @registry.should_receive(:value_exists?).with(key_path, value1).and_return(false)
      @registry.delete_value(key_path, value1)
    end
  end

  describe "create_key" do
    it "creates key if intermediate keys are missing and recursive is set to true" do
      @registry.should_receive(:keys_missing?).with(key_path).and_return(true)
      @registry.should_receive(:create_missing).with(key_path)
      @registry.should_receive(:key_exists?).with(key_path).and_return(false)
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key])
      @hive_mock.should_receive(:create).with(key, ::Win32::Registry::KEY_WRITE | @registry.registry_system_architecture)
      @registry.create_key(key_path, true)
    end

    it "raises an exception if intermediate keys are missing and recursive is set to false" do
      @registry.should_receive(:keys_missing?).with(key_path).and_return(true)
      lambda{@registry.create_key(key_path, false)}.should raise_error(Chef::Exceptions::Win32RegNoRecursive)
    end

    it "does nothing if the key exists" do
      @registry.should_receive(:keys_missing?).with(key_path).and_return(true)
      @registry.should_receive(:create_missing).with(key_path)
      @registry.should_receive(:key_exists?).with(key_path).and_return(true)
      @registry.create_key(key_path, true)
    end

    it "create key if intermediate keys not missing and recursive is set to false" do
      @registry.should_receive(:keys_missing?).with(key_path).and_return(false)
      @registry.should_receive(:key_exists?).with(key_path).and_return(false)
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key])
      @hive_mock.should_receive(:create).with(key, ::Win32::Registry::KEY_WRITE | @registry.registry_system_architecture)
      @registry.create_key(key_path, false)
    end

    it "create key if intermediate keys not missing and recursive is set to true" do
      @registry.should_receive(:keys_missing?).with(key_path).and_return(false)
      @registry.should_receive(:key_exists?).with(key_path).and_return(false)
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key])
      @hive_mock.should_receive(:create).with(key, ::Win32::Registry::KEY_WRITE | @registry.registry_system_architecture)
      @registry.create_key(key_path, true)
    end
  end

  describe "delete_key" do
    it "deletes key if it has subkeys and recursive is set to true" do
      @registry.should_receive(:key_exists?).with(key_path).and_return(true)
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key])
      @registry.should_receive(:has_subkeys?).with(key_path).and_return(true)
      @hive_mock.should_receive(:open).with(key_parent, ::Win32::Registry::KEY_WRITE | @registry.registry_system_architecture).and_yield(@reg_mock)
      @reg_mock.should_receive(:delete_key).with(key_to_delete, true)
      @registry.delete_key(key_path, true)
    end

    it "raises an exception if it has subkeys but recursive is set to false" do
      @registry.should_receive(:key_exists?).with(key_path).and_return(true)
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key])
      @registry.should_receive(:has_subkeys?).with(key_path).and_return(true)
      lambda{@registry.delete_key(key_path, false)}.should raise_error(Chef::Exceptions::Win32RegNoRecursive)
    end

    it "deletes key if the key exists and has no subkeys" do
      @registry.should_receive(:key_exists?).with(key_path).and_return(true)
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key])
      @registry.should_receive(:has_subkeys?).with(key_path).and_return(false)
      @hive_mock.should_receive(:open).with(key_parent, ::Win32::Registry::KEY_WRITE | @registry.registry_system_architecture).and_yield(@reg_mock)
      @reg_mock.should_receive(:delete_key).with(key_to_delete)
      @registry.delete_key(key_path, true)
    end
  end

  describe "key_exists?" do
    it "returns true if key_exists" do
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key])
      @hive_mock.should_receive(:open).with(key, ::Win32::Registry::KEY_READ | @registry.registry_system_architecture).and_yield(@reg_mock)
      @registry.key_exists?(key_path).should == true
    end

    it "returns false if key does not exist" do
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key])
      @hive_mock.should_receive(:open).with(key, ::Win32::Registry::KEY_READ | @registry.registry_system_architecture).and_raise(::Win32::Registry::Error)
      @registry.key_exists?(key_path).should == false
    end
  end

  describe "key_exists!" do
    it "throws an exception if the key_parent does not exist" do
      @registry.should_receive(:key_exists?).with(key_path).and_return(false)
      lambda{@registry.key_exists!(key_path)}.should raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end
  end

  describe "hive_exists?" do
    it "returns true if the hive exists" do
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key])
      @registry.hive_exists?(key_path) == true
    end

    it "returns false if the hive does not exist" do
      @registry.should_receive(:get_hive_and_key).with(key_path).and_raise(Chef::Exceptions::Win32RegHiveMissing)
      @registry.hive_exists?(key_path) == false
    end
  end

  describe "has_subkeys?" do
    it "returns true if the key has subkeys" do
      @registry.should_receive(:key_exists!).with(key_path).and_return(true)
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key])
      @hive_mock.should_receive(:open).with(key, ::Win32::Registry::KEY_READ | @registry.registry_system_architecture).and_yield(@reg_mock)
      @reg_mock.should_receive(:each_key).and_yield(key)
      @registry.has_subkeys?(key_path) == true
    end

    it "returns false if the key does not have subkeys" do
      @registry.should_receive(:key_exists!).with(key_path).and_return(true)
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key])
      @hive_mock.should_receive(:open).with(key, ::Win32::Registry::KEY_READ | @registry.registry_system_architecture).and_yield(@reg_mock)
      @reg_mock.should_receive(:each_key).and_return(no_args())
      @registry.has_subkeys?(key_path).should == false
    end

    it "throws an exception if the key does not exist" do
      @registry.should_receive(:key_exists!).with(key_path).and_raise(Chef::Exceptions::Win32RegKeyMissing)
      lambda {@registry.set_value(key_path, value1)}.should raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end
  end

  describe "get_subkeys" do
    it "returns the subkeys if they exist" do
      @registry.should_receive(:key_exists!).with(key_path).and_return(true)
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key])
      @hive_mock.should_receive(:open).with(key, ::Win32::Registry::KEY_READ | @registry.registry_system_architecture).and_yield(@reg_mock)
      @reg_mock.should_receive(:each_key).and_yield(sub_key)
      @registry.get_subkeys(key_path)
    end
  end

  describe "value_exists?" do
    it "throws an exception if the key does not exist" do
      @registry.should_receive(:key_exists!).with(key_path).and_raise(Chef::Exceptions::Win32RegKeyMissing)
      lambda {@registry.value_exists?(key_path, value1)}.should raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end

    it "returns true if the value exists" do
      @registry.should_receive(:key_exists!).with(key_path).and_return(true)
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key])
      @hive_mock.should_receive(:open).with(key, ::Win32::Registry::KEY_READ | @registry.registry_system_architecture).and_yield(@reg_mock)
      @reg_mock.should_receive(:any?).and_yield("one")
      @registry.value_exists?(key_path, value1) == true
    end

    it "returns false if the value does not exist" do
      @registry.should_receive(:key_exists!).with(key_path).and_return(true)
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key])
      @hive_mock.should_receive(:open).with(key, ::Win32::Registry::KEY_READ | @registry.registry_system_architecture).and_yield(@reg_mock)
      @reg_mock.should_receive(:any?).and_yield(no_args())
      @registry.value_exists?(key_path, value1) == false
    end
  end

  describe "data_exists?" do
    it "throws an exception if the key does not exist" do
      @registry.should_receive(:key_exists!).with(key_path).and_raise(Chef::Exceptions::Win32RegKeyMissing)
      lambda {@registry.data_exists?(key_path, value1)}.should raise_error(Chef::Exceptions::Win32RegKeyMissing)
    end

    it "returns true if the data exists" do
      @registry.should_receive(:key_exists!).with(key_path).and_return(true)
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key])
      @registry.should_receive(:get_type_from_name).with(:string).and_return(1)
      @reg_mock.should_receive(:each).with(no_args()).and_yield("one", 1, "1")
      @hive_mock.should_receive(:open).with(key, ::Win32::Registry::KEY_READ | @registry.registry_system_architecture).and_yield(@reg_mock)
      @registry.data_exists?(key_path, value1).should == true
    end

    it "returns false if the data does not exist" do
      @registry.should_receive(:key_exists!).with(key_path).and_return(true)
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key])
      @hive_mock.should_receive(:open).with(key, ::Win32::Registry::KEY_READ | @registry.registry_system_architecture).and_yield(@reg_mock)
      @registry.should_receive(:get_type_from_name).with(:string).and_return(1)
      @reg_mock.should_receive(:each).with(no_args()).and_yield("one", 1, "2")
      @registry.data_exists?(key_path, value1).should == false
    end
  end

  describe "value_exists!" do
    it "does nothing if the value exists" do
      @registry.should_receive(:value_exists?).with(key_path, value1).and_return(true)
      @registry.value_exists!(key_path, value1)
    end

    it "throws an exception if the value does not exist" do
      @registry.should_receive(:value_exists?).with(key_path, value1).and_return(false)
      lambda{@registry.value_exists!(key_path, value1)}.should raise_error(Chef::Exceptions::Win32RegValueMissing)
    end
  end

  describe "data_exists!" do
    it "does nothing if the data exists" do
      @registry.should_receive(:data_exists?).with(key_path, value1).and_return(true)
      @registry.data_exists!(key_path, value1)
    end

    it "throws an exception if the data does not exist" do
      @registry.should_receive(:data_exists?).with(key_path, value1).and_return(false)
      lambda{@registry.data_exists!(key_path, value1)}.should raise_error(Chef::Exceptions::Win32RegDataMissing)
    end
  end

  describe "type_matches?" do
    it "returns true if type matches" do
      @registry.should_receive(:value_exists!).with(key_path, value1).and_return(true)
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key])
      @hive_mock.should_receive(:open).with(key, ::Win32::Registry::KEY_READ | @registry.registry_system_architecture).and_yield(@reg_mock)
      @registry.should_receive(:get_type_from_name).with(:string).and_return(1)
      @reg_mock.should_receive(:each).and_yield("one", 1)
      @registry.type_matches?(key_path, value1).should == true
    end

    it "returns false if type does not match" do
      @registry.should_receive(:value_exists!).with(key_path, value1).and_return(true)
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key])
      @hive_mock.should_receive(:open).with(key, ::Win32::Registry::KEY_READ | @registry.registry_system_architecture).and_yield(@reg_mock)
      @reg_mock.should_receive(:each).and_yield("two", 2)
      @registry.type_matches?(key_path, value1).should == false
    end

    it "throws an exception if value does not exist" do
      @registry.should_receive(:value_exists?).with(key_path, value1).and_return(false)
      lambda{@registry.type_matches?(key_path, value1)}.should raise_error(Chef::Exceptions::Win32RegValueMissing)
    end
  end

  describe "type_matches!" do
    it "does nothing if the type_matches" do
      @registry.should_receive(:type_matches?).with(key_path, value1).and_return(true)
      @registry.type_matches!(key_path, value1)
    end

    it "throws an exception if the type does not match" do
      @registry.should_receive(:type_matches?).with(key_path, value1).and_return(false)
      lambda{@registry.type_matches!(key_path, value1)}.should raise_error(Chef::Exceptions::Win32RegTypesMismatch)
    end
  end

  describe "keys_missing?" do
    it "returns true if the keys are missing" do
      @registry.should_receive(:key_exists?).with(missing_key_path).and_return(false)
      @registry.keys_missing?(key_path).should == true
    end

    it "returns false if no keys in the path are missing" do
      @registry.should_receive(:key_exists?).with(missing_key_path).and_return(true)
      @registry.keys_missing?(key_path).should == false
    end
  end
end
