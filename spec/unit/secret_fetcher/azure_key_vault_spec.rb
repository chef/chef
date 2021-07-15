
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
  let(:config) { { vault: "myvault" } }
  let(:fetcher) { Chef::SecretFetcher::AzureKeyVault.new(config) }

  context "when validating configuration and configuration is missing :vault" do
    context "and configuration does not have a 'vault'" do
      let(:config) { { } }
      it "raises a MissingVaultError error on validate!" do
        expect{fetcher.validate!}.to raise_error(Chef::Exceptions::Secret::MissingVaultName)
      end
    end
  end

  context "when performing a fetch" do
    let(:body) { "" }
    let(:response_mock) { double("response", body: body) }
    let(:http_mock) { double("http", :get => response_mock, :use_ssl= => nil) }

    before do
      allow(fetcher).to receive(:fetch_token).and_return "a token"
      allow(Net::HTTP).to receive(:new).and_return(http_mock)
    end

    context "and a valid response is received" do
      let(:body) { '{ "value" : "my secret value" }' }
      it "returns the expected response" do
        expect(fetcher.fetch("value")).to eq "my secret value"
      end
    end

    context "and an error response is received in the body" do
      let(:body) { '{ "error" : { "code" : 404, "message" : "secret not found" } }' }
      it "raises FetchFailed" do
        expect{fetcher.fetch("value")}.to raise_error(Chef::Exceptions::Secret::FetchFailed)
      end
    end

  end
end

