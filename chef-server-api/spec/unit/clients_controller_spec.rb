#
# Author:: Michael Ivey (<ivey@gweezlebur.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../spec_model_helper')
require 'pp'

describe "Clients Controller" do
  before do
    Merb.logger.set_log(StringIO.new)
  end

  describe "when deleting a client" do
    before do
      @client = make_client("deleted_client")
      @caller = make_client("deleting_client")
    end

    describe "from an admin client" do
      before do
        @caller.admin(true)
      end

      it "should delete the client" do
        Chef::ApiClient.stub!(:cdb_load).and_return(@client)
        @client.should_receive(:cdb_destroy).and_return(true)
        @controller = mock_request("/clients/deleted_client", {}, {'HTTP_ACCEPT' => "application/json", :request_method => "DELETE"}) do |controller|
          stub_authentication(controller, @caller)
        end
        @response_raw = @controller.body
        @response_json = Chef::JSONCompat.from_json(@response_raw)
      end
    end

    describe "from a non-admin client" do
      it "should not delete the client" do
        Chef::ApiClient.stub!(:cdb_load).and_return(@client)
        lambda {
          @controller = mock_request("/clients/deleted_client", {}, {'HTTP_ACCEPT' => "application/json", :request_method => "DELETE"}) do |controller|
            stub_authentication(controller, @caller)
          end
        }.should raise_error(Merb::ControllerExceptions::Forbidden, /You are not the correct node.*not an API admin/)
      end
    end
    
    describe "from the same client as it is trying to delete" do
      it "should delete the client" do
        Chef::ApiClient.stub!(:cdb_load).and_return(@client)
        @client.should_receive(:cdb_destroy).and_return(true)
        @controller = mock_request("/clients/deleted_client", {}, {'HTTP_ACCEPT' => "application/json", :request_method => "DELETE"}) do |controller|
          stub_authentication(controller, @client)
        end
        @response_raw = @controller.body
        @response_json = Chef::JSONCompat.from_json(@response_raw)
      end
    end

  end
end
