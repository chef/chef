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

  def create_store
    powershell_exec <<~EOC
      New-Item -Path Cert:\\LocalMachine\\#{store}
    EOC
  end

  def delete_store
    powershell_exec <<~EOC
      Remove-Item -Path Cert:\\LocalMachine\\#{store} -Recurse
    EOC
  end

  def certificate_count
    powershell_exec(<<~EOC).result.to_i
      (Get-ChildItem -Force -Path Cert:\\LocalMachine\\#{store} | measure).Count
    EOC
  end

  let(:password) { "P@ssw0rd!" }
  let(:store) { "Chef-Functional-Test" }
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
  end

  describe "action: verify" do
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
    it "does nothing with no certificates in the store" do
      expect(Chef::Log).not_to receive(:info)

      resource.source = tests_thumbprint
      resource.run_action(:fetch)

      expect(resource).not_to be_updated_by_last_action
    end

    context "with a certificate in the store" do
      before do
        resource.source = cer_path
        resource.run_action(:create)
      end

      it "succeeds with a valid thumbprint" do
        resource.source = tests_thumbprint

        Dir.mktmpdir do |dir|
          path = File.join(dir, "test.pem")
          expect(Chef::Log).to receive(:info).with("Certificate export in #{path}")

          resource.cert_path = path
          resource.run_action(:fetch)

          expect(File.exist?(path)).to be_truthy
        end

        expect(resource).not_to be_updated_by_last_action
      end

      it "fails with an invalid thumbprint" do
        expect(Chef::Log).not_to receive(:info)

        resource.source = others_thumbprint

        Dir.mktmpdir do |dir|
          path = File.join(dir, "test.pem")

          resource.cert_path = path
          resource.run_action(:fetch)

          expect(File.exist?(path)).to be_falsy
        end

        expect(resource).not_to be_updated_by_last_action
      end
    end
  end

  describe "action: delete" do
    it "does nothing when attempting to delete a certificate that doesn't exist" do
      expect(Chef::Log).to receive(:debug).with("Certificate not found")

      resource.source = tests_thumbprint
      resource.run_action(:delete)
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

      resource.run_action(:delete)
      expect(certificate_count).to eq(1)
      expect(resource).not_to be_updated_by_last_action

      # Verify second cert still exists
      expect(Chef::Log).to receive(:info).with("Certificate is valid")
      resource.source = others_thumbprint
      resource.run_action(:verify)
    end
  end
end
