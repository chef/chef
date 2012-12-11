#
# Author:: Lamont Granquist (lamont@opscode.com)
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

  let(:testval1) { { :name => "one", :type => :string, :data => "1" } }
  let(:testval1_wrong_type) { { :name => "one", :type => :multi_string, :data => "1" } }
  let(:testval1_wrong_data) { { :name => "one", :type => :string, :data => "2" } }
  let(:testval2) { { :name => "two", :type => :string, :data => "2" } }
  let(:testkey1) { 'HKLM\Software\Opscode\Testing' }

  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::RegistryKey.new("windows is fun", @run_context)
    @new_resource.key testkey1
    @new_resource.values( testval1 )
    @new_resource.recursive false

    @provider = Chef::Provider::RegistryKey.new(@new_resource, @run_context)

    @provider.stub!(:running_on_windows!).and_return(true)
    @double_registry = double(Chef::Win32::Registry)
    @provider.stub!(:registry).and_return(@double_registry)
  end

  describe "when first created" do
  end

  describe "executing load_current_resource" do
    describe "when the key exists" do
      before(:each) do
        @double_registry.should_receive(:key_exists?).with(testkey1).and_return(true)
        @double_registry.should_receive(:get_values).with(testkey1).and_return( testval2 )
        @provider.load_current_resource
      end

      it "should set the key of the current resource to the key of the new resource" do
        @provider.current_resource.key.should == @new_resource.key
      end

      it "should set the architecture of the current resource to the architecture of the new resource" do
        @provider.current_resource.architecture.should == @new_resource.architecture
      end

      it "should set the recursive flag of the current resource to the recursive flag of the new resource" do
        @provider.current_resource.recursive.should == @new_resource.recursive
      end

      it "should set the values of the current resource to the values it got from the registry" do
        @provider.current_resource.values.should == [ testval2 ]
      end
    end

    describe "when the key does not exist" do
      before(:each) do
        @double_registry.should_receive(:key_exists?).with(testkey1).and_return(false)
        @provider.load_current_resource
      end

      it "should set the values in the current resource to empty array" do
        @provider.current_resource.values.should == []
      end
    end
  end

  describe "action_create" do
    context "when the key exists" do
      before(:each) do
        @double_registry.should_receive(:key_exists?).twice.with(testkey1).and_return(true)
      end
      it "should do nothing if the key and the value both exist" do
        @double_registry.should_receive(:get_values).with(testkey1).and_return( testval1 )
        @double_registry.should_not_receive(:set_value)
        @provider.load_current_resource
        @provider.action_create
      end
      it "should create the value if the key exists but the value does not" do
        @double_registry.should_receive(:get_values).with(testkey1).and_return( testval2 )
        @double_registry.should_receive(:set_value).with(testkey1, testval1)
        @provider.load_current_resource
        @provider.action_create
      end
      it "should set the value if the key exists but the data does not match" do
        @double_registry.should_receive(:get_values).with(testkey1).and_return( testval1_wrong_data )
        @double_registry.should_receive(:set_value).with(testkey1, testval1)
        @provider.load_current_resource
        @provider.action_create
      end
      it "should set the value if the key exists but the type does not match" do
        @double_registry.should_receive(:get_values).with(testkey1).and_return( testval1_wrong_type )
        @double_registry.should_receive(:set_value).with(testkey1, testval1)
        @provider.load_current_resource
        @provider.action_create
      end
    end
    context "when the key exists and the values in the new resource are empty" do
      it "when a value is in the key, it should do nothing" do
        @provider.new_resource.values([])
        @double_registry.should_receive(:key_exists?).twice.with(testkey1).and_return(true)
        @double_registry.should_receive(:get_values).with(testkey1).and_return( testval1 )
        @double_registry.should_not_receive(:create_key)
        @double_registry.should_not_receive(:set_value)
        @provider.load_current_resource
        @provider.action_create
      end
      it "when no value is in the key, it should do nothing" do
        @provider.new_resource.values([])
        @double_registry.should_receive(:key_exists?).twice.with(testkey1).and_return(true)
        @double_registry.should_receive(:get_values).with(testkey1).and_return( nil )
        @double_registry.should_not_receive(:create_key)
        @double_registry.should_not_receive(:set_value)
        @provider.load_current_resource
        @provider.action_create
      end
    end
    context "when the key does not exist" do
      before(:each) do
        @double_registry.should_receive(:key_exists?).twice.with(testkey1).and_return(false)
      end
      it "should create the key and the value" do
        @double_registry.should_receive(:create_key).with(testkey1, false)
        @double_registry.should_receive(:set_value).with(testkey1, testval1)
        @provider.load_current_resource
        @provider.action_create
      end
    end
    context "when the key does not exist and the values in the new resource are empty" do
      it "should create the key" do
        @new_resource.values([])
        @double_registry.should_receive(:key_exists?).twice.with(testkey1).and_return(false)
        @double_registry.should_receive(:create_key).with(testkey1, false)
        @double_registry.should_not_receive(:set_value)
        @provider.load_current_resource
        @provider.action_create
      end
    end
  end

  describe "action_create_if_missing" do
    context "when the key exists" do
      before(:each) do
        @double_registry.should_receive(:key_exists?).twice.with(testkey1).and_return(true)
      end
      it "should do nothing if the key and the value both exist" do
        @double_registry.should_receive(:get_values).with(testkey1).and_return( testval1 )
        @double_registry.should_not_receive(:set_value)
        @provider.load_current_resource
        @provider.action_create_if_missing
      end
      it "should create the value if the key exists but the value does not" do
        @double_registry.should_receive(:get_values).with(testkey1).and_return( testval2 )
        @double_registry.should_receive(:set_value).with(testkey1, testval1)
        @provider.load_current_resource
        @provider.action_create_if_missing
      end
      it "should not set the value if the key exists but the data does not match" do
        @double_registry.should_receive(:get_values).with(testkey1).and_return( testval1_wrong_data )
        @double_registry.should_not_receive(:set_value)
        @provider.load_current_resource
        @provider.action_create_if_missing
      end
      it "should not set the value if the key exists but the type does not match" do
        @double_registry.should_receive(:get_values).with(testkey1).and_return( testval1_wrong_type )
        @double_registry.should_not_receive(:set_value)
        @provider.load_current_resource
        @provider.action_create_if_missing
      end
    end
    context "when the key does not exist" do
      before(:each) do
        @double_registry.should_receive(:key_exists?).twice.with(testkey1).and_return(false)
      end
      it "should create the key and the value" do
        @double_registry.should_receive(:create_key).with(testkey1, false)
        @double_registry.should_receive(:set_value).with(testkey1, testval1)
        @provider.load_current_resource
        @provider.action_create_if_missing
      end
    end
  end

  describe "action_delete" do
    context "when the key exists" do
      before(:each) do
        @double_registry.should_receive(:key_exists?).twice.with(testkey1).and_return(true)
      end
      it "deletes the value when the value exists" do
        @double_registry.should_receive(:get_values).with(testkey1).and_return( testval1 )
        @double_registry.should_receive(:delete_value).with(testkey1, testval1)
        @provider.load_current_resource
        @provider.action_delete
      end
      it "deletes the value when the value exists, but the type is wrong" do
        @double_registry.should_receive(:get_values).with(testkey1).and_return( testval1_wrong_type )
        @double_registry.should_receive(:delete_value).with(testkey1, testval1)
        @provider.load_current_resource
        @provider.action_delete
      end
      it "deletes the value when the value exists, but the data is wrong" do
        @double_registry.should_receive(:get_values).with(testkey1).and_return( testval1_wrong_data )
        @double_registry.should_receive(:delete_value).with(testkey1, testval1)
        @provider.load_current_resource
        @provider.action_delete
      end
      it "does not delete the value when the value does not exist" do
        @double_registry.should_receive(:get_values).with(testkey1).and_return( testval2 )
        @double_registry.should_not_receive(:delete_value)
        @provider.load_current_resource
        @provider.action_delete
      end
    end
    context "when the key does not exist" do
      before(:each) do
        @double_registry.should_receive(:key_exists?).twice.with(testkey1).and_return(false)
      end
      it "does nothing" do
        @double_registry.should_not_receive(:delete_value)
        @provider.load_current_resource
        @provider.action_delete
      end
    end
  end

  describe "action_delete_key" do
    context "when the key exists" do
      before(:each) do
        @double_registry.should_receive(:key_exists?).twice.with(testkey1).and_return(true)
      end
      it "deletes the key" do
        @double_registry.should_receive(:get_values).with(testkey1).and_return( testval1 )
        @double_registry.should_receive(:delete_key).with(testkey1, false)
        @provider.load_current_resource
        @provider.action_delete_key
      end
    end
    context "when the key does not exist" do
      before(:each) do
        @double_registry.should_receive(:key_exists?).twice.with(testkey1).and_return(false)
      end
      it "does nothing" do
        @double_registry.should_not_receive(:delete_key)
        @provider.load_current_resource
        @provider.action_delete_key
      end
    end
  end

end

