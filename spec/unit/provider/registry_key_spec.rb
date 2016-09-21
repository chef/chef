#
# Author:: Lamont Granquist (lamont@chef.io)
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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

shared_examples_for "a registry key" do
  describe "when first created" do
  end

  describe "executing load_current_resource" do
    describe "when the key exists" do
      before(:each) do
        expect(@double_registry).to receive(:key_exists?).with(keyname).and_return(true)
        expect(@double_registry).to receive(:get_values).with(keyname).and_return( testval2 )
        @provider.load_current_resource
      end

      it "should set the key of the current resource to the key of the new resource" do
        expect(@provider.current_resource.key).to eq(@new_resource.key)
      end

      it "should set the architecture of the current resource to the architecture of the new resource" do
        expect(@provider.current_resource.architecture).to eq(@new_resource.architecture)
      end

      it "should set the recursive flag of the current resource to the recursive flag of the new resource" do
        expect(@provider.current_resource.recursive).to eq(@new_resource.recursive)
      end

      it "should set the unscrubbed values of the current resource to the values it got from the registry" do
        expect(@provider.current_resource.unscrubbed_values).to eq([ testval2 ])
      end
    end

    describe "when the key does not exist" do
      before(:each) do
        expect(@double_registry).to receive(:key_exists?).with(keyname).and_return(false)
        @provider.load_current_resource
      end

      it "should set the values in the current resource to empty array" do
        expect(@provider.current_resource.values).to eq([])
      end
    end
  end

  describe "action_create" do
    context "when a case insensitive match for the key exists" do
      before(:each) do
        expect(@double_registry).to receive(:key_exists?).twice.with(keyname.downcase).and_return(true)
      end
      it "should do nothing if the if a case insensitive key and the value both exist" do
        @provider.new_resource.key(keyname.downcase)
        expect(@double_registry).to receive(:get_values).with(keyname.downcase).and_return( testval1 )
        expect(@double_registry).not_to receive(:set_value)
        @provider.load_current_resource
        @provider.action_create
      end
    end
    context "when the key exists" do
      before(:each) do
        expect(@double_registry).to receive(:key_exists?).twice.with(keyname).and_return(true)
      end
      it "should do nothing if the key and the value both exist" do
        expect(@double_registry).to receive(:get_values).with(keyname).and_return( testval1 )
        expect(@double_registry).not_to receive(:set_value)
        @provider.load_current_resource
        @provider.action_create
      end
      it "should create the value if the key exists but the value does not" do
        expect(@double_registry).to receive(:get_values).with(keyname).and_return( testval2 )
        expect(@double_registry).to receive(:set_value).with(keyname, testval1)
        @provider.load_current_resource
        @provider.action_create
      end
      it "should set the value if the key exists but the data does not match" do
        expect(@double_registry).to receive(:get_values).with(keyname).and_return( testval1_wrong_data )
        expect(@double_registry).to receive(:set_value).with(keyname, testval1)
        @provider.load_current_resource
        @provider.action_create
      end
      it "should set the value if the key exists but the type does not match" do
        expect(@double_registry).to receive(:get_values).with(keyname).and_return( testval1_wrong_type )
        expect(@double_registry).to receive(:set_value).with(keyname, testval1)
        @provider.load_current_resource
        @provider.action_create
      end
    end
    context "when the key exists and the values in the new resource are empty" do
      it "when a value is in the key, it should do nothing" do
        @provider.new_resource.values([])
        expect(@double_registry).to receive(:key_exists?).twice.with(keyname).and_return(true)
        expect(@double_registry).to receive(:get_values).with(keyname).and_return( testval1 )
        expect(@double_registry).not_to receive(:create_key)
        expect(@double_registry).not_to receive(:set_value)
        @provider.load_current_resource
        @provider.action_create
      end
      it "when no value is in the key, it should do nothing" do
        @provider.new_resource.values([])
        expect(@double_registry).to receive(:key_exists?).twice.with(keyname).and_return(true)
        expect(@double_registry).to receive(:get_values).with(keyname).and_return( nil )
        expect(@double_registry).not_to receive(:create_key)
        expect(@double_registry).not_to receive(:set_value)
        @provider.load_current_resource
        @provider.action_create
      end
    end
    context "when the key does not exist" do
      before(:each) do
        expect(@double_registry).to receive(:key_exists?).twice.with(keyname).and_return(false)
      end
      it "should create the key and the value" do
        expect(@double_registry).to receive(:create_key).with(keyname, false)
        expect(@double_registry).to receive(:set_value).with(keyname, testval1)
        @provider.load_current_resource
        @provider.action_create
      end
    end
    context "when the key does not exist and the values in the new resource are empty" do
      it "should create the key" do
        @new_resource.values([])
        expect(@double_registry).to receive(:key_exists?).twice.with(keyname).and_return(false)
        expect(@double_registry).to receive(:create_key).with(keyname, false)
        expect(@double_registry).not_to receive(:set_value)
        @provider.load_current_resource
        @provider.action_create
      end
    end
  end

  describe "action_create_if_missing" do
    context "when the key exists" do
      before(:each) do
        expect(@double_registry).to receive(:key_exists?).twice.with(keyname).and_return(true)
      end
      it "should do nothing if the key and the value both exist" do
        expect(@double_registry).to receive(:get_values).with(keyname).and_return( testval1 )
        expect(@double_registry).not_to receive(:set_value)
        @provider.load_current_resource
        @provider.action_create_if_missing
      end
      it "should create the value if the key exists but the value does not" do
        expect(@double_registry).to receive(:get_values).with(keyname).and_return( testval2 )
        expect(@double_registry).to receive(:set_value).with(keyname, testval1)
        @provider.load_current_resource
        @provider.action_create_if_missing
      end
      it "should not set the value if the key exists but the data does not match" do
        expect(@double_registry).to receive(:get_values).with(keyname).and_return( testval1_wrong_data )
        expect(@double_registry).not_to receive(:set_value)
        @provider.load_current_resource
        @provider.action_create_if_missing
      end
      it "should not set the value if the key exists but the type does not match" do
        expect(@double_registry).to receive(:get_values).with(keyname).and_return( testval1_wrong_type )
        expect(@double_registry).not_to receive(:set_value)
        @provider.load_current_resource
        @provider.action_create_if_missing
      end
    end
    context "when the key does not exist" do
      before(:each) do
        expect(@double_registry).to receive(:key_exists?).twice.with(keyname).and_return(false)
      end
      it "should create the key and the value" do
        expect(@double_registry).to receive(:create_key).with(keyname, false)
        expect(@double_registry).to receive(:set_value).with(keyname, testval1)
        @provider.load_current_resource
        @provider.action_create_if_missing
      end
    end
  end

  describe "action_delete" do
    context "when the key exists" do
      before(:each) do
        expect(@double_registry).to receive(:key_exists?).twice.with(keyname).and_return(true)
      end
      it "deletes the value when the value exists" do
        expect(@double_registry).to receive(:get_values).with(keyname).and_return( testval1 )
        expect(@double_registry).to receive(:delete_value).with(keyname, testval1)
        @provider.load_current_resource
        @provider.action_delete
      end
      it "deletes the value when the value exists, but the type is wrong" do
        expect(@double_registry).to receive(:get_values).with(keyname).and_return( testval1_wrong_type )
        expect(@double_registry).to receive(:delete_value).with(keyname, testval1)
        @provider.load_current_resource
        @provider.action_delete
      end
      it "deletes the value when the value exists, but the data is wrong" do
        expect(@double_registry).to receive(:get_values).with(keyname).and_return( testval1_wrong_data )
        expect(@double_registry).to receive(:delete_value).with(keyname, testval1)
        @provider.load_current_resource
        @provider.action_delete
      end
      it "does not delete the value when the value does not exist" do
        expect(@double_registry).to receive(:get_values).with(keyname).and_return( testval2 )
        expect(@double_registry).not_to receive(:delete_value)
        @provider.load_current_resource
        @provider.action_delete
      end
    end
    context "when the key does not exist" do
      before(:each) do
        expect(@double_registry).to receive(:key_exists?).twice.with(keyname).and_return(false)
      end
      it "does nothing" do
        expect(@double_registry).not_to receive(:delete_value)
        @provider.load_current_resource
        @provider.action_delete
      end
    end
  end

  describe "action_delete_key" do
    context "when the key exists" do
      before(:each) do
        expect(@double_registry).to receive(:key_exists?).twice.with(keyname).and_return(true)
      end
      it "deletes the key" do
        expect(@double_registry).to receive(:get_values).with(keyname).and_return( testval1 )
        expect(@double_registry).to receive(:delete_key).with(keyname, false)
        @provider.load_current_resource
        @provider.action_delete_key
      end
    end
    context "when the key does not exist" do
      before(:each) do
        expect(@double_registry).to receive(:key_exists?).twice.with(keyname).and_return(false)
      end
      it "does nothing" do
        expect(@double_registry).not_to receive(:delete_key)
        @provider.load_current_resource
        @provider.action_delete_key
      end
    end
  end

