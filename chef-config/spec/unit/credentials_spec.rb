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
require "chef-config/config"
require "chef-config/mixin/credentials"

module Vault
  class Client; end
end

RSpec.describe ChefConfig::Mixin::Credentials do

  let(:test_class) { Class.new { include ChefConfig::Mixin::Credentials } }
  subject(:test_obj) { test_class.new }

  describe "#credentials_profile" do
    context "when an explicit profile is given" do
      it "passes it through" do
        expect(test_obj.credentials_profile("webserver")).to eq("webserver")
      end
    end

    context "when an environment variable is set" do
      before(:all) do
        @original_env = ENV.to_hash
      end

      after(:all) do
        ENV.clear
        ENV.update(@original_env)
      end

      before(:each) do
        ENV["CHEF_PROFILE"] = "acme-server"
      end

      it "picks the profile correctly" do
        expect(test_obj.credentials_profile).to eq("acme-server")
      end
    end

    context "when no profile is given" do
      it "picks the default one" do
        expect(test_obj.credentials_profile).to eq("default")
      end
    end
  end

  describe "#resolve_secrets" do
    context "when no credentials were loaded" do
      it "returns" do
        allow(test_obj).to receive(:credentials_config).and_return(nil)
        expect(test_obj.resolve_secrets("dummy")).to eq(nil)
      end
    end

    context "when credentials do not contain specified profile" do
      it "raises an error" do
        allow(test_obj).to receive(:credentials_config).and_return({ "webserver" => {} })
        expect { test_obj.resolve_secrets("dummy") }.to raise_error(ChefConfig::NoCredentialsFound, /No credentials found for profile/)
      end
    end

    context "when no secrets were referenced in profile" do
      it "returns" do
        allow(test_obj).to receive(:credentials_config).and_return({ "webserver2" => {} })
        expect(test_obj.resolve_secrets("webserver2")).to eq(nil)
      end
    end
  end

  describe "#valid_secrets_provider?" do
    context "when global, valid configuration was provided" do
      let(:global_options) { { "default_secrets_provider" => { "name" => "hashicorp-vault", "endpoint" => "https://198.51.100.5:8200", "token" => "hvs.1234567890" } } }
      let(:secrets_config) { { "secret" => "/chef/sudo_password", "field" => "password" } }

      it "returns true" do
        allow(test_obj).to receive(:global_options).and_return(global_options)
        expect(test_obj.valid_secrets_provider?(secrets_config)).to be(true)
      end
    end

    context "when global, invalid configuration was provided" do
      let(:global_options) { { "default_secrets_provider" => { "name" => "hashicorp-consul" } } }
      let(:secrets_config) { { "secret" => "/chef/sudo_password", "field" => "password" } }

      it "returns false" do
        allow(test_obj).to receive(:global_options).and_return(global_options)
        expect(test_obj.valid_secrets_provider?(secrets_config)).to be(false)
      end
    end

    context "when global, invalid configuration is overridden with a correct value" do
      let(:global_options) { { "default_secrets_provider" => { "name" => "hashicorp-consul" } } }
      let(:secrets_config) { { "secrets_provider" => { "name" => "hashicorp-vault" }, "secret" => "/chef/sudo_password", "field" => "password" } }

      it "returns false" do
        allow(test_obj).to receive(:global_options).and_return(global_options)
        expect(test_obj.valid_secrets_provider?(secrets_config)).to be(true)
      end
    end
  end

  describe "#resolve_secret" do
    before do
      allow(test_obj).to receive(:global_options).and_return(global_options)

      # Simulate "vault" gem
      allow(test_obj).to receive(:require).with("vault")
      vault_double = double("Vault::Client")
      allow(vault_double).to receive_message_chain("logical.read") { secrets_result }
      allow(vault_double).to receive_message_chain("kv.read.data") { secrets_result }
      test_obj.instance_variable_set(:@vault, vault_double)

      # Simulate "jmespath" gem
      allow(test_obj).to receive(:require).with("jmespath")
      jmespath_double = double("JMESPath")
      allow(jmespath_double).to receive_message_chain("search") { search_for = secrets_config["field"]; secrets_result[search_for] }
      stub_const("::JMESPath", jmespath_double)
    end

    context "without default secrets provider being set" do
      let(:global_options) {}

      context "for a secret of type string" do
        let(:secrets_result) { "secret" }
        let(:secrets_config) { { "secrets_provider" => { "name" => "hashicorp-vault" }, "secret" => "/chef/sudo_password" } }

        it "returns the complete value" do
          expect(test_obj.resolve_secret(secrets_config)).to eq("secret")
        end
      end

      context "for a secret of type hash" do
        let(:secrets_result) { { "password" => "secret" } }
        let(:secrets_config) { { "secrets_provider" => { "name" => "hashicorp-vault", "endpoint" => "https://198.51.100.5:8200", "token" => "hvs.1234567890" }, "secret" => "/chef/sudo_password", "field" => "password" } }

        it "returns the correct subkey" do
          expect(test_obj.resolve_secret(secrets_config)).to eq("secret")
        end
      end
    end

    context "with default secrets provider being set" do
      let(:global_options) { { "default_secrets_provider" => { "name" => "hashicorp-vault", "endpoint" => "https://198.51.100.5:8200", "token" => "hvs.1234567890" } } }

      context "for a secret of type string" do
        let(:secrets_result) { "secret" }
        let(:secrets_config) { { "secret" => "/chef/sudo_password" } }

        it "returns the complete value" do
          expect(test_obj.resolve_secret(secrets_config)).to eq("secret")
        end
      end

      context "for a secret of type hash" do
        let(:secrets_result) { { "password" => "secret" } }
        let(:secrets_config) { { "secret" => "/chef/sudo_password", "field" => "password" } }

        it "returns the correct subkey" do
          expect(test_obj.resolve_secret(secrets_config)).to eq("secret")
        end
      end
    end
  end
end
