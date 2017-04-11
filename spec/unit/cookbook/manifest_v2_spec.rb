#
# Copyright:: Copyright 2017, Chef Software Inc.
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
require "chef/cookbook_manifest"
require "chef/digester"
require "pathname"

describe Chef::Cookbook::ManifestV2 do
  let(:version) { "1.2.3" }

  let(:identifier) { "9e10455ce2b4a4e29424b7064b1d67a1a25c9d3b" }

  let(:metadata) do
    Chef::Cookbook::Metadata.new.tap do |m|
      m.version(version)
    end
  end

  let(:cookbook_root) { "/tmp/blah" }

  let(:cookbook_version) do
    Chef::CookbookVersion.new("tatft", cookbook_root).tap do |c|
      c.metadata = metadata
      c.identifier = identifier
    end
  end

  let(:cookbook_manifest) { Chef::CookbookManifest.new(cookbook_version) }

  let(:cookbook_root) { File.join(CHEF_SPEC_DATA, "cb_version_cookbooks", "tatft") }

  let(:all_files) { Dir[File.join(cookbook_root, "**", "**")].reject { |f| File.directory? f } }

  describe "#to_hash" do
    it "accepts a cookbook manifest" do
      result = described_class.to_hash(cookbook_manifest)
      expect(result).to be_a(Hash)
    end

    it "preserves frozeness" do
      cookbook_version.freeze_version
      expect(described_class.to_hash(cookbook_manifest)["frozen?"]).to be true
    end
  end

  context "when given a cookbook with some files" do
    before do
      cookbook_version.all_files = all_files
    end

    it "populates all_files correctly" do
      result = described_class.to_hash(cookbook_manifest)
      expect(result["all_files"][0]).not_to include(:full_path)
    end
  end
end
