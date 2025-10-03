#
# Copyright © 2008-2025 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require "knife_spec_helper"
require "chef/utils/licensing_handler"

describe Chef::Utils::LicensingHandler do
  let(:license_key) { "abc123" }
  let(:license_type) { "commercial" }
  let(:handler) { described_class.new(license_key, license_type) }

  describe "#initialize" do
    it "sets the license key and type" do
      expect(handler.license_key).to eq(license_key)
      expect(handler.license_type).to eq(license_type)
    end
  end

  describe "#omnitruck_url" do
    context "with a commercial license" do
      it "returns the commercial URL with the license key" do
        expected_url = "https://chefdownload-commerical.chef.io/%s?license_id=abc123"
        expect(handler.omnitruck_url).to eq(expected_url)
      end
    end

    context "with a trial license" do
      let(:license_type) { "trial" }

      it "returns the trial URL with the license key" do
        expected_url = "https://chefdownload-trial.chef.io/%s?license_id=abc123"
        expect(handler.omnitruck_url).to eq(expected_url)
      end
    end

    context "with a free license" do
      let(:license_type) { "free" }

      it "returns the free (trial) URL with the license key" do
        expected_url = "https://chefdownload-trial.chef.io/%s?license_id=abc123"
        expect(handler.omnitruck_url).to eq(expected_url)
      end
    end

    context "with an unknown license type" do
      let(:license_type) { "unknown" }

      it "returns the legacy URL without the license key" do
        expected_url = "https://omnitruck.chef.io/%s"
        expect(handler.omnitruck_url).to eq(expected_url)
      end
    end

    context "with no license key" do
      let(:license_key) { nil }
      let(:license_type) { nil }

      it "returns the legacy URL without a license ID parameter" do
        expected_url = "https://omnitruck.chef.io/%s"
        expect(handler.omnitruck_url).to eq(expected_url)
      end
    end
  end

  describe "#install_sh_url" do
    it "formats the omnitruck URL with install.sh" do
      expect(handler).to receive(:omnitruck_url).and_return("https://example.com/%s?license_id=abc123")
      expect(handler.install_sh_url).to eq("https://example.com/install.sh?license_id=abc123")
    end
  end

  describe ".validate!" do
    let(:license_keys) { ["abc123"] }
    let(:license_metadata) do
      double("license_metadata", id: license_key, license_type: license_type)
    end
    let(:licenses_metadata) { [license_metadata] }

    before do
      allow(ChefLicensing::LicenseKeyFetcher).to receive(:fetch).and_return(license_keys)
      allow(ChefLicensing::Api::Describe).to receive(:list).and_return(licenses_metadata)
    end

    context "when license keys are available" do
      it "returns a new handler with the license key and type" do
        handler = described_class.validate!
        expect(handler.license_key).to eq(license_key)
        expect(handler.license_type).to eq(license_type)
      end

      it "fetches license keys using ChefLicensing::LicenseKeyFetcher" do
        expect(ChefLicensing::LicenseKeyFetcher).to receive(:fetch).and_return(license_keys)
        described_class.validate!
      end

      it "gets license metadata using ChefLicensing::Api::Describe" do
        expect(ChefLicensing::Api::Describe).to receive(:list).with({
          license_keys: license_keys,
        }).and_return(licenses_metadata)
        described_class.validate!
      end
    end

    context "when no license keys are available" do
      let(:license_keys) { [] }

      it "returns a new handler with nil license key and type" do
        handler = described_class.validate!
        expect(handler.license_key).to be_nil
        expect(handler.license_type).to be_nil
      end
    end

    context "when ChefLicensing::RestfulClientConnectionError is raised" do
      before do
        allow(ChefLicensing::LicenseKeyFetcher).to receive(:fetch).and_raise(ChefLicensing::RestfulClientConnectionError)
      end

      it "returns a new handler with nil license key and type" do
        handler = described_class.validate!
        expect(handler.license_key).to be_nil
        expect(handler.license_type).to be_nil
      end
    end
  end
end
