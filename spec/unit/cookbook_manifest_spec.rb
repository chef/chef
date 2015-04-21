#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright (c) 2015 Opscode, Inc.
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

require 'spec_helper'
require 'chef/cookbook_manifest'
require 'chef/digester'
require 'pathname'

describe Chef::CookbookManifest do

  let(:version) { "1.2.3" }

  let(:identifier) { "9e10455ce2b4a4e29424b7064b1d67a1a25c9d3b" }

  let(:metadata) do
    Chef::Cookbook::Metadata.new.tap do |m|
      m.version(version)
    end
  end

  let(:cookbook_root) { '/tmp/blah' }

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
      expect(cookbook_manifest.root_paths).to eq(['/tmp/blah'])
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

    it "delegates `segment_filenames' to cookbook_version" do
      expect(cookbook_version).to receive(:segment_filenames).with(:recipes).and_return([])
      expect(cookbook_manifest.segment_filenames(:recipes)).to eq([])
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

        "recipes"     =>[],
        "definitions" =>[],
        "libraries"   =>[],
        "attributes"  =>[],
        "files"       =>[],
        "templates"   =>[],
        "resources"   =>[],
        "providers"   =>[],
        "root_files"  =>[],
      }
    end

    it "converts the CookbookVersion to a ruby Hash representation" do
      expect(cookbook_manifest.to_hash).to eq(expected_hash)
    end

  end

  context "when given a cookbook with files" do

    let(:cookbook_root) { File.join(CHEF_SPEC_DATA, 'cb_version_cookbooks', 'tatft') }

    let(:attribute_filenames)   { Dir[File.join(cookbook_root, 'attributes', '**', '*.rb')] }
    let(:definition_filenames)  { Dir[File.join(cookbook_root, 'definitions', '**', '*.rb')] }
    let(:file_filenames)        { Dir[File.join(cookbook_root, 'files', '**', '*.tgz')] }
    let(:recipe_filenames)      { Dir[File.join(cookbook_root, 'recipes', '**', '*.rb')] }
    let(:template_filenames)    { Dir[File.join(cookbook_root, 'templates', '**', '*.erb')] }
    let(:library_filenames)     { Dir[File.join(cookbook_root, 'libraries', '**', '*.rb')] }
    let(:resource_filenames)    { Dir[File.join(cookbook_root, 'resources', '**', '*.rb')] }
    let(:provider_filenames)    { Dir[File.join(cookbook_root, 'providers', '**', '*.rb')] }
    let(:root_filenames)        { Array(File.join(cookbook_root, 'README.rdoc')) }
    let(:metadata_filenames)    { Array(File.join(cookbook_root, 'metadata.json')) }

    let(:match_md5) { /[0-9a-f]{32}/ }

    def map_to_file_specs(paths)
      paths.map do |path|

        relative_path = Pathname.new(path).relative_path_from(Pathname.new(cookbook_root)).to_s

        {
          "name"        => File.basename(path),
          "path"        => relative_path,
          "checksum"    => Chef::Digester.generate_md5_checksum_for_file(path),
          "specificity" => "default",
        }
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

        "recipes"     => map_to_file_specs(recipe_filenames),
        "definitions" => map_to_file_specs(definition_filenames),
        "libraries"   => map_to_file_specs(library_filenames),
        "attributes"  => map_to_file_specs(attribute_filenames),
        "files"       => map_to_file_specs(file_filenames),
        "templates"   => map_to_file_specs(template_filenames),
        "resources"   => map_to_file_specs(resource_filenames),
        "providers"   => map_to_file_specs(provider_filenames),
        "root_files"  => map_to_file_specs(root_filenames),
      }
    end

    before do
      cookbook_version.attribute_filenames   = attribute_filenames
      cookbook_version.definition_filenames  = definition_filenames
      cookbook_version.file_filenames        = file_filenames
      cookbook_version.recipe_filenames      = recipe_filenames
      cookbook_version.template_filenames    = template_filenames
      cookbook_version.library_filenames     = library_filenames
      cookbook_version.resource_filenames    = resource_filenames
      cookbook_version.provider_filenames    = provider_filenames
      cookbook_version.root_filenames        = root_filenames
      cookbook_version.metadata_filenames    = metadata_filenames
    end

    it "converts the CookbookVersion to a ruby Hash representation" do
      cookbook_manifest_hash = cookbook_manifest.to_hash

      expect(cookbook_manifest_hash.keys).to match_array(expected_hash.keys)
      cookbook_manifest_hash.each do |key, value|
        expect(cookbook_manifest_hash[key]).to eq(expected_hash[key])
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

