#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2015-2016, Chef Software Inc.
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

describe Chef::CookbookManifest do

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

  let(:policy_mode) { false }

  subject(:cookbook_manifest) { Chef::CookbookManifest.new(cookbook_version, policy_mode: policy_mode) }

  context "when policy mode is not specified" do

    subject(:cookbook_manifest) { Chef::CookbookManifest.new(cookbook_version) }

    it "defaults to policies disabled" do
      expect(cookbook_manifest.policy_mode?).to be(false)
    end

  end

  describe "collecting cookbook data from the cookbook version object" do

    it "delegates `name' to cookbook_version" do
      expect(cookbook_manifest.name).to eq("tatft")
    end

    it "delegates `root_paths' to cookbook_version" do
      expect(cookbook_manifest.root_paths).to eq(["/tmp/blah"])
    end

    it "delegates `metadata' to cookbook_version" do
      expect(cookbook_manifest.metadata).to eq(metadata)
    end

    it "delegates `full_name' to cookbook_version" do
      expect(cookbook_manifest.full_name).to eq("tatft-1.2.3")
    end

    it "delegates `version' to cookbook_version" do
      expect(cookbook_manifest.version).to eq(version)
    end

    it "delegates `frozen_version?' to cookbook_version" do
      expect(cookbook_manifest.frozen_version?).to be(false)
    end

  end

  context "when given an empty cookbook" do

    let(:expected_hash) do
      {
        "chef_type" => "cookbook_version",

        "name"          => "tatft-1.2.3",
        "version"       => "1.2.3",
        "cookbook_name" => "tatft",
        "metadata"      => metadata,

        "frozen?" => false,

        "all_files" => [],
      }
    end

    it "converts the CookbookVersion to a ruby Hash representation" do
      expect(cookbook_manifest.to_hash).to eq(expected_hash)
    end

  end

  context "when given a cookbook with files" do

    let(:cookbook_root) { File.join(CHEF_SPEC_DATA, "cb_version_cookbooks", "tatft") }

    let(:all_files) { Dir[File.join(cookbook_root, "**", "**")].reject { |f| File.directory? f } }

    let(:match_md5) { /[0-9a-f]{32}/ }

    def map_to_file_specs(paths, full: false)
      paths.map do |path|

        relative_path = Pathname.new(path).relative_path_from(Pathname.new(cookbook_root)).to_s

        parts = relative_path.split("/")
        name = if %w{templates files}.include?(parts[0]) && parts.length == 3
                 File.join(parts[0], parts[2])
               else
                 relative_path
               end

        {
          "name"        => name,
          "path"        => relative_path,
          "checksum"    => Chef::Digester.generate_md5_checksum_for_file(path),
          "specificity" => "default",
        }.tap do |fp|
          if full
            fp["full_path"] = path
          end
        end
      end
    end

    let(:expected_hash) do
      {
        "chef_type" => "cookbook_version",

        "name"          => "tatft-1.2.3",
        "version"       => "1.2.3",
        "cookbook_name" => "tatft",
        "metadata"      => metadata,

        "frozen?" => false,

        "all_files" => map_to_file_specs(all_files),
      }
    end

    before do
      cookbook_version.all_files = all_files
    end

    it "converts the CookbookVersion to a ruby Hash representation" do
      cookbook_manifest_hash = cookbook_manifest.to_hash

      expect(cookbook_manifest_hash.keys).to match_array(expected_hash.keys)
      cookbook_manifest_hash.each do |key, value|
        expect(cookbook_manifest_hash[key]).to eq(expected_hash[key])
      end
    end

    context ".each_file" do
      it "yields all the files" do
        files = map_to_file_specs(all_files, full: true)
        expect(cookbook_manifest.to_enum(:each_file)).to match_array(files)
      end

      it "excludes certain file parts" do
        files = map_to_file_specs(all_files, full: true).reject { |f| seg = f["name"].split("/")[0]; %w{ files templates }.include?(seg) }
        expect(cookbook_manifest.to_enum(:each_file, excluded_parts: %w{ files templates })).to match_array(files)
      end
    end
  end

  describe "providing upstream URLs for save" do

    context "and policy mode is disabled" do

      it "gives the save URL" do
        expect(cookbook_manifest.save_url).to eq("cookbooks/tatft/1.2.3")
      end

      it "gives the force save URL" do
        expect(cookbook_manifest.force_save_url).to eq("cookbooks/tatft/1.2.3?force=true")
      end

    end

    context "and policy mode is enabled" do

      let(:policy_mode) { true }

      let(:cookbook_manifest_hash) { cookbook_manifest.to_hash }

      it "sets the identifier in the manifest data" do
        expect(cookbook_manifest_hash["identifier"]).to eq("9e10455ce2b4a4e29424b7064b1d67a1a25c9d3b")
      end

      it "sets the name to just the name" do
        expect(cookbook_manifest_hash["name"]).to eq("tatft")
      end

      it "does not set a 'cookbook_name' field" do
        expect(cookbook_manifest_hash).to_not have_key("cookbook_name")
      end

      it "gives the save URL" do
        expect(cookbook_manifest.save_url).to eq("cookbook_artifacts/tatft/9e10455ce2b4a4e29424b7064b1d67a1a25c9d3b")
      end

      it "gives the force save URL" do
        expect(cookbook_manifest.force_save_url).to eq("cookbook_artifacts/tatft/9e10455ce2b4a4e29424b7064b1d67a1a25c9d3b?force=true")
      end

    end
  end

end
