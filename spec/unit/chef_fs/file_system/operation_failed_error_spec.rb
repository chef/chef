#
# Author:: John Keiser (<jkeiser@chef.io>)
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
require "chef/chef_fs/file_system/exceptions"

describe Chef::ChefFS::FileSystem::OperationFailedError do
  context "message" do
    let(:error_message) { 'HTTP error writing: 400 "Bad Request"' }

    context "has a cause attribute and HTTP result code is 400" do
      it "include error cause" do
        response_body = '{"error":["Invalid key test in request body"]}'
        response = double(:response, code: "400", body: response_body)
        exception = Net::HTTPClientException.new("(exception) unauthorized", response)
        expect do
          raise Chef::ChefFS::FileSystem::OperationFailedError.new(:write, self, exception), error_message
        end.to raise_error(Chef::ChefFS::FileSystem::OperationFailedError, "#{error_message} cause: #{response_body}")
      end
    end

    context "does not have a cause attribute" do
      it "does not include error cause" do
        expect do
          raise Chef::ChefFS::FileSystem::OperationFailedError.new(:write, self), error_message
        end.to raise_error(Chef::ChefFS::FileSystem::OperationFailedError, error_message)
      end
    end
  end
end
