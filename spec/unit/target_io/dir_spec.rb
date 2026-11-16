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

RSpec.describe TargetIO::Dir do
  describe ".method_missing dispatch" do
    context "when target mode is enabled" do
      before { allow(ChefConfig::Config).to receive(:target_mode?).and_return(true) }

      it "delegates to TargetIO::TrainCompat::Dir" do
        expect(TargetIO::TrainCompat::Dir).to receive(:entries).with("/etc").and_return([".", ".."])
        expect(described_class.entries("/etc")).to eq([".", ".."])
      end

      it "passes arguments through" do
        expect(TargetIO::TrainCompat::Dir).to receive(:mkdir).with("/new/dir").and_return(nil)
        described_class.mkdir("/new/dir")
      end
    end

    context "when target mode is disabled" do
      before { allow(ChefConfig::Config).to receive(:target_mode?).and_return(false) }

      it "delegates to ::Dir" do
        expect(::Dir).to receive(:exist?).with("/etc").and_return(true)
        expect(described_class.exist?("/etc")).to be true
      end

      it "passes arguments through", not_supported_on_windows: true do
        expect(::Dir).to receive(:entries).with("/tmp").and_call_original
        described_class.entries("/tmp")
      end
    end
  end
end
