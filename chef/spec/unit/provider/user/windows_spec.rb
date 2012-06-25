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

class Chef
  class Util
    class Windows
      class NetUser
      end
    end
  end
end

describe Chef::Provider::User::Windows do
  before(:each) do
    @node = Chef::Node.new
    @new_resource = Chef::Resource::User.new("monkey")
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @current_resource = Chef::Resource::User.new("monkey")

    @net_user = mock("Chef::Util::Windows::NetUser")
    Chef::Util::Windows::NetUser.stub!(:new).and_return(@net_user)

    @provider = Chef::Provider::User::Windows.new(@new_resource, @run_context)
    @provider.current_resource = @current_resource
  end
  
  describe "when comparing the user's current attributes to the desired attributes" do
    before do
      @new_resource.comment   "Adam Jacob"
      @new_resource.uid       1000
      @new_resource.gid       1000
      @new_resource.home      "/home/adam"
      @new_resource.shell     "/usr/bin/zsh"
      @new_resource.password  "abracadabra"

      @provider.current_resource = @new_resource.clone
    end
    describe "and the attributes match" do
      it "doesn't set the comment field to be updated" do
        @provider.set_options.should_not have_key(:full_name)
      end

      it "doesn't set the home directory to be updated" do
        @provider.set_options.should_not have_key(:home_dir)
      end

      it "doesn't set the group id to be updated" do
        @provider.set_options.should_not have_key(:primary_group_id)
      end

      it "doesn't set the user id to be updated" do
        @provider.set_options.should_not have_key(:user_id)
      end

      it "doesn't set the shell to be updated" do
        @provider.set_options.should_not have_key(:script_path)
      end

      it "doesn't set the password to be updated" do
        @provider.set_options.should_not have_key(:password)
      end

    end
    
    describe "and the attributes do not match" do
      before do
        @current_resource = Chef::Resource::User.new("adam")
        @current_resource.comment   "Adam Jacob-foo"
        @current_resource.uid       1111
        @current_resource.gid       1111
        @current_resource.home      "/home/adam-foo"
        @current_resource.shell     "/usr/bin/tcsh"
        @current_resource.password  "foobarbaz"
        @provider.current_resource = @current_resource
      end

      it "marks the full_name field to be updated" do
        @provider.set_options[:full_name].should == "Adam Jacob"
      end

      it "marks the home_dir attribute to be updated" do
        @provider.set_options[:home_dir].should == '/home/adam'
      end

      it "marks the primary_group_id attribute to be updated" do
        @provider.set_options[:primary_group_id].should == 1000
      end

      it "marks the user_id attribute to be updated" do
        @provider.set_options[:user_id].should == 1000
      end

      it "marks the script_path attribute to be updated" do
        @provider.set_options[:script_path].should == '/usr/bin/zsh'
      end

      it "marks the password attribute to be updated" do
        @provider.set_options[:password].should == 'abracadabra'
      end
    end
  end

  describe "when creating the user" do
    it "should call @net_user.add with the return of set_options" do
      @provider.stub!(:set_options).and_return(:name=> "monkey")
      @net_user.should_receive(:add).with(:name=> "monkey")
      @provider.create_user
    end
  end

  describe "manage_user" do
    before(:each) do
      @provider.stub!(:set_options).and_return(:name=> "monkey")
    end
  
    it "should call @net_user.update with the return of set_options" do
      @net_user.should_receive(:update).with(:name=> "monkey")
      @provider.manage_user
    end
  end

  describe "when removing the user" do
    it "should call @net_user.delete" do
      @net_user.should_receive(:delete)
      @provider.remove_user
    end
  end

  describe "when checking if the user is locked" do
    before(:each) do
      @current_resource.password "abracadabra"
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

  describe "locking the user" do
    it "should call @net_user.disable_account" do
      @net_user.stub!(:check_enabled).and_return(true)
      @net_user.should_receive(:disable_account)
      @provider.lock_user
    end
  end

  describe "unlocking the user" do
    it "should call @net_user.enable_account" do
      @net_user.stub!(:check_enabled).and_return(false)
      @net_user.should_receive(:enable_account)
      @provider.unlock_user
    end
  end
end
