
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

require_relative "../../spec_helper"
require "chef/secret_fetcher"
require "chef/secret_fetcher/azure_key_vault"

describe Chef::SecretFetcher::AzureKeyVault do
  let(:config) { { vault: "my_vault" } }
  let(:fetcher) { Chef::SecretFetcher::AzureKeyVault.new(config, nil) }

  context "when performing a fetch" do
    let(:body) { '{ "value" : "my secret value" }' }
    let(:response_mock) { double("response", body: body) }
    let(:http_mock) { double("http", :get => response_mock, :use_ssl= => nil) }

    before do
      allow(fetcher).to receive(:fetch_token).and_return "a token"
      allow(Net::HTTP).to receive(:new).and_return(http_mock)
    end

    context "and vault name is only provided in the secret name" do
      let(:body) { '{ "value" : "my secret value" }' }
      let(:config) { {} }
      it "fetches the value" do
        expect(fetcher.fetch("my_vault/value")).to eq "my secret value"
      end
    end

    context "and vault name is not provided in the secret name" do
      context "and vault name is not provided in config" do
        let(:config) { {} }
        it "raises a ConfigurationInvalid exception" do
          expect { fetcher.fetch("value") }.to raise_error(Chef::Exceptions::Secret::ConfigurationInvalid)
        end
      end

      context "and vault name is provided in config" do
        let(:config) { { vault: "my_vault" } }
        it "fetches the value" do
          expect(fetcher.fetch("value")).to eq "my secret value"
        end
      end
    end
    context "and an error response is received in the body" do
      let(:config) { { vault: "my_vault" } }
      let(:body) { '{ "error" : { "code" : 404, "message" : "secret not found" } }' }
      it "raises FetchFailed" do
        expect { fetcher.fetch("value") }.to raise_error(Chef::Exceptions::Secret::FetchFailed)
      end
    end
  end
end

