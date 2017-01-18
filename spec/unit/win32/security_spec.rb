#
# Author:: Aliasgar Batterywala (aliasgar.batterywala@msystechnologies.com)
# Copyright:: Copyright 2017, Chef Software Inc.
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
        expect { Chef::ReservedNames::Win32::Security.set_named_security_info "/temp_path", :SE_FILE_OBJECT, {} }.to raise_error Chef::Exceptions::Chef::Exceptions::UserIDNotFound
      end
    end
  end
end
