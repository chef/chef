#
# Author:: Marc Paradise <marc@chef.io>
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

require_relative "../../spec_helper"
require "chef/secret_fetcher/hashi_vault"

describe Chef::SecretFetcher::HashiVault do
  let(:node) { {} }
  let(:run_context) { double("run_context", node: node) }

  context "when validating provided HashiVault configuration" do
    it "raises ConfigurationInvalid when the :auth_method is not valid" do
      fetcher = Chef::SecretFetcher::HashiVault.new( { auth_method: :invalid, vault_addr: "https://vault.example.com:8200" }, run_context)
      expect { fetcher.validate! }.to raise_error(Chef::Exceptions::Secret::ConfigurationInvalid, /:auth_method/)
    end

    it "raises ConfigurationInvalid when the vault_addr is not provided" do
      fetcher = Chef::SecretFetcher::HashiVault.new( { auth_method: :iam_role, role_name: "example-role" }, run_context)
      expect { fetcher.validate! }.to raise_error(Chef::Exceptions::Secret::ConfigurationInvalid)
    end

    context "and using auth_method: :iam_role" do
      it "raises ConfigurationInvalid when the role_name is not provided" do
        fetcher = Chef::SecretFetcher::HashiVault.new( { auth_method: :iam_role, vault_addr: "https://vault.example.com:8200" }, run_context)
        expect { fetcher.validate! }.to raise_error(Chef::Exceptions::Secret::ConfigurationInvalid)
      end

      it "obtains a token via AWS IAM auth to allow the gem to do its own validations when all required config is provided" do
        fetcher = Chef::SecretFetcher::HashiVault.new( { auth_method: :iam_role, vault_addr: "https://vault.example.com:8200", role_name: "example-role" }, run_context)
        allow(Aws::InstanceProfileCredentials).to receive(:new).and_return instance_double(Aws::InstanceProfileCredentials)
        auth_double = instance_double(Vault::Authenticate)
        expect(auth_double).to receive(:aws_iam)
        allow(Vault).to receive(:auth).and_return(auth_double)
        fetcher.validate!
      end
    end

    context "and using auth_method: :token" do
      it "raises ConfigurationInvalid when no token is provided" do
        fetcher = Chef::SecretFetcher::HashiVault.new( { auth_method: :token, vault_addr: "https://vault.example.com:8200" }, run_context)
        expect { fetcher.validate! }.to raise_error(Chef::Exceptions::Secret::ConfigurationInvalid)
      end

      it "authenticates using the token during validation when all configuration is correct" do
        fetcher = Chef::SecretFetcher::HashiVault.new( { auth_method: :token, token: "t.1234abcd", vault_addr: "https://vault.example.com:8200" }, run_context)
        auth = instance_double(Vault::Authenticate)
        auth_double = instance_double(Vault::Authenticate)
        expect(auth_double).to receive(:token)
        allow(Vault).to receive(:auth).and_return(auth_double)
        fetcher.validate!
      end
    end

    context "and using auth_method: :approle" do
      it "raises ConfigurationInvalid message when :approle_name or :approle_id are not specified" do
        fetcher = Chef::SecretFetcher::HashiVault.new( { auth_method: :approle, vault_addr: "https://vault.example.com:8200" }, run_context)
        expect { fetcher.validate! }.to raise_error(Chef::Exceptions::Secret::ConfigurationInvalid)
      end

      it "authenticates using the approle_id and approle_secret_id during validation when all configuration is correct" do
        fetcher = Chef::SecretFetcher::HashiVault.new({
          auth_method: :approle,
          approle_id: "idguid",
          approle_secret_id: "secretguid",
          vault_addr: "https://vault.example.com:8200" },
          run_context)
        auth = instance_double(Vault::Authenticate)
        allow(auth).to receive(:approle)
        allow(Vault).to receive(:auth).and_return(auth)
        expect(auth).to receive(:approle).with("idguid", "secretguid")
        fetcher.validate!
      end

      it "looks up the :role_id and :secret_id when all configuration is correct" do
        fetcher = Chef::SecretFetcher::HashiVault.new({
          auth_method: :approle,
          approle_name: "myapprole",
          token: "t.1234abcd",
          vault_addr: "https://vault.example.com:8200" },
          run_context)
        approle = instance_double(Vault::AppRole)
        auth = instance_double(Vault::Authenticate)
        allow(Vault).to receive(:approle).and_return(approle)
        allow(approle).to receive(:role_id).with("myapprole").and_return("idguid")
        allow(approle).to receive(:create_secret_id).with("myapprole").and_return(Vault::Secret.new({
          data: {
            secret_id: "secretguid",
            secret_id_accessor: "accessor_guid",
            secret_id_ttl: 0,
          },
          lease_duration: 0,
          lease_id: "",
        }))
        allow(Vault).to receive(:auth).and_return(auth)
        expect(auth).to receive(:approle).with("idguid", "secretguid")
        fetcher.validate!
      end
    end
  end

  context "when fetching a secret from Hashi Vault" do
    it "raises an FetchFailed message when no secret is returned due to invalid engine path" do
      fetcher = Chef::SecretFetcher::HashiVault.new( { auth_method: :invalid, vault_addr: "https://vault.example.com:8200" }, run_context)
      logical_double = instance_double(Vault::Logical)
      expect(logical_double).to receive(:read).and_return nil
      expect(Vault).to receive(:logical).and_return(logical_double)
      expect { fetcher.do_fetch("anything", nil) }.to raise_error(Chef::Exceptions::Secret::FetchFailed)
    end
  end
end
