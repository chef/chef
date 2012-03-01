#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Author:: Mark Mzyk (<mmzyk@opscode.com>)
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

shared_examples_for "a securable resource" do
  SID = Chef::Win32::Security::SID
  ACE = Chef::Win32::Security::ACE

  context "security" do
    describe "unix-specific behavior" do
      before(:each) do
        pending "SKIPPED - platform specific test" if windows?
        require 'etc'
        @expected_user_name = 'nobody'
        @expected_group_name = 'nobody'
        @expected_uid = Etc.getpwnam(@expected_user_name).uid
        @expected_gid = Etc.getgrnam(@expected_group_name).gid
      end

      it "should set an owner" do
        resource.owner @expected_user_name
        resource.run_action(:create)
        File.stat(path).uid.should == @expected_uid
      end

      it "should set a group" do
        resource.group @expected_group_name
        resource.run_action(:create)
        File.stat(path).gid.should == @expected_gid
      end

      it "should set permissions in string form as an octal number" do
        mode_string = '777'
        resource.mode mode_string
        resource.run_action(:create)
        (File.stat(path).mode & 007777).should == (mode_string.oct & 007777)
      end

      it "should set permissions in numeric form as a ruby-interpreted octal" do
        mode_integer = 0777
        resource.mode mode_integer
        resource.run_action(:create)
        (File.stat(path).mode & 007777).should == (mode_integer & 007777)
      end
    end

    describe "windows-specific behavior" do

      #Helper methods to help with readablity
      def allow_type
        Chef::Win32::API::Security::ACCESS_ALLOWED_ACE_TYPE
      end

      def deny_type
        Chef::Win32::API::Security::ACCESS_DENIED_ACE_TYPE
      end

      def read_perms
        Chef::Win32::API::Security::FILE_GENERIC_READ
      end

      def read_execute_perms
        Chef::Win32::API::Security::FILE_GENERIC_READ | Chef::Win32::API::Security::FILE_GENERIC_EXECUTE
      end

      def write_perms
        Chef::Win32::API::Security::FILE_GENERIC_WRITE
      end

      def modify_perms
        Chef::Win32::API::Security::FILE_GENERIC_READ | Chef::Win32::API::Security::FILE_GENERIC_EXECUTE | Chef::Win32::API::Security::DELETE
      end

      def full_control_perms
        Chef::Win32::API::Security::FILE_ALL_ACCESS
      end

      def get_security_descriptor(path)
        Chef::Win32::Security.get_named_security_info(path)
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

      RSpec::Matchers.define :have_expected_properties do |mask, type, flags|
        match do |ace|
          ace.mask == mask
          ace.type == type
          ace.flags == flags
        end
      end

      def descriptor
        get_security_descriptor(resource.path)
      end

      before(:each) do
        pending "SKIPPED - platform specific test" unless windows?
        resource.run_action(:delete)
      end

      it "sets owner to Administrators on create if owner is not specified" do
        File.exist?(resource.path).should == false
        resource.run_action(:create)
        descriptor.owner.should == Chef::Win32::Security::SID.Administrators
      end

      it "sets owner when owner is specified" do
        resource.owner 'Guest'
        resource.run_action(:create)
        descriptor.owner.should == Chef::Win32::Security::SID.Guest
      end

      it "fails to set owner when owner has invalid characters" do
        lambda { resource.owner 'Lance "The Nose" Glindenberry III' }.should raise_error#(Chef::Exceptions::ValidationFailed)
      end

      it "sets owner when owner is specified with a \\" do
        resource.owner "#{ENV['USERDOMAIN']}\\Guest"
        resource.run_action(:create)
        descriptor.owner.should == Chef::Win32::Security::SID.Guest
      end

      it "leaves owner alone if owner is not specified and resource already exists" do
        # Set owner to Guest so it's not the same as the current user (which is the default on create)
        resource.owner.should == nil
        resource.owner 'Guest'
        resource.run_action(:create)
        descriptor.owner.should == SID.Guest

        resource.owner nil
        resource.run_action(:create)
        descriptor.owner.should == SID.Guest
      end

      it "sets group to None on create if group is not specified" do
        resource.group.should == nil
        File.exist?(resource.path).should == false
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

        resource.group nil
        resource.run_action(:create)
        descriptor.group.should == SID.Everyone
      end

      describe "should set permissions using the windows-only rights attribute" do

        it "correctly sets :read rights", :blah => true do
          resource.rights(:read, 'Guest')
          resource.run_action(:create)
          explicit_aces.should == [
            ACE.access_allowed(SID.Guest, read_perms)
          ]
        end

        it "correctly sets :read_execute rights" do
          resource.rights(:read_execute, 'Guest')
          resource.run_action(:create)
          explicit_aces.should == [
            ACE.access_allowed(SID.Guest, read_execute_perms)
          ]
        end

        it "correctly sets :write rights" do
          resource.rights(:write, 'Guest')
          resource.run_action(:create)
          explicit_aces.should == [
            ACE.access_allowed(SID.Guest, write_perms)
          ]
        end

        it "correctly sets :modify rights" do
          resource.rights(:modify, 'Guest')
          resource.run_action(:create)
          explicit_aces.should == [
            ACE.access_allowed(SID.Guest, modify_perms)
          ]
        end

        it "correctly sets :full_control rights" do
          resource.rights(:full_control, 'Guest')
          resource.run_action(:create)
          explicit_aces.should == [
            ACE.access_allowed(SID.Guest, full_control_perms)
          ]
        end

        it "correctly sets deny_rights", :blah => true do
          # deny is an ACE with full rights, but is a deny type ace, not an allow type
          resource.deny_rights(:full_control, 'Guest')
          resource.run_action(:create)
          explicit_aces.should == [
            ACE.access_denied(SID.Guest, full_control_perms)
          ]
        end

        it "Sets multiple rights" do
          resource.rights(:read, 'Everyone')
          resource.rights(:modify, 'Guest')
          resource.run_action(:create)

          explicit_aces.should == [
            ACE.access_allowed(SID.Everyone, read_perms),
            ACE.access_allowed(SID.Guest, modify_perms)
          ]
        end

        it "Sets deny_rights ahead of rights" do
          resource.rights(:read, 'Everyone')
          resource.deny_rights(:modify, 'Guest')
          resource.run_action(:create)

          explicit_aces.should == [
            ACE.access_denied(SID.Guest, modify_perms),
            ACE.access_allowed(SID.Everyone, read_perms)
          ]
        end

        it "Sets deny_rights ahead of rights when specified in reverse order" do
          resource.deny_rights(:modify, 'Guest')
          resource.rights(:read, 'Everyone')
          resource.run_action(:create)

          explicit_aces.should == [
            ACE.access_denied(SID.Guest, modify_perms),
            ACE.access_allowed(SID.Everyone, read_perms)
          ]
        end

      end

      it "should set permissions in string form as an octal number using mode" do
        #on windows, mode cannot modify owner and/or group permissons
        #unless the owner and/or group as appropriate is specified
        resource.mode '400'
        resource.owner 'Guest'
        resource.run_action(:create)

        explicit_aces.should == [
          ACE.access_allowed(SID.Guest, Chef::Win32::API::Security::FILE_GENERIC_READ)
        ]
      end

      it "should set permissions in numeric form as a ruby-interpreted octal using mode" do
        resource.mode 0700
        resource.owner 'Guest'
        resource.run_action(:create)

        explicit_aces.should == [
          ACE.access_allowed(SID.Guest, Chef::Win32::API::Security::FILE_GENERIC_READ | Chef::Win32::API::Security::FILE_GENERIC_WRITE | Chef::Win32::API::Security::FILE_GENERIC_EXECUTE | Chef::Win32::API::Security::DELETE)
        ]
      end

    end
  end
end
