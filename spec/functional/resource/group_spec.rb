#
# Author:: Chirag Jog (<chirag@clogeny.com>)
# Author:: Siddheshwar More (<siddheshwar.more@clogeny.com>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require "spec_helper"
require "chef/mixin/shell_out"

describe Chef::Resource::Group, :requires_root_or_running_windows do
  include Chef::Mixin::ShellOut

  def group_should_exist(group)
    case ohai[:os]
    when "linux"
      expect { Etc.getgrnam(group) }.not_to raise_error
      expect(group).to eq(Etc.getgrnam(group).name)
    when "windows"
      expect { Chef::Util::Windows::NetGroup.new(group).local_get_members }.not_to raise_error
    end
  end

  def user_exist_in_group?(user)
    case ohai[:platform_family]
    when "windows"
      user_sid = sid_string_from_user(user)
      user_sid.nil? ? false : Chef::Util::Windows::NetGroup.new(group_name).local_get_members.include?(user_sid)
    when "mac_os_x"
      membership_info = shell_out("dscl . -read /Groups/#{group_name}").stdout
      members = membership_info.split(" ")
      members.shift # Get rid of GroupMembership: string
      members.include?(user)
    else
      Etc.getgrnam(group_name).mem.include?(user)
    end
  end

  def group_should_not_exist(group)
    case ohai[:os]
    when "linux"
      expect { Etc.getgrnam(group) }.to raise_error(ArgumentError, "can't find group for #{group}")
    when "windows"
      expect { Chef::Util::Windows::NetGroup.new(group).local_get_members }.to raise_error(ArgumentError, /The group name could not be found./)
    end
  end

  def compare_gid(resource, gid)
    return resource.gid == Etc.getgrnam(resource.name).gid if unix?
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
    domain, user = user_name.split("\\")

    if user && domain != "."
      computer_name = ENV["computername"]
      !domain.casecmp(computer_name.downcase) == 0
    end
  end

  def node
    node = Chef::Node.new
    node.consume_external_attrs(ohai.data, {})
    node
  end

  def user(username)
    usr = Chef::Resource.resource_for_node(:user, node).new(username, run_context)
    if ohai[:platform_family] == "windows"
      usr.password("ComplexPass11!")
    end
    usr
  end

  def create_user(username, uid = nil)
    unless windows_domain_user?(username)
      user_to_create = user(username)
      user_to_create.uid(uid) if uid
      user_to_create.run_action(:create)
    end
    # TODO: User should exist
  end

  def remove_user(username)
    unless windows_domain_user?(username)
      u = user(username)
      u.manage_home false # jekins hosts throw mail spool file not owned by user if we use manage_home true
      u.run_action(:remove)
    end
    # TODO: User shouldn't exist
  end

  let(:run_context) do
    node = Chef::Node.new
    node.default[:platform] = ohai[:platform]
    node.default[:platform_version] = ohai[:platform_version]
    node.default[:os] = ohai[:os]
    events = Chef::EventDispatch::Dispatcher.new
    Chef::RunContext.new(node, {}, events)
  end

  shared_examples_for "correct group management" do
    def add_members_to_group(members)
      temp_resource = group_resource.dup
      temp_resource.members(members)
      temp_resource.excluded_members([ ])
      temp_resource.append(true)
      temp_resource.run_action(:modify)
      members.each do |member|
        expect(user_exist_in_group?(member)).to eq(true)
      end
    end

    def create_group
      temp_resource = group_resource.dup
      temp_resource.members([ ])
      temp_resource.excluded_members([ ])
      temp_resource.run_action(:create)
      group_should_exist(group_name)
      included_members.each do |member|
        expect(user_exist_in_group?(member)).to eq(false)
      end
    end

    before(:each) do
      create_group
    end

    after(:each) do
      group_resource.run_action(:remove)
      group_should_not_exist(group_name)
    end

    # dscl doesn't perform any error checking and will let you add users that don't exist.
    describe "when no users exist", :not_supported_on_macos do
      describe "when append is not set" do
        # excluded_members can only be used when append is set.  It is ignored otherwise.
        let(:excluded_members) { [] }

        let(:expected_error_class) { windows? ? ArgumentError : Mixlib::ShellOut::ShellCommandFailed }

        it "should raise an error" do
          expect { group_resource.run_action(tested_action) }.to raise_error(expected_error_class)
        end
      end

      describe "when append is set" do
        before do
          group_resource.append(true)
        end

        let(:expected_error_class) { windows? ? Chef::Exceptions::Win32APIError : Mixlib::ShellOut::ShellCommandFailed }

        it "should raise an error" do
          expect { group_resource.run_action(tested_action) }.to raise_error(expected_error_class)
        end
      end
    end

    describe "when the users exist" do
      before do
        high_uid = 30000
        (spec_members).each do |member|
          remove_user(member)
          create_user(member, high_uid)
          high_uid += 1
        end
      end

      after do
        (spec_members).each do |member|
          remove_user(member)
        end
      end

      describe "when append is not set" do
        it "should set the group to to contain given members" do
          group_resource.run_action(tested_action)

          included_members.each do |member|
            expect(user_exist_in_group?(member)).to eq(true)
          end
          (spec_members - included_members).each do |member|
            expect(user_exist_in_group?(member)).to eq(false)
          end
        end

        describe "when group already contains some users" do
          before do
            add_members_to_group([included_members[0]])
            add_members_to_group(spec_members - included_members)
          end

          it "should remove all existing users and only add the new users to the group" do
            group_resource.run_action(tested_action)

            included_members.each do |member|
              expect(user_exist_in_group?(member)).to eq(true)
            end
            (spec_members - included_members).each do |member|
              expect(user_exist_in_group?(member)).to eq(false)
            end
          end
        end
      end

      describe "when append is set" do
        before(:each) do
          group_resource.append(true)
        end

        it "should add included members to the group" do
          group_resource.run_action(tested_action)

          included_members.each do |member|
            expect(user_exist_in_group?(member)).to eq(true)
          end
          excluded_members.each do |member|
            expect(user_exist_in_group?(member)).to eq(false)
          end
        end

        describe "when group already contains some users" do
          before(:each) do
            add_members_to_group([included_members[0], excluded_members[0]])
          end

          it "should add the included users and remove excluded users" do
            group_resource.run_action(tested_action)

            included_members.each do |member|
              expect(user_exist_in_group?(member)).to eq(true)
            end
            excluded_members.each do |member|
              expect(user_exist_in_group?(member)).to eq(false)
            end
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

    after(:each) do
      group_resource.run_action(:remove)
    end

    # TODO: The ones below might actually return ArgumentError now - but I don't have
    # a way to verify that.  Change it and delete this comment if that's the case.
    describe "when updating membership" do
      it "raises an error for a non well-formed domain name" do
        group_resource.members [invalid_domain_user_name]
        expect { group_resource.run_action(tested_action) }.to raise_error Chef::Exceptions::Win32APIError
      end

      it "raises an error for a nonexistent domain" do
        group_resource.members [nonexistent_domain_user_name]
        expect { group_resource.run_action(tested_action) }.to raise_error Chef::Exceptions::Win32APIError
      end
    end

    describe "when removing members" do
      it "does not raise an error for a non well-formed domain name" do
        group_resource.excluded_members [invalid_domain_user_name]
        expect { group_resource.run_action(tested_action) }.to_not raise_error
      end

      it "does not raise an error for a nonexistent domain" do
        group_resource.excluded_members [nonexistent_domain_user_name]
        expect { group_resource.run_action(tested_action) }.to_not raise_error
      end
    end
  end

  let(:number) do
    # Loop until we pick a gid that is not in use.
    loop do

      gid = rand(2000..9999) # avoid low group numbers
      return nil if Etc.getgrgid(gid).nil? # returns nil on windows
    rescue ArgumentError # group does not exist
      return gid

    end
  end

  let(:group_name) { "grp#{number}" } # group name should be 8 characters or less for Solaris, and possibly others
  # https://community.aegirproject.org/developing/architecture/unix-group-limitations/index.html#Group_name_length_limits
  let(:included_members) { [] }
  let(:excluded_members) { [] }
  let(:group_resource) do
    group = Chef::Resource::Group.new(group_name, run_context)
    group.members(included_members)
    group.excluded_members(excluded_members)
    group.gid(number) unless ohai[:platform_family] == "mac_os_x"
    group
  end

  it "append should be false by default" do
    expect(group_resource.append).to eq(false)
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
      let!(:group_name) do
        "theoldmanwalkingdownthestreetalwayshadagood"\
          "smileonhisfacetheoldmanwalkingdownthestreetalwayshadagoodsmileonhisface"\
          "theoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalking"\
          "downthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestree"
      end

      it "should create a group" do
        group_resource.run_action(:create)
        group_should_exist(group_name)
      end
    end

    # not_supported_on_solaris because of the use of excluded_members
    describe "should raise an error when same member is included in the members and excluded_members", :not_supported_on_solaris do
      it "should raise an error" do
        invalid_resource = group_resource.dup
        invalid_resource.members(["Jack"])
        invalid_resource.excluded_members(["Jack"])
        expect { invalid_resource.run_action(:create) }.to raise_error(Chef::Exceptions::ConflictingMembersInGroup)
      end
    end
  end

  # Note:This testcase is written separately from the `group create action` defined above because
  # for group name > 256, Windows 2016 returns "The parameter is incorrect"
  context "group create action: when group name length is more than 256", :windows_only do
    let!(:group_name) do
      "theoldmanwalkingdownthestreetalwayshadagood"\
        "smileonhisfacetheoldmanwalkingdownthestreetalwayshadagoodsmileonhisface"\
        "theoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalking"\
        "downthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestreeQQQQQQ"
    end

    it "should not create a group" do
      expect { group_resource.run_action(:create) }.to raise_error(ArgumentError)
      if windows_gte_10?
        expect { Chef::Util::Windows::NetGroup.new(group_name).local_get_members }.to raise_error(ArgumentError, /The parameter is incorrect./)
      else
        group_should_not_exist(group_name)
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
    let(:spec_members) { %w{mnou5sdz htulrvwq x4c3g1lu} }
    let(:included_members) { [spec_members[0], spec_members[1]] }
    let(:excluded_members) { [spec_members[2]] }
    let(:tested_action) { :modify }

    describe "when there is no group" do
      it "should raise an error" do
        expect { group_resource.run_action(:modify) }.to raise_error(Chef::Exceptions::Group)
      end
    end

    describe "when there is a group" do
      it_behaves_like "correct group management"
    end

    describe "when running on Windows", :windows_only do
      describe "when members are Active Directory domain identities", :windows_domain_joined_only do
        let(:computer_domain) { ohai[:kernel]["cs_info"]["domain"].split(".")[0] }
        let(:spec_members) { ["#{computer_domain}\\Domain Admins", "#{computer_domain}\\Domain Users", "#{computer_domain}\\Domain Computers"] }

        include_examples "correct group management"
      end

      it_behaves_like "an expected invalid domain error case"
    end
  end

  describe "group manage action" do
    let(:spec_members) { %w{mnou5sdz htulrvwq x4c3g1lu} }
    let(:included_members) { [spec_members[0], spec_members[1]] }
    let(:excluded_members) { [spec_members[2]] }
    let(:tested_action) { :manage }

    describe "when there is no group" do
      before(:each) do
        group_resource.run_action(:remove)
        group_should_not_exist(group_name)
      end

      it "raises an error on modify" do
        expect { group_resource.run_action(:modify) }.to raise_error(Chef::Exceptions::Group)
      end

      it "does not raise an error on manage" do
        allow(Etc).to receive(:getpwnam).and_return(double("User"))
        expect { group_resource.run_action(:manage) }.not_to raise_error
      end
    end

    describe "when there is a group" do
      it_behaves_like "correct group management"
    end

    describe "running on windows", :windows_only do
      describe "when members are Windows domain identities", :windows_domain_joined_only do
        let(:computer_domain) { ohai[:kernel]["cs_info"]["domain"].split(".")[0] }
        let(:spec_members) { ["#{computer_domain}\\Domain Admins", "#{computer_domain}\\Domain Users", "#{computer_domain}\\Domain Computers"] }

        include_examples "correct group management"
      end

      it_behaves_like "an expected invalid domain error case"
    end
  end

end
