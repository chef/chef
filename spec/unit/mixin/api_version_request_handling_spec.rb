#
# Author:: Tyler Cloke (tyler@chef.io)
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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

describe Chef::Mixin::ApiVersionRequestHandling do
  let(:dummy_class) { Class.new { include Chef::Mixin::ApiVersionRequestHandling } }
  let(:object) { dummy_class.new }

  describe ".server_client_api_version_intersection" do
    let(:default_supported_client_versions) { [0, 1, 2] }

    context "when the response code is not 406" do
      let(:response) { OpenStruct.new(:code => "405") }
      let(:exception) { Net::HTTPServerException.new("405 Something Else", response) }

      it "returns nil" do
        expect(object.server_client_api_version_intersection(exception, default_supported_client_versions)).
          to be_nil
      end

    end # when the response code is not 406

    context "when the response code is 406" do
      let(:response) { OpenStruct.new(:code => "406") }
      let(:exception) { Net::HTTPServerException.new("406 Not Acceptable", response) }

      context "when x-ops-server-api-version header does not exist" do
        it "returns nil" do
          expect(object.server_client_api_version_intersection(exception, default_supported_client_versions)).
            to be_nil
        end
      end # when x-ops-server-api-version header does not exist

      context "when x-ops-server-api-version header exists" do
        let(:min_server_version) { 2 }
        let(:max_server_version) { 4 }
        let(:return_hash) do
          {
            "min_version" => min_server_version,
            "max_version" => max_server_version,
          }
        end

        before(:each) do
          allow(response).to receive(:[]).with("x-ops-server-api-version").and_return(Chef::JSONCompat.to_json(return_hash))
        end

        context "when there is no intersection between client and server versions" do
          shared_examples_for "no intersection between client and server versions" do
            it "return an array" do
              expect(object.server_client_api_version_intersection(exception, supported_client_versions)).
                to be_a_kind_of(Array)
            end

            it "returns an empty array" do
              expect(object.server_client_api_version_intersection(exception, supported_client_versions).length).
                to eq(0)
            end

          end

          context "when all the versions are higher than the max" do
            it_should_behave_like "no intersection between client and server versions" do
              let(:supported_client_versions) { [5, 6, 7] }
            end
          end

          context "when all the versions are lower than the min" do
            it_should_behave_like "no intersection between client and server versions" do
              let(:supported_client_versions) { [0, 1] }
            end
          end

        end # when there is no intersection between client and server versions

        context "when there is an intersection between client and server versions" do
          context "when multiple versions intersect" do
            let(:supported_client_versions) { [1, 2, 3, 4, 5] }

            it "includes all of the intersection" do
              expect(object.server_client_api_version_intersection(exception, supported_client_versions)).
                to eq([2, 3, 4])
            end
          end # when multiple versions intersect

          context "when only the min client version intersects" do
            let(:supported_client_versions) { [0, 1, 2] }

            it "includes the intersection" do
              expect(object.server_client_api_version_intersection(exception, supported_client_versions)).
                to eq([2])
            end
          end # when only the min client version intersects

          context "when only the max client version intersects" do
            let(:supported_client_versions) { [4, 5, 6] }

            it "includes the intersection" do
              expect(object.server_client_api_version_intersection(exception, supported_client_versions)).
                to eq([4])
            end
          end # when only the max client version intersects

        end # when there is an intersection between client and server versions

      end # when x-ops-server-api-version header exists
    end # when the response code is 406

  end # .server_client_api_version_intersection
end # Chef::Mixin::ApiVersionRequestHandling
