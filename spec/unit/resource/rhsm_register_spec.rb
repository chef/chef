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

describe Chef::Resource::RhsmRegister do

  let(:resource) { Chef::Resource::RhsmRegister.new("foo") }
  let(:provider) { resource.provider_for_action(:register) }

  it "has a resource name of :rhsm_register" do
    expect(resource.resource_name).to eql(:rhsm_register)
  end

  it "sets the default action as :register" do
    expect(resource.action).to eql([:register])
  end

  it "supports :register, :unregister actions" do
    expect { resource.action :register }.not_to raise_error
    expect { resource.action :unregister }.not_to raise_error
  end

  it "coerces activation_key to an array" do
    resource.activation_key "foo"
    expect(resource.activation_key).to eql(["foo"])
  end

  it "coerces not_registered_strings to an array" do
    resource.not_registered_strings "unregistered"
    expect(resource.not_registered_strings).to eql(["unregistered"])
  end

  describe "#katello_cert_rpm_installed?" do
    context "when the output contains katello-ca-consumer" do
      let(:with_katello) { double("shell_out", stdout: <<~RPM) }
        libevent-2.0.21-4.el7.x86_64
        gettext-libs-0.19.8.1-3.el7.x86_64
        yum-metadata-parser-1.1.4-10.el7.x86_64
        pyliblzma-0.5.3-11.el7.x86_64
        python-IPy-0.75-6.el7.noarch
        grubby-8.28-26.el7.x86_64
        fipscheck-lib-1.4.1-6.el7.x86_64
        centos-logos-70.0.6-3.el7.centos.noarch
        nss-tools-3.44.0-7.el7_7.x86_64
        katello-ca-consumer-somehostname-1.0-1.el7.x86_64
        rpm-4.11.3-43.el7.x86_64
        gpgme-1.3.2-5.el7.x86_64
        libnfsidmap-0.25-19.el7.x86_64
      RPM

      it "returns true" do
        allow(provider).to receive(:shell_out).and_return(with_katello)
        expect(provider.katello_cert_rpm_installed?).to eq(true)
      end
    end

    context "when the output does not contain katello-ca-consumer" do
      let(:without_katello) { double("shell_out", stdout: "") }

      it "returns false" do
        allow(provider).to receive(:shell_out).and_return(without_katello)
        expect(provider.katello_cert_rpm_installed?).to eq(false)
      end
    end
  end

  describe "#register_command" do
    before do
      allow(provider).to receive(:activation_key).and_return([])
      allow(provider).to receive(:auto_attach)
    end

    context "when activation keys exist" do
      before do
        allow(resource).to receive(:activation_key).and_return(%w{key1 key2})
      end

      context "when no org exists" do
        it "raises an exception" do
          allow(resource).to receive(:organization).and_return(nil)
          expect { provider.register_command }.to raise_error(RuntimeError)
        end
      end

      context "when an org exists" do
        it "returns a command containing the keys and org" do
          allow(resource).to receive(:organization).and_return("myorg")

          expect(provider.register_command).to match("--activationkey=key1 --activationkey=key2 --org=myorg")
        end
      end

      context "when a system_name is provided" do
        it "returns a command containing the system name" do
          allow(resource).to receive(:organization).and_return("myorg")
          allow(resource).to receive(:system_name).and_return("myname")
          expect(provider.register_command).to match("--name=myname")
        end
      end

      context "when a system_name is not provided" do
        it "returns a command containing the system name" do
          allow(resource).to receive(:organization).and_return("myorg")
          allow(resource).to receive(:system_name).and_return(nil)
          expect(provider.register_command).not_to match("--name")
        end
      end

      context "when auto_attach is true" do
        it "does not return a command with --auto-attach since it is not supported with activation keys" do
          allow(resource).to receive(:organization).and_return("myorg")
          allow(resource).to receive(:auto_attach).and_return(true)

          expect(provider.register_command).not_to match("--auto-attach")
        end
      end
    end

    context "when username and password exist" do
      before do
        allow(resource).to receive(:username).and_return("myuser")
        allow(resource).to receive(:password).and_return("mypass")
        allow(resource).to receive(:environment)
        allow(resource).to receive(:using_satellite_host?)
        allow(resource).to receive(:activation_key).and_return([])
      end

      context "when auto_attach is true" do
        it "returns a command containing --auto-attach" do
          allow(resource).to receive(:auto_attach).and_return(true)

          expect(provider.register_command).to match("--auto-attach")
        end
      end

      context "when auto_attach is false" do
        it "returns a command that does not contain --auto-attach" do
          allow(resource).to receive(:auto_attach).and_return(false)

          expect(provider.register_command).not_to match("--auto-attach")
        end
      end

      context "when a system_name is provided" do
        it "returns a command containing the system name" do
          allow(resource).to receive(:system_name).and_return("myname")
          expect(provider.register_command).to match("--name=myname")
        end
      end

      context "when a server_url is provided" do
        it "returns a command containing the server url" do
          allow(resource).to receive(:server_url).and_return("https://fqdn.example")
          expect(provider.register_command).to match("--serverurl=https://fqdn.example")
        end
      end

      context "when a base_url is provided" do
        it "returns a command containing the base url" do
          allow(resource).to receive(:base_url).and_return("https://fqdn.example")
          expect(provider.register_command).to match("--baseurl=https://fqdn.example")
        end
      end

      context "when a service_level is provided" do
        it "returns a command containing the service level" do
          allow(resource).to receive(:service_level).and_return("None")
          allow(resource).to receive(:auto_attach).and_return(true)
          expect(provider.register_command).to match("--servicelevel=None")
        end

        it "raises an exception if auto_attach is not set" do
          allow(resource).to receive(:service_level).and_return("None")
          allow(resource).to receive(:auto_attach).and_return(nil)
          expect { provider.register_command }.to raise_error(RuntimeError)
        end
      end

      context "when a release is provided" do
        it "returns a command containing the release" do
          allow(resource).to receive(:release).and_return("8.4")
          allow(resource).to receive(:auto_attach).and_return(true)
          expect(provider.register_command).to match("--release=8.4")
        end

        it "raises an exception if auto_attach is not set" do
          allow(resource).to receive(:release).and_return("8.4")
          allow(resource).to receive(:auto_attach).and_return(nil)
          expect { provider.register_command }.to raise_error(RuntimeError)
        end
      end

      context "when a system_name is not provided" do
        it "returns a command containing the system name" do
          allow(resource).to receive(:system_name).and_return(nil)
          expect(provider.register_command).not_to match("--name")
        end
      end

      context "when auto_attach is nil" do
        it "returns a command that does not contain --auto-attach" do
          allow(resource).to receive(:auto_attach).and_return(nil)

          expect(provider.register_command).not_to match("--auto-attach")
        end
      end

      context "when environment does not exist" do
        context "when registering to a satellite server" do
          it "raises an exception" do
            allow(provider).to receive(:using_satellite_host?).and_return(true)
            allow(resource).to receive(:environment).and_return(nil)
            expect { provider.register_command }.to raise_error(RuntimeError)
          end
        end

        context "when registering to RHSM proper" do
          before do
            allow(provider).to receive(:using_satellite_host?).and_return(false)
            allow(resource).to receive(:environment).and_return(nil)
          end

          it "does not raise an exception" do
            expect { provider.register_command }.not_to raise_error
          end

          it "returns a command containing the username and password and no environment" do
            allow(resource).to receive(:environment).and_return("myenv")
            expect(provider.register_command).to match("--username=myuser --password=mypass")
            expect(provider.register_command).not_to match("--environment")
          end
        end
      end

      context "when an environment exists" do
        it "returns a command containing the username, password, and environment" do
          allow(provider).to receive(:using_satellite_host?).and_return(true)
          allow(resource).to receive(:environment).and_return("myenv")
          expect(provider.register_command).to match("--username=myuser --password=mypass --environment=myenv")
        end
      end
    end

    context "when no activation keys, username, or password exist" do
      it "raises an exception" do
        allow(resource).to receive(:activation_key).and_return([])
        allow(resource).to receive(:username).and_return(nil)
        allow(resource).to receive(:password).and_return(nil)

        expect { provider.register_command }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#ca_consumer_package_source" do
    let(:satellite_host) { "sat-host" }

    before do
      resource.satellite_host = satellite_host
    end

    context "when https_for_ca_consumer is true" do
      before { resource.https_for_ca_consumer true }

      it "returns url with https" do
        expect(provider.ca_consumer_package_source).to eq("https://#{satellite_host}/pub/katello-ca-consumer-latest.noarch.rpm")
      end
    end

    context "when https_for_ca_consumer is false" do
      before { resource.https_for_ca_consumer false }

      it "returns url with http" do
        expect(provider.ca_consumer_package_source).to eq("http://#{satellite_host}/pub/katello-ca-consumer-latest.noarch.rpm")
      end
    end
  end

  describe "#registered_with_rhsm?" do
    context "when not_registered_strings is default and the status is Unknown" do
      let(:unknown_status) { double("shell_out", stdout: "Overall Status: Unknown") }

      it "returns false" do
        allow(provider).to receive(:shell_out).and_return(unknown_status)
        expect(provider.registered_with_rhsm?).to eq(false)
      end
    end

    context "when not_registered_strings is default and the status is Not registered" do
      let(:not_registered) { double("shell_out", stdout: "Overall Status: Not registered") }

      it "returns false" do
        allow(provider).to receive(:shell_out).and_return(not_registered)
        expect(provider.registered_with_rhsm?).to eq(false)
      end
    end

    context "when not_registered_strings is default and the status is anything else" do
      let(:known_status) { double("shell_out", stdout: "Overall Status: Insufficient") }

      it "returns true" do
        allow(provider).to receive(:shell_out).and_return(known_status)
        expect(provider.registered_with_rhsm?).to eq(true)
      end
    end

    context "when not_registered_strings is Insufficient and the status is Insufficient" do
      before { resource.not_registered_strings "Overall Status: Insufficient" }

      let(:known_status) { double("shell_out", stdout: "Overall Status: Insufficient") }

      it "returns false" do
        allow(provider).to receive(:shell_out).and_return(known_status)
        expect(provider.registered_with_rhsm?).to eq(false)
      end
    end
  end
end
