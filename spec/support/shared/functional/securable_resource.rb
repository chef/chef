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

require 'etc'
require 'functional/resource/base'

shared_context "setup correct permissions" do
  if windows?
    include_context "use Windows permissions"
  end

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
    if ohai[:platform] == "aix"
      File.chown(Etc.getpwnam('guest').uid, 1337, path)
    else
      File.chown(Etc.getpwnam('nobody').uid, 1337, path)
    end
  end

  before :each, :windows_only do
    so = SecurableObject.new(path)
    so.owner = SID.Administrator
    so.group = SID.Administrators
    dacl = ACL.create(denied_acl(SID.Guest, expected_modify_perms) +
                      allowed_acl(SID.Guest, expected_read_perms))
    so.dacl = dacl
  end
end

shared_context "setup broken permissions" do
  if windows?
    include_context "use Windows permissions"
  end

  before :each, :unix_only do
    File.chmod(0644, path)
  end

  before :each, :unix_only, :requires_root do
    File.chown(0, 0, path)
  end

  before :each, :windows_only do
    so = SecurableObject.new(path)
    so.owner = SID.Guest
    so.group = SID.Everyone
    dacl = ACL.create(allowed_acl(SID.Guest, expected_modify_perms))
    so.set_dacl(dacl, true)
  end
end

shared_context "use Windows permissions", :windows_only do
  if windows?
    SID ||= Chef::ReservedNames::Win32::Security::SID
    ACE ||= Chef::ReservedNames::Win32::Security::ACE
    ACL ||= Chef::ReservedNames::Win32::Security::ACL
    SecurableObject ||= Chef::ReservedNames::Win32::Security::SecurableObject
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
end

shared_examples_for "a securable resource with existing target" do

  include_context "diff disabled"

  context "on Unix", :unix_only do
    if ohai[:platform] == "aix"
      let(:expected_user_name) { 'guest' }
    else
      let(:expected_user_name) { 'nobody' }
    end
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
    include_context "use Windows permissions"

    describe "when setting owner" do
      before do
        resource.owner(SID.admin_account_name)
        resource.run_action(:create)
      end

      it "should set the owner" do
        descriptor.owner.should == SID.Administrator
      end

      it "is marked as updated only if changes are made" do
        resource.updated_by_last_action?.should == expect_updated?
      end
    end

    describe "when setting group" do
      before do
        resource.group('Administrators')
        resource.run_action(:create)
      end

      it "should set the group" do
        descriptor.group.should == SID.Administrators
      end

      it "is marked as updated only if changes are made" do
        resource.updated_by_last_action?.should == expect_updated?
      end
    end

    describe "when setting rights and deny_rights" do
      before do
        resource.deny_rights(:modify, 'Guest')
        resource.rights(:read, 'Guest')
        resource.run_action(:create)
      end

      it "should set the rights and deny_rights" do
        explicit_aces.should == denied_acl(SID.Guest, expected_modify_perms) + allowed_acl(SID.Guest, expected_read_perms)
      end

      it "is marked as updated only if changes are made" do
        resource.updated_by_last_action?.should == expect_updated?
      end
    end
  end
end

shared_examples_for "a securable resource without existing target" do

  include_context "diff disabled"

  context "on Unix", :unix_only do
    pending "if we need any securable resource tests on Unix without existing target resource."
  end

  context "on Windows", :windows_only do
    include_context "use Windows permissions"

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
        Security ||= Chef::ReservedNames::Win32::API::Security
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
        Chef::Log.stub(:warn) { |msg| @warn << msg }

        resource.mode 0400
        resource.run_action(:create)

        @warn.include?("Mode 400 includes bits for the owner, but owner is not specified").should be_true
      end

      it 'warns when mode tries to set group bits but group is not specified' do
        @warn = []
        Chef::Log.stub(:warn) { |msg| @warn << msg }

        resource.mode 0040
        resource.run_action(:create)

        @warn.include?("Mode 040 includes bits for the group, but group is not specified").should be_true
      end
    end

    it "does not inherit aces if inherits is set to false" do
      # We need at least one ACE if we're creating a securable without
      # inheritance
      resource.rights(:full_control, 'Administrators')
      resource.inherits(false)
      resource.run_action(:create)

      descriptor.dacl.each do | ace |
        ace.inherited?.should == false
      end
    end

    it "has the inheritable acls of parent directory if no acl is specified" do
      File.exist?(path).should == false

      # Collect the inheritable acls form the parent by creating a file without
      # any specific ACLs
      parent_acls = parent_inheritable_acls

      # On certain flavors of Windows the default list of ACLs sometimes includes
      # non-inherited ACLs. Filter them out here.
      parent_inherited_acls = parent_acls.dacl.collect do |ace|
        ace.inherited?
      end

      resource.run_action(:create)

      # Similarly filter out the non-inherited ACLs
      resource_inherited_acls = descriptor.dacl.collect do |ace|
        ace.inherited?
      end

      resource_inherited_acls.should == parent_inherited_acls
    end

  end
end
