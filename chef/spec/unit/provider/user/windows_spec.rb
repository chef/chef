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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper"))

class Chef
  class Util
    class Windows
      class NetUser
      end
    end
  end
end

describe Chef::Provider::User::Windows, "set_options" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User",
      :null_object => true,
      :username => "adam",
      :comment => "Adam Jacob",
      :uid => 1000,
      :gid => 1000,
      :home => "/home/adam",
      :shell => "/usr/bin/zsh",
      :password => "abracadabra",
      :updated => nil
    )
    @current_resource = mock("Chef::Resource::User",
      :null_object => true,
      :username => "adam",
      :comment => "Adam Jacob",
      :uid => 1000,
      :gid => 1000,
      :home => "/home/adam",
      :shell => "/usr/bin/zsh",
      :password => "abracadabra",
      :updated => nil
    )
    @net_user = mock("Chef::Util::Windows::NetUser",
      :null_object => true
    )
    Chef::Util::Windows::NetUser.stub!(:new).and_return(@net_user)
    @provider = Chef::Provider::User::Windows.new(@node, @new_resource)
    @provider.current_resource = @current_resource
  end
  
  field_list = {
    'comment' => 'full_name',
    'home' => 'home_dir',
    'gid' => 'primary_group_id',
    'uid' => 'user_id',
    'shell' => 'script_path',
    'password' => 'password'
  }
  field_list.each do |attribute, option|
    it "should check for differences in #{attribute} between the new and current resources" do
      @current_resource.should_receive(attribute)
      @new_resource.should_receive(attribute)
      @provider.set_options
    end
    
    it "should set the option for #{attribute} if the new resources #{attribute} is not null" do
      @new_resource.stub!(attribute).and_return("hola")
      @provider.set_options.should eql({:name, @new_resource.username, option.to_sym, @new_resource.send(attribute)})
    end
  end
end

describe Chef::Provider::User::Windows, "create_user" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", :null_object => true)
    @net_user = mock("Chef::Util::Windows::NetUser",
      :null_object => true
    )
    Chef::Util::Windows::NetUser.stub!(:new).and_return(@net_user)
    @provider = Chef::Provider::User::Windows.new(@node, @new_resource)
    @provider.stub!(:set_options).and_return({:name, "monkey"})
    @net_user.stub!(:add)
  end

  it "should call @net_user.add with the return of set_options" do
    @net_user.should_receive(:add).with({:name, "monkey"})
    @provider.create_user
  end
end

describe Chef::Provider::User::Windows, "manage_user" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", :null_object => true)
    @net_user = mock("Chef::Util::Windows::NetUser",
      :null_object => true
    )
    Chef::Util::Windows::NetUser.stub!(:new).and_return(@net_user)
    @provider = Chef::Provider::User::Windows.new(@node, @new_resource)
    @provider.stub!(:set_options).and_return({:name, "monkey"})
    @net_user.stub!(:update)
  end
  
  it "should call @net_user.update with the return of set_options" do
    @net_user.should_receive(:update).with({:name, "monkey"})
    @provider.manage_user
  end
end

describe Chef::Provider::User::Windows, "remove_user" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User",
      :null_object => true,
      :username => "adam"
    )
    @net_user = mock("Chef::Util::Windows::NetUser",
      :null_object => true
    )
    Chef::Util::Windows::NetUser.stub!(:new).and_return(@net_user)
    @provider = Chef::Provider::User::Windows.new(@node, @new_resource)
    @net_user.stub!(:delete)
  end
  
  it "should call @net_user.delete" do
    @net_user.should_receive(:delete)
    @provider.remove_user
  end
end

describe Chef::Provider::User::Windows, "check_lock" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", :null_object => true)
    @current_resource = mock("Chef::Resource::User",
      :null_object => true,
      :password => "abracadabra"
    )
    @net_user = mock("Chef::Util::Windows::NetUser",
      :null_object => true
    )
    Chef::Util::Windows::NetUser.stub!(:new).and_return(@net_user)
    @provider = Chef::Provider::User::Windows.new(@node, @new_resource)
    @provider.current_resource = @current_resource
  end

  it "should return true if user is locked" do
    @net_user.stub!(:check_enabled).and_return(true)
    @provider.check_lock.should eql(true)
  end

  it "should return false if user is not locked" do
    @net_user.stub!(:check_enabled).and_return(false)
    @provider.check_lock.should eql(false)
  end
end

describe Chef::Provider::User::Windows, "lock_user" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User",
      :null_object => true,
      :username => "adam"
    )
    @net_user = mock("Chef::Util::Windows::NetUser",
      :null_object => true
    )
    Chef::Util::Windows::NetUser.stub!(:new).and_return(@net_user)
    @net_user.stub!(:check_enabled).and_return(true)
    @net_user.stub!(:disable_account)
    @provider = Chef::Provider::User::Windows.new(@node, @new_resource)
  end
  
  it "should call @net_user.disable_account" do
    @net_user.should_receive(:disable_account)
    @provider.lock_user
  end
end

describe Chef::Provider::User::Windows, "unlock_user" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User",
      :null_object => true,
      :username => "adam"
    )
    @net_user = mock("Chef::Util::Windows::NetUser",
      :null_object => true
    )
    Chef::Util::Windows::NetUser.stub!(:new).and_return(@net_user)
    @net_user.stub!(:check_enabled).and_return(false)
    @net_user.stub!(:enable_account)
    @provider = Chef::Provider::User::Windows.new(@node, @new_resource)
  end
  
  it "should call @net_user.enable_account" do
    @net_user.should_receive(:enable_account)
    @provider.unlock_user
  end
end
