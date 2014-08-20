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

# Chef::Resource::Group are turned off on Mac OS X 10.6 due to caching
# issues around Etc.getgrnam() not picking up the group membership
# changes that are done on the system. Etc.endgrent is not functioning
# correctly on certain 10.6 boxes.
describe Chef::Resource::Group, :requires_root_or_running_windows, :not_supported_on_mac_osx_106 do
  def group_should_exist(group)
    case ohai[:platform_family]
    when "debian", "fedora", "rhel", "suse", "gentoo", "slackware", "arch"
      expect { Etc::getgrnam(group) }.to_not raise_error(ArgumentError, "can't find group for #{group}")
      expect(group).to eq(Etc::getgrnam(group).name)
    when "windows"
      expect { Chef::Util::Windows::NetGroup.new(group).local_get_members }.to_not raise_error(ArgumentError, "The group name could not be found.")
    end
  end

  def user_exist_in_group?(user)
    case ohai[:platform_family]
    when "windows"
      user_sid = sid_string_from_user(user)
      user_sid.nil? ? false : Chef::Util::Windows::NetGroup.new(group_name).local_get_members.include?(user_sid)
    else
      Etc::getgrnam(group_name).mem.include?(user)
    end
  end

  def group_should_not_exist(group)
    case ohai[:platform_family]
    when "debian", "fedora", "rhel", "suse", "gentoo", "slackware", "arch"
      expect { Etc::getgrnam(group) }.to raise_error(ArgumentError, "can't find group for #{group}")
    when "windows"
      expect { Chef::Util::Windows::NetGroup.new(group).local_get_members }.to raise_error(ArgumentError, "The group name could not be found.")
    end
  end

  def compare_gid(resource, gid)
    return resource.gid == Etc::getgrnam(resource.name).gid if unix?
  end

  def sid_string_from_user(user)
    begin
      sid = Chef::ReservedNames::Win32::Security.lookup_account_name(user)
    rescue Chef::Exceptions::Win32APIError
      sid = nil
    end

    sid.nil? ? nil : sid[1].to_s
  end

  def windows_domain_user?(user_name)
    domain, user = user_name.split('\\')

    if user && domain != '.'
      computer_name = ENV['computername']
      domain.downcase != computer_name.downcase
    end
  end

  def user(username)
    usr = Chef::Resource::User.new("#{username}", run_context)
    if ohai[:platform_family] == "windows"
      usr.password("ComplexPass11!")
    end
    usr
  end

  def create_user(username)
    user(username).run_action(:create) if ! windows_domain_user?(username)
    # TODO: User shouldn't exist
  end

  def remove_user(username)
    user(username).run_action(:remove) if ! windows_domain_user?(username)
    # TODO: User shouldn't exist
  end

  shared_examples_for "correct group management" do
    def add_members_to_group(members)
      temp_resource = group_resource.dup
      temp_resource.members(members)
      temp_resource.excluded_members([ ])
      temp_resource.append(true)
      temp_resource.run_action(:modify)
      members.each do |member|
        user_exist_in_group?(member).should == true
      end
    end

    def create_group
      temp_resource = group_resource.dup
      temp_resource.members([ ])
      temp_resource.excluded_members([ ])
      temp_resource.run_action(:create)
      group_should_exist(group_name)
      included_members.each do |member|
        user_exist_in_group?(member).should == false
      end
    end

    before(:each) do
      create_group
    end

    after(:each) do
      group_resource.run_action(:remove)
      group_should_not_exist(group_name)
    end

    describe "when append is not set" do
      let(:included_members) { [spec_members[1]] }

      before do
        create_user(spec_members[1])
        create_user(spec_members[0])
        add_members_to_group([spec_members[0]])
      end

      after do
        remove_user(spec_members[1])
        remove_user(spec_members[0])
      end

      it "should remove the existing users and add the new users to the group" do
        group_resource.run_action(tested_action)

        user_exist_in_group?(spec_members[1]).should == true
        user_exist_in_group?(spec_members[0]).should == false
      end
    end

    describe "when append is set" do
      before(:each) do
        group_resource.append(true)
      end

      describe "when the users exist" do
        before do
          (included_members + excluded_members).each do |member|
            create_user(member)
          end
        end

        after do
          (included_members + excluded_members).each do |member|
            remove_user(member)
          end
        end

        it "should add included members to the group" do
          group_resource.run_action(tested_action)

          included_members.each do |member|
            user_exist_in_group?(member).should == true
          end
          excluded_members.each do |member|
            user_exist_in_group?(member).should == false
          end
        end

        describe "when group contains some users" do
          before(:each) do
            add_members_to_group([ spec_members[0], spec_members[2] ])
          end

          it "should add the included users and remove excluded users" do
            group_resource.run_action(tested_action)

            included_members.each do |member|
              user_exist_in_group?(member).should == true
            end
            excluded_members.each do |member|
              user_exist_in_group?(member).should == false
            end
          end
        end
      end

      describe "when the users doesn't exist" do
        describe "when append is not set" do
          it "should raise an error" do
            lambda { @grp_resource.run_action(tested_action) }.should raise_error
          end
        end

        describe "when append is set" do
          it "should raise an error" do
            lambda { @grp_resource.run_action(tested_action) }.should raise_error
          end
        end
      end
    end
  end

  shared_examples_for "an expected invalid domain error case" do
    let(:invalid_domain_user_name) { "no space\\administrator" }
    let(:nonexistent_domain_user_name) { "xxfakedom\\administrator" }
    before(:each) do
      group_resource.members []
      group_resource.excluded_members []
      group_resource.append(true)
      group_resource.run_action(:create)
      group_should_exist(group_name)
    end

    describe "when updating membership" do
      it "raises an error for a non well-formed domain name" do
        group_resource.members [invalid_domain_user_name]
        lambda { group_resource.run_action(tested_action) }.should raise_error Chef::Exceptions::Win32APIError
      end

      it "raises an error for a nonexistent domain" do
        group_resource.members [nonexistent_domain_user_name]
        lambda { group_resource.run_action(tested_action) }.should raise_error Chef::Exceptions::Win32APIError
      end
    end

    describe "when removing members" do
      it "raises an error for a non well-formed domain name" do
        group_resource.excluded_members [invalid_domain_user_name]
        lambda { group_resource.run_action(tested_action) }.should raise_error Chef::Exceptions::Win32APIError
      end

      it "raises an error for a nonexistent domain" do
        group_resource.excluded_members [nonexistent_domain_user_name]
        lambda { group_resource.run_action(tested_action) }.should raise_error Chef::Exceptions::Win32APIError
      end
    end
  end

  let(:group_name) { "t-#{SecureRandom.random_number(9999)}" }
  let(:included_members) { nil }
  let(:excluded_members) { nil }
  let(:group_resource) {
    group = Chef::Resource::Group.new(group_name, run_context)
    group.members(included_members)
    group.excluded_members(excluded_members)
    group
  }

  it "append should be false by default" do
    group_resource.append.should == false
  end

  describe "group create action" do
    after(:each) do
      group_resource.run_action(:remove)
      group_should_not_exist(group_name)
    end

    it "should create a group" do
      group_resource.run_action(:create)
      group_should_exist(group_name)
    end

    describe "when group name is length 256", :windows_only do
      let!(:group_name) { "theoldmanwalkingdownthestreetalwayshadagood\
smileonhisfacetheoldmanwalkingdownthestreetalwayshadagoodsmileonhisface\
theoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalking\
downthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestree" }

      it "should create a group" do
        group_resource.run_action(:create)
        group_should_exist(group_name)
      end
    end

    describe "when group name length is more than 256", :windows_only do
      let!(:group_name) { "theoldmanwalkingdownthestreetalwayshadagood\
smileonhisfacetheoldmanwalkingdownthestreetalwayshadagoodsmileonhisface\
theoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalking\
downthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestreeQQQQQQ" }

      it "should not create a group" do
        lambda { group_resource.run_action(:create) }.should raise_error
        group_should_not_exist(group_name)
      end
    end

    # not_supported_on_solaris because of the use of excluded_members
    describe "should raise an error when same member is included in the members and excluded_members", :not_supported_on_solaris do
      it "should raise an error" do
        invalid_resource = group_resource.dup
        invalid_resource.members(["Jack"])
        invalid_resource.excluded_members(["Jack"])
        lambda { invalid_resource.run_action(:create)}.should raise_error(Chef::Exceptions::ConflictingMembersInGroup)
      end
    end
  end

  describe "group remove action" do
    describe "when there is a group" do
      before do
        group_resource.run_action(:create)
        group_should_exist(group_name)
      end

      it "should remove a group" do
        group_resource.run_action(:remove)
        group_should_not_exist(group_name)
      end
    end

    describe "when there is no group" do
      it "should be no-op" do
        group_resource.run_action(:remove)
        group_should_not_exist(group_name)
      end
    end
  end

  describe "group modify action", :not_supported_on_solaris do
    let(:spec_members){ ["Gordon", "Eric", "Anthony"] }
    let(:included_members) { [spec_members[0], spec_members[1]] }
    let(:excluded_members) { [spec_members[2]] }
    let(:tested_action) { :modify }

    describe "when there is no group" do
      it "should raise an error" do
        lambda { group_resource.run_action(:modify) }.should raise_error
      end
    end

    describe "when there is a group" do
      it_behaves_like "correct group management"
    end

    describe "when running on Windows", :windows_only do
      describe "when members are Active Directory domain identities", :windows_domain_joined_only do
        let(:computer_domain) { ohai[:kernel]['cs_info']['domain'].split('.')[0] }
        let(:spec_members){ ["#{computer_domain}\\Domain Admins", "#{computer_domain}\\Domain Users", "#{computer_domain}\\Domain Computers"] }

        include_examples "correct group management"
      end

      it_behaves_like "an expected invalid domain error case"
    end
  end

  describe "group manage action", :not_supported_on_solaris do
    let(:spec_members){ ["Gordon", "Eric", "Anthony"] }
    let(:included_members) { [spec_members[0], spec_members[1]] }
    let(:excluded_members) { [spec_members[2]] }
    let(:tested_action) { :manage }

    describe "when there is no group" do
      it "should raise an error" do
        lambda { group_resource.run_action(:manage) }.should_not raise_error
        group_should_not_exist(group_name)
      end
    end

    describe "when there is a group" do
      it_behaves_like "correct group management"
    end

    describe "running on windows", :windows_only do
      describe "when members are Windows domain identities", :windows_domain_joined_only do
        let(:computer_domain) { ohai[:kernel]['cs_info']['domain'].split('.')[0] }
        let(:spec_members){ ["#{computer_domain}\\Domain Admins", "#{computer_domain}\\Domain Users", "#{computer_domain}\\Domain Computers"] }

        include_examples "correct group management"
      end

      it_behaves_like "an expected invalid domain error case"
    end
  end

  describe "group resource with Usermod provider", :solaris_only do
    describe "when excluded_members is set" do
      let(:excluded_members) { ["Anthony"] }

      it ":manage should raise an error" do
        lambda {group_resource.run_action(:manage) }.should raise_error
      end

      it ":modify should raise an error" do
        lambda {group_resource.run_action(:modify) }.should raise_error
      end

      it ":create should raise an error" do
        lambda {group_resource.run_action(:create) }.should raise_error
      end
    end

    describe "when append is not set" do
      let(:included_members) { ["Gordon", "Eric"] }

      before(:each) do
        group_resource.append(false)
      end

      it ":manage should raise an error" do
        lambda {group_resource.run_action(:manage) }.should raise_error
      end

      it ":modify should raise an error" do
        lambda {group_resource.run_action(:modify) }.should raise_error
      end
    end
  end
end



