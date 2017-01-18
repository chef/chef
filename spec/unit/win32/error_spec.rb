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
  require "chef/win32/api/error"
end

describe "Chef::Win32::Error", :windows_only do
  describe "self.raise!" do
    context "code is not passed to the raise! method" do
      context "last error received is user_not_found" do
        it "raises UserIDNotFound exception" do
          expect(Chef::ReservedNames::Win32::Error).to receive(:get_last_error).and_return(
            Chef::ReservedNames::Win32::API::Error::ERROR_USER_NOT_FOUND
          )
          expect(Chef::ReservedNames::Win32::Error).to receive_message_chain(:format_message, :strip)
          expect { Chef::ReservedNames::Win32::Error.raise! }.to raise_error Chef::Exceptions::UserIDNotFound
        end
      end

      context "last error received is not user_not_found" do
        it "raises Win32APIError exception" do
          expect(Chef::ReservedNames::Win32::Error).to receive(:get_last_error).and_return(
            Chef::ReservedNames::Win32::API::Error::ERROR_BAD_USERNAME
          )
          expect(Chef::ReservedNames::Win32::Error).to receive_message_chain(:format_message, :strip).and_return("Bad Username")
          expect { Chef::ReservedNames::Win32::Error.raise! }.to raise_error Chef::Exceptions::Win32APIError
        end
      end
    end

    context "code is passed to the raise! method" do
      context "last error received is user_not_found" do
        it "raises UserIDNotFound exception" do
          expect(Chef::ReservedNames::Win32::Error).to_not receive(:get_last_error)
          expect(Chef::ReservedNames::Win32::Error).to receive_message_chain(:format_message, :strip)
          expect { Chef::ReservedNames::Win32::Error.raise! nil, Chef::ReservedNames::Win32::API::Error::ERROR_USER_NOT_FOUND }.to raise_error Chef::Exceptions::UserIDNotFound
        end
      end

      context "last error received is not user_not_found" do
        it "raises Win32APIError exception" do
          expect(Chef::ReservedNames::Win32::Error).to_not receive(:get_last_error)
          expect(Chef::ReservedNames::Win32::Error).to receive_message_chain(:format_message, :strip).and_return("Bad Username")
          expect { Chef::ReservedNames::Win32::Error.raise! nil, Chef::ReservedNames::Win32::API::Error::ERROR_BAD_USERNAME }.to raise_error Chef::Exceptions::Win32APIError
        end
      end
    end
  end
end
