#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

EtcPwnamIsh = Struct.new(:name, :passwd, :uid, :gid, :gecos, :dir, :shell, :change, :uclass, :expire)
EtcGrnamIsh = Struct.new(:name, :passwd, :gid, :mem)

describe Chef::Provider::User do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::User.new("adam")
    @new_resource.comment "Adam Jacob"
    @new_resource.uid 1000
    @new_resource.gid 1000
    @new_resource.home "/home/adam"
    @new_resource.shell "/usr/bin/zsh"

    @current_resource = Chef::Resource::User.new("adam")
    @current_resource.comment "Adam Jacob"
    @current_resource.uid 1000
    @current_resource.gid 1000
    @current_resource.home "/home/adam"
    @current_resource.shell "/usr/bin/zsh"

    @provider = Chef::Provider::User.new(@new_resource, @run_context)
    @provider.current_resource = @current_resource
  end

  describe "when first created" do
    it "assume the user exists by default" do
      @provider.user_exists.should eql(true)
    end

    it "does not know the locked state" do
      @provider.locked.should eql(nil)
    end
  end

  describe "executing load_current_resource" do
    before(:each) do
      @node = Chef::Node.new
      #@new_resource = mock("Chef::Resource::User", 
      #  :null_object => true,
      #  :username => "adam",
      #  :comment => "Adam Jacob",
      #  :uid => 1000,
      #  :gid => 1000,
      #  :home => "/home/adam",
      #  :shell => "/usr/bin/zsh",
      #  :password => nil,
      #  :updated => nil
      #)
      Chef::Resource::User.stub!(:new).and_return(@current_resource)
      @pw_user = EtcPwnamIsh.new
      @pw_user.name = "adam"
      @pw_user.gid = 1000
      @pw_user.uid = 1000
      @pw_user.gecos = "Adam Jacob"
      @pw_user.dir = "/home/adam"
      @pw_user.shell = "/usr/bin/zsh"
      @pw_user.passwd = "*"
      Etc.stub!(:getpwnam).and_return(@pw_user)
    end

    it "should create a current resource with the same name as the new resource" do
      @provider.load_current_resource
      @provider.current_resource.name.should == 'adam'
    end

    it "should set the username of the current resource to the username of the new resource" do
      @provider.load_current_resource
      @current_resource.username.should == @new_resource.username
    end

    it "should look up the user in /etc/passwd with getpwnam" do
      Etc.should_receive(:getpwnam).with(@new_resource.username).and_return(@pw_user)
      @provider.load_current_resource
    end

    it "should set user_exists to false if the user is not found with getpwnam" do
      Etc.should_receive(:getpwnam).and_raise(ArgumentError)
      @provider.load_current_resource
      @provider.user_exists.should eql(false)
    end

    # The mapping between the Chef::Resource::User and Getpwnam struct
    user_attrib_map = {
      :uid => :uid,
      :gid => :gid,
      :comment => :gecos,
      :home => :dir,
      :shell => :shell
    }
    user_attrib_map.each do |user_attrib, getpwnam_attrib|
      it "should set the current resources #{user_attrib} based on getpwnam #{getpwnam_attrib}" do
        @current_resource.should_receive(user_attrib).with(@pw_user.send(getpwnam_attrib))
        @provider.load_current_resource
      end
    end

    it "should attempt to convert the group gid if one has been supplied" do
      @provider.should_receive(:convert_group_name)
      @provider.load_current_resource
    end

    it "shouldn't try and convert the group gid if none has been supplied" do
      @new_resource.stub!(:gid).and_return(nil)
      @provider.should_not_receive(:convert_group_name)
      @provider.load_current_resource
    end

    it "should return the current resource" do
      @provider.load_current_resource.should eql(@current_resource)
    end

    describe "and running assertions" do
      def self.shadow_lib_unavail?
        begin
          require 'rubygems'
          require 'shadow'
        rescue LoadError => e
          pending "ruby-shadow gem not installed for dynamic load test"
          true
        else
          false
        end
      end

      before (:each) do
        user = @pw_user.dup
        user.name = "root"
        user.passwd = "x"
        @new_resource.password "some new password"
        Etc.stub!(:getpwnam).and_return(user)
      end
      
      unless shadow_lib_unavail?
        context "and we have the ruby-shadow gem" do
          pending "and we are not root (rerun this again as root)", :requires_unprivileged_user => true 
  
          context "and we are root", :requires_root => true do
            it "should pass assertions when ruby-shadow can be loaded" do
              @provider.action = 'create'
              original_method = @provider.method(:require)
              @provider.should_receive(:require) { |*args| original_method.call(*args) }
              passwd_info = Struct::PasswdEntry.new(:sp_namp => "adm ", :sp_pwdp => "$1$T0N0Q.lc$nyG6pFI3Dpqa5cxUz/57j0", :sp_lstchg => 14861, :sp_min => 0, :sp_max => 99999, 
                                                    :sp_warn => 7, :sp_inact => -1, :sp_expire => -1, :sp_flag => -1)
              Shadow::Passwd.should_receive(:getspnam).with("adam").and_return(passwd_info)
              @provider.load_current_resource
              @provider.define_resource_requirements
              @provider.process_resource_requirements
            end
          end
        end
      end

      it "should fail assertions when ruby-shadow cannot be loaded" do
        @provider.should_receive(:require).with("shadow") { raise LoadError }
        @provider.load_current_resource
        @provider.define_resource_requirements
        lambda {@provider.process_resource_requirements}.should raise_error Chef::Exceptions::MissingLibrary 
      end

    end
  end

  describe "compare_user" do
    before(:each) do
      # @node = Chef::Node.new
      # @new_resource = mock("Chef::Resource::User", 
      #   :null_object => true,
      #   :username => "adam",
      #   :comment => "Adam Jacob",
      #   :uid => 1000,
      #   :gid => 1000,
      #   :home => "/home/adam",
      #   :shell => "/usr/bin/zsh",
      #   :password => nil,
      #   :updated => nil
      # )
      # @current_resource = mock("Chef::Resource::User", 
      #   :null_object => true,
      #   :username => "adam",
      #   :comment => "Adam Jacob",
      #   :uid => 1000,
      #   :gid => 1000,
      #   :home => "/home/adam",
      #   :shell => "/usr/bin/zsh",
      #   :password => nil,
      #   :updated => nil
      # )
      # @provider = Chef::Provider::User.new(@node, @new_resource)
      # @provider.current_resource = @current_resource
    end

    %w{uid gid comment home shell password}.each do |attribute|
      it "should return true if #{attribute} doesn't match" do
        @new_resource.should_receive(attribute).exactly(2).times.and_return(true)
        @current_resource.should_receive(attribute).once.and_return(false)
        @provider.compare_user.should eql(true)
      end
    end

    it "should return false if the objects are identical" do
      @provider.compare_user.should eql(false)
    end  
  end

  describe "action_create" do
    before(:each) do
      @provider.stub!(:load_current_resource)
      # @current_resource = mock("Chef::Resource::User", 
      #   :null_object => true,
      #   :username => "adam",
      #   :comment => "Adam Jacob",
      #   :uid => 1000,
      #   :gid => 1000,
      #   :home => "/home/adam",
      #   :shell => "/usr/bin/zsh",
      #   :password => nil,
      #   :updated => nil
      # )
      # @provider = Chef::Provider::User.new(@node, @new_resource)
      # @provider.current_resource = @current_resource
      # @provider.user_exists = false
      # @provider.stub!(:create_user).and_return(true)
      # @provider.stub!(:manage_user).and_return(true)
    end

    it "should call create_user if the user does not exist" do
      @provider.user_exists = false
      @provider.should_receive(:create_user).and_return(true)
      @provider.action_create
      @provider.set_updated_status
      @new_resource.should be_updated
    end

    it "should call manage_user if the user exists and has mismatched attributes" do
      @provider.user_exists = true
      @provider.stub!(:compare_user).and_return(true)
      @provider.should_receive(:manage_user).and_return(true)
      @provider.action_create
    end

    it "should set the the new_resources updated flag when it creates the user if we call manage_user" do
      @provider.user_exists = true
      @provider.stub!(:compare_user).and_return(true)
      @provider.stub!(:manage_user).and_return(true)
      @provider.action_create
      @provider.set_updated_status
      @new_resource.should be_updated
    end
  end

  describe "action_remove" do
    before(:each) do
      @provider.stub!(:load_current_resource)
    end

    it "should not call remove_user if the user does not exist" do
      @provider.user_exists = false
      @provider.should_not_receive(:remove_user) 
      @provider.action_remove
    end

    it "should call remove_user if the user exists" do
      @provider.user_exists = true
      @provider.should_receive(:remove_user)
      @provider.action_remove
    end

    it "should set the new_resources updated flag to true if the user is removed" do
      @provider.user_exists = true
      @provider.should_receive(:remove_user)
      @provider.action_remove
      @provider.set_updated_status
      @new_resource.should be_updated
    end
  end

  describe "action_manage" do
    before(:each) do
      @provider.stub!(:load_current_resource)
      # @node = Chef::Node.new
      # @new_resource = mock("Chef::Resource::User", 
      #   :null_object => true
      # )
      # @current_resource = mock("Chef::Resource::User", 
      #   :null_object => true
      # )
      # @provider = Chef::Provider::User.new(@node, @new_resource)
      # @provider.current_resource = @current_resource
      # @provider.user_exists = true
      # @provider.stub!(:manage_user).and_return(true)
    end

    it "should run manage_user if the user exists and has mismatched attributes" do
      @provider.should_receive(:compare_user).and_return(true)
      @provider.should_receive(:manage_user).and_return(true)
      @provider.action_manage
    end

    it "should set the new resources updated flag to true if manage_user is called" do
      @provider.stub!(:compare_user).and_return(true)
      @provider.stub!(:manage_user).and_return(true)
      @provider.action_manage
      @provider.set_updated_status
      @new_resource.should be_updated
    end

    it "should not run manage_user if the user does not exist" do
      @provider.user_exists = false
      @provider.should_not_receive(:manage_user)
      @provider.action_manage
    end

    it "should not run manage_user if the user exists but has no differing attributes" do
      @provider.should_receive(:compare_user).and_return(false)
      @provider.should_not_receive(:manage_user)
      @provider.action_manage
    end
  end

  describe "action_modify" do
    before(:each) do
      @provider.stub!(:load_current_resource)
      # @node = Chef::Node.new
      # @new_resource = mock("Chef::Resource::User", 
      #   :null_object => true
      # )
      # @current_resource = mock("Chef::Resource::User", 
      #   :null_object => true
      # )
      # @provider = Chef::Provider::User.new(@node, @new_resource)
      # @provider.current_resource = @current_resource
      # @provider.user_exists = true
      # @provider.stub!(:manage_user).and_return(true)
    end

    it "should run manage_user if the user exists and has mismatched attributes" do
      @provider.should_receive(:compare_user).and_return(true)
      @provider.should_receive(:manage_user).and_return(true)
      @provider.action_modify
    end

    it "should set the new resources updated flag to true if manage_user is called" do
      @provider.stub!(:compare_user).and_return(true)
      @provider.stub!(:manage_user).and_return(true)
      @provider.action_modify
      @provider.set_updated_status
      @new_resource.should be_updated
    end

    it "should not run manage_user if the user exists but has no differing attributes" do
      @provider.should_receive(:compare_user).and_return(false)
      @provider.should_not_receive(:manage_user)
      @provider.action_modify
    end

    it "should raise a Chef::Exceptions::User if the user doesn't exist" do
      @provider.user_exists = false
      lambda { @provider.action = :modify; @provider.run_action }.should raise_error(Chef::Exceptions::User)
    end
  end


  describe "action_lock" do
    before(:each) do
      @provider.stub!(:load_current_resource)
    end
    it "should lock the user if it exists and is unlocked" do
      @provider.stub!(:check_lock).and_return(false)
      @provider.should_receive(:lock_user).and_return(true)
      @provider.action_lock
    end

    it "should set the new resources updated flag to true if lock_user is called" do
      @provider.stub!(:check_lock).and_return(false)
      @provider.should_receive(:lock_user)
      @provider.action_lock
      @provider.set_updated_status
      @new_resource.should be_updated
    end

    it "should raise a Chef::Exceptions::User if we try and lock a user that does not exist" do
      @provider.user_exists = false
      @provider.action = :lock

      lambda { @provider.run_action }.should raise_error(Chef::Exceptions::User)
    end
  end

  describe "action_unlock" do
    before(:each) do
      @provider.stub!(:load_current_resource)
      # @node = Chef::Node.new
      # @new_resource = mock("Chef::Resource::User", 
      #   :null_object => true
      # )
      # @current_resource = mock("Chef::Resource::User", 
      #   :null_object => true
      # )
      # @provider = Chef::Provider::User.new(@node, @new_resource)
      # @provider.current_resource = @current_resource
      # @provider.user_exists = true
      # @provider.stub!(:check_lock).and_return(true)
      # @provider.stub!(:unlock_user).and_return(true)
    end

    it "should unlock the user if it exists and is locked" do
      @provider.stub!(:check_lock).and_return(true)
      @provider.should_receive(:unlock_user).and_return(true)
      @provider.action_unlock
      @provider.set_updated_status
      @new_resource.should be_updated
    end

    it "should raise a Chef::Exceptions::User if we try and unlock a user that does not exist" do
      @provider.user_exists = false
      @provider.action = :unlock
      lambda { @provider.run_action }.should raise_error(Chef::Exceptions::User)
    end
  end

  describe "convert_group_name" do
    before do
      @new_resource.gid('999')
      @group = EtcGrnamIsh.new('wheel', '*', 999, [])
    end

    it "should lookup the group name locally" do
      Etc.should_receive(:getgrnam).with("999").and_return(@group)
      @provider.convert_group_name.should == 999
    end

    it "should raise an error if we can't translate the group name during resource assertions" do
      Etc.should_receive(:getgrnam).and_raise(ArgumentError)
      @provider.define_resource_requirements
      @provider.convert_group_name
      lambda { @provider.process_resource_requirements }.should raise_error(Chef::Exceptions::User)
    end

    it "should set the new resources gid to the integerized version if available" do
      Etc.should_receive(:getgrnam).with("999").and_return(@group)
      @provider.convert_group_name
      @new_resource.gid.should == 999
    end
  end
end
