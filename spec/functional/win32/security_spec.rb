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
if Chef::Platform.windows?
  require "chef/win32/security"
end

describe "Chef::Win32::Security", :windows_only do
  it "has_admin_privileges? returns true when running as admin" do
    expect(Chef::ReservedNames::Win32::Security.has_admin_privileges?).to eq(true)
  end

  # We've done some investigation adding a negative test and it turned
  # out to be a lot of work since mixlib-shellout doesn't have user
  # support for windows.
  #
  # TODO - Add negative tests once mixlib-shellout has user support
  it "has_admin_privileges? returns false when running as non-admin" do
    skip "requires user support in mixlib-shellout"
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
end
