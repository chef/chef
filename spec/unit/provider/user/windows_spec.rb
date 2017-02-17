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
    @new_resource = Chef::Resource::User::WindowsUser.new("monkey")
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @current_resource = Chef::Resource::User::WindowsUser.new("monkey")

    @net_user = double("Chef::Util::Windows::NetUser")
    allow(Chef::Util::Windows::NetUser).to receive(:new).and_return(@net_user)

    @provider = Chef::Provider::User::Windows.new(@new_resource, @run_context)
    @provider.current_resource = @current_resource
  end

  it "creates a net_user object with the provided username" do
    @new_resource.username "not-monkey"
    expect(Chef::Util::Windows::NetUser).to receive(:new).with("not-monkey")
    @provider = Chef::Provider::User::Windows.new(@new_resource, @run_context)
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
        expect(@provider.set_options).not_to have_key(:full_name)
      end

      it "doesn't set the home directory to be updated" do
        expect(@provider.set_options).not_to have_key(:home_dir)
      end

      it "doesn't set the group id to be updated" do
        expect(@provider.set_options).not_to have_key(:primary_group_id)
      end

      it "doesn't set the user id to be updated" do
        expect(@provider.set_options).not_to have_key(:user_id)
      end

      it "doesn't set the shell to be updated" do
        expect(@provider.set_options).not_to have_key(:script_path)
      end

      it "doesn't set the password to be updated" do
        expect(@provider.set_options).not_to have_key(:password)
      end

    end

    describe "and the attributes do not match" do
      before do
        @current_resource = Chef::Resource::User::WindowsUser.new("adam")
        @current_resource.comment   "Adam Jacob-foo"
        @current_resource.uid       1111
        @current_resource.gid       1111
        @current_resource.home      "/home/adam-foo"
        @current_resource.shell     "/usr/bin/tcsh"
        @current_resource.password  "foobarbaz"
        @provider.current_resource = @current_resource
      end

      it "marks the full_name field to be updated" do
        expect(@provider.set_options[:full_name]).to eq("Adam Jacob")
      end

      it "marks the home_dir attribute to be updated" do
        expect(@provider.set_options[:home_dir]).to eq("/home/adam")
      end

      it "ignores the primary_group_id attribute" do
        expect(@provider.set_options[:primary_group_id]).to eq(nil)
      end

      it "marks the user_id attribute to be updated" do
        expect(@provider.set_options[:user_id]).to eq(1000)
      end

      it "marks the script_path attribute to be updated" do
        expect(@provider.set_options[:script_path]).to eq("/usr/bin/zsh")
      end

      it "marks the password attribute to be updated" do
        expect(@provider.set_options[:password]).to eq("abracadabra")
      end
    end
  end

  describe "when creating the user" do
    it "should call @net_user.add with the return of set_options" do
      allow(@provider).to receive(:set_options).and_return(name: "monkey")
      expect(@net_user).to receive(:add).with(name: "monkey")
      @provider.create_user
    end
  end

  describe "manage_user" do
    before(:each) do
      allow(@provider).to receive(:set_options).and_return(name: "monkey")
    end

    it "should call @net_user.update with the return of set_options" do
      expect(@net_user).to receive(:update).with(name: "monkey")
      @provider.manage_user
    end
  end

  describe "when removing the user" do
    it "should call @net_user.delete" do
      expect(@net_user).to receive(:delete)
      @provider.remove_user
    end
  end

  describe "when checking if the user is locked" do
    before(:each) do
      @current_resource.password "abracadabra"
    end

    it "should return true if user is locked" do
      allow(@net_user).to receive(:check_enabled).and_return(true)
      expect(@provider.check_lock).to eql(true)
    end

    it "should return false if user is not locked" do
      allow(@net_user).to receive(:check_enabled).and_return(false)
      expect(@provider.check_lock).to eql(false)
    end
  end

  describe "locking the user" do
    it "should call @net_user.disable_account" do
      allow(@net_user).to receive(:check_enabled).and_return(true)
      expect(@net_user).to receive(:disable_account)
      @provider.lock_user
    end
  end

  describe "unlocking the user" do
    it "should call @net_user.enable_account" do
      allow(@net_user).to receive(:check_enabled).and_return(false)
      expect(@net_user).to receive(:enable_account)
      @provider.unlock_user
    end
  end
end
