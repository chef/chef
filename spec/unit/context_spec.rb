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
require "chef/context"
require "openssl"

describe Chef::Context do
  describe "when executed normally" do
    before(:each) do
      described_class.send(:reset_context)
      allow(ENV).to receive(:fetch).with("IS_KITCHEN", "").and_return("")
    end

    it "#test_kitchen_context? should return false" do
      expect(described_class.test_kitchen_context?).to be_falsey
    end

    it "#fetch_env_value should be empty" do
      expect(described_class.send(:fetch_env_value)).to eq("")
    end
  end

  context "when executed from test kitchen" do
    before(:each) do
      described_class.send(:reset_context)
      allow(ENV).to receive(:fetch).with("IS_KITCHEN", "").and_return("true")
    end

    it "#fetch_env_value should return true" do
      expect(described_class.send(:fetch_env_value)).to eq("true")
    end

    it "#test_kitchen_context? should return true" do
      expect(described_class.test_kitchen_context?).to eq(true)
    end
  end

  context "when switching to workstation entitlement" do
    it "should set the entitlement ID to the workstation ID" do
      described_class.switch_to_workstation_entitlement
      expect(ChefLicensing::Config.chef_entitlement_id).to eq(Chef::LicensingConfig::WORKSTATION_ENTITLEMENT_ID)
    end
  end
end
