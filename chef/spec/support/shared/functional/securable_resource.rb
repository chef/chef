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

shared_examples_for "a securable resource" do
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
        Chef::Win32::API::Security::FILE_GENERIC_READ | Chef::Win32::API::Security::FILE_GENERIC_EXECUTE
      end

      def write_perms
        Chef::Win32::API::Security::FILE_GENERIC_WRITE | Chef::Win32::API::Security::FILE_GENERIC_READ | Chef::Win32::API::Security::FILE_GENERIC_EXECUTE
      end

      def all_access_perms
        Chef::Win32::API::Security::FILE_ALL_ACCESS
      end

      def get_security_descriptor(path)
        Chef::Win32::Security.get_named_security_info(path)
      end

      def get_ace(user, path)
          descriptor = get_security_descriptor(path)
          acl = descriptor.dacl
          wanted_ace = []

          acl.each do |ace|
            # the acl can have more than one ace - only interested in
            # the one that applies to the test
            # regex maybe too permissive
            if ace.sid.account_name.match /.*#{user}.*/
             wanted_ace << ace
            end
          end

          if wanted_ace.size == 1
            wanted_ace.pop
          else
            wanted_ace
          end
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

      before(:each) do
        pending "SKIPPED - platform specific test" unless windows?
        @expected_user_name = 'Administrator'
        #SID of Administrator is S-1-23-domain-500
        #domain will vary
        @expected_group_name = 'Guests'
      end

      it "should set a default owner of Administrators" do
        #list of window's SIDs http://support.microsoft.com/kb/243330
        #default set by the resource is:
        #Administrators, SID S-1-5-32-544
        #Administrators is the default owner for any object created
        #by a member of the Administrators group
        #if nothing is set
        resource.run_action(:create)
        descriptor = get_security_descriptor(resource.path)
        #owner returns the SID of the owner, not the human readable name
        descriptor.owner.to_s.should == 'S-1-5-32-544'
      end

      it "should set an owner" do
        resource.owner @expected_user_name
        resource.run_action(:create)
        descriptor = get_security_descriptor(resource.path)
        #regex has wildcards, b/c domain will vary
        descriptor.owner.to_s.should match  /^S-1-5-21-.*-500$/
      end

      it "should set a default group of Domain Users" do
        #default set by the resource is:
        #Domain Users, SID 1-5-21-domain-513
        resource.run_action(:create)
        descriptor = get_security_descriptor(resource.path)
        descriptor.group.to_s.should match /^S-1-5-21-.*-513$/
      end

      it "should set a group" do
        resource.group @expected_group_name
        resource.run_action(:create)
        descriptor = get_security_descriptor(resource.path)
        descriptor.group.to_s.should == 'S-1-5-32-546'
      end

      describe "should set permissions using the windows-only rights attribute" do

        it "should set read rights" do
          resource.rights(:read, 'Guest')
          resource.run_action(:create)
          ace = get_ace('Guest', resource.path)
          mask = read_perms
          ace_type = allow_type
          flags = 0
          ace.should have_expected_properties(mask, ace_type, flags)
        end

        it "should set write rights" do
          resource.rights(:write, 'Guest')
          resource.run_action(:create)
          ace = get_ace('Guest', resource.path)
          mask = write_perms
          ace_type = allow_type
          flags = 0
          ace.should have_expected_properties(mask, ace_type, flags)
        end

        it "should set full control rights" do
          resource.rights(:full_control, 'Guest')
          resource.run_action(:create)
          ace = get_ace('Guest', resource.path)
          mask = all_access_perms
          ace_type = allow_type
          flags = 0
          ace.should have_expected_properties(mask, ace_type, flags)
        end

        it "should set deny rights" do
          # deny is an ACE with full rights, but is a deny type ace, not an allow type
          resource.rights(:deny, 'Guest')
          resource.run_action(:create)
          ace = get_ace('Guest', resource.path)
          mask = all_access_perms
          ace_type = deny_type
          flags = 0
          ace.should have_expected_properties(mask, ace_type, flags)
        end

        it "should set writes cumulatively" do
          resource.rights(:read, 'Guest')
          resource.rights(:write, 'Guest')
          resource.run_action(:create)

          write_ace = { :mask => write_perms, :type => allow_type, :flags => 0 }
          read_ace = { :mask => read_perms, :type => allow_type, :flags => 0 }
          expected_aces = [ read_ace, write_ace ]

          aces = get_ace('Guest', resource.path)

          ace_properties = extract_ace_properties(aces)
          ace_properties.size.should == expected_aces.size

          expected_aces.each do |expected_ace|
            ace_properties.should include expected_ace
          end
        end

        it "should have deny rights trump other writes when set cumulatively" do
          #when setting deny and any other writes, all of the ACEs are created
          #but windows knows that deny trumps
          #the only way to test is that we set all teh aces correctly - by
          #making sure they are all there. The rest is dependend on windows
          #behavior
          resource.rights(:read, 'Guest')
          resource.rights(:write, 'Guest')
          resource.rights(:deny, 'Guest')
          resource.run_action(:create)

          write_ace = { :mask => write_perms, :type => allow_type, :flags => 0 }
          read_ace = { :mask => read_perms, :type => allow_type, :flags => 0 }
          deny_ace = { :mask => all_access_perms, :type => deny_type, :flags => 0 }
          expected_aces = [ read_ace, write_ace, deny_ace]

          aces = get_ace('Guest', resource.path)

          ace_properties = extract_ace_properties(aces)
          ace_properties.size.should == expected_aces.size

          expected_aces.each do |expected_ace|
            ace_properties.should include expected_ace
          end
        end

      end

      it "should set permissions in string form as an octal number using mode" do
        #on windows, mode cannot modify owner and/or group permissons
        #unless the owner and/or group as appropriate is specified
        mode_string = '400'
        owner_string = 'Guest'
        resource.mode mode_string
        resource.owner owner_string
        resource.run_action(:create)
        ace = get_ace('Guest', resource.path)
        ace.mask.should == Chef::Win32::API::Security::FILE_GENERIC_READ
        ace.type.should == Chef::Win32::API::Security::ACCESS_ALLOWED_ACE_TYPE
        ace.flags.should == 0
      end

      it "should set permissions in numeric form as a ruby-interpreted octal using mode" do
        mode_integer = 0700
        owner_string = 'Guest'
        resource.mode mode_integer
        resource.owner owner_string
        resource.run_action(:create)
        ace = get_ace('Guest', resource.path)
        ace.mask.should == Chef::Win32::API::Security::FILE_GENERIC_READ | Chef::Win32::API::Security::FILE_GENERIC_WRITE | Chef::Win32::API::Security::FILE_GENERIC_EXECUTE
        ace.type.should == Chef::Win32::API::Security::ACCESS_ALLOWED_ACE_TYPE
        ace.flags.should == 0
      end

    end
  end
end