end

describe Chef::Provider::RegistryKey do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::RegistryKey.new("windows is fun", @run_context)
    @new_resource.key keyname
    @new_resource.values( testval1 )
    @new_resource.recursive false

    @provider = Chef::Provider::RegistryKey.new(@new_resource, @run_context)

    allow(@provider).to receive(:running_on_windows!).and_return(true)
    @double_registry = double(Chef::Win32::Registry)
    allow(@provider).to receive(:registry).and_return(@double_registry)
  end

  context "when the key data is safe" do
    let(:keyname) { 'HKLM\Software\Opscode\Testing\Safe' }
    let(:testval1) { { :name => "one", :type => :string, :data => "1" } }
    let(:testval1_wrong_type) { { :name => "one", :type => :multi_string, :data => "1" } }
    let(:testval1_wrong_data) { { :name => "one", :type => :string, :data => "2" } }
    let(:testval2) { { :name => "two", :type => :string, :data => "2" } }

    it_should_behave_like "a registry key"
  end

  context "when the key data is unsafe" do
    let(:keyname) { 'HKLM\Software\Opscode\Testing\Unsafe' }
    let(:testval1) { { :name => "one", :type => :binary, :data => 255.chr * 1 } }
    let(:testval1_wrong_type) { { :name => "one", :type => :string, :data => 255.chr * 1 } }
    let(:testval1_wrong_data) { { :name => "one", :type => :binary, :data => 254.chr * 1 } }
    let(:testval2) { { :name => "two", :type => :binary, :data => 0.chr * 1 } }

    it_should_behave_like "a registry key"
  end

  describe "action_create" do
    context "when key exists and type matches" do
      let(:keyname) { 'hklm\\software\\opscode\\testing\\dword' }
      let(:dword_passed_as_integer) { { :name => "one", :type => :dword, :data => 12345 } }
      let(:testval1) { { :name => "one", :type => :dword, :data => "12345" } }
      before do
        expect(@double_registry).to receive(:key_exists?).twice.with(keyname).and_return(true)
      end

      it "does not make a change for datatype of data value differing" do
        expect(@double_registry).to receive(:get_values).with(keyname).and_return( dword_passed_as_integer )
        expect(@double_registry).not_to receive(:set_value)
        @provider.load_current_resource
        @provider.action_create
      end
    end
  end
