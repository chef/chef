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
  let(:class_instance) { Chef::HTTP::Authenticator.new(client_name: "test") }
  let(:method) { "GET" }
  let(:url) { URI("https://chef.example.com/organizations/test") }
  let(:headers) { Hash.new }
  let(:data) { "" }

  context "when handle_request is called" do
    shared_examples_for "merging the server API version into the headers" do
      before do
        allow(class_instance).to receive(:authentication_headers).and_return({})
      end

      it "merges the default version of X-Ops-Server-API-Version into the headers" do
        # headers returned
        expect(class_instance.handle_request(method, url, headers, data)[2])
          .to include({ "X-Ops-Server-API-Version" => Chef::HTTP::Authenticator::DEFAULT_SERVER_API_VERSION })
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
          expect(class_instance.handle_request(method, url, headers, data)[2])
            .to include({ "X-Ops-Server-API-Version" => "2" })
        end
      end

      context "when api_version is set to something other than the default" do
        let(:class_instance) { Chef::HTTP::Authenticator.new({ api_version: "-10" }) }

        it "merges the requested version of X-Ops-Server-API-Version into the headers" do
          expect(class_instance.handle_request(method, url, headers, data)[2])
            .to include({ "X-Ops-Server-API-Version" => "-10" })
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

    context "when ssh_agent_signing" do
      let(:public_key) { <<~EOH }
        -----BEGIN PUBLIC KEY-----
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA49TA0y81ps0zxkOpmf5V
        4/c4IeR5yVyQFpX3JpxO4TquwnRh8VSUhrw8kkTLmB3cS39Db+3HadvhoqCEbqPE
        6915kXSuk/cWIcNozujLK7tkuPEyYVsyTioQAddSdfe+8EhQVf3oHxaKmUd6waXr
        WqYCnhxgOjxocenREYNhZ/OETIeiPbOku47vB4nJK/0GhKBytL2XnsRgfKgDxf42
        BqAi1jglIdeq8lAWZNF9TbNBU21AO1iuT7Pm6LyQujhggPznR5FJhXKRUARXBJZa
        wxpGV4dGtdcahwXNE4601aXPra+xPcRd2puCNoEDBzgVuTSsLYeKBDMSfs173W1Q
        YwIDAQAB
        -----END PUBLIC KEY-----
      EOH

      let(:class_instance) { Chef::HTTP::Authenticator.new(client_name: "test", raw_key: public_key, ssh_agent_signing: true) }

      it "sets use_ssh_agent if needed" do
        expect(Mixlib::Authentication::SignedHeaderAuth).to receive(:signing_object).and_wrap_original { |m, *args|
          m.call(*args).tap do |signing_obj|
            expect(signing_obj).to receive(:sign).with(instance_of(OpenSSL::PKey::RSA), use_ssh_agent: true).and_return({})
          end
        }
        class_instance.handle_request(method, url, headers, data)
      end
    end
  end
end
