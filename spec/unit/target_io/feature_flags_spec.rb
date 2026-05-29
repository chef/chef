#
# Copyright:: Copyright (c) 2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require "spec_helper"
require "chef/target_io"

RSpec.describe TargetIO::FeatureFlags do
  before do
    described_class.reset_flag_state_for_testing!
    allow(ENV).to receive(:[]).and_call_original
  end

  describe ".target_io_backend_helper_enabled?" do
    it "is disabled by default and logs the state" do
      allow(ENV).to receive(:[]).with("CHEF_TARGET_IO_BACKEND_HELPER").and_return(nil)
      expect(Chef::Log).to receive(:info).with("TargetIO feature flag CHEF_TARGET_IO_BACKEND_HELPER=false")

      expect(described_class.target_io_backend_helper_enabled?).to be false
    end

    it "is enabled when CHEF_TARGET_IO_BACKEND_HELPER=true and logs the state" do
      allow(ENV).to receive(:[]).with("CHEF_TARGET_IO_BACKEND_HELPER").and_return("true")
      expect(Chef::Log).to receive(:info).with("TargetIO feature flag CHEF_TARGET_IO_BACKEND_HELPER=true")

      expect(described_class.target_io_backend_helper_enabled?).to be true
    end
  end

  describe ".choose_backend" do
    let(:target_backend) { double("TargetBackend") }
    let(:local_backend) { double("LocalBackend") }

    it "returns target backend in target mode" do
      allow(ChefConfig::Config).to receive(:target_mode?).and_return(true)

      expect(described_class.choose_backend(name: "TargetIO::File", target_backend: target_backend, local_backend: local_backend)).to eq(target_backend)
    end

    it "returns local backend when target mode is disabled" do
      allow(ChefConfig::Config).to receive(:target_mode?).and_return(false)

      expect(described_class.choose_backend(name: "TargetIO::File", target_backend: target_backend, local_backend: local_backend)).to eq(local_backend)
    end
  end
end
