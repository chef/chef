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
      "definitions" => [{ "name" => "runit_service.rb", "path" => "definitions/runit_service.rb", "checksum" => "c40cf9b4c6eb15a8e49e31602f701161", "specificity" => "default" }],
      "files" => [{ "name" => "giant_blob.tgz", "path" => "files/default/giant_blob.tgz", "checksum" => "5b4b194bb80938bb18da7af5c823cb1b", "specificity" => "default" }],
      "frozen?" => false,
      "libraries" => [{ "name" => "ownage.rb", "path" => "libraries/ownage.rb", "checksum" => "4686edd9968909034692e09e058d90d9", "specificity" => "default" }],
      "name" => "tatft-1.2.3",
      "providers" => [{ "name" => "lwp.rb", "path" => "providers/lwp.rb", "checksum" => "bc189d68f77bb054d1070aeff7669557", "specificity" => "default" }],
      "recipes" => [{ "name" => "default.rb", "path" => "recipes/default.rb", "checksum" => "09bc749f00c68717d288de9c8d7c644f", "specificity" => "default" }],
      "resources" => [{ "name" => "lwr.rb", "path" => "resources/lwr.rb", "checksum" => "609c40d3d3f269e7edf230277a240ef5", "specificity" => "default" }],
      "root_files" => [{ "name" => "README.rdoc", "path" => "README.rdoc", "checksum" => "cd7be9a1b9b1f33e3bcd9c3f4bc8dde5", "specificity" => "default" }],
      "templates" => [{ "name" => "configuration.erb", "path" => "templates/default/configuration.erb", "checksum" => "d41d8cd98f00b204e9800998ecf8427e", "specificity" => "default" }],
      "version" => "1.2.3",
    }
  end

  describe "#from_hash" do
    let(:source_hash) do
      {
      "attributes" => [{ "name" => "default.rb", "path" => "attributes/default.rb", "checksum" => "a88697db56181498a8828d5531271ad9", "specificity" => "default" }],
      "recipes" => [{ "name" => "default.rb", "path" => "recipes/default.rb", "checksum" => "09bc749f00c68717d288de9c8d7c644f", "specificity" => "default" }],
      "root_files" => [{ "name" => "README.rdoc", "path" => "README.rdoc", "checksum" => "cd7be9a1b9b1f33e3bcd9c3f4bc8dde5", "specificity" => "default" }],
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
      expect(result[:all_files].map { |f| f["name"] }).to match_array %w{ recipes/default.rb attributes/default.rb README.rdoc }
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
