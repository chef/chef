#--
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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
require "chef/cookbook_version"

describe Chef::Cookbook::FileVendor do

  let(:file_vendor_class) { Class.new(described_class) }

  context "when configured to fetch files over http" do

    let(:http) { double("Chef::ServerAPI") }

    # A manifest is a Hash of the format defined by Chef::CookbookVersion#manifest
    let(:manifest) do
      cbv = Chef::CookbookVersion.new("bob", Array(Dir.tmpdir))
      cbv.cookbook_manifest
    end

    before do
      file_vendor_class.fetch_from_remote(http)
    end

    it "sets the vendor class to RemoteFileVendor" do
      expect(file_vendor_class.vendor_class).to eq(Chef::Cookbook::RemoteFileVendor)
    end

    it "sets the initialization options to the given http object" do
      expect(file_vendor_class.initialization_options).to eq(http)
    end

    context "with a manifest from a cookbook version" do

      # # A manifest is a Hash of the format defined by Chef::CookbookVersion#manifest
      # let(:manifest) do
      #   cbv = Chef::CookbookVersion.new("bob", Array(Dir.tmpdir))
      #   cbv.cookbook_manifest
      # end

      it "creates a RemoteFileVendor for a given manifest" do
        file_vendor = file_vendor_class.create_from_manifest(manifest)
        expect(file_vendor).to be_a_kind_of(Chef::Cookbook::RemoteFileVendor)
        expect(file_vendor.rest).to eq(http)
        expect(file_vendor.cookbook_name).to eq("bob")
      end

    end

    context "with a manifest from a cookbook artifact" do

      it "creates a RemoteFileVendor for a given manifest" do
        file_vendor = file_vendor_class.create_from_manifest(manifest)
        expect(file_vendor).to be_a_kind_of(Chef::Cookbook::RemoteFileVendor)
        expect(file_vendor.rest).to eq(http)
        expect(file_vendor.cookbook_name).to eq("bob")
      end

    end
  end

  context "when configured to load files from disk" do

    let(:cookbook_path) { %w{/var/chef/cookbooks /var/chef/other_cookbooks} }

    let(:manifest) do
      cbv = Chef::CookbookVersion.new("bob", Array(Dir.tmpdir))
      cbv.cookbook_manifest
    end

    before do
      file_vendor_class.fetch_from_disk(cookbook_path)
    end

    it "sets the vendor class to FileSystemFileVendor" do
      expect(file_vendor_class.vendor_class).to eq(Chef::Cookbook::FileSystemFileVendor)
    end

    it "sets the initialization options to the given cookbook paths" do
      expect(file_vendor_class.initialization_options).to eq(cookbook_path)
    end

    it "creates a FileSystemFileVendor for a given manifest" do
      file_vendor = file_vendor_class.create_from_manifest(manifest)
      expect(file_vendor).to be_a_kind_of(Chef::Cookbook::FileSystemFileVendor)
      expect(file_vendor.cookbook_name).to eq("bob")
      expect(file_vendor.repo_paths).to eq(cookbook_path)
    end

  end

  context "when vendoring a cookbook with a name mismatch" do
    let(:cookbook_path) { File.join(CHEF_SPEC_DATA, "cookbooks") }

    let(:manifest) do
      cbv = Chef::CookbookVersion.new("name-mismatch", Array(Dir.tmpdir))
      cbv.cookbook_manifest
    end

    before do
      file_vendor_class.fetch_from_disk(cookbook_path)
    end

    it "retrieves the file from the correct location based on path to the cookbook that conatins the correct name metadata" do
      file_vendor = file_vendor_class.create_from_manifest(manifest)
      file_vendor.get_filename("metadata.rb")
    end
  end
end
