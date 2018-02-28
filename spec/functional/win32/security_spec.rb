#
# Author:: Serdar Sutay (<serdar@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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
if Chef::Platform.windows?
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
      whoami = Mixlib::ShellOut.new("whoami")
      whoami.run_command
      whoami.error!
      whoami.stdout.split("\\")[0]
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
        "C:\\Program Files")
      # Make sure the security descriptor works
      expect(security_descriptor.dacl_present?).to be true
    end
  end

  describe "access_check" do
    let(:security_descriptor) do
      Chef::ReservedNames::Win32::Security.get_file_security(
        "C:\\Program Files")
    end

    let(:token_rights) { Chef::ReservedNames::Win32::Security::TOKEN_ALL_ACCESS }

    let(:token) do
      Chef::ReservedNames::Win32::Security.open_process_token(
        Chef::ReservedNames::Win32::Process.get_current_process,
        token_rights).duplicate_token(:SecurityImpersonation)
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
        token_rights)
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
        token_rights)
    end

    context "when the token is valid" do
      let(:token_elevation_type) { [:TokenElevationTypeDefault, :TokenElevationTypeFull, :TokenElevationTypeLimited] }

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
end
