
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
require "chef/secret_fetcher"
require "chef/secret_fetcher/azure_key_vault"
require "net/http/responses"

describe Chef::SecretFetcher::AzureKeyVault do
  let(:config) { { vault: "my-vault" } }
  let(:fetcher) { Chef::SecretFetcher::AzureKeyVault.new(config, nil) }
  let(:secrets_response_body) { '{ "value" : "my secret value" }' }
  let(:secrets_response_mock) do
    rm = Net::HTTPSuccess.new("1.0", "400", "OK")
    allow(rm).to receive(:body).and_return(secrets_response_body)
    rm
  end
  let(:token_response_body) { %Q({"access_token":"#{access_token}","client_id":"#{client_id}","expires_in":"86294","expires_on":"1627761860","ext_expires_in":"86399","not_before":"1627675160","resource":"https://vault.azure.net","token_type":"Bearer"}) }
  let(:access_token) { "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Im5PbzNaRHJPRFhFSzFqS1doWHNsSFJfS1hFZyIsImtpZCI6Im5PbzNaRHJPRFhFSzFqS1doWHNsSFJfS1hFZyJ9.eyJhdWQiOiJodHRwczovL3ZhdWx0LmF6dXJlLm5ldCIsImlzcyI6Imh0dHBzOi8vc3RzLndpbmRvd3MubmV0L2E5ZTY2ZDhkLTA1ZTAtNGMwMC1iOWRkLWM0Yjc3M2U5MWNhNi8iLCJpYXQiOjE2Mjc2NzUxNjAsIm5iZiI6MTYyNzY3NTE2MCwiZXhwIjoxNjI3NzYxODYwLCJhaW8iOiJFMlpnWUhCWGplaTdWS214eEh6bjdoSWpNZFlMQUE9PSIsImFwcGlkIjoiNjU2Mjc1MjEtMzYzYi00ZDk2LTkyMTctMjcIsIm9pZCI6IjNiZjI1NjVhLWY4NWQtNDBiNy1hZWJkLTNlZDA1ZDA0N2FmNiIsInJoIjoiMC5BUk1BalczbXFlQUZBRXk1M2NTM2Mta2NwaUYxWW1VN05wWk5raGNuRGpuZEwxb1RBQUEuIiwic3ViIjoiM2JmMjU2NWEtZjg1ZC00MGI3LWFlYmQtM2VkMDVkMDQ3YWY2IiwidGlkIjoiYTllNjZkOGQtMDVlMC00YzAwLWI5ZGQtYzRiNzczZTkxY2E2IiwidXRpIjoibXlzeHpSRTV3ay1ibTFlYkNqc09BQSIsInZlciI6IjEuMCIsInhtc19taXJpZCI6Ii9zdWJzY3JpcHRpb25zLzYzNDJkZDZkLTc1NTQtNDJjOS04NTM2LTdkZmU3MmY1MWZhZC9yZXNvdXJjZWdyb3Vwcy9pbWFnZS1waXBlbGluZS1ydW5uZXItcWEtZWFzdHVzMi1yZy9wcm92aWRlcnMvTWljcm9zb2Z0Lk1hbmFnZWRJZGVudGl0eS91c2VyQXNzaWduZWRJZGVudGl0aWVzL2ltYWdlLXBpcGVsaW5lLXJ1bm5lci1xYS1lYXN0dXMyLW1pIn0.BquzjN6d0g4zlvkbkdVwNEfRxIXSmxYwCHMk6UG3iza2fVioiOrcoP4Cp9P5--AB4G_CAhIXaP7YIZs3mq05QiDjSvkVAM0t67UPGhEr66sNXkV72iZBnKca_auh6EHsjPfxeVHkE1wdrsncrYdKhzgO4IAj8Jg4N5qjcE2q-OkliadmEuTwrhPhq" }
  let(:token_response_mock) do
    rm = Net::HTTPSuccess.new("1.0", "400", "OK")
    allow(rm).to receive(:body).and_return(token_response_body)
    rm
  end
  let(:client_id) { SecureRandom.uuid }
  let(:http_mock) { instance_double("Net::HTTP", :use_ssl= => nil) }
  let(:token_uri) { URI.parse("http://169.254.169.254/metadata/identity/oauth2/token") }
  let(:vault_name) { "my-vault" }
  let(:secret_name) { "my-secret" }
  let(:vault_secret_uri) { URI.parse("https://#{vault_name}.vault.azure.net/secrets/#{secret_name}/?api-version=7.2") }

  before do
    # Cache these up front so we can pass into allow statements without hitting:
    #   URI received :parse with unexpected arguments
    token_uri
    vault_secret_uri
  end

  before do
    allow(Net::HTTP).to receive(:new).and_return(http_mock)
    allow(URI).to receive(:parse).with("http://169.254.169.254/metadata/identity/oauth2/token").and_return(token_uri)
    allow(URI).to receive(:parse).with("https://#{vault_name}.vault.azure.net/secrets/#{secret_name}/?api-version=7.2").and_return(vault_secret_uri)
    allow(http_mock).to receive(:get).with(token_uri, { "Metadata" => "true" }).and_return(token_response_mock)
    allow(http_mock).to receive(:get).with(vault_secret_uri, { "Authorization" => "Bearer #{access_token}", "Content-Type" => "application/json" }).and_return(secrets_response_mock)
  end

  describe "#validate!" do
    it "raises error when more than one is provided: :object_id, :client_id, :mi_res_id" do
      expect { Chef::SecretFetcher::AzureKeyVault.new({ object_id: "abc", client_id: "abc", mi_res_id: "abc" }, nil).validate! }.to raise_error(Chef::Exceptions::Secret::ConfigurationInvalid)
      expect { Chef::SecretFetcher::AzureKeyVault.new({ object_id: "abc", client_id: "abc" }, nil).validate! }.to raise_error(Chef::Exceptions::Secret::ConfigurationInvalid)
      expect { Chef::SecretFetcher::AzureKeyVault.new({ object_id: "abc", mi_res_id: "abc" }, nil).validate! }.to raise_error(Chef::Exceptions::Secret::ConfigurationInvalid)
      expect { Chef::SecretFetcher::AzureKeyVault.new({ client_id: "abc", mi_res_id: "abc" }, nil).validate! }.to raise_error(Chef::Exceptions::Secret::ConfigurationInvalid)
    end
  end

  describe "#fetch_token" do
    context "when Net::HTTPBadRequest is returned and the error description contains \"Identity not found\"" do
      let(:token_response_mock) { Net::HTTPBadRequest.new("1.0", "400", "Bad Request") }

      before do
        allow(fetcher).to receive(:fetch_token).and_call_original
        allow(token_response_mock).to receive(:body).and_return('{"error":"invalid_request","error_description":"Identity not found"}')
      end

      it "raises Chef::Exceptions::Secret::Azure::IdentityNotFound" do
        expect { fetcher.send(:fetch_token) }.to raise_error(Chef::Exceptions::Secret::Azure::IdentityNotFound)
      end
    end

    context "when :object_id is provided" do
      let(:object_id) { SecureRandom.uuid }
      let(:config) { { vault: "my-vault", object_id: object_id } }

      it "adds client_id to request params" do
        fetcher.send(:fetch_token)
        expect(token_uri.query).to match(/object_id=#{object_id}/)
      end
    end

    context "when :client_id is provided" do
      let(:config) { { vault: "my-vault", client_id: client_id } }

      it "adds client_id to request params" do
        fetcher.send(:fetch_token)
        expect(token_uri.query).to match(/client_id=#{client_id}/)
      end
    end

    context "when :mi_res_id is provided" do
      let(:mi_res_id) { SecureRandom.uuid }
      let(:config) { { vault: "my-vault", mi_res_id: mi_res_id } }

      it "adds client_id to request params" do
        fetcher.send(:fetch_token)
        expect(token_uri.query).to match(/mi_res_id=#{mi_res_id}/)
      end
    end
  end

  describe "#fetch" do
    context "when vault name is only provided in the secret name" do
      let(:secrets_response_body) { '{ "value" : "my secret value" }' }
      let(:config) { {} }
      it "fetches the value" do
        expect(fetcher.fetch("my-vault/my-secret")).to eq "my secret value"
      end
    end

    context "when vault name is not provided in the secret name" do
      context "and vault name is not provided in config" do
        let(:config) { {} }
        it "raises a ConfigurationInvalid exception" do
          expect { fetcher.fetch("my-secret") }.to raise_error(Chef::Exceptions::Secret::ConfigurationInvalid)
        end
      end

      context "and vault name is provided in config" do
        let(:config) { { vault: "my-vault" } }
        it "fetches the value" do
          expect(fetcher.fetch("my-secret")).to eq "my secret value"
        end
      end
    end

    context "when an error response is received in the response body" do
      let(:config) { { vault: "my-vault" } }
      let(:secrets_response_body) { '{ "error" : { "code" : 404, "message" : "secret not found" } }' }
      it "raises FetchFailed" do
        expect { fetcher.fetch("my-secret") }.to raise_error(Chef::Exceptions::Secret::FetchFailed)
      end
    end
  end
end
