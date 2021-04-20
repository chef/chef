# Author: Nimesh Patni (nimesh.patni@msystechnologies.com)
# Copyright:: Copyright (c) Chef Software Inc.
# License: Apache License, Version 2.0
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
require "chef/mixin/powershell_exec"
require "chef/resource/windows_certificate"

describe Chef::Resource::WindowsCertificate, :windows_only do
  include Chef::Mixin::PowershellExec

  def create_store(store_location: "LocalMachine", store_name: store)
    powershell_exec <<~EOC
      New-Item -Path Cert:\\#{store_location}\\#{store_name}
    EOC
  end

  def delete_store(store_location: "LocalMachine", store_name: store)
    powershell_exec <<~EOC
      Remove-Item -Path Cert:\\#{store_location}\\#{store_name} -Recurse
    EOC
  end

  def certificate_count(store_location: "LocalMachine", store_name: store)
    powershell_exec(<<~EOC).result.to_i
      (Get-ChildItem -Force -Path Cert:\\#{store_location}\\#{store_name} | measure).Count
    EOC
  end

  def list_certificates(store_location: "LocalMachine", store_name: store)
    powershell_exec(<<~EOC)
      Get-ChildItem -Force -Path Cert:\\#{store_location}\\#{store_name} -Recurse
    EOC
  end

  def refresh_certstore(store_location: "LocalMachine")
    powershell_exec(<<~EOC)
      Get-ChildItem -Force -Path Cert:\\#{store_location} -Recurse
    EOC
  end

  let(:password) { "P@ssw0rd!" }
  let(:store) { "Chef-Functional-Test" }
  let(:store_name) { "MY" }
  let(:store_location) { "LocalMachine" }
  let(:download_cert_url) { "https://testingchef.blob.core.windows.net/files/test.cer" }
  let(:cert_output_path) { ::File.join(Chef::Config[:file_cache_path], "output.cer") }
  let(:pfx_output_path) { ::File.join(Chef::Config[:file_cache_path], "output.pfx") }
  let(:key_output_path) { ::File.join(Chef::Config[:file_cache_path], "output.key") }
  let(:cer_path) { File.join(CHEF_SPEC_DATA, "windows_certificates", "test.cer") }
  let(:base64_path) { File.join(CHEF_SPEC_DATA, "windows_certificates", "base64_test.cer") }
  let(:pem_path) { File.join(CHEF_SPEC_DATA, "windows_certificates", "test.pem") }
  let(:p7b_path) { File.join(CHEF_SPEC_DATA, "windows_certificates", "test.p7b") }
  let(:pfx_path) { File.join(CHEF_SPEC_DATA, "windows_certificates", "test.pfx") }
  let(:tests_thumbprint) { "e45a4a7ff731e143cf20b8bfb9c7c4edd5238bb3" }
  let(:other_cer_path) { File.join(CHEF_SPEC_DATA, "windows_certificates", "othertest.cer") }
  let(:others_thumbprint) { "6eae1deefaf59daf1a97c9ceeff39c98b3da38cb" }
  let(:p7b_thumbprint) { "f867e25b928061318ed2c36ca517681774b06260" }
  let(:p7b_nested_thumbprint) { "dc395eae6be5b69951b8b6e1090cfc33df30d2cd" }

  let(:resource) do
    run_context = Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
    Chef::Resource::WindowsCertificate.new("ChefFunctionalTest", run_context).tap do |r|
      r.store_name = store
    end
  end

  before do
    # Bypass validation of the store name so we can use a fake test store.
    allow_any_instance_of(Chef::Mixin::ParamsValidate)
      .to receive(:_pv_equal_to)
      .with({ store_name: store }, :store_name, anything)
      .and_return(true)

    create_store

  end

  after { delete_store }

  describe "action: create" do
    it "starts with no certificates" do
      delete_store
      create_store
      foo = list_certificates
      expect(certificate_count).to eq(0)
    end

    it "can add a certificate idempotently" do
      resource.source = cer_path
      resource.run_action(:create)

      expect(certificate_count).to eq(1)
      expect(resource).to be_updated_by_last_action

      # Adding the cert again should have no effect
      resource.run_action(:create)
      expect(certificate_count).to eq(1)
      expect(resource).not_to be_updated_by_last_action

      # Adding the cert again with a different format should have no effect
      resource.source = pem_path
      resource.run_action(:create)
      expect(certificate_count).to eq(1)
      expect(resource).not_to be_updated_by_last_action

      # Adding another cert should work correctly
      resource.source = other_cer_path
      resource.run_action(:create)

      expect(certificate_count).to eq(2)
      expect(resource).to be_updated_by_last_action
    end

    it "can add a certificate from a valid url" do
      resource.source = download_cert_url
      resource.run_action(:create)

      expect(certificate_count).to eq(1)
      expect(resource).to be_updated_by_last_action
    end

    it "can add a base64 encoded certificate idempotently" do
      resource.source = base64_path
      resource.run_action(:create)

      expect(certificate_count).to eq(1)

      resource.run_action(:create)
      expect(certificate_count).to eq(1)
      expect(resource).not_to be_updated_by_last_action
    end

    it "can add a PEM certificate idempotently" do
      resource.source = pem_path
      resource.run_action(:create)

      expect(certificate_count).to eq(1)

      resource.run_action(:create)

      expect(certificate_count).to eq(1)
      expect(resource).not_to be_updated_by_last_action
    end

    it "can add a P7B certificate idempotently" do
      resource.source = p7b_path
      resource.run_action(:create)

      # A P7B cert includes nested certs
      expect(certificate_count).to eq(3)

      resource.run_action(:create)

      expect(resource).not_to be_updated_by_last_action
      expect(certificate_count).to eq(3)
    end

    it "can add a PFX certificate idempotently with a valid password" do
      resource.source = pfx_path
      resource.pfx_password = password
      resource.run_action(:create)

      expect(certificate_count).to eq(1)

      resource.run_action(:create)
      expect(certificate_count).to eq(1)
      expect(resource).not_to be_updated_by_last_action
    end

    it "raises an error when adding a PFX certificate with an invalid password" do
      resource.source = pfx_path
      resource.pfx_password = "Invalid password"

      expect { resource.run_action(:create) }.to raise_error(OpenSSL::PKCS12::PKCS12Error)
    end
    after { delete_store }
  end

  describe "action: verify" do
    before do
      create_store
    end
    it "fails with no certificates in the store" do
      expect(Chef::Log).to receive(:info).with("Certificate not found")

      resource.source = tests_thumbprint
      resource.run_action(:verify)

      expect(resource).not_to be_updated_by_last_action
    end

    context "with a certificate in the store" do
      before do
        resource.source = cer_path
        resource.run_action(:create)
      end

      it "succeeds with a valid thumbprint" do
        expect(Chef::Log).to receive(:info).with("Certificate is valid")

        resource.source = tests_thumbprint
        resource.run_action(:verify)

        expect(resource).not_to be_updated_by_last_action
      end

      it "fails with an invalid thumbprint" do
        expect(Chef::Log).to receive(:info).with("Certificate not found")

        resource.source = others_thumbprint
        resource.run_action(:verify)

        expect(resource).not_to be_updated_by_last_action
      end
    end

    context "with a nested certificate in the store" do
      before do
        resource.source = p7b_path
        resource.run_action(:create)
      end

      it "succeeds with the main certificate's thumbprint" do
        expect(Chef::Log).to receive(:info).with("Certificate is valid")

        resource.source = p7b_thumbprint
        resource.run_action(:verify)

        expect(resource).not_to be_updated_by_last_action
      end

      it "succeeds with the nested certificate's thumbprint" do
        expect(Chef::Log).to receive(:info).with("Certificate is valid")

        resource.source = p7b_nested_thumbprint
        resource.run_action(:verify)

        expect(resource).not_to be_updated_by_last_action
      end

      it "fails with an invalid thumbprint" do
        expect(Chef::Log).to receive(:info).with("Certificate not found")

        resource.source = others_thumbprint
        resource.run_action(:verify)

        expect(resource).not_to be_updated_by_last_action
      end
    end
  end

  describe "action: fetch" do
    context "with no certificate in the store" do
      it "throws an error with no certificates in the store" do
        expect(Chef::Log).not_to receive(:info)
        resource.source = others_thumbprint
        resource.output_path = cert_output_path
        expect { resource.run_action :fetch }.to raise_error(ArgumentError)
      end
    end

    context "with a certificate in the store" do
      before do
        resource.source = cer_path
        resource.run_action(:create)
      end

      it "succeeds with a valid thumbprint" do
        resource.source = tests_thumbprint
        local_output_path = ::File.join(Chef::Config[:file_cache_path], "test.pem")
        resource.output_path = local_output_path
        resource.run_action(:fetch)
        expect(File.exist?(local_output_path)).to be_truthy
      end

      it "fails with an invalid thumbprint" do
        expect(Chef::Log).not_to receive(:info)

        resource.source = others_thumbprint

        Dir.mktmpdir do |dir|
          path = File.join(dir, "test.pem")

          resource.output_path = path
          expect { resource.run_action :fetch }.to raise_error(ArgumentError)
        end

      end
    end

    context "with a pfx/pkcs12 object in the store" do
      before do
        create_store
        refresh_certstore
        resource.source = pfx_path
        resource.pfx_password = password
        resource.exportable = true
        resource.run_action(:create)
      end

      it "exports a PFX file with a valid thumbprint" do
        resource.source = tests_thumbprint
        resource.pfx_password = password
        resource.output_path = pfx_output_path
        resource.run_action(:fetch)
        expect(File.exist?(pfx_output_path)).to be_truthy
      end

      it "exports a key file with a valid thumbprint" do
        resource.source = tests_thumbprint
        resource.pfx_password = password
        resource.output_path = key_output_path
        resource.run_action(:fetch)
        expect(File.exist?(key_output_path)).to be_truthy
      end

      it "throws an exception when output_path is not specified" do
        resource.source = tests_thumbprint
        resource.pfx_password = password
        expect { resource.run_action :fetch }.to raise_error(::Chef::Exceptions::ResourceNotFound)
      end

      after { delete_store }

    end
  end

  describe "action: delete" do
    it "throws an argument error when attempting to delete a certificate that doesn't exist" do
      resource.source = tests_thumbprint
      expect { resource.run_action :delete }.to raise_error(ArgumentError)
    end

    it "deletes an existing certificate while leaving other certificates alone" do
      # Add two certs
      resource.source = cer_path
      resource.run_action(:create)

      resource.source = other_cer_path
      resource.run_action(:create)

      # Delete the first cert added
      resource.source = tests_thumbprint
      resource.run_action(:delete)

      expect(certificate_count).to eq(1)
      expect(resource).to be_updated_by_last_action

      expect { resource.run_action :delete }.to raise_error(ArgumentError)
      expect(certificate_count).to eq(1)
      expect(resource).not_to be_updated_by_last_action

      # Verify second cert still exists
      expect(Chef::Log).to receive(:info).with("Certificate is valid")
      resource.source = others_thumbprint
      resource.run_action(:verify)
    end
  end
end
