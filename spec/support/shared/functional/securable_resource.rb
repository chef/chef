#
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Author:: Mark Mzyk (<mmzyk@chef.io>)
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright 2011-2016, Chef Software Inc.
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

require "etc"
require "functional/resource/base"

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
      File.chown(Etc.getpwnam("guest").uid, 1337, path)
    else
      File.chown(Etc.getpwnam("nobody").uid, 1337, path)
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
    SecurableObject ||= Chef::ReservedNames::Win32::Security::SecurableObject # rubocop:disable Style/ConstantName
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
      :specific => Chef::ReservedNames::Win32::API::Security::FILE_GENERIC_READ | Chef::ReservedNames::Win32::API::Security::FILE_GENERIC_EXECUTE,
    }
  end

  let(:expected_write_perms) do
    {
      :generic => Chef::ReservedNames::Win32::API::Security::GENERIC_WRITE,
      :specific => Chef::ReservedNames::Win32::API::Security::FILE_GENERIC_WRITE,
    }
  end

  let(:expected_modify_perms) do
    {
      :generic => Chef::ReservedNames::Win32::API::Security::GENERIC_READ | Chef::ReservedNames::Win32::API::Security::GENERIC_WRITE | Chef::ReservedNames::Win32::API::Security::GENERIC_EXECUTE | Chef::ReservedNames::Win32::API::Security::DELETE,
      :specific => Chef::ReservedNames::Win32::API::Security::FILE_GENERIC_READ | Chef::ReservedNames::Win32::API::Security::FILE_GENERIC_WRITE | Chef::ReservedNames::Win32::API::Security::FILE_GENERIC_EXECUTE | Chef::ReservedNames::Win32::API::Security::DELETE,
    }
  end

  let(:expected_full_control_perms) do
    {
      :generic => Chef::ReservedNames::Win32::API::Security::GENERIC_ALL,
      :specific => Chef::ReservedNames::Win32::API::Security::FILE_ALL_ACCESS,
    }
  end

  RSpec::Matchers.define :have_expected_properties do |mask, type, flags|
    match do |ace|
      ace.mask == mask &&
        ace.type == type &&
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
      let(:expected_user_name) { "guest" }
    else
      let(:expected_user_name) { "nobody" }
    end
    let(:expected_uid) { Etc.getpwnam(expected_user_name).uid }
    let(:desired_gid) { 1337 }
    let(:expected_gid) { 1337 }

    describe "when setting the owner", :requires_root do
      before do
        resource.owner expected_user_name
        resource.run_action(:create)
      end

      it "should set an owner" do
        expect(File.lstat(path).uid).to eq(expected_uid)
      end

      it "is marked as updated only if changes are made" do
        expect(resource.updated_by_last_action?).to eq(expect_updated?)
      end

    end

    describe "when setting the group", :requires_root do
      before do
        resource.group desired_gid
        resource.run_action(:create)
      end

      it "should set a group" do
        expect(File.lstat(path).gid).to eq(expected_gid)
      end

      it "is marked as updated only if changes are made" do
        expect(resource.updated_by_last_action?).to eq(expect_updated?)
      end

    end

    describe "when setting the permissions from octal given as a String" do
      before do
        @mode_string = "776"
        resource.mode @mode_string
        resource.run_action(:create)
      end

      it "is marked as updated only if changes are made" do
        expect(resource.updated_by_last_action?).to eq(expect_updated?)
      end
    end

    describe "when setting permissions from a literal octal Integer" do
      before do
        @mode_integer = 0776
        resource.mode @mode_integer
        resource.run_action(:create)
      end

      it "is marked as updated only if changes are made" do
        expect(resource.updated_by_last_action?).to eq(expect_updated?)
      end
    end

    describe "when setting the suid bit", :requires_root do
      before do
        @suid_mode = 04776
        resource.mode @suid_mode
        resource.run_action(:create)
      end

      it "should set the suid bit" do
        expect(File.lstat(path).mode & 007777).to eq(@suid_mode & 007777)
      end

      it "should retain the suid bit when updating the user" do
        resource.user 1338
        resource.run_action(:create)
        expect(File.lstat(path).mode & 007777).to eq(@suid_mode & 007777)
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
        expect(descriptor.owner).to eq(SID.Administrator)
      end

      it "is marked as updated only if changes are made" do
        expect(resource.updated_by_last_action?).to eq(expect_updated?)
      end
    end

    describe "when setting group" do
      before do
        resource.group("Administrators")
        resource.run_action(:create)
      end

      it "should set the group" do
        expect(descriptor.group).to eq(SID.Administrators)
      end

      it "is marked as updated only if changes are made" do
        expect(resource.updated_by_last_action?).to eq(expect_updated?)
      end
    end

    describe "when setting rights and deny_rights" do
      before do
        resource.deny_rights(:modify, "Guest")
        resource.rights(:read, "Guest")
        resource.run_action(:create)
      end

      it "should set the rights and deny_rights" do
        expect(explicit_aces).to eq(denied_acl(SID.Guest, expected_modify_perms) + allowed_acl(SID.Guest, expected_read_perms))
      end

      it "is marked as updated only if changes are made" do
        expect(resource.updated_by_last_action?).to eq(expect_updated?)
      end
    end
  end
