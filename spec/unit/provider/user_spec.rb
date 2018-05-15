#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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
      expect(@provider.user_exists).to eql(true)
    end

    it "does not know the locked state" do
      expect(@provider.locked).to eql(nil)
    end
  end

  describe "executing load_current_resource" do
    before(:each) do
      @node = Chef::Node.new
      # @new_resource = double("Chef::Resource::User",
      #  :null_object => true,
      #  :username => "adam",
      #  :comment => "Adam Jacob",
      #  :uid => 1000,
      #  :gid => 1000,
      #  :home => "/home/adam",
      #  :shell => "/usr/bin/zsh",
      #  :password => nil,
      #  :updated => nil
      # )
      allow(Chef::Resource::User).to receive(:new).and_return(@current_resource)
      @pw_user = EtcPwnamIsh.new
      @pw_user.name = "adam"
      @pw_user.gid = 1000
      @pw_user.uid = 1000
      @pw_user.gecos = "Adam Jacob"
      @pw_user.dir = "/home/adam"
      @pw_user.shell = "/usr/bin/zsh"
      @pw_user.passwd = "*"
      allow(Etc).to receive(:getpwnam).and_return(@pw_user)
    end

    it "should create a current resource with the same name as the new resource" do
      @provider.load_current_resource
      expect(@provider.current_resource.name).to eq("adam")
    end

    it "should set the username of the current resource to the username of the new resource" do
      @provider.load_current_resource
      expect(@current_resource.username).to eq(@new_resource.username)
    end

    it "should change the encoding of gecos to the encoding of the new resource" do
      @pw_user.gecos.force_encoding("ASCII-8BIT")
      @provider.load_current_resource
      expect(@provider.current_resource.comment.encoding).to eq(@new_resource.comment.encoding)
    end

    it "should look up the user in /etc/passwd with getpwnam" do
      expect(Etc).to receive(:getpwnam).with(@new_resource.username).and_return(@pw_user)
      @provider.load_current_resource
    end

    it "should set user_exists to false if the user is not found with getpwnam" do
      expect(Etc).to receive(:getpwnam).and_raise(ArgumentError)
      @provider.load_current_resource
      expect(@provider.user_exists).to eql(false)
    end

    # The mapping between the Chef::Resource::User and Getpwnam struct
    user_attrib_map = {
      uid: :uid,
      gid: :gid,
      comment: :gecos,
      home: :dir,
      shell: :shell,
    }
    user_attrib_map.each do |user_attrib, getpwnam_attrib|
      it "should set the current resources #{user_attrib} based on getpwnam #{getpwnam_attrib}" do
        expect(@current_resource).to receive(user_attrib).with(@pw_user.send(getpwnam_attrib))
        @provider.load_current_resource
      end
    end

    it "should attempt to convert the group gid if one has been supplied" do
      expect(@provider).to receive(:convert_group_name)
      @provider.load_current_resource
    end

    it "shouldn't try and convert the group gid if none has been supplied" do
      @new_resource.gid(false)
      expect(@provider).not_to receive(:convert_group_name)
      @provider.load_current_resource
    end

    it "should return the current resource" do
      expect(@provider.load_current_resource).to eql(@current_resource)
    end

    describe "and running assertions" do
      def self.shadow_lib_unavail?
        require "rubygems"
        require "shadow"
      rescue LoadError
        skip "ruby-shadow gem not installed for dynamic load test"
        true
      else
        false
      end

      before(:each) do
        user = @pw_user.dup
        user.name = "root"
        user.passwd = "x"
        @new_resource.password "some new password"
        allow(Etc).to receive(:getpwnam).and_return(user)
      end

      unless shadow_lib_unavail?
        context "and we have the ruby-shadow gem" do
          skip "and we are not root (rerun this again as root)", requires_unprivileged_user: true

          context "and we are root", requires_root: true do
            it "should pass assertions when ruby-shadow can be loaded" do
              @provider.action = "create"
              original_method = @provider.method(:require)
              expect(@provider).to receive(:require) { |*args| original_method.call(*args) }
              passwd_info = Struct::PasswdEntry.new(sp_namp: "adm ", sp_pwdp: "$1$T0N0Q.lc$nyG6pFI3Dpqa5cxUz/57j0", sp_lstchg: 14861, sp_min: 0, sp_max: 99999,
                                                    sp_warn: 7, sp_inact: -1, sp_expire: -1, sp_flag: -1)
              expect(Shadow::Passwd).to receive(:getspnam).with("adam").and_return(passwd_info)
              @provider.load_current_resource
              @provider.define_resource_requirements
              @provider.process_resource_requirements
            end
          end
        end
      end

      it "should fail assertions when ruby-shadow cannot be loaded" do
        expect(@provider).to receive(:require).with("shadow") { raise LoadError }
        @provider.load_current_resource
        @provider.define_resource_requirements
        expect { @provider.process_resource_requirements }.to raise_error Chef::Exceptions::MissingLibrary
      end

    end
  end

  describe "compare_user" do
    let(:mapping) do
      {
        "username" => %w{adam Adam},
        "comment" => ["Adam Jacob", "adam jacob"],
        "uid" => [1000, 1001],
        "gid" => [1000, 1001],
        "home" => ["/home/adam", "/Users/adam"],
        "shell" => ["/usr/bin/zsh", "/bin/bash"],
        "password" => %w{abcd 12345},
      }
    end

    %w{uid gid comment home shell password}.each do |attribute|
      it "should return true if #{attribute} doesn't match" do
        @new_resource.send(attribute, mapping[attribute][0])
        @current_resource.send(attribute, mapping[attribute][1])
        expect(@provider.compare_user).to eql(true)
      end
    end

    %w{uid gid}.each do |attribute|
      it "should return false if string #{attribute} matches fixnum" do
        @new_resource.send(attribute, "100")
        @current_resource.send(attribute, 100)
        expect(@provider.compare_user).to eql(false)
      end
    end

    it "should return false if the objects are identical" do
      expect(@provider.compare_user).to eql(false)
    end

    it "should ignore differences in trailing slash in home paths" do
      @new_resource.home "/home/adam"
      @current_resource.home "/home/adam/"
      expect(@provider.compare_user).to eql(false)
    end
  end

  describe "action_create" do
    before(:each) do
      allow(@provider).to receive(:load_current_resource)
      # @current_resource = double("Chef::Resource::User",
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
      # @provider.stub(:create_user).and_return(true)
      # @provider.stub(:manage_user).and_return(true)
    end

    it "should call create_user if the user does not exist" do
      @provider.user_exists = false
      expect(@provider).to receive(:create_user).and_return(true)
      @provider.action_create
      @provider.set_updated_status
      expect(@new_resource).to be_updated
    end

    it "should call manage_user if the user exists and has mismatched attributes" do
      @provider.user_exists = true
      allow(@provider).to receive(:compare_user).and_return(true)
      expect(@provider).to receive(:manage_user).and_return(true)
      @provider.action_create
    end

    it "should set the new_resources updated flag when it creates the user if we call manage_user" do
      @provider.user_exists = true
      allow(@provider).to receive(:compare_user).and_return(true)
      allow(@provider).to receive(:manage_user).and_return(true)
      @provider.action_create
      @provider.set_updated_status
      expect(@new_resource).to be_updated
    end
  end

  describe "action_remove" do
    before(:each) do
      allow(@provider).to receive(:load_current_resource)
    end

    it "should not call remove_user if the user does not exist" do
      @provider.user_exists = false
      expect(@provider).not_to receive(:remove_user)
      @provider.action_remove
    end

    it "should call remove_user if the user exists" do
      @provider.user_exists = true
      expect(@provider).to receive(:remove_user)
      @provider.action_remove
    end

    it "should set the new_resources updated flag to true if the user is removed" do
      @provider.user_exists = true
      expect(@provider).to receive(:remove_user)
      @provider.action_remove
      @provider.set_updated_status
      expect(@new_resource).to be_updated
    end
  end

  describe "action_manage" do
    before(:each) do
      allow(@provider).to receive(:load_current_resource)
      # @node = Chef::Node.new
      # @new_resource = double("Chef::Resource::User",
      #   :null_object => true
      # )
      # @current_resource = double("Chef::Resource::User",
      #   :null_object => true
      # )
      # @provider = Chef::Provider::User.new(@node, @new_resource)
      # @provider.current_resource = @current_resource
      # @provider.user_exists = true
      # @provider.stub(:manage_user).and_return(true)
    end

    it "should run manage_user if the user exists and has mismatched attributes" do
      expect(@provider).to receive(:compare_user).and_return(true)
      expect(@provider).to receive(:manage_user).and_return(true)
      @provider.action_manage
    end

    it "should set the new resources updated flag to true if manage_user is called" do
      allow(@provider).to receive(:compare_user).and_return(true)
      allow(@provider).to receive(:manage_user).and_return(true)
      @provider.action_manage
      @provider.set_updated_status
      expect(@new_resource).to be_updated
    end

    it "should not run manage_user if the user does not exist" do
      @provider.user_exists = false
      expect(@provider).not_to receive(:manage_user)
      @provider.action_manage
    end

    it "should not run manage_user if the user exists but has no differing attributes" do
      expect(@provider).to receive(:compare_user).and_return(false)
      expect(@provider).not_to receive(:manage_user)
      @provider.action_manage
    end
  end

  describe "action_modify" do
    before(:each) do
      allow(@provider).to receive(:load_current_resource)
      # @node = Chef::Node.new
      # @new_resource = double("Chef::Resource::User",
      #   :null_object => true
      # )
      # @current_resource = double("Chef::Resource::User",
      #   :null_object => true
      # )
      # @provider = Chef::Provider::User.new(@node, @new_resource)
      # @provider.current_resource = @current_resource
      # @provider.user_exists = true
      # @provider.stub(:manage_user).and_return(true)
    end

    it "should run manage_user if the user exists and has mismatched attributes" do
      expect(@provider).to receive(:compare_user).and_return(true)
      expect(@provider).to receive(:manage_user).and_return(true)
      @provider.action_modify
    end

    it "should set the new resources updated flag to true if manage_user is called" do
      allow(@provider).to receive(:compare_user).and_return(true)
      allow(@provider).to receive(:manage_user).and_return(true)
      @provider.action_modify
      @provider.set_updated_status
      expect(@new_resource).to be_updated
    end

    it "should not run manage_user if the user exists but has no differing attributes" do
      expect(@provider).to receive(:compare_user).and_return(false)
      expect(@provider).not_to receive(:manage_user)
      @provider.action_modify
    end

    it "should raise a Chef::Exceptions::User if the user doesn't exist" do
      @provider.user_exists = false
      expect { @provider.action = :modify; @provider.run_action }.to raise_error(Chef::Exceptions::User)
    end
  end

  describe "action_lock" do
    before(:each) do
      allow(@provider).to receive(:load_current_resource)
    end
    it "should lock the user if it exists and is unlocked" do
      allow(@provider).to receive(:check_lock).and_return(false)
      expect(@provider).to receive(:lock_user).and_return(true)
      @provider.action_lock
    end

    it "should set the new resources updated flag to true if lock_user is called" do
      allow(@provider).to receive(:check_lock).and_return(false)
      expect(@provider).to receive(:lock_user)
      @provider.action_lock
      @provider.set_updated_status
      expect(@new_resource).to be_updated
    end

    it "should raise a Chef::Exceptions::User if we try and lock a user that does not exist" do
      @provider.user_exists = false
      @provider.action = :lock

      expect { @provider.run_action }.to raise_error(Chef::Exceptions::User)
    end
  end

  describe "action_unlock" do
    before(:each) do
      allow(@provider).to receive(:load_current_resource)
      # @node = Chef::Node.new
      # @new_resource = double("Chef::Resource::User",
      #   :null_object => true
      # )
      # @current_resource = double("Chef::Resource::User",
      #   :null_object => true
      # )
      # @provider = Chef::Provider::User.new(@node, @new_resource)
      # @provider.current_resource = @current_resource
      # @provider.user_exists = true
      # @provider.stub(:check_lock).and_return(true)
      # @provider.stub(:unlock_user).and_return(true)
    end

    it "should unlock the user if it exists and is locked" do
      allow(@provider).to receive(:check_lock).and_return(true)
      expect(@provider).to receive(:unlock_user).and_return(true)
      @provider.action_unlock
      @provider.set_updated_status
      expect(@new_resource).to be_updated
    end

    it "should raise a Chef::Exceptions::User if we try and unlock a user that does not exist" do
      @provider.user_exists = false
      @provider.action = :unlock
      expect { @provider.run_action }.to raise_error(Chef::Exceptions::User)
    end
  end

  describe "convert_group_name" do
    before do
      @new_resource.gid("999")
      @group = EtcGrnamIsh.new("wheel", "*", 999, [])
    end

    it "should lookup the group name locally" do
      expect(Etc).to receive(:getgrnam).with("999").and_return(@group)
      expect(@provider.convert_group_name).to eq(999)
    end

    it "should raise an error if we can't translate the group name during resource assertions" do
      expect(Etc).to receive(:getgrnam).and_raise(ArgumentError)
      @provider.action = :create
      @provider.define_resource_requirements
      @provider.convert_group_name
      expect { @provider.process_resource_requirements }.to raise_error(Chef::Exceptions::User)
    end

    it "does not raise an error if we can't translate the group name during resource assertions if we are removing the user" do
      expect(Etc).to receive(:getgrnam).and_raise(ArgumentError)
      @provider.action = :remove
      @provider.define_resource_requirements
      @provider.convert_group_name
      expect { @provider.process_resource_requirements }.not_to raise_error
    end

    it "should set the new resources gid to the integerized version if available" do
      expect(Etc).to receive(:getgrnam).with("999").and_return(@group)
      @provider.convert_group_name
      expect(@new_resource.gid).to eq(999)
    end
  end
end
