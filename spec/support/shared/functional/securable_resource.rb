#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Author:: Mark Mzyk (<mmzyk@opscode.com>)
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

# TODO test that these work when you are logged on as a user joined to a domain (rather than local computer)
# TODO test that you can set users from other domains

require 'etc'

shared_context "setup correct permissions" do

  # I could not get this to work with :requires_unprivileged_user for whatever
  # reason. The setup when running as root is the same as non-root, except we
  # also do a chown, so this sets up correct context for either case.
  before :each, :unix_only do
    File.chmod(0776, path)
    now = Time.now.to_i
    File.utime(now - 9000, now - 9000, path)
  end

  # Root only context.
  before :each, :unix_only, :requires_root do
    File.chown(Etc.getpwnam('nobody').uid, 1337, path)
  end

  # FIXME: windows
end

shared_context "setup broken permissions" do

  before :each, :unix_only do
    File.chmod(0644, path)
  end

  before :each, :unix_only, :requires_root do
    File.chown(0, 0, path)
  end

  # FIXME: windows
end

shared_examples_for "a securable resource" do
  context "on Unix", :unix_only do
    let(:expected_user_name) { 'nobody' }
    let(:expected_uid) { Etc.getpwnam(expected_user_name).uid }
    let(:desired_gid) { 1337 }
    let(:expected_gid) { 1337 }

    pending "should set an owner (Rerun specs under root)", :requires_unprivileged_user => true
    pending "should set a group (Rerun specs under root)",  :requires_unprivileged_user => true

    describe "when setting the owner", :requires_root do
      before do
        resource.owner expected_user_name
        resource.run_action(:create)
      end

      it "should set an owner" do
        File.lstat(path).uid.should == expected_uid
      end

      it "is marked as updated only if changes are made" do
        resource.updated_by_last_action?.should == expect_updated?
      end

    end

    describe "when setting the group", :requires_root do
      before do
        resource.group desired_gid
        resource.run_action(:create)
      end

      it "should set a group" do
        File.lstat(path).gid.should == expected_gid
      end

      it "is marked as updated only if changes are made" do
        resource.updated_by_last_action?.should == expect_updated?
      end

    end

    describe "when setting the permissions from octal given as a String" do
      before do
        @mode_string = '776'
        resource.mode @mode_string
        resource.run_action(:create)
      end

      it "should set permissions as specified" do
        pending('Linux does not support lchmod', :if => resource.instance_of?(Chef::Resource::Link) && !os_x? && !freebsd?) do
          (File.lstat(path).mode & 007777).should == (@mode_string.oct & 007777)
        end
      end

      it "is marked as updated only if changes are made" do
        resource.updated_by_last_action?.should == expect_updated?
      end
    end

    describe "when setting permissions from a literal octal Integer" do
      before do
        @mode_integer = 0776
        resource.mode @mode_integer
        resource.run_action(:create)
      end

      it "should set permissions in numeric form as a ruby-interpreted octal" do
        pending('Linux does not support lchmod', :if => resource.instance_of?(Chef::Resource::Link) && !os_x? && !freebsd?) do
          (File.lstat(path).mode & 007777).should == (@mode_integer & 007777)
        end
      end

      it "is marked as updated only if changes are made" do
        resource.updated_by_last_action?.should == expect_updated?
      end
    end
  end

  context "on Windows", :windows_only do

    if windows?
      SID = Chef::ReservedNames::Win32::Security::SID
      ACE = Chef::ReservedNames::Win32::Security::ACE
    end

    def get_security_descriptor(path)
      Chef::ReservedNames::Win32::Security.get_named_security_info(path)
    end

    def explicit_aces
      descriptor.dacl.select { |ace| ace.explicit? }
    end

    def extract_ace_properties(aces)
      hashes = []
        aces.each do |ace|
          hashes << { :mask => ace.mask, :type => ace.type, :flags => ace.flags }
        end
      hashes
    end

    # Standard expected rights
    let(:expected_read_perms) do
      {
        :generic => Chef::ReservedNames::Win32::API::Security::GENERIC_READ,
        :specific => Chef::ReservedNames::Win32::API::Security::FILE_GENERIC_READ,
      }
    end

    let(:expected_read_execute_perms) do
      {
        :generic => Chef::ReservedNames::Win32::API::Security::GENERIC_READ | Chef::ReservedNames::Win32::API::Security::GENERIC_EXECUTE,
        :specific => Chef::ReservedNames::Win32::API::Security::FILE_GENERIC_READ | Chef::ReservedNames::Win32::API::Security::FILE_GENERIC_EXECUTE
      }
    end

    let(:expected_write_perms) do
      {
        :generic => Chef::ReservedNames::Win32::API::Security::GENERIC_WRITE,
        :specific => Chef::ReservedNames::Win32::API::Security::FILE_GENERIC_WRITE
      }
    end

    let(:expected_modify_perms) do
      {
        :generic => Chef::ReservedNames::Win32::API::Security::GENERIC_READ | Chef::ReservedNames::Win32::API::Security::GENERIC_WRITE | Chef::ReservedNames::Win32::API::Security::GENERIC_EXECUTE | Chef::ReservedNames::Win32::API::Security::DELETE,
        :specific => Chef::ReservedNames::Win32::API::Security::FILE_GENERIC_READ | Chef::ReservedNames::Win32::API::Security::FILE_GENERIC_WRITE | Chef::ReservedNames::Win32::API::Security::FILE_GENERIC_EXECUTE | Chef::ReservedNames::Win32::API::Security::DELETE
      }
    end

    let(:expected_full_control_perms) do
      {
        :generic => Chef::ReservedNames::Win32::API::Security::GENERIC_ALL,
        :specific => Chef::ReservedNames::Win32::API::Security::FILE_ALL_ACCESS
      }
    end

    RSpec::Matchers.define :have_expected_properties do |mask, type, flags|
      match do |ace|
        ace.mask == mask
        ace.type == type
        ace.flags == flags
      end
    end

    def descriptor
      get_security_descriptor(path)
    end

    before(:each) do
      resource.run_action(:delete)
    end

    it "sets owner to Administrators on create if owner is not specified" do
      File.exist?(path).should == false
      resource.run_action(:create)
      descriptor.owner.should == SID.Administrators
    end

    it "sets owner when owner is specified" do
      resource.owner 'Guest'
      resource.run_action(:create)
      descriptor.owner.should == SID.Guest
    end

    it "fails to set owner when owner has invalid characters" do
      lambda { resource.owner 'Lance "The Nose" Glindenberry III' }.should raise_error#(Chef::Exceptions::ValidationFailed)
    end

    it "sets owner when owner is specified with a \\" do
      resource.owner "#{ENV['USERDOMAIN']}\\Guest"
      resource.run_action(:create)
      descriptor.owner.should == SID.Guest
    end

    it "leaves owner alone if owner is not specified and resource already exists" do
      # Set owner to Guest so it's not the same as the current user (which is the default on create)
      resource.owner 'Guest'
      resource.run_action(:create)
      descriptor.owner.should == SID.Guest

      new_resource = create_resource
      new_resource.owner.should == nil
      new_resource.run_action(:create)
      descriptor.owner.should == SID.Guest
    end

    it "sets group to None on create if group is not specified" do
      resource.group.should == nil
      File.exist?(path).should == false
      resource.run_action(:create)
      descriptor.group.should == SID.None
    end

    it "sets group when group is specified" do
      resource.group 'Everyone'
      resource.run_action(:create)
      descriptor.group.should == SID.Everyone
    end

    it "fails to set group when group has invalid characters" do
      lambda { resource.group 'Lance "The Nose" Glindenberry III' }.should raise_error(Chef::Exceptions::ValidationFailed)
    end

    it "sets group when group is specified with a \\" do
      pending "Need to find a group containing a backslash that is on most peoples' machines" do
        resource.group "#{ENV['COMPUTERNAME']}\\Administrators"
        resource.run_action(:create)
        descriptor.group.should == SID.Everyone
      end
    end

    it "leaves group alone if group is not specified and resource already exists" do
      # Set group to Everyone so it's not the default (None)
      resource.group 'Everyone'
      resource.run_action(:create)
      descriptor.group.should == SID.Everyone

      new_resource = create_resource
      new_resource.group.should == nil
      new_resource.run_action(:create)
      descriptor.group.should == SID.Everyone
    end

    describe "with rights and deny_rights attributes" do

      it "correctly sets :read rights" do
        resource.rights(:read, 'Guest')
        resource.run_action(:create)
        explicit_aces.should == allowed_acl(SID.Guest, expected_read_perms)
      end

      it "correctly sets :read_execute rights" do
        resource.rights(:read_execute, 'Guest')
        resource.run_action(:create)
        explicit_aces.should == allowed_acl(SID.Guest, expected_read_execute_perms)
      end

      it "correctly sets :write rights" do
        resource.rights(:write, 'Guest')
        resource.run_action(:create)
        explicit_aces.should == allowed_acl(SID.Guest, expected_write_perms)
      end

      it "correctly sets :modify rights" do
        resource.rights(:modify, 'Guest')
        resource.run_action(:create)
        explicit_aces.should == allowed_acl(SID.Guest, expected_modify_perms)
      end

      it "correctly sets :full_control rights" do
        resource.rights(:full_control, 'Guest')
        resource.run_action(:create)
        explicit_aces.should == allowed_acl(SID.Guest, expected_full_control_perms)
      end

      it "correctly sets deny_rights" do
        # deny is an ACE with full rights, but is a deny type ace, not an allow type
        resource.deny_rights(:full_control, 'Guest')
        resource.run_action(:create)
        explicit_aces.should == denied_acl(SID.Guest, expected_full_control_perms)
      end

      it "Sets multiple rights" do
        resource.rights(:read, 'Everyone')
        resource.rights(:modify, 'Guest')
        resource.run_action(:create)

        explicit_aces.should ==
          allowed_acl(SID.Everyone, expected_read_perms) +
          allowed_acl(SID.Guest, expected_modify_perms)
      end

      it "Sets deny_rights ahead of rights" do
        resource.rights(:read, 'Everyone')
        resource.deny_rights(:modify, 'Guest')
        resource.run_action(:create)

        explicit_aces.should ==
          denied_acl(SID.Guest, expected_modify_perms) +
          allowed_acl(SID.Everyone, expected_read_perms)
      end

      it "Sets deny_rights ahead of rights when specified in reverse order" do
        resource.deny_rights(:modify, 'Guest')
        resource.rights(:read, 'Everyone')
        resource.run_action(:create)

        explicit_aces.should ==
          denied_acl(SID.Guest, expected_modify_perms) +
          allowed_acl(SID.Everyone, expected_read_perms)
      end

    end

    context "with a mode attribute" do
      if windows?
        Security = Chef::ReservedNames::Win32::API::Security
      end

      it "respects mode in string form as an octal number" do
        #on windows, mode cannot modify owner and/or group permissons
        #unless the owner and/or group as appropriate is specified
        resource.mode '400'
        resource.owner 'Guest'
        resource.group 'Everyone'
        resource.run_action(:create)

        explicit_aces.should == [ ACE.access_allowed(SID.Guest, Security::FILE_GENERIC_READ) ]
      end

      it "respects mode in numeric form as a ruby-interpreted octal" do
        resource.mode 0700
        resource.owner 'Guest'
        resource.run_action(:create)

        explicit_aces.should == [ ACE.access_allowed(SID.Guest, Security::FILE_GENERIC_READ | Security::FILE_GENERIC_WRITE | Security::FILE_GENERIC_EXECUTE | Security::DELETE) ]
      end

      it "respects the owner, group and everyone bits of mode" do
        resource.mode 0754
        resource.owner 'Guest'
        resource.group 'Administrators'
        resource.run_action(:create)

        explicit_aces.should == [
          ACE.access_allowed(SID.Guest, Security::FILE_GENERIC_READ | Security::FILE_GENERIC_WRITE | Security::FILE_GENERIC_EXECUTE | Security::DELETE),
          ACE.access_allowed(SID.Administrators, Security::FILE_GENERIC_READ | Security::FILE_GENERIC_EXECUTE),
          ACE.access_allowed(SID.Everyone, Security::FILE_GENERIC_READ)
        ]
      end

      it "respects the individual read, write and execute bits of mode" do
        resource.mode 0421
        resource.owner 'Guest'
        resource.group 'Administrators'
        resource.run_action(:create)

        explicit_aces.should == [
          ACE.access_allowed(SID.Guest, Security::FILE_GENERIC_READ),
          ACE.access_allowed(SID.Administrators, Security::FILE_GENERIC_WRITE | Security::DELETE),
          ACE.access_allowed(SID.Everyone, Security::FILE_GENERIC_EXECUTE)
        ]
      end

      it 'warns when mode tries to set owner bits but owner is not specified' do
        @warn = []
        Chef::Log.stub!(:warn) { |msg| @warn << msg }

        resource.mode 0400
        resource.run_action(:create)

        @warn.include?("Mode 400 includes bits for the owner, but owner is not specified").should be_true
      end

      it 'warns when mode tries to set group bits but group is not specified' do
        @warn = []
        Chef::Log.stub!(:warn) { |msg| @warn << msg }

        resource.mode 0040
        resource.run_action(:create)

        @warn.include?("Mode 040 includes bits for the group, but group is not specified").should be_true
      end
    end

  end
end
