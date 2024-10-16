#
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

require "knife_spec_helper"
require "chef-licensing"

describe Chef::Knife::License do
  include SpecHelpers::Knife

  let(:knife) { described_class.new }

  context "arguments" do
    it "should have the chef-license-key as an option" do
      expect(knife.options).to include(:chef_license_key)
    end
  end

  context "license command" do
    it "should invoke the fetch and persist" do
      expect(ChefLicensing).to receive(:fetch_and_persist).and_return([])

      knife.run
    end

    it "should print the key returned from the chef-licensing" do
      allow(ChefLicensing).to receive(:fetch_and_persist).and_return(["key-123"])

      expect(knife.run).to eq(["key-123"])
      expect(knife.ui).to receive(:msg).and_return("License Key: key-123")
      knife.run
    end

    it "should fail if no license provided" do
      allow(STDOUT).to receive(:isatty).and_return(false)
      ChefLicensing.configure do |c|
        c.output = STDOUT
      end

      expect { knife.run }.to raise_error(ChefLicensing::LicenseKeyFetcher::LicenseKeyNotFetchedError, "Unable to obtain a License Key.")
    end
  end

  context "license list command" do
    before do
      allow(STDOUT).to receive(:isatty).and_return(false)
      ChefLicensing.configure do |c|
        c.output = STDOUT
      end
    end

    it "should invoke list command method" do
      with_argv(%w{license list}) do
        expect(ChefLicensing).to receive(:list_license_keys_info).and_return(["key-123"])

        knife.run
      end
    end
  end

  context "license add command" do
    before do
      allow(STDOUT).to receive(:isatty).and_return(false)
      ChefLicensing.configure do |c|
        c.output = STDOUT
      end
    end

    it "should invoke license add method" do
      with_argv(%w{license add --chef-license-key key-123}) do
        expect(ChefLicensing).to receive(:add_license).and_return(true)

        knife.run
      end
    end
  end
end