end

describe Chef::Provider::RegistryKey, "key_missing?" do
  let(:provider) { Chef::Provider::RegistryKey.new(nil, nil) }
  let(:all_keys_present_in_all_hash) do
    [ { :name => "input1_value1", :type => :string, :data => "my_value1" },
      { :name => "input1_value2", :type => :string, :data => "my_value2" },
    ]
  end
  let(:type_key_not_present_in_any_hash) do
    [ { :name => "input2_value1", :data => "my_value1" },
      { :name => "input2_value2", :data => "my_value2" },
    ]
  end
  let(:type_key_not_present_in_some_hash) do
    [ { :name => "input3_value1", :data => "my_value1" },
      { :name => "input3_value2", :type => :string, :data => "my_value2" },
    ]
  end
  let(:data_key_not_present_in_any_hash) do
    [ { :name => "input4_value1", :type => :string },
      { :name => "input4_value2", :type => :string },
    ]
  end
  let(:data_key_not_present_in_some_hash) do
    [ { :name => "input5_value1", :type => :string, :data => "my_value1" },
      { :name => "input5_value2", :type => :string },
    ]
  end
  let(:only_name_key_present_in_all_hash) do
    [ { :name => "input6_value1" },
      { :name => "input6_value2" },
    ]
  end

  context "type key" do
    context "when type key is present in all the values hash of registry_key resource" do
      it "returns false" do
        response = provider.key_missing?(all_keys_present_in_all_hash, :type)
        expect(response).to be == false
      end
    end

    context "when type key is not present in any of the values hash of registry_key resource" do
      it "returns true" do
        response = provider.key_missing?(type_key_not_present_in_any_hash, :type)
        expect(response).to be == true
      end
    end

    context "when type key is not present only in some of the values hash of registry_key resource" do
      it "returns true" do
        response = provider.key_missing?(type_key_not_present_in_some_hash, :type)
        expect(response).to be == true
      end
    end

    context "when only name key is present in all the values hash of registry_key resource" do
      it "returns true" do
        response = provider.key_missing?(only_name_key_present_in_all_hash, :type)
        expect(response).to be == true
      end
    end
  end

  context "data key" do
    context "when data key is present in all the values hash of registry_key resource" do
      it "returns false" do
        response = provider.key_missing?(all_keys_present_in_all_hash, :data)
        expect(response).to be == false
      end
    end

    context "when data key is not present in any of the values hash of registry_key resource" do
      it "returns true" do
        response = provider.key_missing?(data_key_not_present_in_any_hash, :data)
        expect(response).to be == true
      end
    end

    context "when data key is not present only in some of the values hash of registry_key resource" do
      it "returns true" do
        response = provider.key_missing?(data_key_not_present_in_some_hash, :data)
        expect(response).to be == true
      end
    end

    context "when only name key is present in all the values hash of registry_key resource" do
      it "returns true" do
        response = provider.key_missing?(only_name_key_present_in_all_hash, :data)
        expect(response).to be == true
      end
    end
  end
end
