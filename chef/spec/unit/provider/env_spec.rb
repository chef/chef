#
# Author:: Doug MacEachern (<dougm@vmware.com>)
# Copyright:: Copyright (c) 2010 VMware, Inc.
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Provider::Env, "initialize" do

  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Env",
      :null_object => true,
      :key_name => "FOO",
      :value => "bar"
    )
    @provider = Chef::Provider::Env.new(@node, @new_resource)
  end

  it "should return a Chef::Provider::Env" do
    @provider.should be_a_kind_of(Chef::Provider::Env)
  end

  it "should assume the key_name exists by default" do
    @provider.key_exists.should be_true
  end
end

describe Chef::Provider::Env, "load_current_resource" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Env",
      :null_object => true,
      :key_name => "FOO",
      :value => "bar"
    )
    @current_resource = mock("Chef::Resource::Env",
      :null_object => true,
      :key_name => "FOO",
      :value => "bar"
    )
    Chef::Resource::Env.stub!(:new).and_return(@current_resource)
    @provider = Chef::Provider::Env.new(@node, @new_resource)
    @provider.stub!(:env_value).with("FOO").and_return(@current_resource.value)
    @provider.stub!(:env_key_exists).and_return(true)
  end

  it "should create a current resource with the same name as the new resource" do
    Chef::Resource::Env.should_receive(:new).with(@new_resource.name).and_return(@current_resource)
    @provider.load_current_resource
  end

  it "should set the key_name to the key name of the new resource" do
    @current_resource.should_receive(:key_name).with(@new_resource.key_name)
    @provider.load_current_resource
  end

  it "should check if the key_name exists" do
    @provider.should_receive(:env_key_exists).with(@new_resource.key_name).and_return(true)
    @provider.load_current_resource
  end

  it "should flip the value of exists if the key does not exist" do
    @provider.stub!(:env_key_exists).and_return(false)
    @provider.load_current_resource
    @provider.key_exists.should be_false
  end

  it "should return the current resource" do
    @provider.load_current_resource.should eql(@current_resource)
  end
end

describe Chef::Provider::Env, "action_create" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Env",
      :null_object => true,
      :key_name => "FOO",
      :value => "bar"
    )
    @current_resource = mock("Chef::Resource::Env",
      :null_object => true,
      :key_name => "FOO",
      :value => "bar"
    )
    @provider = Chef::Provider::Env.new(@node, @new_resource)
    @provider.key_exists = false
    @provider.stub!(:create_env).and_return(true)
    @provider.stub!(:modify_env).and_return(true)
  end

  it "should call create_env if the key does not exist" do
    @provider.should_receive(:create_env).and_return(true)
    @provider.action_create
  end

  it "should set the the new_resources updated flag when it creates the key" do
    @new_resource.should_receive(:updated=).with(true).and_return(true)
    @provider.action_create
  end

  it "should check to see if the values are the same if the key exists" do
    @provider.key_exists = true
    @provider.should_receive(:compare_value).and_return(false)
    @provider.action_create
  end

  it "should call modify_env if the key exists and values are not equal" do
    @provider.key_exists = true
    @provider.stub!(:compare_value).and_return(true)
    @provider.should_receive(:modify_env).and_return(true)
    @provider.action_create
  end

  it "should set the the new_resources updated flag when it updates an existing value" do
    @provider.key_exists = true
    @provider.stub!(:compare_value).and_return(true)
    @provider.stub!(:modify_env).and_return(true)
    @new_resource.should_receive(:updated=).with(true).and_return(true)
    @provider.action_create
  end
end

