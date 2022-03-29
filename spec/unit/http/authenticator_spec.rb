#
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

describe Chef::HTTP::Authenticator, :windows_only do
  let(:class_instance) { Chef::HTTP::Authenticator.new(client_name: "test") }
  let(:method) { "GET" }
  let(:url) { URI("https://chef.example.com/organizations/test") }
  let(:headers) { {} }
  let(:data) { "" }
  let(:node_name) { "test" }
  let(:passwrd) { "some_insecure_password" }

  before do
    Chef::Config[:node_name] = node_name
    cert_name = "chef-#{node_name}"
    d = Time.now
    end_date = Time.new(d.year, d.month + 3, d.day, d.hour, d.min, d.sec).utc.iso8601

    my_client = Chef::Client.new
    pfx = my_client.generate_pfx_package(cert_name, end_date)
    my_client.import_pfx_to_store(pfx)
  end

  after(:each) do
    require "chef/mixin/powershell_exec"
    extend Chef::Mixin::PowershellExec
    cert_name = "chef-#{node_name}"
    delete_certificate(cert_name)
  end

  context "when retrieving a certificate from the certificate store" do
    it "retrieves a certificate password from the registry when the hive does not already exist" do
      delete_registry_hive
      expect { class_instance.get_cert_password }.not_to raise_error
    end

    it "should return a password of at least 14 characters in length" do
      password = class_instance.get_cert_password
      expect(password.length).to eql(14)
    end

    it "correctly retrieves a valid certificate in pem format from the certstore" do
      require "openssl"
      certificate = class_instance.retrieve_certificate_key(node_name)
      cert_object = OpenSSL::PKey::RSA.new(certificate)
      expect(cert_object.to_s).to match(/BEGIN RSA PRIVATE KEY/)
    end
  end

  def delete_certificate(cert_name)
    powershell_code = <<~CODE
      Get-ChildItem -path cert:\\LocalMachine\\My -Recurse -Force  | Where-Object { $_.Subject -Match "#{cert_name}" } | Remove-item
    CODE
    powershell_exec!(powershell_code)
  end

  def delete_registry_hive
    @win32registry = Chef::Win32::Registry.new
    path = "HKEY_LOCAL_MACHINE\\Software\\Progress\\Authentication"
    present = @win32registry.get_values(path)
    unless present.nil? || present.empty?
      @win32registry.delete_key(path, true)
    end
  end
end

describe Chef::HTTP::Authenticator do
  let(:class_instance) { Chef::HTTP::Authenticator.new(client_name: "test") }
  let(:method) { "GET" }
  let(:url) { URI("https://chef.example.com/organizations/test") }
  let(:headers) { {} }
  let(:data) { "" }

  before do
    ::Chef::Config[:node_name] = "foo"
  end

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
          { "X-Ops-Server-API-Version" => Chef::HTTP::Authenticator::DEFAULT_SERVER_API_VERSION }
        ).and_return({})
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
