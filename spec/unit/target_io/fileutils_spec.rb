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

RSpec.describe TargetIO::FileUtils do
  let(:dir_path) { "/new/dir" }

  describe ".method_missing dispatch" do
    context "when helper flag is enabled" do
      before do
        allow(ChefConfig::Config).to receive(:target_mode?).and_return(true)
        allow(TargetIO::FeatureFlags).to receive(:target_io_backend_helper_enabled?).and_return(true)
      end

      it "uses the helper to choose backend" do
        expect(TargetIO::FeatureFlags).to receive(:choose_backend)
          .with(name: "TargetIO::FileUtils", target_backend: TargetIO::TrainCompat::FileUtils, local_backend: ::FileUtils)
          .and_return(TargetIO::TrainCompat::FileUtils)
        expect(TargetIO::TrainCompat::FileUtils).to receive(:mkdir_p).with(dir_path).and_return(nil)

        described_class.mkdir_p(dir_path)
      end
    end

    context "when target mode is enabled" do
      before do
        allow(ChefConfig::Config).to receive(:target_mode?).and_return(true)
        allow(TargetIO::FeatureFlags).to receive(:target_io_backend_helper_enabled?).and_return(false)
      end

      it "delegates to TargetIO::TrainCompat::FileUtils" do
        expect(TargetIO::TrainCompat::FileUtils).to receive(:mkdir_p).with(dir_path).and_return(nil)
        described_class.mkdir_p(dir_path)
      end

      it "passes keyword arguments through" do
        expect(TargetIO::TrainCompat::FileUtils).to receive(:cp).with("/src", "/dest", preserve: true).and_return(nil)
        described_class.cp("/src", "/dest", preserve: true)
      end
    end

    context "when target mode is disabled" do
      before do
        allow(ChefConfig::Config).to receive(:target_mode?).and_return(false)
        allow(TargetIO::FeatureFlags).to receive(:target_io_backend_helper_enabled?).and_return(false)
      end

      it "delegates to ::FileUtils" do
        expect(::FileUtils).to receive(:mkdir_p).with(dir_path).and_return([dir_path])
        described_class.mkdir_p(dir_path)
      end

      it "passes keyword arguments through" do
        expect(::FileUtils).to receive(:touch).with(["/tmp/file"]).and_return(nil)
        described_class.touch(["/tmp/file"])
      end
    end
  end
end
