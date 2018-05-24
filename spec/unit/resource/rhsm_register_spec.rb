#
# Copyright:: Copyright 2018, Chef Software, Inc.
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

  describe "#katello_cert_rpm_installed?" do
    let(:cmd) { double("cmd") }

    before do
      allow(Mixlib::ShellOut).to receive(:new).and_return(cmd)
      allow(cmd).to receive(:run_command)
    end

    context "when the output contains katello-ca-consumer" do
      it "returns true" do
        allow(cmd).to receive(:stdout).and_return("katello-ca-consumer-somehostname-1.0-1")
        expect(provider.katello_cert_rpm_installed?).to eq(true)
      end
    end

    context "when the output does not contain katello-ca-consumer" do
      it "returns false" do
        allow(cmd).to receive(:stdout).and_return("katello-agent-but-not-the-ca")
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

  describe "#registered_with_rhsm?" do
    let(:cmd) { double("cmd") }

    before do
      allow(Mixlib::ShellOut).to receive(:new).and_return(cmd)
      allow(cmd).to receive(:run_command)
    end

    context "when the status is Unknown" do
      it "returns false" do
        allow(cmd).to receive(:stdout).and_return("Overall Status: Unknown")
        expect(provider.registered_with_rhsm?).to eq(false)
      end
    end

    context "when the status is anything else" do
      it "returns true" do
        allow(cmd).to receive(:stdout).and_return("Overall Status: Insufficient")
        expect(provider.registered_with_rhsm?).to eq(true)
      end
    end
  end
end
