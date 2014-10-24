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

require 'spec_helper'

describe Chef::Provider::Env do

  before do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Env.new("FOO")
    @new_resource.value("bar")
    @provider = Chef::Provider::Env.new(@new_resource, @run_context)
  end

  it "assumes the key_name exists by default" do
    @provider.key_exists.should be_true
  end

  describe "when loading the current status" do
    before do
      #@current_resource = @new_resource.clone
      #Chef::Resource::Env.stub(:new).and_return(@current_resource)
      @provider.current_resource = @current_resource
      @provider.stub(:env_value).with("FOO").and_return("bar")
      @provider.stub(:env_key_exists).and_return(true)
    end

    it "should create a current resource with the same name as the new resource" do
      @provider.load_current_resource
      @provider.new_resource.name.should == "FOO"
    end

    it "should set the key_name to the key name of the new resource" do
      @provider.load_current_resource
      @provider.current_resource.key_name.should == "FOO"
    end

    it "should check if the key_name exists" do
      @provider.should_receive(:env_key_exists).with("FOO").and_return(true)
      @provider.load_current_resource
      @provider.key_exists.should be_true
    end

    it "should flip the value of exists if the key does not exist" do
      @provider.should_receive(:env_key_exists).with("FOO").and_return(false)
      @provider.load_current_resource
      @provider.key_exists.should be_false
    end

    it "should return the current resource" do
      @provider.load_current_resource.should be_a_kind_of(Chef::Resource::Env)
    end
  end

  describe "action_create" do
    before do
      @provider.key_exists = false
      @provider.stub(:create_env).and_return(true)
      @provider.stub(:modify_env).and_return(true)
    end

    it "should call create_env if the key does not exist" do
      @provider.should_receive(:create_env).and_return(true)
      @provider.action_create
    end

    it "should set the new_resources updated flag when it creates the key" do
      @provider.action_create
      @new_resource.should be_updated
    end

    it "should check to see if the values are the same if the key exists" do
      @provider.key_exists = true
      @provider.should_receive(:requires_modify_or_create?).and_return(false)
      @provider.action_create
    end

    it "should call modify_env if the key exists and values are not equal" do
      @provider.key_exists = true
      @provider.stub(:requires_modify_or_create?).and_return(true)
      @provider.should_receive(:modify_env).and_return(true)
      @provider.action_create
    end

    it "should set the new_resources updated flag when it updates an existing value" do
      @provider.key_exists = true
      @provider.stub(:requires_modify_or_create?).and_return(true)
      @provider.stub(:modify_env).and_return(true)
      @provider.action_create
      @new_resource.should be_updated
    end
  end

  describe "action_delete" do
    before(:each) do
      @provider.current_resource = @current_resource
      @provider.key_exists = false
      @provider.stub(:delete_element).and_return(false)
      @provider.stub(:delete_env).and_return(true)
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
      @provider.action_delete
      @new_resource.should be_updated
    end
  end

  describe "action_modify" do
    before(:each) do
      @provider.current_resource = @current_resource
      @provider.key_exists = true
      @provider.stub(:modify_env).and_return(true)
    end

    it "should call modify_group if the key exists and values are not equal" do
      @provider.should_receive(:requires_modify_or_create?).and_return(true)
      @provider.should_receive(:modify_env).and_return(true)
      @provider.action_modify
    end

    it "should set the new resources updated flag to true if modify_env is called" do
      @provider.stub(:requires_modify_or_create?).and_return(true)
      @provider.stub(:modify_env).and_return(true)
      @provider.action_modify
      @new_resource.should be_updated
    end

    it "should not call modify_env if the key exists but the values are equal" do
      @provider.should_receive(:requires_modify_or_create?).and_return(false)
      @provider.should_not_receive(:modify_env)
      @provider.action_modify
    end

    it "should raise a Chef::Exceptions::Env if the key doesn't exist" do
      @provider.key_exists = false
      lambda { @provider.action_modify }.should raise_error(Chef::Exceptions::Env)
    end
  end

  describe "delete_element" do
    before(:each) do
      @current_resource = Chef::Resource::Env.new("FOO")

      @new_resource.delim ";"
      @new_resource.value "C:/bar/bin"

      @current_resource.value "C:/foo/bin;C:/bar/bin"
      @provider.current_resource = @current_resource
    end

    it "should return true if the element is not found" do
      @new_resource.stub(:value).and_return("C:/baz/bin")
      @provider.delete_element.should eql(true)
    end

    it "should return false if the delim not defined" do
      @new_resource.stub(:delim).and_return(nil)
      @provider.delete_element.should eql(false)
    end

    it "should return true if the element is deleted" do
      @new_resource.value("C:/foo/bin")
      @provider.should_receive(:create_env)
      @provider.delete_element.should eql(true)
      @new_resource.should be_updated
    end

    context "when new_resource's value contains the delimiter"  do
      it "should return false if all the elements are deleted" do
        # This indicates that the entire key needs to be deleted
        @new_resource.value("C:/foo/bin;C:/bar/bin")
        @provider.delete_element.should eql(false)
        @new_resource.should_not be_updated  # This will be updated in action_delete
      end

      it "should return true if any, but not all, of the elements are deleted" do
        @new_resource.value("C:/foo/bin;C:/notbaz/bin")
        @provider.should_receive(:create_env)
        @provider.delete_element.should eql(true)
        @new_resource.should be_updated
      end

      it "should return true if none of the elements are deleted" do
        @new_resource.value("C:/notfoo/bin;C:/notbaz/bin")
        @provider.delete_element.should eql(true)
        @new_resource.should_not be_updated
      end
    end
  end

  describe "requires_modify_or_create?" do
    before(:each) do
      @new_resource.value("C:/bar")
      @current_resource = @new_resource.clone
      @provider.current_resource = @current_resource
    end

    it "should return false if the values are equal" do
      @provider.requires_modify_or_create?.should be_false
    end

    it "should return true if the values not are equal" do
      @new_resource.value("C:/elsewhere")
      @provider.requires_modify_or_create?.should be_true
    end

    it "should return false if the current value contains the element" do
      @new_resource.delim(";")
      @current_resource.value("C:/bar;C:/foo;C:/baz")

      @provider.requires_modify_or_create?.should be_false
    end

    it "should return true if the current value does not contain the element" do
      @new_resource.delim(";")
      @current_resource.value("C:/biz;C:/foo/bin;C:/baz")
      @provider.requires_modify_or_create?.should be_true
    end

    context "when new_resource's value contains the delimiter"  do
      it "should return false if all the current values are contained" do
        @new_resource.value("C:/biz;C:/baz")
        @new_resource.delim(";")
        @current_resource.value("C:/biz;C:/foo/bin;C:/baz")
        @provider.requires_modify_or_create?.should be_false
      end

      it "should return true if any of the new values are not contained" do
        @new_resource.value("C:/biz;C:/baz;C:/bin")
        @new_resource.delim(";")
        @current_resource.value("C:/biz;C:/foo/bin;C:/baz")
        @provider.requires_modify_or_create?.should be_true
      end
    end
  end

  describe "modify_env" do
    before(:each) do
      @provider.stub(:create_env).and_return(true)
      @new_resource.delim ";"

      @current_resource = Chef::Resource::Env.new("FOO")
      @current_resource.value "C:/foo/bin"
      @provider.current_resource = @current_resource
    end

    it "should not modify the variable passed to the resource" do
      new_value = "C:/bar/bin"
      passed_value = new_value.dup
      @new_resource.value(passed_value)
      @provider.modify_env
      passed_value.should == new_value
    end

    it "should only add values not already contained when a delimiter is provided" do
      @new_resource.value("C:/foo;C:/bar;C:/baz")
      @new_resource.delim(";")
      @current_resource.value("C:/foo/bar;C:/bar;C:/baz")
      @provider.modify_env
      @new_resource.value.should eq("C:/foo;C:/foo/bar;C:/bar;C:/baz")
    end
  end
end
