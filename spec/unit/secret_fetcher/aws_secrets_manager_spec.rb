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
#

require_relative "../../spec_helper"
require "chef/secret_fetcher/aws_secrets_manager"

describe Chef::SecretFetcher::AWSSecretsManager do
  let(:node) { {} }
  let(:aws_global_config) { {} }
  let(:fetcher_config) { {} }
  let(:run_context) { double("run_context", node: node) }
  let(:fetcher) {
    Chef::SecretFetcher::AWSSecretsManager.new( fetcher_config, run_context )
  }

  before do
    allow(Aws).to receive(:config).and_return(aws_global_config)
  end

  context "when region is provided" do
    let(:fetcher_config) { { region: "region-from-caller" } }
    it "uses the provided region" do
      fetcher.validate!
      expect(fetcher.config[:region]).to eq "region-from-caller"
    end
  end

  context "when region is not provided" do
    context "and no region exists in AWS config or node attributes" do
      it "raises a ConfigurationInvalid error" do
        expect { fetcher.validate! }.to raise_error Chef::Exceptions::Secret::ConfigurationInvalid
      end
    end

    context "and region exists in AWS config and node attributes" do
      let(:aws_global_config)  { { region: "region-from-aws-global-config" } }
      let(:node) { { "ec2" => { "region" => "region-from-ohai-data" } } }
      it "uses the region from AWS config" do
        fetcher.validate!
        expect(fetcher.config[:region]).to eq "region-from-aws-global-config"
      end
    end

    context "and region exists only in node attributes" do
      let(:node) { { "ec2" => { "region" => "region-from-ohai-data" } } }
      it "uses the region from AWS config" do
        fetcher.validate!
        expect(fetcher.config[:region]).to eq "region-from-ohai-data"
      end

    end

  end
end
