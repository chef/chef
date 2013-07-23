#
# Author:: Chirag Jog (<chirag@clogeny.com>)
# Author:: Siddheshwar More (<siddheshwar.more@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'spec_helper'
require 'functional/resource/base'

describe Chef::Resource::Group, :requires_root_or_running_windows do

  def group_should_exist(resource)
    case ohai[:platform_family]
    when "debian", "fedora", "rhel", "suse", "gentoo", "slackware", "arch"
      expect { Etc::getgrnam(resource.name) }.to_not raise_error(ArgumentError, "can't find group for #{resource.name}")
      expect(resource.name).to eq(Etc::getgrnam(resource.name).name)
    when "windows"
      expect { Chef::Util::Windows::NetGroup.new(resource.group_name).local_get_members }.to_not raise_error(ArgumentError, "The group name could not be found.")
    end
  end

  def user_exist_in_group?(resource, user)
    case ohai[:platform_family]
    when "debian", "fedora", "rhel", "suse", "gentoo", "slackware", "arch"
      Etc::getgrnam(resource.name).mem.include?(user)
    when "windows"
      Chef::Util::Windows::NetGroup.new(resource.group_name).local_get_members.include?(user)
    end
  end

  def group_should_not_exist(resource)
    case ohai[:platform_family]
    when "debian", "fedora", "rhel", "suse", "gentoo", "slackware", "arch"
      expect { Etc::getgrnam(resource.name) }.to raise_error(ArgumentError, "can't find group for #{resource.name}")
    when "windows"
      expect { Chef::Util::Windows::NetGroup.new(resource.group_name).local_get_members }.to raise_error(ArgumentError, "The group name could not be found.")
    end
  end

  def compare_gid(resource, gid)
    case ohai[:platform_family]
    when "debian", "fedora", "rhel", "suse", "gentoo", "slackware", "arch", "mac_os_x"
      resource.gid == Etc::getgrnam(resource.name).gid
    end
  end

  def get_user_resource(username)
    usr = Chef::Resource::User.new("#{username}", run_context)
  end

  def create_user(username)
    get_user_resource(username).run_action(:create)
  end

  def remove_user(username)
    get_user_resource(username).run_action(:remove)
  end

  before do
    @grp_resource = Chef::Resource::Group.new("test-group-#{SecureRandom.random_number(9999)}", run_context)
  end

  context "group create action" do
    after(:each) do
      @grp_resource.run_action(:remove)
    end

    it "create a group" do
      @grp_resource.run_action(:create)
      group_should_exist(@grp_resource)
    end

    context "group name with 256 characters", :windows_only do
      before(:each) do
        grp_name = "theoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestree"
        @new_grp = Chef::Resource::Group.new(grp_name, run_context)
      end
      after do
        @new_grp.run_action(:remove)
      end
      it " create a group" do
        @new_grp.run_action(:create)
        group_should_exist(@new_grp)
      end
    end
    context "group name with more than 256 characters", :windows_only do
      before(:each) do
        grp_name = "theoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestreeQQQQQQQQQQQQQQQQQ"
        @new_grp = Chef::Resource::Group.new(grp_name, run_context)
      end
      it " not create a group" do
        expect { @new_grp.run_action(:create) }.to raise_error
        group_should_not_exist(@new_grp)
      end
    end
  end

  context "group remove action" do
    before(:each) do
      @grp_resource.run_action(:create)
    end

    it "remove a group" do
      @grp_resource.run_action(:remove)
      group_should_not_exist(@grp_resource)
    end
  end

  context "group modify action", :unix_only_but_not_osx do
    before(:each) do
      @grp_resource.run_action(:create)
    end

    after(:each) do
      @grp_resource.run_action(:remove)
    end

    it "add user to group" do
      user1 = "user1-#{SecureRandom.random_number(9999)}"
      user2 = "user2-#{SecureRandom.random_number(9999)}"

      create_user(user1)
      @grp_resource.members(user1)
      expect(user_exist_in_group?(@grp_resource, user1)).to be_false
      @grp_resource.run_action(:modify)
      group_should_exist(@grp_resource)
      expect(user_exist_in_group?(@grp_resource, user1)).to be_true

      create_user(user2)
      expect(user_exist_in_group?(@grp_resource, user2)).to be_false
      @grp_resource.members(user2)
      @grp_resource.run_action(:modify)
      group_should_exist(@grp_resource)

      #default append is false, so modify action remove old member user1 from group and add new member user2
      expect(user_exist_in_group?(@grp_resource, user1)).to be_false
      expect(user_exist_in_group?(@grp_resource, user2)).to be_true
      remove_user(user1)
      remove_user(user2)
    end


    it "append user to a group" do
      user1 = "user1-#{SecureRandom.random_number(9999)}"
      user2 = "user2-#{SecureRandom.random_number(9999)}"
      create_user(user1)
      @grp_resource.members(user1)
      expect(user_exist_in_group?(@grp_resource, user1)).to be_false
      #default append attribute is false
      @grp_resource.run_action(:modify)
      group_should_exist(@grp_resource)
      expect(user_exist_in_group?(@grp_resource, user1)).to be_true
      #set append attribute to true
      @grp_resource.append(true)
      create_user(user2)
      expect(user_exist_in_group?(@grp_resource, user2)).to be_false
      @grp_resource.members(user2)
      @grp_resource.run_action(:modify)
      group_should_exist(@grp_resource)
      expect(user_exist_in_group?(@grp_resource, user1)).to be_true
      expect(user_exist_in_group?(@grp_resource, user2)).to be_true
      remove_user(user1)
      remove_user(user2)
    end

    it "raise error on add non-existent user to group" do
      user1 = "user1-#{SecureRandom.random_number(9999)}"
      @grp_resource.members(user1)
      @grp_resource.append(true)
      expect(user_exist_in_group?(@grp_resource, user1)).to be_false
      expect { @grp_resource.run_action(:modify) }.to raise_error
    end
  end

  context "group manage action", :unix_only do
    before(:each) do
      @grp_resource.run_action(:create)
    end

    after(:each) do
      @grp_resource.run_action(:remove)
    end

    it "change gid of the group" do
      grp_id = 1234567890
      @grp_resource.gid(grp_id)
      @grp_resource.run_action(:manage)
      group_should_exist(@grp_resource)
      expect(compare_gid(@grp_resource, grp_id)).to be_true
    end
  end
end
