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

describe Chef::HTTP::Authenticator, :windows_only do
  let(:client_name) { "test-node" }

  before do
    allow(described_class).to receive(:get_cert_user).and_return("LocalMachine")
  end

  describe ".get_the_key_ps" do
    it "uses GetRandomFileName to generate a unique temp file path rather than a hardcoded name" do
      ps_code = described_class.get_the_key_ps(client_name, "s3cr3t")
      expect(ps_code).to include("GetRandomFileName()")
      expect(ps_code).not_to include("export_pfx.pfx")
    end

    it "uses Path::Combine to safely join the temp directory and unique filename" do
      ps_code = described_class.get_the_key_ps(client_name, "s3cr3t")
      expect(ps_code).to include("GetTempPath()")
      expect(ps_code).to include("Combine(")
    end
  end

  describe ".retrieve_certificate_key" do
    context "on Windows" do
      before do
        allow(ChefUtils).to receive(:windows?).and_return(true)
        allow(described_class).to receive(:get_cert_password).and_return("s3cr3t")
      end

      context "when ps_blob is false (PowerShell Catch fired due to race condition)" do
        before do
          allow(described_class).to receive(:check_certstore_for_key).and_return(true)
          allow(described_class).to receive(:powershell_exec!).and_return(double("ps", result: false))
        end

        it "returns false without raising NoMethodError" do
          expect { described_class.retrieve_certificate_key(client_name) }.not_to raise_error
          expect(described_class.retrieve_certificate_key(client_name)).to eq(false)
        end
      end

      context "when ps_blob is nil" do
        before do
          allow(described_class).to receive(:check_certstore_for_key).and_return(true)
          allow(described_class).to receive(:powershell_exec!).and_return(double("ps", result: nil))
        end

        it "returns false without raising NoMethodError" do
          expect { described_class.retrieve_certificate_key(client_name) }.not_to raise_error
        end
      end

      context "when ps_blob is a Hash but missing PSPath key" do
        before do
          allow(described_class).to receive(:check_certstore_for_key).and_return(true)
          allow(described_class).to receive(:powershell_exec!).and_return(double("ps", result: { "OtherKey" => "value" }))
        end

        it "returns false without raising NoMethodError" do
          expect(described_class.retrieve_certificate_key(client_name)).to eq(false)
        end
      end

      context "when the PowerShell cert export succeeds" do
        let(:pfx_path) { "/tmp/export_pfx.pfx" }
        let(:mock_ps_blob) { { "PSPath" => "Microsoft.PowerShell.Security\\Certificate::#{pfx_path}" } }
        let(:mock_key) { double("OpenSSL::PKey::RSA", private_to_pem: "-----BEGIN RSA PRIVATE KEY-----\n...") }
        let(:mock_cert) { double("OpenSSL::X509::Certificate", not_after: (Time.now + 3600 * 24 * 30).utc) }
        let(:mock_pkcs) { double("OpenSSL::PKCS12", key: mock_key, certificate: mock_cert) }

        before do
          allow(described_class).to receive(:check_certstore_for_key).and_return(true)
          allow(described_class).to receive(:powershell_exec!).and_return(double("ps", result: mock_ps_blob))
          allow(File).to receive(:binread).with(pfx_path).and_return("pfx_data")
          allow(File).to receive(:exist?).with(pfx_path).and_return(true)
          allow(File).to receive(:delete).with(pfx_path)
          allow(OpenSSL::PKCS12).to receive(:new).with("pfx_data", "s3cr3t").and_return(mock_pkcs)
          allow(described_class).to receive(:is_certificate_expiring?).and_return(false)
        end

        it "returns the private key in PEM format" do
          expect(described_class.retrieve_certificate_key(client_name)).to eq("-----BEGIN RSA PRIVATE KEY-----\n...")
        end

        it "deletes the temp file via ensure on the happy path" do
          expect(File).to receive(:delete).with(pfx_path)
          described_class.retrieve_certificate_key(client_name)
        end
      end

      context "when File.binread raises after export (e.g. file deleted by another thread)" do
        let(:pfx_path) { "/tmp/chef_pfx_abc123.pfx" }
        let(:mock_ps_blob) { { "PSPath" => "Microsoft.PowerShell.Security\\Certificate::#{pfx_path}" } }

        before do
          allow(described_class).to receive(:check_certstore_for_key).and_return(true)
          allow(described_class).to receive(:powershell_exec!).and_return(double("ps", result: mock_ps_blob))
          allow(File).to receive(:binread).with(pfx_path).and_raise(Errno::ENOENT, "No such file or directory")
          allow(File).to receive(:exist?).with(pfx_path).and_return(true)
        end

        it "attempts to delete the temp file via ensure even when an exception is raised" do
          expect(File).to receive(:delete).with(pfx_path)
          expect { described_class.retrieve_certificate_key(client_name) }.to raise_error(Errno::ENOENT)
        end
      end

      context "when called concurrently from multiple threads" do
        let(:thread_count) { 10 }
        let(:mutex) { Mutex.new }
        let(:exported_paths) { [] }
        let(:deleted_paths) { [] }
        let(:mock_key) { double("OpenSSL::PKey::RSA", private_to_pem: "-----BEGIN RSA PRIVATE KEY-----\n...") }
        let(:mock_cert) { double("OpenSSL::X509::Certificate", not_after: (Time.now + 3600 * 24 * 30).utc) }
        let(:mock_pkcs) { double("OpenSSL::PKCS12", key: mock_key, certificate: mock_cert) }

        before do
          require "securerandom" unless defined?(SecureRandom)
          allow(described_class).to receive(:check_certstore_for_key).and_return(true)
          allow(described_class).to receive(:powershell_exec!) do
            unique_path = "/tmp/chef_pfx_#{SecureRandom.hex(8)}.pfx"
            mutex.synchronize { exported_paths << unique_path }
            double("ps", result: { "PSPath" => "Microsoft.PowerShell.Security\\Certificate::#{unique_path}" })
          end
          allow(File).to receive(:binread).and_return("pfx_data")
          allow(File).to receive(:exist?).and_return(true)
          allow(File).to receive(:delete) { |path| mutex.synchronize { deleted_paths << path } }
          allow(OpenSSL::PKCS12).to receive(:new).and_return(mock_pkcs)
          allow(described_class).to receive(:is_certificate_expiring?).and_return(false)
        end

        it "does not raise NoMethodError under concurrent access" do
          threads = thread_count.times.map { Thread.new { described_class.retrieve_certificate_key(client_name) } }
          expect { threads.each(&:join) }.not_to raise_error
        end

        it "uses a unique temp file path per thread so no two threads share a file" do
          threads = thread_count.times.map { Thread.new { described_class.retrieve_certificate_key(client_name) } }
          threads.each(&:join)
          expect(exported_paths.uniq.length).to eq(thread_count)
        end

        it "cleans up every unique temp file so no PFX files are orphaned on disk" do
          threads = thread_count.times.map { Thread.new { described_class.retrieve_certificate_key(client_name) } }
          threads.each(&:join)
          expect(deleted_paths.sort).to eq(exported_paths.sort)
        end
      end
    end
  end
end
