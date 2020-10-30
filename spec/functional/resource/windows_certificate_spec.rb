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

module WindowsCertificateHelper
  include Chef::Mixin::PowershellExec

  def create_store(store)
    path = "Cert:\\LocalMachine\\" + store
    command = <<~EOC
      New-Item -Path #{path}
    EOC
    powershell_exec(command)
  end

  def cleanup(store)
    path = "Cert:\\LocalMachine\\" + store
    command = <<~EOC
      Remove-Item -Path #{path} -Recurse
    EOC
    powershell_exec(command)
  end

  def no_of_certificates
    path = "Cert:\\LocalMachine\\" + store
    # Seems weird that we have to call dir twice right?
    # The powershell pki module cache the last dir in module session state
    # Issuing dir with a different arg (-Force) seems to refresh that state.
    command = <<~EOC
      dir #{path} -Force | Out-Null
      (dir #{path} | measure).Count
    EOC
    powershell_exec(command).result.to_i
  end
end

describe Chef::Resource::WindowsCertificate, :windows_only do
  include WindowsCertificateHelper

  let(:stdout) { StringIO.new }
  let(:username) { "ChefFunctionalTest" }
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:new_resource) { Chef::Resource::WindowsCertificate.new(username, run_context) }
  let(:password) { "P@ssw0rd!" }
  let(:store) { "Chef-Functional-Test" }
  let(:certificate_path) { File.expand_path(File.join(CHEF_SPEC_DATA, "windows_certificates")) }
  let(:cer_path) { File.join(certificate_path, "test.cer") }
  let(:base64_path) { File.join(certificate_path, "base64_test.cer") }
  let(:pem_path) { File.join(certificate_path, "test.pem") }
  let(:p7b_path) { File.join(certificate_path, "test.p7b") }
  let(:pfx_path) { File.join(certificate_path, "test.pfx") }
  let(:out_path) { File.join(certificate_path, "testout.pem") }
  let(:tests_thumbprint) { "e45a4a7ff731e143cf20b8bfb9c7c4edd5238bb3" }
  let(:other_cer_path) { File.join(certificate_path, "othertest.cer") }
  let(:others_thumbprint) { "6eae1deefaf59daf1a97c9ceeff39c98b3da38cb" }
  let(:p7b_thumbprint) { "f867e25b928061318ed2c36ca517681774b06260" }
  let(:p7b_nested_thumbprint) { "dc395eae6be5b69951b8b6e1090cfc33df30d2cd" }

  before do
    opts = { store_name: store }
    key = :store_name
    to_be = ["TRUSTEDPUBLISHER", "TrustedPublisher", "CLIENTAUTHISSUER",
             "REMOTE DESKTOP", "ROOT", "TRUSTEDDEVICES", "WEBHOSTING",
             "CA", "AUTHROOT", "TRUSTEDPEOPLE", "MY", "SMARTCARDROOT", "TRUST",
             "DISALLOWED"]

    # Byepassing the validation so that we may create a custom store
    allow_any_instance_of(Chef::Mixin::ParamsValidate)
      .to receive(:_pv_equal_to)
      .with(opts, key, to_be)
      .and_return(true)

    # Creating a custom store for the testing
    create_store(store)

    allow(Chef::Log).to receive(:info) do |msg|
      stdout.puts(msg)
    end
  end

  after { cleanup(store) }

  subject(:win_certificate) do
    new_resource.store_name = store
    new_resource
  end

  it "Initially there are no certificates" do
    expect(no_of_certificates).to eq(0)
  end

  describe "action :create" do
    before do
      win_certificate.source = cer_path
      win_certificate.run_action(:create)
    end

    context "Adding a certificate" do
      it "Imports certificate into store" do
        expect(no_of_certificates).to eq(1)
      end

      it "Converges while addition" do
        expect(win_certificate).to be_updated_by_last_action
      end
    end

    context "Again adding the same certificate" do
      before do
        win_certificate.run_action(:create)
      end
      it "Does not imports certificate into store" do
        expect(no_of_certificates).to eq(1)
      end
      it "Idempotent: Does not converge while addition" do
        expect(no_of_certificates).to eq(1)
        expect(win_certificate).not_to be_updated_by_last_action
      end
    end

    context "Again adding the same certificate of other format" do
      before do
        win_certificate.source = pem_path
        win_certificate.run_action(:create)
      end
      it "Does not imports certificate into store" do
        expect(no_of_certificates).to eq(1)
      end
      it "Idempotent: Does not converge while addition" do
        expect(no_of_certificates).to eq(1)
        expect(win_certificate).not_to be_updated_by_last_action
      end
    end

    context "Adding another certificate" do
      before do
        win_certificate.source = other_cer_path
        win_certificate.run_action(:create)
      end
      it "Imports certificate into store" do
        expect(no_of_certificates).to eq(2)
      end
      it "Converges while addition" do
        expect(no_of_certificates).to eq(2)
        expect(win_certificate).to be_updated_by_last_action
      end
    end
  end

  describe "Works for various formats" do
    context "Adds CER" do
      before do
        win_certificate.source = cer_path
        win_certificate.run_action(:create)
      end
      it "Imports certificate into store" do
        expect(no_of_certificates).to eq(1)
      end
      it "Idempotent: Does not converge while adding again" do
        win_certificate.run_action(:create)
        expect(no_of_certificates).to eq(1)
        expect(win_certificate).not_to be_updated_by_last_action
      end
    end

    context "Adds Base64 Encoded CER" do
      before do
        win_certificate.source = base64_path
        win_certificate.run_action(:create)
      end
      it "Imports certificate into store" do
        expect(no_of_certificates).to eq(1)
      end
      it "Idempotent: Does not converge while adding again" do
        win_certificate.run_action(:create)
        expect(no_of_certificates).to eq(1)
        expect(win_certificate).not_to be_updated_by_last_action
      end
    end

    context "Adds PEM" do
      before do
        win_certificate.source = pem_path
        win_certificate.run_action(:create)
      end
      it "Imports certificate into store" do
        expect(no_of_certificates).to eq(1)
      end
      it "Idempotent: Does not converge while adding again" do
        win_certificate.run_action(:create)
        expect(no_of_certificates).to eq(1)
        expect(win_certificate).not_to be_updated_by_last_action
      end
    end

    context "Adds P7B" do
      before do
        win_certificate.source = p7b_path
        win_certificate.run_action(:create)
      end
      it "Imports certificate into store" do
        expect(no_of_certificates).not_to eq(0)
      end
      it "Idempotent: Does not converge while adding again" do
        win_certificate.run_action(:create)
        expect(win_certificate).not_to be_updated_by_last_action
      end
      it "Nested certificates are also imported" do
        expect(no_of_certificates).to eq(3)
      end
    end

    context "Adds PFX" do
      context "With valid password" do
        before do
          win_certificate.source = pfx_path
          win_certificate.pfx_password = password
          win_certificate.run_action(:create)
        end
        it "Imports certificate into store" do
          expect(no_of_certificates).to eq(1)
        end
        it "Idempotent: Does not converge while adding again" do
          win_certificate.run_action(:create)
          expect(no_of_certificates).to eq(1)
          expect(win_certificate).not_to be_updated_by_last_action
        end
      end

      context "With Invalid password" do
        before do
          win_certificate.source = pfx_path
          win_certificate.pfx_password = "Invalid password"
        end
        it "Raises an error" do
          expect { win_certificate.run_action(:create) }.to raise_error(OpenSSL::PKCS12::PKCS12Error)
        end
      end
    end
  end

  describe "action: verify" do
    context "When a certificate is not present" do
      before do
        win_certificate.source = tests_thumbprint
        win_certificate.run_action(:verify)
      end
      it "Initial check if certificate is not present" do
        expect(no_of_certificates).to eq(0)
      end
      it "Displays correct message" do
        expect(stdout.string.strip).to eq("Certificate not found")
      end
      it "Does not converge while verifying" do
        expect(win_certificate).not_to be_updated_by_last_action
      end
    end

    context "When a certificate is present" do
      before do
        win_certificate.source = cer_path
        win_certificate.run_action(:create)
      end

      context "For a valid thumbprint" do
        before do
          win_certificate.source = tests_thumbprint
          win_certificate.run_action(:verify)
        end
        it "Initial check if certificate is present" do
          expect(no_of_certificates).to eq(1)
        end
        it "Displays correct message" do
          expect(stdout.string.strip).to eq("Certificate is valid")
        end
        it "Does not converge while verifying" do
          expect(win_certificate).not_to be_updated_by_last_action
        end
      end

      context "For an invalid thumbprint" do
        before do
          win_certificate.source = others_thumbprint
          win_certificate.run_action(:verify)
        end
        it "Initial check if certificate is present" do
          expect(no_of_certificates).to eq(1)
        end
        it "Displays correct message" do
          expect(stdout.string.strip).to eq("Certificate not found")
        end
        it "Does not converge while verifying" do
          expect(win_certificate).not_to be_updated_by_last_action
        end
      end
    end

    context "When multiple certificates are present" do
      before do
        win_certificate.source = p7b_path
        win_certificate.run_action(:create)
      end

      context "With main certificate's thumbprint" do
        before do
          win_certificate.source = p7b_thumbprint
          win_certificate.run_action(:verify)
        end
        it "Initial check if certificate is present" do
          expect(no_of_certificates).to eq(3)
        end
        it "Displays correct message" do
          expect(stdout.string.strip).to eq("Certificate is valid")
        end
        it "Does not converge while verifying" do
          expect(win_certificate).not_to be_updated_by_last_action
        end
      end

      context "With nested certificate's thumbprint" do
        before do
          win_certificate.source = p7b_nested_thumbprint
          win_certificate.run_action(:verify)
        end
        it "Initial check if certificate is present" do
          expect(no_of_certificates).to eq(3)
        end
        it "Displays correct message" do
          expect(stdout.string.strip).to eq("Certificate is valid")
        end
        it "Does not converge while verifying" do
          expect(win_certificate).not_to be_updated_by_last_action
        end
      end

      context "For an invalid thumbprint" do
        before do
          win_certificate.source = others_thumbprint
          win_certificate.run_action(:verify)
        end
        it "Initial check if certificate is present" do
          expect(no_of_certificates).to eq(3)
        end
        it "Displays correct message" do
          expect(stdout.string.strip).to eq("Certificate not found")
        end
        it "Does not converge while verifying" do
          expect(win_certificate).not_to be_updated_by_last_action
        end
      end
    end
  end

  describe "action: fetch" do
    context "When a certificate is not present" do
      before do
        win_certificate.source = tests_thumbprint
        win_certificate.run_action(:fetch)
      end
      it "Initial check if certificate is not present" do
        expect(no_of_certificates).to eq(0)
      end
      it "Does not show any content" do
        expect(stdout.string.strip).to be_empty
      end
      it "Does not converge while fetching" do
        expect(win_certificate).not_to be_updated_by_last_action
      end
    end

    context "When a certificate is present" do
      before do
        win_certificate.source = cer_path
        win_certificate.run_action(:create)
      end

      after do
        if File.exist?(out_path)
          File.delete(out_path)
        end
      end

      context "For a valid thumbprint" do
        before do
          win_certificate.source = tests_thumbprint
          win_certificate.cert_path = out_path
          win_certificate.run_action(:fetch)
        end
        it "Initial check if certificate is present" do
          expect(no_of_certificates).to eq(1)
        end
        it "Stores Certificate content at given path" do
          expect(File.exist?(out_path)).to be_truthy
        end
        it "Does not converge while fetching" do
          expect(win_certificate).not_to be_updated_by_last_action
        end
      end

      context "For an invalid thumbprint" do
        before do
          win_certificate.source = others_thumbprint
          win_certificate.cert_path = out_path
          win_certificate.run_action(:fetch)
        end
        it "Initial check if certificate is present" do
          expect(no_of_certificates).to eq(1)
        end
        it "Does not show any content" do
          expect(stdout.string.strip).to be_empty
        end
        it "Does not store certificate content at given path" do
          expect(File.exist?(out_path)).to be_falsy
        end
        it "Does not converge while fetching" do
          expect(win_certificate).not_to be_updated_by_last_action
        end
      end
    end
  end

  describe "action: delete" do
    context "When a certificate is not present" do
      before do
        win_certificate.source = tests_thumbprint
        win_certificate.run_action(:delete)
      end
      it "Initial check if certificate is not present" do
        expect(no_of_certificates).to eq(0)
      end
      it "Does not delete any certificate" do
        expect(stdout.string.strip).to be_empty
      end
    end

    context "When a certificate is present" do
      before do
        win_certificate.source = cer_path
        win_certificate.run_action(:create)
      end
      before { win_certificate.source = tests_thumbprint }
      it "Initial check if certificate is present" do
        expect(no_of_certificates).to eq(1)
      end
      it "Deletes the certificate" do
        win_certificate.run_action(:delete)
        expect(no_of_certificates).to eq(0)
      end
      it "Converges while deleting" do
        win_certificate.run_action(:delete)
        expect(win_certificate).to be_updated_by_last_action
      end
      it "Idempotent: Does not converge while deleting again" do
        win_certificate.run_action(:delete)
        win_certificate.run_action(:delete)
        expect(no_of_certificates).to eq(0)
        expect(win_certificate).not_to be_updated_by_last_action
      end
      it "Deletes the valid certificate" do
        # Add another certificate"
        win_certificate.source = other_cer_path
        win_certificate.run_action(:create)
        expect(no_of_certificates).to eq(2)

        # Delete previously added certificate
        win_certificate.source = tests_thumbprint
        win_certificate.run_action(:delete)
        expect(no_of_certificates).to eq(1)

        # Verify another certificate still exists
        win_certificate.source = others_thumbprint
        win_certificate.run_action(:verify)
        expect(stdout.string.strip).to eq("Certificate is valid")
      end
    end
  end
end
