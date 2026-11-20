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
require "chef/licensing"

describe Chef::Licensing do
  # Start from an environment with none of the variables that mark a CI run,
  # so the specs behave the same whether or not they run in CI.
  let(:env) { ENV.to_hash.reject { |k, _| %w{TEST_KITCHEN GITHUB_ACTIONS BUILDKITE CI}.include?(k) } }

  before do
    stub_const("ENV", env)
    allow(ChefUtils).to receive(:docker?).and_return(false)
  end

  after { ChefLicensing::Config.make_licensing_optional = false }

  describe ".check_software_entitlement_compliance_phase!" do
    context "in a CI environment" do
      let(:env) { super().merge("GITHUB_ACTIONS" => "true") }

      it "does not contact the licensing server" do
        expect(ChefLicensing).not_to receive(:check_software_entitlement!)
        described_class.check_software_entitlement_compliance_phase!
      end

      it "leaves the Infra entitlement ID in place" do
        described_class.check_software_entitlement_compliance_phase!
        expect(ChefLicensing::Config.chef_entitlement_id).to eq(Chef::LicensingConfig::INFRA_ENTITLEMENT_ID)
      end

      it "makes the check InSpec's runner does a no-op" do
        described_class.check_software_entitlement_compliance_phase!
        expect(ChefLicensing::Config.make_licensing_optional).to be true
        expect(ChefLicensing).not_to receive(:client)
        expect(ChefLicensing.check_software_entitlement!).to be true
      end
    end

    context "in a CI environment inside docker" do
      let(:env) { super().merge("GITHUB_ACTIONS" => "true") }

      before { allow(ChefUtils).to receive(:docker?).and_return(true) }

      it "checks the compliance entitlement" do
        expect(ChefLicensing).to receive(:check_software_entitlement!)
        described_class.check_software_entitlement_compliance_phase!
        expect(ChefLicensing::Config.make_licensing_optional).to be false
      end
    end

    context "outside CI" do
      it "checks the compliance entitlement, then restores the Infra entitlement ID" do
        expect(ChefLicensing).to receive(:check_software_entitlement!) do
          expect(ChefLicensing::Config.chef_entitlement_id).to eq(Chef::LicensingConfig::COMPLIANCE_ENTITLEMENT_ID)
        end
        described_class.check_software_entitlement_compliance_phase!
        expect(ChefLicensing::Config.chef_entitlement_id).to eq(Chef::LicensingConfig::INFRA_ENTITLEMENT_ID)
      end

      it "raises EntitlementError when the license is not entitled" do
        allow(ChefLicensing).to receive(:check_software_entitlement!).and_raise(ChefLicensing::SoftwareNotEntitled)
        expect { described_class.check_software_entitlement_compliance_phase! }.to raise_error(Chef::Licensing::EntitlementError)
      end
    end
  end

  describe ".check_software_entitlement!" do
    context "in a CI environment" do
      let(:env) { super().merge("CI" => "true") }

      it "does not contact the licensing server" do
        expect(ChefLicensing).not_to receive(:check_software_entitlement!)
        described_class.check_software_entitlement!
      end
    end
  end
end