describe Chef::Provider::Env, "action_delete" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Env",
      :null_object => true
    )
    @current_resource = mock("Chef::Resource::Env",
      :null_object => true
    )
    @provider = Chef::Provider::Env.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.key_exists = false
    @provider.stub!(:delete_element).and_return(false)
    @provider.stub!(:delete_env).and_return(true)
  end

  it "should not call delete_env if the key does not exist" do
    @provider.should_not_receive(:delete_env)
    @provider.action_delete
  end

  it "should not call delete_element if the key does not exist" do
    @provider.should_not_receive(:delete_element)
    @provider.action_delete
  end

  it "should call delete_env if the key exists" do
    @provider.key_exists = true
    @provider.should_receive(:delete_env)
    @provider.action_delete
  end

  it "should set the new_resources updated flag to true if the key is deleted" do
    @provider.key_exists = true
    @new_resource.should_receive(:updated=).with(true).and_return(true)
    @provider.action_delete
  end
end

describe Chef::Provider::Env, "action_modify" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Env",
      :null_object => true
    )
    @current_resource = mock("Chef::Resource::Env",
      :null_object => true
    )
    @provider = Chef::Provider::Env.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.key_exists = true
    @provider.stub!(:modify_env).and_return(true)
  end

  it "should call modify_group if the key exists and values are not equal" do
    @provider.should_receive(:compare_value).and_return(true)
    @provider.should_receive(:modify_env).and_return(true)
    @provider.action_modify
  end

  it "should set the new resources updated flag to true if modify_env is called" do
    @provider.stub!(:compare_value).and_return(true)
    @provider.stub!(:modify_env).and_return(true)
    @new_resource.should_receive(:updated=).with(true).and_return(true)
    @provider.action_modify
  end

  it "should not call modify_env if the key exists but the values are equal" do
    @provider.should_receive(:compare_value).and_return(false)
    @provider.should_not_receive(:modify_env)
    @provider.action_modify
  end

  it "should raise a Chef::Exceptions::Env if the key doesn't exist" do
    @provider.key_exists = false
    lambda { @provider.action_modify }.should raise_error(Chef::Exceptions::Env)
  end
end

describe Chef::Provider::Env, "delete_element" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Env",
      :null_object => true,
      :delim => ";",
      :value => "C:/bar/bin"
    )
    @current_resource = mock("Chef::Resource::Env",
      :null_object => true,
      :value => "C:/foo/bin;C:/bar/bin"
    )
    @provider = Chef::Provider::Env.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:create_env).and_return(true)
  end

  it "should return true if the element is not found" do
    @new_resource.stub!(:value).and_return("C:/baz/bin")
    @provider.delete_element.should eql(true)
  end

  it "should return false if the delim not defined" do
    @new_resource.stub!(:delim).and_return(nil)
    @provider.delete_element.should eql(false)
  end

  it "should return true if the element is deleted" do
    @new_resource.should_receive(:value).with("C:/foo/bin").and_return(true)
    @provider.should_receive(:create_env)
    @new_resource.should_receive(:updated=).with(true).and_return(true)
    @provider.delete_element.should eql(true)
  end
end

describe Chef::Provider::Env, "compare_value" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Env",
      :null_object => true,
      :delim => nil,
      :value => "C:/foo"
    )
    @current_resource = mock("Chef::Resource::Env",
      :null_object => true,
      :value => "C:/foo"
    )
    @provider = Chef::Provider::Env.new(@node, @new_resource)
    @provider.current_resource = @current_resource
  end

  it "should return false if the values are equal" do
    @provider.compare_value.should eql(false)
  end

  it "should return true if the values not are equal" do
    @new_resource.stub!(:value).and_return("C:/elsewhere")
    @provider.compare_value.should eql(true)
  end

  it "should return false if the current value contains the element" do
    @new_resource.stub!(:delim).and_return(";")
    @current_resource.stub!(:value).and_return("C:/biz;C:/foo;C:/baz")
    @provider.compare_value.should eql(false)
  end

  it "should return true if the current value does not contain the element" do
    @new_resource.stub!(:delim).and_return(";")
    @current_resource.stub!(:value).and_return("C:/biz;C:/foo/bin;C:/baz")
    @provider.compare_value.should eql(true)
  end
end

