#
# Author:: Tyler Cloke (<tyler@chef.io>)
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
require "chef/http/authenticator"

describe Chef::HTTP::Authenticator do
  let(:class_instance) { Chef::HTTP::Authenticator.new }
  let(:method) { double("method") }
  let(:url) { double("url") }
  let(:headers) { Hash.new }
  let(:data) { double("data") }

  before do
    allow(class_instance).to receive(:authentication_headers).and_return({})
  end

  context "when handle_request is called" do
    shared_examples_for "merging the server API version into the headers" do
      it "merges the default version of X-Ops-Server-API-Version into the headers" do
        # headers returned
        expect(class_instance.handle_request(method, url, headers, data)[2]).
          to include({ "X-Ops-Server-API-Version" => Chef::HTTP::Authenticator::DEFAULT_SERVER_API_VERSION })
      end

      context "when version_class is provided" do
        class V0Class; extend Chef::Mixin::VersionedAPI; minimum_api_version 0; end
        class V2Class; extend Chef::Mixin::VersionedAPI; minimum_api_version 2; end

        class AuthFactoryClass
          extend Chef::Mixin::VersionedAPIFactory
          add_versioned_api_class V0Class
          add_versioned_api_class V2Class
        end

        let(:class_instance) { Chef::HTTP::Authenticator.new({ version_class: AuthFactoryClass }) }

        it "uses it to select the correct http version" do
          Chef::ServerAPIVersions.instance.reset!
          expect(AuthFactoryClass).to receive(:best_request_version).and_call_original
          expect(class_instance.handle_request(method, url, headers, data)[2]).
            to include({ "X-Ops-Server-API-Version" => "2" })
        end
      end

      context "when api_version is set to something other than the default" do
        let(:class_instance) { Chef::HTTP::Authenticator.new({ :api_version => "-10" }) }

        it "merges the requested version of X-Ops-Server-API-Version into the headers" do
          expect(class_instance.handle_request(method, url, headers, data)[2]).
            to include({ "X-Ops-Server-API-Version" => "-10" })
        end
      end
    end

    context "when !sign_requests?" do
      before do
        allow(class_instance).to receive(:sign_requests?).and_return(false)
      end

      it_behaves_like "merging the server API version into the headers"

      it "authentication_headers is not called" do
        expect(class_instance).to_not receive(:authentication_headers)
        class_instance.handle_request(method, url, headers, data)
      end

    end

    context "when sign_requests?" do
      before do
        allow(class_instance).to receive(:sign_requests?).and_return(true)
      end

      it_behaves_like "merging the server API version into the headers"

      it "calls authentication_headers with the proper input" do
        expect(class_instance).to receive(:authentication_headers).with(
          method, url, data,
          { "X-Ops-Server-API-Version" => Chef::HTTP::Authenticator::DEFAULT_SERVER_API_VERSION }).and_return({})
        class_instance.handle_request(method, url, headers, data)
      end
    end
  end
end
