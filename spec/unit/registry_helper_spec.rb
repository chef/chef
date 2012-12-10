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

module Win32
  class Registry
    KEY_SET_VALUE = 0x0002
    KEY_QUERY_VALUE = 0x0001
  end
end

describe Chef::Provider::RegistryKey do

  let(:value1) { { :name => "one", :type => :string, :data => "1" } }
  #let(:value2) { { :name => "two", :type => :string, :data => "2" } }
  let(:key_path) { 'HKCU\Software\OpscodeNumbers' }
  let(:key1) { 'Software\OpscodeNumbers' }

  before(:each) do
    Chef::Win32::Registry.any_instance.stub(:machine_architecture).and_return(:x86_64)
    @registry = Chef::Win32::Registry.new()
  end

  describe "when first created" do
    it "does nothing if key and hive and value exist" do
      @registry.should_receive(:key_exists!).with(key_path).and_return(true)
      @hive_mock = mock("::Win32::Registry::HKEY_CURRENT_USER")
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key1])
      @registry.should_receive(:value_exists?).with(key_path, value1).and_return(true)
      @registry.should_receive(:data_exists?).with(key_path, value1).and_return(true)
      @registry.set_value(key_path, value1)
    end

    it "updates value if key and hive and value exist, but data is different" do
      @registry.should_receive(:key_exists!).with(key_path).and_return(true)
      @hive_mock = mock("::Win32::Registry::HKEY_CURRENT_USER")
      @registry.should_receive(:get_hive_and_key).with(key_path).and_return([@hive_mock, key1])
      @registry.should_receive(:value_exists?).with(key_path, value1).and_return(true)
      @registry.should_receive(:data_exists?).with(key_path, value1).and_return(false)
      @reg_mock = mock("reg")
      @hive_mock.should_receive(:open).with(key1, ::Win32::Registry::KEY_SET_VALUE | ::Win32::Registry::KEY_QUERY_VALUE | @registry.registry_system_architecture).and_yield(@reg_mock)
      @registry.should_receive(:get_type_from_name).with(:string).and_return(1)
      @reg_mock.should_receive(:write).with("one", 1, "1")
      @registry.set_value(key_path, value1)
    end
  end
end
