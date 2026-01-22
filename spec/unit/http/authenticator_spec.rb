#
# Author:: Tyler Cloke (<tyler@chef.io>)
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
require "chef/http/authenticator"
require "chef/mixin/powershell_exec"

require_relative "../../../lib/chef/win32/registry"

describe Chef::HTTP::Authenticator, :windows_only do
  let(:class_instance) { Chef::HTTP::Authenticator.new(client_name: "test") }
  let(:method) { "GET" }
  let(:url) { URI("https://chef.example.com/organizations/test") }
  let(:headers) { {} }
  let(:data) { "" }
  let(:node_name) { "test" }
  let(:passwrd) { "some_insecure_password" }

  before(:each) do
    Chef::Config[:node_name] = node_name
    cert_name = "chef-#{node_name}"
    d = Time.now
    end_date = Time.new + (3600 * 24 * 90)
    end_date = end_date.utc.iso8601

    my_client = Chef::Client.new
    class_instance.get_cert_password
    pfx = my_client.generate_pfx_package(cert_name, end_date)
    my_client.import_pfx_to_store(pfx)
  end

  after(:each) do
    require "chef/mixin/powershell_exec"
    extend Chef::Mixin::PowershellExec
    cert_name = "chef-#{node_name}"
    delete_certificate(cert_name)
  end

  context "when retrieving a certificate from the certificate store it" do
    it "properly creates the password hive in the registry when it doesn't exist" do
      delete_registry_hive
      class_instance.get_cert_password
      win32registry = Chef::Win32::Registry.new
      expected_path = "HKEY_LOCAL_MACHINE\\Software\\Progress\\Authentication"
      path_created = win32registry.key_exists?(expected_path)
      expect(path_created).to be(true)
    end

    it "retrieves a certificate password from the registry when the hive does not already exist" do
      delete_registry_hive
      password = class_instance.get_cert_password
      expect { class_instance.get_cert_password }.not_to raise_error
      expect(password).not_to be(nil)
    end

    it "should return a password of at least 14 characters in length" do
      password = class_instance.get_cert_password
      expect(password.length).to eql(14)
    end

    it "will retrieve a password from a partial registry hive and upgrades it while using the old decryptor" do
      delete_registry_hive
      load_partial_registry_hive
      password = class_instance.get_cert_password
      expect(password).to eql(passwrd)
    end

    it "verifies that the new password is now using a vector" do
      win32registry = Chef::Win32::Registry.new
      path = "HKEY_LOCAL_MACHINE\\Software\\Progress\\Authentication"
      password_blob = win32registry.get_values(path)
      if password_blob.nil? || password_blob.empty?
        raise Chef::Exceptions::Win32RegKeyMissing
      end

      raw_data = password_blob.map { |x| x[:data] }
      vector = raw_data[2]
      expect(vector).not_to be(nil)
    end

    it "correctly retrieves a valid certificate in pem format from the LocalMachine certstore" do
      require "openssl"
      certificate = class_instance.retrieve_certificate_key(node_name)
      cert_object = OpenSSL::PKey::RSA.new(certificate)
      expect(cert_object.to_s).to match(/BEGIN RSA PRIVATE KEY/)
    end
  end

  def load_partial_registry_hive
    extend Chef::Mixin::PowershellExec
    password = "some_insecure_password"
    powershell_code = <<~CODE
      $encrypted_string = ConvertTo-SecureString "#{password}" -AsPlainText -Force
      $secure_string = ConvertFrom-SecureString $encrypted_string
      return $secure_string
    CODE
    encrypted_pass = powershell_exec!(powershell_code).result
    Chef::Config[:auth_key_registry_type] == "user" ? store = "HKEY_CURRENT_USER" : store = "HKEY_LOCAL_MACHINE"
    hive_path = "#{store}\\Software\\Progress\\Authentication"
    win32registry = Chef::Win32::Registry.new
    unless win32registry.key_exists?(hive_path)
      win32registry.create_key(hive_path, true)
    end
    values = { name: "PfxPass", type: :string, data: encrypted_pass }
    win32registry.set_value(hive_path, values)
  end

  def delete_registry_hive
    win32registry = Chef::Win32::Registry.new
    hive_path = "HKEY_LOCAL_MACHINE\\Software\\Progress"
    if win32registry.key_exists?(hive_path)
      win32registry.delete_key(hive_path, true)
    end
  end

  def delete_certificate(cert_name)
    powershell_code = <<~CODE
      Get-ChildItem -path cert:\\LocalMachine\\My -Recurse -Force  | Where-Object { $_.Subject -Match "#{cert_name}" } | Remove-item
    CODE
    powershell_exec!(powershell_code)
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
