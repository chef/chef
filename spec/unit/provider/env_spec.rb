#
# Author:: Doug MacEachern (<dougm@vmware.com>)
# Copyright:: Copyright 2010-2016, VMware, Inc.
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
    expect(@provider.key_exists).to be_truthy
  end

  describe "when loading the current status" do
    before do
      #@current_resource = @new_resource.clone
      #Chef::Resource::Env.stub(:new).and_return(@current_resource)
      @provider.current_resource = @current_resource
      allow(@provider).to receive(:env_value).with("FOO").and_return("bar")
      allow(@provider).to receive(:env_key_exists).and_return(true)
    end

    it "should create a current resource with the same name as the new resource" do
      @provider.load_current_resource
      expect(@provider.new_resource.name).to eq("FOO")
    end

    it "should set the key_name to the key name of the new resource" do
      @provider.load_current_resource
      expect(@provider.current_resource.key_name).to eq("FOO")
    end

    it "should check if the key_name exists" do
      expect(@provider).to receive(:env_key_exists).with("FOO").and_return(true)
      @provider.load_current_resource
      expect(@provider.key_exists).to be_truthy
    end

    it "should flip the value of exists if the key does not exist" do
      expect(@provider).to receive(:env_key_exists).with("FOO").and_return(false)
      @provider.load_current_resource
      expect(@provider.key_exists).to be_falsey
    end

    it "should return the current resource" do
      expect(@provider.load_current_resource).to be_a_kind_of(Chef::Resource::Env)
    end
  end

  describe "action_create" do
    before do
      @provider.key_exists = false
      allow(@provider).to receive(:create_env).and_return(true)
      allow(@provider).to receive(:modify_env).and_return(true)
    end

    it "should call create_env if the key does not exist" do
      expect(@provider).to receive(:create_env).and_return(true)
      @provider.action_create
    end

    it "should set the new_resources updated flag when it creates the key" do
      @provider.action_create
      expect(@new_resource).to be_updated
    end

    it "should check to see if the values are the same if the key exists" do
      @provider.key_exists = true
      expect(@provider).to receive(:requires_modify_or_create?).and_return(false)
      @provider.action_create
    end

    it "should call modify_env if the key exists and values are not equal" do
      @provider.key_exists = true
      allow(@provider).to receive(:requires_modify_or_create?).and_return(true)
      expect(@provider).to receive(:modify_env).and_return(true)
      @provider.action_create
    end

    it "should set the new_resources updated flag when it updates an existing value" do
      @provider.key_exists = true
      allow(@provider).to receive(:requires_modify_or_create?).and_return(true)
      allow(@provider).to receive(:modify_env).and_return(true)
      @provider.action_create
      expect(@new_resource).to be_updated
    end
  end

  describe "action_delete" do
    before(:each) do
      @provider.current_resource = @current_resource
      @provider.key_exists = false
      allow(@provider).to receive(:delete_element).and_return(false)
      allow(@provider).to receive(:delete_env).and_return(true)
    end

    it "should not call delete_env if the key does not exist" do
      expect(@provider).not_to receive(:delete_env)
      @provider.action_delete
    end

    it "should not call delete_element if the key does not exist" do
      expect(@provider).not_to receive(:delete_element)
      @provider.action_delete
    end

    it "should call delete_env if the key exists" do
      @provider.key_exists = true
      expect(@provider).to receive(:delete_env)
      @provider.action_delete
    end

    it "should set the new_resources updated flag to true if the key is deleted" do
      @provider.key_exists = true
      @provider.action_delete
      expect(@new_resource).to be_updated
    end
  end

  describe "action_modify" do
    before(:each) do
      @provider.current_resource = @current_resource
      @provider.key_exists = true
      allow(@provider).to receive(:modify_env).and_return(true)
    end

    it "should call modify_group if the key exists and values are not equal" do
      expect(@provider).to receive(:requires_modify_or_create?).and_return(true)
      expect(@provider).to receive(:modify_env).and_return(true)
      @provider.action_modify
    end

    it "should set the new resources updated flag to true if modify_env is called" do
      allow(@provider).to receive(:requires_modify_or_create?).and_return(true)
      allow(@provider).to receive(:modify_env).and_return(true)
      @provider.action_modify
      expect(@new_resource).to be_updated
    end

    it "should not call modify_env if the key exists but the values are equal" do
      expect(@provider).to receive(:requires_modify_or_create?).and_return(false)
      expect(@provider).not_to receive(:modify_env)
      @provider.action_modify
    end

    it "should raise a Chef::Exceptions::Env if the key doesn't exist" do
      @provider.key_exists = false
      expect { @provider.action_modify }.to raise_error(Chef::Exceptions::Env)
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
      @new_resource.value("C:/baz/bin")
      expect(@provider.delete_element).to eql(true)
    end

    it "should return false if the delim not defined" do
      @new_resource.delim(nil)
      expect(@provider.delete_element).to eql(false)
    end

    it "should return true if the element is deleted" do
      @new_resource.value("C:/foo/bin")
      expect(@provider).to receive(:create_env)
      expect(@provider.delete_element).to eql(true)
      expect(@new_resource).to be_updated
    end

    context "when new_resource's value contains the delimiter" do
      it "should return false if all the elements are deleted" do
        # This indicates that the entire key needs to be deleted
        @new_resource.value("C:/foo/bin;C:/bar/bin")
        expect(@provider.delete_element).to eql(false)
        expect(@new_resource).not_to be_updated # This will be updated in action_delete
      end

      it "should return true if any, but not all, of the elements are deleted" do
        @new_resource.value("C:/foo/bin;C:/notbaz/bin")
        expect(@provider).to receive(:create_env)
        expect(@provider.delete_element).to eql(true)
        expect(@new_resource).to be_updated
      end

      it "should return true if none of the elements are deleted" do
        @new_resource.value("C:/notfoo/bin;C:/notbaz/bin")
        expect(@provider.delete_element).to eql(true)
        expect(@new_resource).not_to be_updated
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
      expect(@provider.requires_modify_or_create?).to be_falsey
    end

    it "should return true if the values not are equal" do
      @new_resource.value("C:/elsewhere")
      expect(@provider.requires_modify_or_create?).to be_truthy
    end

    it "should return false if the current value contains the element" do
      @new_resource.delim(";")
      @current_resource.value("C:/bar;C:/foo;C:/baz")

      expect(@provider.requires_modify_or_create?).to be_falsey
    end

    it "should return true if the current value does not contain the element" do
      @new_resource.delim(";")
      @current_resource.value("C:/biz;C:/foo/bin;C:/baz")
      expect(@provider.requires_modify_or_create?).to be_truthy
    end

    context "when new_resource's value contains the delimiter" do
      it "should return false if all the current values are contained in specified order" do
        @new_resource.value("C:/biz;C:/baz")
        @new_resource.delim(";")
        @current_resource.value("C:/biz;C:/foo/bin;C:/baz")
        expect(@provider.requires_modify_or_create?).to be_falsey
      end

      it "should return true if any of the new values are not contained" do
        @new_resource.value("C:/biz;C:/baz;C:/bin")
        @new_resource.delim(";")
        @current_resource.value("C:/biz;C:/foo/bin;C:/baz")
        expect(@provider.requires_modify_or_create?).to be_truthy
      end

      it "should return true if values are contained in different order" do
        @new_resource.value("C:/biz;C:/baz")
        @new_resource.delim(";")
        @current_resource.value("C:/baz;C:/foo/bin;C:/biz")
        expect(@provider.requires_modify_or_create?).to be_truthy
      end
    end
  end

  describe "modify_env" do
    before(:each) do
      allow(@provider).to receive(:create_env).and_return(true)
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
      expect(passed_value).to eq(new_value)
    end

    it "should only add values not already contained" do
      @new_resource.value("C:/foo;C:/bar;C:/baz")
      @current_resource.value("C:/bar;C:/baz;C:/foo/bar")
      @provider.modify_env
      expect(@new_resource.value).to eq("C:/foo;C:/bar;C:/baz;C:/foo/bar")
    end

    it "should reorder values to keep order which asked" do
      @new_resource.value("C:/foo;C:/bar;C:/baz")
      @current_resource.value("C:/foo/bar;C:/baz;C:/bar")
      @provider.modify_env
      expect(@new_resource.value).to eq("C:/foo;C:/bar;C:/baz;C:/foo/bar")
    end
  end
end