end

shared_examples_for "a securable resource without existing target" do

  include_context "diff disabled"

  context "on Windows", :windows_only do
    include_context "use Windows permissions"

    it "leaves owner as system default on create if owner is not specified" do
      expect(File.exist?(path)).to eq(false)
      resource.run_action(:create)
      expect(descriptor.owner).to eq(SID.default_security_object_owner)
    end

    it "sets owner when owner is specified" do
      resource.owner "Guest"
      resource.run_action(:create)
      expect(descriptor.owner).to eq(SID.Guest)
    end

    it "fails to set owner when owner has invalid characters" do
      expect { resource.owner 'Lance "The Nose" Glindenberry III' }.to raise_error(Chef::Exceptions::ValidationFailed)
    end

    it "sets owner when owner is specified with a \\" do
      resource.owner "#{ENV['USERDOMAIN']}\\Guest"
      resource.run_action(:create)
      expect(descriptor.owner).to eq(SID.Guest)
    end

    it "leaves owner alone if owner is not specified and resource already exists" do
      arbitrary_non_default_owner = SID.Guest
      expect(arbitrary_non_default_owner).not_to eq(SID.default_security_object_owner)

      resource.owner "Guest" # Change to arbitrary_non_default_owner once issue #1508 is fixed
      resource.run_action(:create)
      expect(descriptor.owner).to eq(arbitrary_non_default_owner)

      new_resource = create_resource
      expect(new_resource.owner).to eq(nil)
      new_resource.run_action(:create)
      expect(descriptor.owner).to eq(arbitrary_non_default_owner)
    end

    it "leaves group as system default on create if group is not specified" do
      expect(resource.group).to eq(nil)
      expect(File.exist?(path)).to eq(false)
      resource.run_action(:create)
      expect(descriptor.group).to eq(SID.default_security_object_group)
    end

    it "sets group when group is specified" do
      resource.group "Everyone"
      resource.run_action(:create)
      expect(descriptor.group).to eq(SID.Everyone)
    end

    it "fails to set group when group has invalid characters" do
      expect { resource.group 'Lance "The Nose" Glindenberry III' }.to raise_error(Chef::Exceptions::ValidationFailed)
    end

    it "leaves group alone if group is not specified and resource already exists" do
      arbitrary_non_default_group = SID.Everyone
      expect(arbitrary_non_default_group).not_to eq(SID.default_security_object_group)

      resource.group "Everyone" # Change to arbitrary_non_default_group once issue #1508 is fixed
      resource.run_action(:create)
      expect(descriptor.group).to eq(arbitrary_non_default_group)

      new_resource = create_resource
      expect(new_resource.group).to eq(nil)
      new_resource.run_action(:create)
      expect(descriptor.group).to eq(arbitrary_non_default_group)
    end

    describe "with rights and deny_rights attributes" do

      it "correctly sets :read rights" do
        resource.rights(:read, "Guest")
        resource.run_action(:create)
        expect(explicit_aces).to eq(allowed_acl(SID.Guest, expected_read_perms))
      end

      it "correctly sets :read_execute rights" do
        resource.rights(:read_execute, "Guest")
        resource.run_action(:create)
        expect(explicit_aces).to eq(allowed_acl(SID.Guest, expected_read_execute_perms))
      end

      it "correctly sets :write rights" do
        resource.rights(:write, "Guest")
        resource.run_action(:create)
        expect(explicit_aces).to eq(allowed_acl(SID.Guest, expected_write_perms))
      end

      it "correctly sets :modify rights" do
        resource.rights(:modify, "Guest")
        resource.run_action(:create)
        expect(explicit_aces).to eq(allowed_acl(SID.Guest, expected_modify_perms))
      end

      it "correctly sets :full_control rights" do
        resource.rights(:full_control, "Guest")
        resource.run_action(:create)
        expect(explicit_aces).to eq(allowed_acl(SID.Guest, expected_full_control_perms))
      end

      it "correctly sets deny_rights" do
        # deny is an ACE with full rights, but is a deny type ace, not an allow type
        resource.deny_rights(:full_control, "Guest")
        resource.run_action(:create)
        expect(explicit_aces).to eq(denied_acl(SID.Guest, expected_full_control_perms))
      end

      it "Sets multiple rights" do
        resource.rights(:read, "Everyone")
        resource.rights(:modify, "Guest")
        resource.run_action(:create)

        expect(explicit_aces).to eq(
          allowed_acl(SID.Everyone, expected_read_perms) +
          allowed_acl(SID.Guest, expected_modify_perms)
        )
      end

      it "Sets deny_rights ahead of rights" do
        resource.rights(:read, "Everyone")
        resource.deny_rights(:modify, "Guest")
        resource.run_action(:create)

        expect(explicit_aces).to eq(
          denied_acl(SID.Guest, expected_modify_perms) +
          allowed_acl(SID.Everyone, expected_read_perms)
        )
      end

      it "Sets deny_rights ahead of rights when specified in reverse order" do
        resource.deny_rights(:modify, "Guest")
        resource.rights(:read, "Everyone")
        resource.run_action(:create)

        expect(explicit_aces).to eq(
          denied_acl(SID.Guest, expected_modify_perms) +
          allowed_acl(SID.Everyone, expected_read_perms)
        )
      end

    end

    context "with a mode attribute" do
      if windows?
        Security ||= Chef::ReservedNames::Win32::API::Security # rubocop:disable Style/ConstantName
      end

      it "respects mode in string form as an octal number" do
        #on windows, mode cannot modify owner and/or group permissons
        #unless the owner and/or group as appropriate is specified
        resource.mode "400"
        resource.owner "Guest"
        resource.group "Everyone"
        resource.run_action(:create)

        expect(explicit_aces).to eq([ ACE.access_allowed(SID.Guest, Security::FILE_GENERIC_READ) ])
      end

      it "respects mode in numeric form as a ruby-interpreted octal" do
        resource.mode 0700
        resource.owner "Guest"
        resource.run_action(:create)

        expect(explicit_aces).to eq([ ACE.access_allowed(SID.Guest, Security::FILE_GENERIC_READ | Security::FILE_GENERIC_WRITE | Security::FILE_GENERIC_EXECUTE | Security::DELETE) ])
      end

      it "respects the owner, group and everyone bits of mode" do
        resource.mode 0754
        resource.owner "Guest"
        resource.group "Administrators"
        resource.run_action(:create)

        expect(explicit_aces).to eq([
          ACE.access_allowed(SID.Guest, Security::FILE_GENERIC_READ | Security::FILE_GENERIC_WRITE | Security::FILE_GENERIC_EXECUTE | Security::DELETE),
          ACE.access_allowed(SID.Administrators, Security::FILE_GENERIC_READ | Security::FILE_GENERIC_EXECUTE),
          ACE.access_allowed(SID.Everyone, Security::FILE_GENERIC_READ),
        ])
      end

      it "respects the individual read, write and execute bits of mode" do
        resource.mode 0421
        resource.owner "Guest"
        resource.group "Administrators"
        resource.run_action(:create)

        expect(explicit_aces).to eq([
          ACE.access_allowed(SID.Guest, Security::FILE_GENERIC_READ),
          ACE.access_allowed(SID.Administrators, Security::FILE_GENERIC_WRITE | Security::DELETE),
          ACE.access_allowed(SID.Everyone, Security::FILE_GENERIC_EXECUTE),
        ])
      end

      it "warns when mode tries to set owner bits but owner is not specified" do
        @warn = []
        allow(Chef::Log).to receive(:warn) { |msg| @warn << msg }

        resource.mode 0400
        resource.run_action(:create)

        expect(@warn.include?("Mode 400 includes bits for the owner, but owner is not specified")).to be_truthy
      end

      it "warns when mode tries to set group bits but group is not specified" do
        @warn = []
        allow(Chef::Log).to receive(:warn) { |msg| @warn << msg }

        resource.mode 0040
        resource.run_action(:create)

        expect(@warn.include?("Mode 040 includes bits for the group, but group is not specified")).to be_truthy
      end
    end

    it "does not inherit aces if inherits is set to false" do
      # We need at least one ACE if we're creating a securable without
      # inheritance
      resource.rights(:full_control, "Administrators")
      resource.inherits(false)
      resource.run_action(:create)

      descriptor.dacl.each do |ace|
        expect(ace.inherited?).to eq(false)
      end
    end

    it "has the inheritable acls of parent directory if no acl is specified" do
      expect(File.exist?(path)).to eq(false)

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

      expect(resource_inherited_acls).to eq(parent_inherited_acls)
    end

  end
end
