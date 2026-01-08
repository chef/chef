#
# Author:: Serdar Sutay (<serdar@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
require "mixlib/shellout"
require "chef/mixin/user_context"
if ChefUtils.windows?
  require "chef/win32/security"
end

describe "Chef::Win32::Security", :windows_only do
  it "has_admin_privileges? returns true when running as admin" do
    expect(Chef::ReservedNames::Win32::Security.has_admin_privileges?).to eq(true)
  end

  describe "running as non admin user" do
    include Chef::Mixin::UserContext
    let(:user) { "security_user" }
    let(:password) { "Security@123" }

    let(:domain) do
      ENV["COMPUTERNAME"]
    end

    before do
      allow_any_instance_of(Chef::Mixin::UserContext).to receive(:node).and_return({ "platform_family" => "windows" })
      add_user = Mixlib::ShellOut.new("net user #{user} #{password} /ADD")
      add_user.run_command
      add_user.error!
    end

    after do
      delete_user = Mixlib::ShellOut.new("net user #{user} /delete")
      delete_user.run_command
      delete_user.error!
    end

    it "has_admin_privileges? returns false" do
      has_admin_privileges = with_user_context(user, password, domain, :local) do
        Chef::ReservedNames::Win32::Security.has_admin_privileges?
      end
      expect(has_admin_privileges).to eq(false)
    end
  end

  describe "get_file_security" do
    it "should return a security descriptor when called with a path that exists" do
      security_descriptor = Chef::ReservedNames::Win32::Security.get_file_security(
        "C:\\Program Files"
      )
      # Make sure the security descriptor works
      expect(security_descriptor.dacl_present?).to be true
    end
  end

  describe "access_check" do
    let(:security_descriptor) do
      Chef::ReservedNames::Win32::Security.get_file_security(
        "C:\\Program Files"
      )
    end

    let(:token_rights) { Chef::ReservedNames::Win32::Security::TOKEN_ALL_ACCESS }

    let(:token) do
      Chef::ReservedNames::Win32::Security.open_process_token(
        Chef::ReservedNames::Win32::Process.get_current_process,
        token_rights
      ).duplicate_token(:SecurityImpersonation)
    end

    let(:mapping) do
      mapping = Chef::ReservedNames::Win32::Security::GENERIC_MAPPING.new
      mapping[:GenericRead] = Chef::ReservedNames::Win32::Security::FILE_GENERIC_READ
      mapping[:GenericWrite] = Chef::ReservedNames::Win32::Security::FILE_GENERIC_WRITE
      mapping[:GenericExecute] = Chef::ReservedNames::Win32::Security::FILE_GENERIC_EXECUTE
      mapping[:GenericAll] = Chef::ReservedNames::Win32::Security::FILE_ALL_ACCESS
      mapping
    end

    let(:desired_access) { Chef::ReservedNames::Win32::Security::FILE_GENERIC_READ }

    it "should check if the provided token has the desired access" do
      expect(Chef::ReservedNames::Win32::Security.access_check(security_descriptor,
        token, desired_access, mapping)).to be true
    end
  end

  describe "Chef::Win32::Security::Token" do
    let(:token) do
      Chef::ReservedNames::Win32::Security.open_process_token(
        Chef::ReservedNames::Win32::Process.get_current_process,
        token_rights
      )
    end
    context "with all rights" do
      let(:token_rights) { Chef::ReservedNames::Win32::Security::TOKEN_ALL_ACCESS }

      it "can duplicate a token" do
        expect { token.duplicate_token(:SecurityImpersonation) }.not_to raise_error
      end
    end

    context "with read only rights" do
      let(:token_rights) { Chef::ReservedNames::Win32::Security::TOKEN_READ }

      it "raises an exception when trying to duplicate" do
        expect { token.duplicate_token(:SecurityImpersonation) }.to raise_error(Chef::Exceptions::Win32APIError)
      end
    end
  end

  describe ".get_token_information_elevation_type" do
    let(:token_rights) { Chef::ReservedNames::Win32::Security::TOKEN_READ }

    let(:token) do
      Chef::ReservedNames::Win32::Security.open_process_token(
        Chef::ReservedNames::Win32::Process.get_current_process,
        token_rights
      )
    end

    context "when the token is valid" do
      let(:token_elevation_type) { %i{TokenElevationTypeDefault TokenElevationTypeFull TokenElevationTypeLimited} }

      it "returns the token elevation type" do
        elevation_type = Chef::ReservedNames::Win32::Security.get_token_information_elevation_type(token)
        expect(token_elevation_type).to include(elevation_type)
      end
    end

    context "when the token is invalid" do
      it "raises `handle invalid` error" do
        # If `OpenProcessToken` is stubbed, `open_process_token` returns an invalid token
        allow(Chef::ReservedNames::Win32::Security).to receive(:OpenProcessToken).and_return(true)
        expect { Chef::ReservedNames::Win32::Security.get_token_information_elevation_type(token) }.to raise_error(Chef::Exceptions::Win32APIError)
      end
    end
  end

  describe ".get_account_right" do
    let(:username) { ENV["USERNAME"] }

    context "when given a valid username" do
      it "returns an array of account right constants" do
        Chef::ReservedNames::Win32::Security.add_account_right(username, "SeBatchLogonRight")
        expect(Chef::ReservedNames::Win32::Security.get_account_right(username)).to include("SeBatchLogonRight")
      end

      it "passes an FFI::Pointer to LsaFreeMemory" do
        Chef::ReservedNames::Win32::Security.add_account_right(username, "SeBatchLogonRight") # otherwise we return an empty array before LsaFreeMemory
        expect(Chef::ReservedNames::Win32::Security).to receive(:LsaFreeMemory).with(instance_of(FFI::Pointer)).and_return(0) # not FFI::MemoryPointer
        Chef::ReservedNames::Win32::Security.get_account_right(username)
      end
    end

    context "when given an invalid username" do
      let(:username) { "noooooooooope" }

      it "raises an exception" do
        expect { Chef::ReservedNames::Win32::Security.get_account_right(username) }.to raise_error(Chef::Exceptions::Win32APIError)
      end
    end
  end

  describe ".remove_account_right" do
    let(:username) { ENV["USERNAME"] }

    context "when given a valid username" do
      it "removes the account right constants" do
        Chef::ReservedNames::Win32::Security.add_account_right(username, "SeBatchLogonRight")
        expect(Chef::ReservedNames::Win32::Security.get_account_right(username)).to include("SeBatchLogonRight")
        Chef::ReservedNames::Win32::Security.remove_account_right(username, "SeBatchLogonRight")
        expect(Chef::ReservedNames::Win32::Security.get_account_right(username)).not_to include("SeBatchLogonRight")
      end
    end

    context "when given an invalid username" do
      let(:username) { "noooooooooope" }

      it "raises an exception" do
        expect { Chef::ReservedNames::Win32::Security.remove_account_right(username, "SeBatchLogonRight") }.to raise_error(Chef::Exceptions::Win32APIError)
      end
    end
  end

  describe ".get_account_with_user_rights" do
    let(:domain) { ENV["COMPUTERNAME"] }
    let(:username) { ENV["USERNAME"] }

    context "when given a valid user right" do
      it "gets all accounts associated with given user right" do
        Chef::ReservedNames::Win32::Security.add_account_right(username, "SeBatchLogonRight")
        expect(Chef::ReservedNames::Win32::Security.get_account_with_user_rights("SeBatchLogonRight").flatten).to include("#{domain}\\#{username}")
        Chef::ReservedNames::Win32::Security.remove_account_right(username, "SeBatchLogonRight")
        expect(Chef::ReservedNames::Win32::Security.get_account_with_user_rights("SeBatchLogonRight").flatten).not_to include("#{domain}\\#{username}")
      end
    end

    context "when given an invalid user right" do
      let(:user_right) { "SeTest" }

      it "returns empty array" do
        expect(Chef::ReservedNames::Win32::Security.get_account_with_user_rights(user_right)).to be_empty
      end
    end
  end

  describe ".test_and_raise_lsa_nt_status" do
    # NTSTATUS code: 0xC0000001 / STATUS_UNSUCCESSFUL
    # Windows Error: ERROR_GEN_FAILURE / 31 / 0x1F / A device attached to the system is not functioning.
    let(:status_unsuccessful) { 0xC0000001 }

    it "raises an exception with the Win Error if the win32 result is not 0" do
      expect { Chef::ReservedNames::Win32::Security.test_and_raise_lsa_nt_status(status_unsuccessful) }.to raise_error(Chef::Exceptions::Win32APIError)
    end
  end
end
