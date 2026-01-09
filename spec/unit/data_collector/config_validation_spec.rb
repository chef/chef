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
require "chef/data_collector/config_validation"

describe Chef::DataCollector::ConfigValidation do
  describe "#should_be_enabled?" do
    shared_examples_for "a solo-like run" do
      it "is disabled in solo-legacy without a data_collector url and token" do
        expect(Chef::DataCollector::ConfigValidation.should_be_enabled?).to be false
      end

      it "is disabled in solo-legacy with only a url" do
        Chef::Config[:data_collector][:server_url] = "https://www.esa.local/ariane5"
        expect(Chef::DataCollector::ConfigValidation.should_be_enabled?).to be false
      end

      it "is disabled in solo-legacy with only a token" do
        Chef::Config[:data_collector][:token] = "admit_one"
        expect(Chef::DataCollector::ConfigValidation.should_be_enabled?).to be false
      end

      it "is enabled in solo-legacy with both a token and url" do
        Chef::Config[:data_collector][:server_url] = "https://www.esa.local/ariane5"
        Chef::Config[:data_collector][:token] = "no_cash_value"
        expect(Chef::DataCollector::ConfigValidation.should_be_enabled?).to be true
      end

      it "is enabled in solo-legacy with only an output location to a file" do
        Chef::Config[:data_collector][:output_locations] = { files: [ "/always/be/counting/down" ] }
        expect(Chef::DataCollector::ConfigValidation.should_be_enabled?).to be true
      end

      it "is disabled in solo-legacy with only an output location to a uri" do
        Chef::Config[:data_collector][:output_locations] = { urls: [ "https://esa.local/ariane5" ] }
        expect(Chef::DataCollector::ConfigValidation.should_be_enabled?).to be false
      end

      it "is enabled in solo-legacy with only an output location to a uri with a token" do
        Chef::Config[:data_collector][:output_locations] = { urls: [ "https://esa.local/ariane5" ] }
        Chef::Config[:data_collector][:token] = "good_for_one_fare"
        expect(Chef::DataCollector::ConfigValidation.should_be_enabled?).to be true
      end

      it "is enabled in solo-legacy when the mode is :solo" do
        Chef::Config[:data_collector][:server_url] = "https://www.esa.local/ariane5"
        Chef::Config[:data_collector][:token] = "non_redeemable"
        Chef::Config[:data_collector][:mode] = :solo
        expect(Chef::DataCollector::ConfigValidation.should_be_enabled?).to be true
      end

      it "is enabled in solo-legacy when the mode is :both" do
        Chef::Config[:data_collector][:server_url] = "https://www.esa.local/ariane5"
        Chef::Config[:data_collector][:token] = "non_negotiable"
        Chef::Config[:data_collector][:mode] = :both
        expect(Chef::DataCollector::ConfigValidation.should_be_enabled?).to be true
      end

      it "is disabled in solo-legacy when the mode is :client" do
        Chef::Config[:data_collector][:server_url] = "https://www.esa.local/ariane5"
        Chef::Config[:data_collector][:token] = "NYCTA"
        Chef::Config[:data_collector][:mode] = :client
        expect(Chef::DataCollector::ConfigValidation.should_be_enabled?).to be false
      end

      it "is disabled in solo-legacy mode when the mode is :nonsense" do
        Chef::Config[:data_collector][:server_url] = "https://www.esa.local/ariane5"
        Chef::Config[:data_collector][:token] = "MTA"
        Chef::Config[:data_collector][:mode] = :nonsense
        expect(Chef::DataCollector::ConfigValidation.should_be_enabled?).to be false
      end
    end

    it "by default it is enabled" do
      expect(Chef::DataCollector::ConfigValidation.should_be_enabled?).to be true
    end

    it "is disabled in why-run" do
      Chef::Config[:why_run] = true
      expect(Chef::DataCollector::ConfigValidation.should_be_enabled?).to be false
    end

    describe "a solo legacy run" do
      before(:each) do
        Chef::Config[:solo_legacy_mode] = true
      end

      it_behaves_like "a solo-like run"
    end

    describe "a local mode run" do
      before(:each) do
        Chef::Config[:local_mode] = true
      end

      it_behaves_like "a solo-like run"
    end

    it "is enabled in client mode when the mode is :both" do
      Chef::Config[:data_collector][:mode] = :both
      expect(Chef::DataCollector::ConfigValidation.should_be_enabled?).to be true
    end

    it "is disabled in client mode when the mode is :solo" do
      Chef::Config[:data_collector][:mode] = :solo
      expect(Chef::DataCollector::ConfigValidation.should_be_enabled?).to be false
    end

    it "is disabled in client mode when the mode is :nonsense" do
      Chef::Config[:data_collector][:mode] = :nonsense
      expect(Chef::DataCollector::ConfigValidation.should_be_enabled?).to be false
    end

    it "is still enabled if you set a token in client mode" do
      Chef::Config[:data_collector][:token] =  "good_for_one_ride"
      expect(Chef::DataCollector::ConfigValidation.should_be_enabled?).to be true
    end
  end

  describe "validate_server_url!" do
    it "with valid server url" do
      Chef::Config[:data_collector][:server_url] = "https://www.esa.local/ariane5"
      expect(Chef::DataCollector::ConfigValidation.validate_server_url!).to be_nil
    end

    it "with invalid server URL" do
      Chef::Config[:data_collector][:server_url] = "not valid URL"
      expect { Chef::DataCollector::ConfigValidation.validate_server_url! }.to raise_error(Chef::Exceptions::ConfigurationError,
         "Chef::Config[:data_collector][:server_url] (not valid URL) is not a valid URI.")
    end

    it "with invalid server URL without host" do
      Chef::Config[:data_collector][:server_url] = "no-host"
      expect { Chef::DataCollector::ConfigValidation.validate_server_url! }.to raise_error(Chef::Exceptions::ConfigurationError,
         "Chef::Config[:data_collector][:server_url] (no-host) is a URI with no host. Please supply a valid URL.")
    end

    it "skip validation if output_locations is set" do
      Chef::Config[:data_collector][:output_locations] = { files: ["https://www.esa.local/ariane5"] }
      expect(Chef::DataCollector::ConfigValidation.validate_server_url!).to be_nil
    end

    it "skip validation if output_locations & server_url both are set" do
      Chef::Config[:data_collector][:server_url] = "https://www.esa.local/ariane5"
      Chef::Config[:data_collector][:output_locations] = { files: ["https://www.esa.local/ariane5"] }
      expect(Chef::DataCollector::ConfigValidation.validate_server_url!).to be_nil
    end
  end

  describe "validate_output_locations!" do
    it "with nil or not set skip validation" do
      Chef::Config[:data_collector][:output_locations] = nil
      expect(Chef::DataCollector::ConfigValidation.validate_output_locations!).to be_nil
    end

    it "with empty value raise validation error" do
      Chef::Config[:data_collector][:output_locations] = {}
      expect { Chef::DataCollector::ConfigValidation.validate_output_locations! }.to raise_error(Chef::Exceptions::ConfigurationError,
        "Chef::Config[:data_collector][:output_locations] is empty. Please supply an hash of valid URLs and / or local file paths.")
    end

    it "with valid URLs options" do
      Chef::Config[:data_collector][:output_locations] = { urls: ["https://www.esa.local/ariane5/data-collector"] }
      expect { Chef::DataCollector::ConfigValidation.validate_output_locations! }.not_to raise_error
    end

    context "output_locations contains files" do
      let(:file_path) { "/tmp/client-runs.txt" }

      before(:each) do
        allow(File).to receive(:exist?).with(file_path).and_return(true)
        allow(File).to receive(:readable?).with(file_path).and_return(true)
        allow(File).to receive(:writable?).with(file_path).and_return(true)
        allow(File).to receive(:expand_path).with(file_path).and_return(file_path)
      end

      it "with valid files options" do
        Chef::Config[:data_collector][:output_locations] = { files: [file_path] }
        expect { Chef::DataCollector::ConfigValidation.validate_output_locations! }.not_to raise_error
      end

      it "with valid files & URLs options" do
        Chef::Config[:data_collector][:output_locations] = { urls: ["https://www.esa.local/ariane5/data-collector"], files: [file_path] }
        expect { Chef::DataCollector::ConfigValidation.validate_output_locations! }.not_to raise_error
      end

      it "with valid files options & String location value" do
        Chef::Config[:data_collector][:output_locations] = { files: file_path }
        expect { Chef::DataCollector::ConfigValidation.validate_output_locations! }.not_to raise_error
      end
    end
  end
end
