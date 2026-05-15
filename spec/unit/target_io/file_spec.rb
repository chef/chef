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

RSpec.describe TargetIO::File do
  let(:path) { "/tmp/foo" }

  describe ".method_missing dispatch" do
    context "when target mode is enabled" do
      before { allow(ChefConfig::Config).to receive(:target_mode?).and_return(true) }

      it "delegates to TargetIO::TrainCompat::File" do
        expect(TargetIO::TrainCompat::File).to receive(:exist?).with(path).and_return(true)
        expect(described_class.exist?(path)).to be true
      end

      it "passes positional arguments through" do
        expect(TargetIO::TrainCompat::File).to receive(:read).with(path).and_return("data")
        expect(described_class.read(path)).to eq("data")
      end

      it "passes keyword arguments through" do
        expect(TargetIO::TrainCompat::File).to receive(:open).with(path, "r").and_return("io")
        described_class.open(path, "r")
      end

      it "forwards blocks" do
        allow(TargetIO::TrainCompat::File).to receive(:open).with(path).and_yield("content")
        yielded = nil
        described_class.open(path) { |f| yielded = f }
        expect(yielded).to eq("content")
      end
    end

    context "when target mode is disabled" do
      before { allow(ChefConfig::Config).to receive(:target_mode?).and_return(false) }

      it "delegates to ::File" do
        expect(::File).to receive(:exist?).with(path).and_return(false)
        expect(described_class.exist?(path)).to be false
      end

      it "passes positional arguments through" do
        expect(::File).to receive(:read).with("/tmp/bar").and_return("local data")
        expect(described_class.read("/tmp/bar")).to eq("local data")
      end

      it "passes keyword arguments through" do
        expect(::File).to receive(:join).with("/a", "b").and_call_original
        expect(described_class.join("/a", "b")).to eq("/a/b")
      end
    end
  end
end
