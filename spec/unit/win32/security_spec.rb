#
# Author:: Aliasgar Batterywala (aliasgar.batterywala@msystechnologies.com)
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
if ChefUtils.windows?
  require "chef/win32/error"
  require "chef/win32/security"
  require "chef/win32/api/error"
end

describe "Chef::Win32::Security", :windows_only do
  describe "self.get_named_security_info" do
    context "when HR result is ERROR_SUCCESS" do
      it "does not raise the exception" do
        expect(Chef::ReservedNames::Win32::Security).to receive(:GetNamedSecurityInfoW).and_return(
          Chef::ReservedNames::Win32::API::Error::ERROR_SUCCESS
        )
        expect { Chef::ReservedNames::Win32::Security.get_named_security_info "/temp_path" }.to_not raise_error
      end
    end

    context "when HR result is not ERROR_SUCCESS and not ERROR_USER_NOT_FOUND" do
      it "raises Win32APIError exception" do
        expect(Chef::ReservedNames::Win32::Security).to receive(:GetNamedSecurityInfoW).and_return(
          Chef::ReservedNames::Win32::API::Error::ERROR_INVALID_ACCESS
        )
        expect { Chef::ReservedNames::Win32::Security.get_named_security_info "/temp_path" }.to raise_error Chef::Exceptions::Win32APIError
      end
    end
  end

  describe "self.set_named_security_info" do
    context "when HR result is ERROR_SUCCESS" do
      it "does not raise the exception" do
        expect(Chef::ReservedNames::Win32::Security).to receive(:SetNamedSecurityInfoW).and_return(
          Chef::ReservedNames::Win32::API::Error::ERROR_SUCCESS
        )
        expect { Chef::ReservedNames::Win32::Security.set_named_security_info "/temp_path", :SE_FILE_OBJECT, {} }.to_not raise_error
      end
    end

    context "when HR result is not ERROR_SUCCESS but it is ERROR_USER_NOT_FOUND" do
      it "raises UserIDNotFound exception" do
        expect(Chef::ReservedNames::Win32::Security).to receive(:SetNamedSecurityInfoW).and_return(
          Chef::ReservedNames::Win32::API::Error::ERROR_USER_NOT_FOUND
        )
        expect { Chef::ReservedNames::Win32::Security.set_named_security_info "/temp_path", :SE_FILE_OBJECT, {} }.to raise_error Chef::Exceptions::UserIDNotFound
      end
    end
  end

  describe "self.has_admin_privileges?" do
    context "when the user doesn't have admin privileges" do
      it "returns false" do
        allow(Chef::ReservedNames::Win32::Security).to receive(:open_current_process_token).and_raise("Access is denied.")
        expect(Chef::ReservedNames::Win32::Security.has_admin_privileges?).to be false
      end
    end

    context "when open_current_process_token fails with some other error than `Access is Denied`" do
      it "raises error" do
        allow(Chef::ReservedNames::Win32::Security).to receive(:open_current_process_token).and_raise("boom")
        expect { Chef::ReservedNames::Win32::Security.has_admin_privileges? }.to raise_error(Chef::Exceptions::Win32APIError)
      end
    end

    context "when the user has admin privileges" do
      it "returns true" do
        token = double(:process_token)
        allow(token).to receive_message_chain(:handle, :handle)

        allow(Chef::ReservedNames::Win32::Security).to receive(:open_current_process_token).and_return(token)
        allow(Chef::ReservedNames::Win32::Security).to receive(:get_token_information_elevation_type)
        allow(Chef::ReservedNames::Win32::Security).to receive(:GetTokenInformation).and_return(true)
        allow_any_instance_of(FFI::Buffer).to receive(:read_ulong).and_return(1)
        expect(Chef::ReservedNames::Win32::Security.has_admin_privileges?).to be true
      end
    end
  end

  describe "self.get_token_information_elevation_type" do
    let(:token_rights) { Chef::ReservedNames::Win32::Security::TOKEN_READ }

    let(:token) do
      Chef::ReservedNames::Win32::Security.open_process_token(
        Chef::ReservedNames::Win32::Process.get_current_process,
        token_rights
      )
    end

    it "raises error if GetTokenInformation fails" do
      allow(Chef::ReservedNames::Win32::Security).to receive(:GetTokenInformation).and_return(false)
      expect { Chef::ReservedNames::Win32::Security.get_token_information_elevation_type(token) }.to raise_error(Chef::Exceptions::Win32APIError)
    end
  end

  describe "self.lookup_account_name" do
    let(:security_class) { Chef::ReservedNames::Win32::Security }

    context "when FFI::LastError.error result is ERROR_INSUFFICIENT_BUFFER" do
      it "does not raise the exception" do
        expect(FFI::LastError).to receive(:error).and_return(122)
        expect { security_class.lookup_account_name "system" }.to_not raise_error
      end
    end

    context "when operation completed successfully and FFI::LastError.error result is NO_ERROR" do
      it "does not raise the exception" do
        expect(FFI::LastError).to receive(:error).and_return(0)
        expect { security_class.lookup_account_name "system" }.to_not raise_error
      end
    end

    context "when FFI::LastError.error result is not ERROR_INSUFFICIENT_BUFFER and not NO_ERROR" do
      it "raises Chef::ReservedNames::Win32::Error.raise! exception" do
        expect(FFI::LastError).to receive(:error).and_return(123).at_least(:once)
        expect { security_class.lookup_account_name "system" }.to raise_error(Chef::Exceptions::Win32APIError)
      end
    end
  end
end
