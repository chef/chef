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

require "spec_helper"
require "chef/cookbook_manifest"
require "chef/digester"
require "pathname"

describe Chef::Cookbook::ManifestV0 do
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

  let(:expected_hash) do
    {
      "attributes" => [{ "name" => "default.rb", "path" => "attributes/default.rb", "checksum" => "a88697db56181498a8828d5531271ad9", "specificity" => "default" }],
      "chef_type" => "cookbook_version",
      "cookbook_name" => "tatft",
      "definitions" => [{ "name" => "runit_service.rb", "path" => "definitions/runit_service.rb", "checksum" => "e2bd63f174dcbe034cd669778cdab748", "specificity" => "default" }],
      "files" => [{ "name" => "giant_blob.tgz", "path" => "files/default/giant_blob.tgz", "checksum" => "5b4b194bb80938bb18da7af5c823cb1b", "specificity" => "default" }],
      "frozen?" => false,
      "libraries" => [{ "name" => "ownage.rb", "path" => "libraries/ownage.rb", "checksum" => "7774500d1b8f19c48343efd496095105", "specificity" => "default" }],
      "name" => "tatft-1.2.3",
      "providers" => [{ "name" => "lwp.rb", "path" => "providers/lwp.rb", "checksum" => "d95d615bff87374e6f24fd87bcd9a19b", "specificity" => "default" }],
      "recipes" => [{ "name" => "default.rb", "path" => "recipes/default.rb", "checksum" => "7570bbaa6e36a331e4659dd30d7ab3f5", "specificity" => "default" }],
      "resources" => [{ "name" => "lwr.rb", "path" => "resources/lwr.rb", "checksum" => "6f4d7ef8d9ad06b7eefe565b66e3d0bb", "specificity" => "default" }],
      "root_files" => [{ "name" => "README.rdoc", "path" => "README.rdoc", "checksum" => "e35b32dfd08c170855583eac21afc6d4", "specificity" => "default" }],
      "templates" => [{ "name" => "configuration.erb", "path" => "templates/default/configuration.erb", "checksum" => "68b329da9893e34099c7d8ad5cb9c940", "specificity" => "default" }],
      "version" => "1.2.3",
    }
  end

  describe "#from_hash" do
    let(:source_hash) do
      {
      "attributes" => [{ "name" => "default.rb", "path" => "attributes/default.rb", "checksum" => "a88697db56181498a8828d5531271ad9", "specificity" => "default" }],
      "recipes" => [{ "name" => "default.rb", "path" => "recipes/default.rb", "checksum" => "7570bbaa6e36a331e4659dd30d7ab3f5", "specificity" => "default" }],
      "root_files" => [{ "name" => "README.rdoc", "path" => "README.rdoc", "checksum" => "e35b32dfd08c170855583eac21afc6d4", "specificity" => "default" }],
      "name" => "tatft-1.2.3",
      "version" => "1.2.3",
      }
    end

    it "preserves the version" do
      result = described_class.from_hash(source_hash)
      expect(result["version"]).to eq "1.2.3"
    end

    it "creates an all_files key and populates it" do
      result = described_class.from_hash(source_hash)
      expect(result[:all_files].map { |f| f["name"] }).to match_array %w{ recipes/default.rb attributes/default.rb root_files/README.rdoc }
    end

    it "deletes unwanted segment types" do
      result = described_class.from_hash(source_hash)
      expect(result["attributes"]).to be_nil
    end

    it "preserves frozeness" do
      source_hash["frozen?"] = true
      result = described_class.from_hash(source_hash)
      expect(result["frozen?"]).to be true
    end
  end

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

  context "ensures that all segments exist" do
    Chef::Cookbook::ManifestV0::COOKBOOK_SEGMENTS.each do |segment|
      it "with #{segment}" do
        result = described_class.to_hash(cookbook_manifest)
        expect(result[segment]).to be_empty
      end
    end
  end

  context "when given a cookbook with some files" do
    before do
      cookbook_version.all_files = all_files
    end

    Chef::Cookbook::ManifestV0::COOKBOOK_SEGMENTS.each do |segment|
      it "places the files for #{segment} correctly" do
        result = described_class.to_hash(cookbook_manifest)
        expect(result[segment]).to eq(expected_hash[segment])
      end
    end
  end
end
