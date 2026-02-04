#
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

describe Chef::Resource::ChefClientHabCaCert do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::ChefClientHabCaCert.new("foo", run_context) }
  let(:provider) { resource.provider_for_action(:add) }

  it "has a resource name of :chef_client_hab_ca_cert" do
    expect(resource.resource_name).to eql(:chef_client_hab_ca_cert)
  end

  it "has a name property of cert_name" do
    expect(resource.cert_name).to eql("foo")
  end

  it "sets the default action as :add" do
    expect(resource.action).to eql([:add])
  end

  it "does not support :remove action" do
    expect { resource.action :remove }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  describe "#ca_cert_path", :linux_only do
    let(:mock_chef_path) { "/hab/pkgs/chef/chef-infra-client/19.0.0/20250101010101/bin/chef-client" }
    let(:mock_hab_path) { "/hab/bin/hab" }
    let(:dependencies_output) { "core/cacerts/2023.1.0\nother/dependency" }
    let(:pkg_path_output) { "/hab/pkgs/core/cacerts/2023.1.0\n" }

    before do
      allow(Chef::ResourceHelpers::PathHelpers).to receive(:chef_client_hab_package_binary_path).and_return(mock_chef_path)
      allow(Chef::ResourceHelpers::PathHelpers).to receive(:hab_executable_binary_path).and_return(mock_hab_path)
      allow_any_instance_of(Chef::Resource::ChefClientHabCaCert::ActionClass).to receive(:shell_out).with("#{mock_hab_path} pkg dependencies chef/chef-infra-client/19.0.0/20250101010101").and_return(double(stdout: dependencies_output, error?: false))
      allow_any_instance_of(Chef::Resource::ChefClientHabCaCert::ActionClass).to receive(:shell_out).with("#{mock_hab_path} pkg path core/cacerts/2023.1.0").and_return(double(stdout: pkg_path_output, error?: false))
    end

    it "returns the correct ca cert path" do
      expect(provider.ca_cert_path).to eq("/hab/pkgs/core/cacerts/2023.1.0/ssl/certs/cacert.pem")
    end

    context "when shell_out fails for dependencies" do
      before do
        allow(provider).to receive(:shell_out).with("#{mock_hab_path} pkg dependencies chef/chef-infra-client/19.0.0/20250101010101").and_return(double(error?: true))
      end

      it "raises an error" do
        expect { provider.ca_cert_path }.to raise_error(RuntimeError, /Failed to determine CA Certs/)
      end
    end

    context "when core/cacerts is not found in dependencies" do
      before do
        allow(provider).to receive(:shell_out).with("#{mock_hab_path} pkg dependencies chef/chef-infra-client/19.0.0/20250101010101").and_return(double(stdout: "other/dependency\n", error?: false))
      end

      it "raises an error" do
        expect { provider.ca_cert_path }.to raise_error(RuntimeError, /Unable to find 'core\/cacerts'/) # rubocop:disable Style/RegexpLiteral
      end
    end
  end

  describe "#ca_cert_path", :windows_only do
    let(:mock_chef_path_windows) { "C:\\hab\\pkgs\\chef\\chef-infra-client\\19.0.0\\20250101010101\\bin\\chef-client.exe" }
    let(:mock_hab_path_windows) { "C:\\ProgramData\\Habitat\\hab.exe" }
    let(:dependencies_output) { "core/cacerts/2023.1.0\nother/dependency" }
    let(:pkg_path_output) { "/hab/pkgs/core/cacerts/2023.1.0\n" }

    before do
      allow(Chef::ResourceHelpers::PathHelpers).to receive(:chef_client_hab_package_binary_path).and_return(mock_chef_path_windows)
      allow(Chef::ResourceHelpers::PathHelpers).to receive(:hab_executable_binary_path).and_return(mock_hab_path_windows)
      allow(provider).to receive(:shell_out).with("#{mock_hab_path_windows} pkg dependencies chef/chef-infra-client/19.0.0/20250101010101").and_return(double(stdout: dependencies_output, error?: false))
      allow(provider).to receive(:shell_out).with("#{mock_hab_path_windows} pkg path core/cacerts/2023.1.0").and_return(double(stdout: pkg_path_output, error?: false))
    end

    it "extracts version correctly from Windows paths" do
      expect(provider.ca_cert_path).to eq("/hab/pkgs/core/cacerts/2023.1.0/ssl/certs/cacert.pem")
    end
  end

  describe "action :add", :linux_only do
    let(:mock_chef_path) { "/hab/pkgs/chef/chef-infra-client/19.0.0/20250101010101/bin/chef-client" }
    let(:mock_hab_path) { "/hab/bin/hab" }
    let(:dependencies_output) { "core/cacerts/2023.1.0\nother/dependency" }
    let(:pkg_path_output) { "/hab/pkgs/core/cacerts/2023.1.0\n" }
    let(:temp_cert_file) { Tempfile.new(["test_cacert", ".pem"]) }
    let(:test_certificate) do
      <<~CERT
        -----BEGIN CERTIFICATE-----
        MIIDeTCCAmGgAwIBAgIJAPziuikCTox4MA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNV
        BAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMRYwFAYDVQQHDA1TYW4gRnJhbmNp
        c2NvMQ8wDQYDVQQKDAZCYWRTU0wxFTATBgNVBAMMDCouYmFkc3NsLmNvbTAeFw0x
        OTEwMDkyMzQxNTJaFw0yMTEwMDgyMzQxNTJaMGIxCzAJBgNVBAYTAlVTMRMwEQYD
        VQQIDApDYWxpZm9ybmlhMRYwFAYDVQQHDA1TYW4gRnJhbmNpc2NvMQ8wDQYDVQQK
        DAZCYWRTU0wxFTATBgNVBAMMDCouYmFkc3NsLmNvbTCCASIwDQYJKoZIhvcNAQEB
        BQADggEPADCCAQoCggEBAMIE7PiM7gTCs9hQ1XBYzJMY61yoaEmwIrX5lZ6xKyx2
        PmzAS2BMTOqytMAPgLaw+XLJhgL5XEFdEyt/ccRLvOmULlA3pmccYYz2QULFRtMW
        hyefdOsKnRFSJiFzbIRMeVXk0WvoBj1IFVKtsyjbqv9u/2CVSndrOfEk0TG23U3A
        xPxTuW1CrbV8/q71FdIzSOciccfCFHpsKOo3St/qbLVytH5aohbcabFXRNsKEqve
        ww9HdFxBIuGa+RuT5q0iBikusbpJHAwnnqP7i/dAcgCskgjZjFeEU4EFy+b+a1SY
        QCeFxxC7c3DvaRhBB0VVfPlkPz0sw6l865MaTIbRyoUCAwEAAaMyMDAwCQYDVR0T
        BAIwADAjBgNVHREEHDAaggwqLmJhZHNzbC5jb22CCmJhZHNzbC5jb20wDQYJKoZI
        hvcNAQELBQADggEBAGlwCdbPxflZfYOaukZGCaxYK6gpincX4Lla4Ui2WdeQxE95
        w7fChXvP3YkE3UYUE7mupZ0eg4ZILr/A0e7JQDsgIu/SRTUE0domCKgPZ8v99k3A
        vka4LpLK51jHJJK7EFgo3ca2nldd97GM0MU41xHFk8qaK1tWJkfrrfcGwDJ4GQPI
        iLlm6i0yHq1Qg1RypAXJy5dTlRXlCLd8ufWhhiwW0W75Va5AEnJuqpQrKwl3KQVe
        wGj67WWRgLfSr+4QG1mNvCZb2CkjZWmxkGPuoP40/y7Yu5OFqxP5tAjj4YixCYTW
        EVA0pmzIzgBg+JIe3PdRy27T0asgQW/F4TY61Yk=
        -----END CERTIFICATE-----
      CERT
    end

    before do
      allow(Chef::ResourceHelpers::PathHelpers).to receive(:chef_client_hab_package_binary_path).and_return(mock_chef_path)
      allow(Chef::ResourceHelpers::PathHelpers).to receive(:hab_executable_binary_path).and_return(mock_hab_path)
      allow(provider).to receive(:shell_out).with("#{mock_hab_path} pkg dependencies chef/chef-infra-client/19.0.0/20250101010101").and_return(double(stdout: dependencies_output, error?: false))
      allow(provider).to receive(:shell_out).with("#{mock_hab_path} pkg path core/cacerts/2023.1.0").and_return(double(stdout: pkg_path_output, error?: false))

      # Write initial content to temp cert file
      temp_cert_file.write("# Existing CA Bundle\n")
      temp_cert_file.close

      # Ensure resource uses our pre-built provider, then stub its ca_cert_path
      allow_any_instance_of(Chef::Resource::ChefClientHabCaCert).to receive(:provider_for_action).and_return(provider)
      allow(provider).to receive(:ca_cert_path).and_return(temp_cert_file.path)
    end

    after do
      temp_cert_file.unlink
    end

    context "when adding a new certificate" do
      before do
        resource.certificate test_certificate
      end

      it "adds the certificate to the CA bundle file" do
        resource.run_action(:add)

        cert_content = File.read(temp_cert_file.path)
        expect(cert_content).to include("Cert Bundle - foo")
        expect(cert_content).to include("===========================")
        expect(cert_content).to include(test_certificate.strip)
      end

      it "marks the resource as updated" do
        resource.run_action(:add)
        expect(resource).to be_updated_by_last_action
      end

      it "maintains existing content in the bundle" do
        resource.run_action(:add)

        cert_content = File.read(temp_cert_file.path)
        expect(cert_content).to include("# Existing CA Bundle")
      end

      it "validates the certificate format is preserved" do
        resource.run_action(:add)

        cert_content = File.read(temp_cert_file.path)
        expect(cert_content).to include("-----BEGIN CERTIFICATE-----")
        expect(cert_content).to include("-----END CERTIFICATE-----")
      end
    end

    context "when certificate already exists" do
      before do
        resource.certificate test_certificate
        # Pre-populate the file with the certificate
        File.open(temp_cert_file.path, "a") do |f|
          f.puts "\nCert Bundle - foo"
          f.puts "==========================="
          f.puts test_certificate
        end
      end

      it "does not add duplicate certificate" do
        initial_content = File.read(temp_cert_file.path)
        resource.run_action(:add)
        final_content = File.read(temp_cert_file.path)

        expect(initial_content).to eq(final_content)
      end

      it "does not mark resource as updated" do
        resource.run_action(:add)
        expect(resource).not_to be_updated_by_last_action
      end
    end
  end

  describe "action :add", :windows_only do
    let(:mock_chef_path) { "C:\\hab\\pkgs\\chef\\chef-infra-client\\19.0.0\\20250101010101\\bin\\chef-client.exe" }
    let(:mock_hab_path) { "C:\\ProgramData\\Habitat\\hab.exe" }
    let(:dependencies_output) { "core/cacerts/2023.1.0\nother/dependency" }
    let(:pkg_path_output) { "/hab/pkgs/core/cacerts/2023.1.0\n" }
    let(:temp_cert_file) { Tempfile.new(["test_cacert", ".pem"]) }
    let(:test_certificate) do
      <<~CERT
        -----BEGIN CERTIFICATE-----
        MIIDeTCCAmGgAwIBAgIJAPziuikCTox4MA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNV
        BAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMRYwFAYDVQQHDA1TYW4gRnJhbmNp
        c2NvMQ8wDQYDVQQKDAZCYWRTU0wxFTATBgNVBAMMDCouYmFkc3NsLmNvbTAeFw0x
        OTEwMDkyMzQxNTJaFw0yMTEwMDgyMzQxNTJaMGIxCzAJBgNVBAYTAlVTMRMwEQYD
        VQQIDApDYWxpZm9ybmlhMRYwFAYDVQQHDA1TYW4gRnJhbmNpc2NvMQ8wDQYDVQQK
        DAZCYWRTU0wxFTATBgNVBAMMDCouYmFkc3NsLmNvbTCCASIwDQYJKoZIhvcNAQEB
        BQADggEPADCCAQoCggEBAMIE7PiM7gTCs9hQ1XBYzJMY61yoaEmwIrX5lZ6xKyx2
        PmzAS2BMTOqytMAPgLaw+XLJhgL5XEFdEyt/ccRLvOmULlA3pmccYYz2QULFRtMW
        hyefdOsKnRFSJiFzbIRMeVXk0WvoBj1IFVKtsyjbqv9u/2CVSndrOfEk0TG23U3A
        xPxTuW1CrbV8/q71FdIzSOciccfCFHpsKOo3St/qbLVytH5aohbcabFXRNsKEqve
        ww9HdFxBIuGa+RuT5q0iBikusbpJHAwnnqP7i/dAcgCskgjZjFeEU4EFy+b+a1SY
        QCeFxxC7c3DvaRhBB0VVfPlkPz0sw6l865MaTIbRyoUCAwEAAaMyMDAwCQYDVR0T
        BAIwADAjBgNVHREEHDAaggwqLmJhZHNzbC5jb22CCmJhZHNzbC5jb20wDQYJKoZI
        hvcNAQELBQADggEBAGlwCdbPxflZfYOaukZGCaxYK6gpincX4Lla4Ui2WdeQxE95
        w7fChXvP3YkE3UYUE7mupZ0eg4ZILr/A0e7JQDsgIu/SRTUE0domCKgPZ8v99k3A
        vka4LpLK51jHJJK7EFgo3ca2nldd97GM0MU41xHFk8qaK1tWJkfrrfcGwDJ4GQPI
        iLlm6i0yHq1Qg1RypAXJy5dTlRXlCLd8ufWhhiwW0W75Va5AEnJuqpQrKwl3KQVe
        wGj67WWRgLfSr+4QG1mNvCZb2CkjZWmxkGPuoP40/y7Yu5OFqxP5tAjj4YixCYTW
        EVA0pmzIzgBg+JIe3PdRy27T0asgQW/F4TY61Yk=
        -----END CERTIFICATE-----
      CERT
    end

    before do
      allow(Chef::ResourceHelpers::PathHelpers).to receive(:chef_client_hab_binary_path).and_return(mock_chef_path)
      allow(Chef::ResourceHelpers::PathHelpers).to receive(:hab_executable_binary_path).and_return(mock_hab_path)
      allow(provider).to receive(:shell_out).with("#{mock_hab_path} pkg dependencies chef/chef-infra-client/19.0.0/20250101010101").and_return(double(stdout: dependencies_output, error?: false))
      allow(provider).to receive(:shell_out).with("#{mock_hab_path} pkg path core/cacerts/2023.1.0").and_return(double(stdout: pkg_path_output, error?: false))

      temp_cert_file.write("# Existing CA Bundle\n")
      temp_cert_file.close

      allow_any_instance_of(Chef::Resource::ChefClientHabCaCert).to receive(:provider_for_action).and_return(provider)
      allow(provider).to receive(:ca_cert_path).and_return(temp_cert_file.path)
    end

    after do
      temp_cert_file.unlink
    end

    context "when adding a new certificate" do
      before do
        resource.certificate test_certificate
      end

      it "adds the certificate to the CA bundle file" do
        resource.run_action(:add)

        cert_content = File.read(temp_cert_file.path)
        expect(cert_content).to include("Cert Bundle - foo")
        expect(cert_content).to include("===========================")
        expect(cert_content).to include(test_certificate.strip)
      end

      it "marks the resource as updated" do
        resource.run_action(:add)
        expect(resource).to be_updated_by_last_action
      end

      it "maintains existing content in the bundle" do
        resource.run_action(:add)

        cert_content = File.read(temp_cert_file.path)
        expect(cert_content).to include("# Existing CA Bundle")
      end

      it "validates the certificate format is preserved" do
        resource.run_action(:add)

        cert_content = File.read(temp_cert_file.path)
        expect(cert_content).to include("-----BEGIN CERTIFICATE-----")
        expect(cert_content).to include("-----END CERTIFICATE-----")
      end
    end

    context "when certificate already exists" do
      before do
        resource.certificate test_certificate
        File.open(temp_cert_file.path, "a") do |f|
          f.puts "\nCert Bundle - foo"
          f.puts "==========================="
          f.puts test_certificate
        end
      end

      it "does not add duplicate certificate" do
        initial_content = File.read(temp_cert_file.path)
        resource.run_action(:add)
        final_content = File.read(temp_cert_file.path)

        expect(initial_content).to eq(final_content)
      end

      it "does not mark resource as updated" do
        resource.run_action(:add)
        expect(resource).not_to be_updated_by_last_action
      end
    end
  end

end
