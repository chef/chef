#
# Author:: Adam Jacob (<adam@chef.io>)
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
require "chef/mixin/checksum"
require "stringio"

class Chef::CMCCheck
  include Chef::Mixin::Checksum
end

describe Chef::Mixin::Checksum do
  before(:each) do
    @checksum_user = Chef::CMCCheck.new
    @cache = Chef::Digester.instance
    @file = CHEF_SPEC_DATA + "/checksum/random.txt"
    @stat = double("File::Stat", { mtime: Time.at(0) })
    allow(File).to receive(:stat).and_return(@stat)
  end

  it "gets the checksum of a file" do
    expect(@checksum_user.checksum(@file)).to eq("dc6665c18676f5f30fdaa420343960edf1883790f83f51f437dbfa0ff678499d")
  end

  describe "short_cksum" do
    context "nil provided for checksum" do
      it "returns none" do
        expect(@checksum_user.short_cksum(nil)).to eq("none")
      end
    end

    context "non-nil provided for checksum" do
      it "returns the short checksum" do
        expect(@checksum_user.short_cksum("u7ghbxikk3i9blsimmy2y2ionmxx")).to eq("u7ghbx")
      end
    end
  end

  describe "checksum_match?" do
    context "when checksum cases match" do
      it "returns true" do
        expect(@checksum_user.checksum_match?("u7ghbxikk3i9blsimmy2y2ionmxx", "u7ghbxikk3i9blsimmy2y2ionmxx")).to be true
      end
    end

    context "when one checksum is uppercase and other is lowercase" do
      it "returns true" do
        expect(@checksum_user.checksum_match?("U7GHBXIKK3I9BLSIMMY2Y2IONMXX", "u7ghbxikk3i9blsimmy2y2ionmxx")).to be true
      end
    end

    context "when checksums do not match" do
      it "returns false" do
        expect(@checksum_user.checksum_match?("u7ghbxikk3i9blsimmy2y2ionmxx", "dc6665c18676f5f30fdaa4203439")).to be false
      end
    end

    context "when checksum is nil" do
      it "returns false" do
        expect(@checksum_user.checksum_match?("u7ghbxikk3i9blsimmy2y2ionmxx", nil)).to be false
        expect(@checksum_user.checksum_match?(nil, "dc6665c18676f5f30fdaa4203439")).to be false
        expect(@checksum_user.checksum_match?(nil, nil)).to be false
      end
    end
  end

end
