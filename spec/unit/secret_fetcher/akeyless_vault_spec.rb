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
require "chef/secret_fetcher/akeyless_vault"

describe Chef::SecretFetcher::AKeylessVault do
  let(:node) { {} }
  let(:run_context) { double("run_context", node: node) }

  context "when validating provided AKeyless Vault configuration" do
    it "raises ConfigurationInvalid when :secret_access_key is not provided" do
      fetcher = Chef::SecretFetcher::AKeylessVault.new( { access_id: "provided" }, run_context)
      expect { fetcher.validate! }.to raise_error(Chef::Exceptions::Secret::ConfigurationInvalid, /:secret_access_key/)
    end

    it "raises ConfigurationInvalid when :access_key_id is not provided" do
      fetcher = Chef::SecretFetcher::AKeylessVault.new( { access_key: "provided" }, run_context)
      expect { fetcher.validate! }.to raise_error(Chef::Exceptions::Secret::ConfigurationInvalid, /:access_key_id/)
    end
  end
end
