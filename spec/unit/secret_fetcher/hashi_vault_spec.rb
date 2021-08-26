#
# Author:: Marc Paradise <marc@chef.io>
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
#

require_relative "../../spec_helper"
require "chef/secret_fetcher/hashi_vault"

describe Chef::SecretFetcher::HashiVault do
  let(:node) { {} }
  let(:run_context) { double("run_context", node: node) }
  let(:fetcher_config) { {} }
  let(:fetcher) {
    Chef::SecretFetcher::HashiVault.new( fetcher_config, run_context )
  }

  context "when validating HashiVault provided configuration" do
    context "and role_name is not provided" do
      let(:fetcher_config) { { vault_addr: "vault.example.com" } }
      it "raises ConfigurationInvalid" do
        expect { fetcher.validate! }.to raise_error(Chef::Exceptions::Secret::ConfigurationInvalid)
      end
    end
    context "and vault_addr is not provided" do
      let(:fetcher_config) { { role_name: "example-role" } }
      it "raises ConfigurationInvalid" do
        expect { fetcher.validate! }.to raise_error(Chef::Exceptions::Secret::ConfigurationInvalid)
      end
    end
  end

  context "when all required config is provided" do
    let(:fetcher_config) { { vault_addr: "vault.example.com", role_name: "example-role" } }
    it "obtains a token via AWS IAM auth" do
      auth_stub = double("vault auth", aws_iam: nil)
      allow(Aws::InstanceProfileCredentials).to receive(:new).and_return double("credentials")
      allow(Vault).to receive(:auth).and_return(auth_stub)
      fetcher.validate!

    end
  end
end

