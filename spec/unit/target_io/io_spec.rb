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

RSpec.describe TargetIO::IO do
  let(:hosts_path)    { "/etc/hosts" }
  let(:hosts_content) { "127.0.0.1 localhost" }

  describe ".method_missing dispatch" do
    context "when target mode is enabled" do
      before { allow(ChefConfig::Config).to receive(:target_mode?).and_return(true) }

      it "delegates to TargetIO::TrainCompat::IO" do
        expect(TargetIO::TrainCompat::IO).to receive(:read).with(hosts_path).and_return(hosts_content)
        expect(described_class.read(hosts_path)).to eq(hosts_content)
      end
    end

    context "when target mode is disabled" do
      before { allow(ChefConfig::Config).to receive(:target_mode?).and_return(false) }

      it "delegates to ::IO" do
        expect(::IO).to receive(:read).with(hosts_path).and_return(hosts_content)
        expect(described_class.read(hosts_path)).to eq(hosts_content)
      end
    end
  end
end
