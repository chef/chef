#
# Author:: Tim Hinderliter (<tim@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Copyright:: Copyright 2010-2016, Chef Software Inc.
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

describe Chef::CookbookVersion, "file specificity" do
  before(:each) do
    @cookbook = Chef::CookbookVersion.new("test-cookbook", "/cookbook-folder")
    @cookbook.manifest = {
      "all_files" =>
      [
       # afile.rb
       {
         :name => "files/afile.rb",
         :path => "files/host-examplehost.example.org/afile.rb",
         :full_path => "/cookbook-folder/files/host-examplehost.example.org/afile.rb",
         :checksum => "csum-host",
         :specificity => "host-examplehost.example.org",
       },
       {
         :name => "files/afile.rb",
         :path => "files/ubuntu-9.10/afile.rb",
         :full_path => "/cookbook-folder/files/ubuntu-9.10/afile.rb",
         :checksum => "csum-platver-full",
         :specificity => "ubuntu-9.10",
       },
       {
         :name => "files/afile.rb",
         :path => "files/newubuntu-9/afile.rb",
         :full_path => "/cookbook-folder/files/newubuntu-9/afile.rb",
         :checksum => "csum-platver-partial",
         :specificity => "newubuntu-9",
       },
       {
         :name => "files/afile.rb",
         :path => "files/ubuntu/afile.rb",
         :full_path => "/cookbook-folder/files/ubuntu/afile.rb",
         :checksum => "csum-plat",
         :specificity => "ubuntu",
       },
       {
         :name => "files/afile.rb",
         :path => "files/default/afile.rb",
         :full_path => "/cookbook-folder/files/default/afile.rb",
         :checksum => "csum-default",
         :specificity => "default",
       },

       # for different/odd platform_versions
       {
         :name => "files/bfile.rb",
         :path => "files/fakeos-2.0.rc.1/bfile.rb",
         :full_path => "/cookbook-folder/files/fakeos-2.0.rc.1/bfile.rb",
         :checksum => "csum2-platver-full",
         :specificity => "fakeos-2.0.rc.1",
       },
       {
         :name => "files/bfile.rb",
         :path => "files/newfakeos-2.0.rc/bfile.rb",
         :full_path => "/cookbook-folder/files/newfakeos-2.0.rc/bfile.rb",
         :checksum => "csum2-platver-partial",
         :specificity => "newfakeos-2.0.rc",
       },
       {
         :name => "files/bfile.rb",
         :path => "files/fakeos-maple tree/bfile.rb",
         :full_path => "/cookbook-folder/files/fakeos-maple tree/bfile.rb",
         :checksum => "csum3-platver-full",
         :specificity => "maple tree",
       },
       {
         :name => "files/bfile.rb",
         :path => "files/fakeos-1/bfile.rb",
         :full_path => "/cookbook-folder/files/fakeos-1/bfile.rb",
         :checksum => "csum4-platver-full",
         :specificity => "fakeos-1",
       },

       # directory adirectory
       {
         :name => "files/anotherfile1.rb",
         :path => "files/host-examplehost.example.org/adirectory/anotherfile1.rb.host",
         :full_path => "/cookbook-folder/files/host-examplehost.example.org/adirectory/anotherfile1.rb.host",
         :checksum => "csum-host-1",
         :specificity => "host-examplehost.example.org",
       },
       {
         :name => "files/anotherfile2.rb",
         :path => "files/host-examplehost.example.org/adirectory/anotherfile2.rb.host",
         :full_path => "/cookbook-folder/files/host-examplehost.example.org/adirectory/anotherfile2.rb.host",
         :checksum => "csum-host-2",
         :specificity => "host-examplehost.example.org",
       },

       {
         :name => "files/anotherfile1.rb",
         :path => "files/ubuntu-9.10/adirectory/anotherfile1.rb.platform-full-version",
         :full_path => "/cookbook-folder/files/ubuntu-9.10/adirectory/anotherfile1.rb.platform-full-version",
         :checksum => "csum-platver-full-1",
         :specificity => "ubuntu-9.10",
       },
       {
         :name => "files/anotherfile2.rb",
         :path => "files/ubuntu-9.10/adirectory/anotherfile2.rb.platform-full-version",
         :full_path => "/cookbook-folder/files/ubuntu-9.10/adirectory/anotherfile2.rb.platform-full-version",
         :checksum => "csum-platver-full-2",
         :specificity => "ubuntu-9.10",
       },

       {
         :name => "files/anotherfile1.rb",
         :path => "files/newubuntu-9/adirectory/anotherfile1.rb.platform-partial-version",
         :full_path => "/cookbook-folder/files/newubuntu-9/adirectory/anotherfile1.rb.platform-partial-version",
         :checksum => "csum-platver-partial-1",
         :specificity => "newubuntu-9",
       },
       {
         :name => "files/anotherfile2.rb",
         :path => "files/newubuntu-9/adirectory/anotherfile2.rb.platform-partial-version",
         :full_path => "/cookbook-folder/files/newubuntu-9/adirectory/anotherfile2.rb.platform-partial-version",
         :checksum => "csum-platver-partial-2",
         :specificity => "nweubuntu-9",
       },

       {
         :name => "files/anotherfile1.rb",
         :path => "files/ubuntu/adirectory/anotherfile1.rb.platform",
         :full_path => "/cookbook-folder/files/ubuntu/adirectory/anotherfile1.rb.platform",
         :checksum => "csum-plat-1",
         :specificity => "ubuntu",
       },
       {
         :name => "files/anotherfile2.rb",
         :path => "files/ubuntu/adirectory/anotherfile2.rb.platform",
         :full_path => "/cookbook-folder/files/ubuntu/adirectory/anotherfile2.rb.platform",
         :checksum => "csum-plat-2",
         :specificity => "ubuntu",
       },

       {
         :name => "files/anotherfile1.rb",
         :path => "files/default/adirectory/anotherfile1.rb.default",
         :full_path => "/cookbook-folder/files/default/adirectory/anotherfile1.rb.default",
         :checksum => "csum-default-1",
         :specificity => "default",
       },
       {
         :name => "files/anotherfile2.rb",
         :path => "files/default/adirectory/anotherfile2.rb.default",
         :full_path => "/cookbook-folder/files/default/adirectory/anotherfile2.rb.default",
         :checksum => "csum-default-2",
         :specificity => "default",
       },
       # for different/odd platform_versions
       {
         :name => "files/anotherfile1.rb",
         :path => "files/fakeos-2.0.rc.1/adirectory/anotherfile1.rb.platform-full-version",
         :full_path => "/cookbook-folder/files/fakeos-2.0.rc.1/adirectory/anotherfile1.rb.platform-full-version",
         :checksum => "csum2-platver-full-1",
         :specificity => "fakeos-2.0.rc.1",
       },
       {
         :name => "files/anotherfile2.rb",
         :path => "files/fakeos-2.0.rc.1/adirectory/anotherfile2.rb.platform-full-version",
         :full_path => "/cookbook-folder/files/fakeos-2.0.rc.1/adirectory/anotherfile2.rb.platform-full-version",
         :checksum => "csum2-platver-full-2",
         :specificity => "fakeos-2.0.rc.1",
       },
       {
         :name => "files/anotherfile1.rb",
         :path => "files/newfakeos-2.0.rc.1/adirectory/anotherfile1.rb.platform-partial-version",
         :full_path => "/cookbook-folder/files/newfakeos-2.0.rc.1/adirectory/anotherfile1.rb.platform-partial-version",
         :checksum => "csum2-platver-partial-1",
         :specificity => "newfakeos-2.0.rc",
       },
       {
         :name => "files/anotherfile2.rb",
         :path => "files/newfakeos-2.0.rc.1/adirectory/anotherfile2.rb.platform-partial-version",
         :full_path => "/cookbook-folder/files/newfakeos-2.0.rc.1/adirectory/anotherfile2.rb.platform-partial-version",
         :checksum => "csum2-platver-partial-2",
         :specificity => "newfakeos-2.0.rc",
       },
       {
         :name => "files/anotherfile1.rb",
         :path => "files/fakeos-maple tree/adirectory/anotherfile1.rb.platform-full-version",
         :full_path => "/cookbook-folder/files/fakeos-maple tree/adirectory/anotherfile1.rb.platform-full-version",
         :checksum => "csum3-platver-full-1",
         :specificity => "fakeos-maple tree",
       },
       {
         :name => "files/anotherfile2.rb",
         :path => "files/fakeos-maple tree/adirectory/anotherfile2.rb.platform-full-version",
         :full_path => "/cookbook-folder/files/fakeos-maple tree/adirectory/anotherfile2.rb.platform-full-version",
         :checksum => "csum3-platver-full-2",
         :specificity => "fakeos-maple tree",
       },
       {
         :name => "files/anotherfile1.rb",
         :path => "files/fakeos-1/adirectory/anotherfile1.rb.platform-full-version",
         :full_path => "/cookbook-folder/files/fakeos-1/adirectory/anotherfile1.rb.platform-full-version",
         :checksum => "csum4-platver-full-1",
         :specificity => "fakeos-1",
       },
       {
         :name => "files/anotherfile2.rb",
         :path => "files/fakeos-1/adirectory/anotherfile2.rb.platform-full-version",
         :full_path => "/cookbook-folder/files/fakeos-1/adirectory/anotherfile2.rb.platform-full-version",
         :checksum => "csum4-platver-full-2",
         :specificity => "fakeos-1",
       },
      ],
    }

  end

  it "should return a manifest record based on priority preference: host" do
    node = Chef::Node.new
    node.automatic_attrs[:platform] = "ubuntu"
    node.automatic_attrs[:platform_version] = "9.10"
    node.automatic_attrs[:fqdn] = "examplehost.example.org"

    manifest_record = @cookbook.preferred_manifest_record(node, :files, "afile.rb")
    expect(manifest_record).not_to be_nil
    expect(manifest_record[:checksum]).to eq("csum-host")
  end

  it "should return a manifest record based on priority preference: platform & full version" do
    node = Chef::Node.new
    node.automatic_attrs[:platform] = "ubuntu"
    node.automatic_attrs[:platform_version] = "9.10"
    node.automatic_attrs[:fqdn] = "differenthost.example.org"

    manifest_record = @cookbook.preferred_manifest_record(node, :files, "afile.rb")
    expect(manifest_record).not_to be_nil
    expect(manifest_record[:checksum]).to eq("csum-platver-full")
  end

  it "should return a manifest record based on priority preference: platform & partial version" do
    node = Chef::Node.new
    node.automatic_attrs[:platform] = "newubuntu"
    node.automatic_attrs[:platform_version] = "9.10"
    node.automatic_attrs[:fqdn] = "differenthost.example.org"

    manifest_record = @cookbook.preferred_manifest_record(node, :files, "afile.rb")
    expect(manifest_record).not_to be_nil
    expect(manifest_record[:checksum]).to eq("csum-platver-partial")
  end

  it "should return a manifest record based on priority preference: platform only" do
    node = Chef::Node.new
    node.automatic_attrs[:platform] = "ubuntu"
    node.automatic_attrs[:platform_version] = "1.0"
    node.automatic_attrs[:fqdn] = "differenthost.example.org"

    manifest_record = @cookbook.preferred_manifest_record(node, :files, "afile.rb")
    expect(manifest_record).not_to be_nil
    expect(manifest_record[:checksum]).to eq("csum-plat")
  end

  it "should return a manifest record based on priority preference: default" do
    node = Chef::Node.new
    node.automatic_attrs[:platform] = "notubuntu"
    node.automatic_attrs[:platform_version] = "1.0"
    node.automatic_attrs[:fqdn] = "differenthost.example.org"

    manifest_record = @cookbook.preferred_manifest_record(node, :files, "afile.rb")
    expect(manifest_record).not_to be_nil
    expect(manifest_record[:checksum]).to eq("csum-default")
  end

  it "should return a manifest record based on priority preference: platform & full version - platform_version variant 1" do
    node = Chef::Node.new
    node.automatic_attrs[:platform] = "fakeos"
    node.automatic_attrs[:platform_version] = "2.0.rc.1"
    node.automatic_attrs[:fqdn] = "differenthost.example.org"

    manifest_record = @cookbook.preferred_manifest_record(node, :files, "bfile.rb")
    expect(manifest_record).not_to be_nil
    expect(manifest_record[:checksum]).to eq("csum2-platver-full")
  end

  it "should return a manifest record based on priority preference: platform & partial version - platform_version variant 1" do
    node = Chef::Node.new
    node.automatic_attrs[:platform] = "newfakeos"
    node.automatic_attrs[:platform_version] = "2.0.rc.1"
    node.automatic_attrs[:fqdn] = "differenthost.example.org"

    manifest_record = @cookbook.preferred_manifest_record(node, :files, "bfile.rb")
    expect(manifest_record).not_to be_nil
    expect(manifest_record[:checksum]).to eq("csum2-platver-partial")
  end

  it "should return a manifest record based on priority preference: platform & full version - platform_version variant 2" do
    node = Chef::Node.new
    node.automatic_attrs[:platform] = "fakeos"
    node.automatic_attrs[:platform_version] = "maple tree"
    node.automatic_attrs[:fqdn] = "differenthost.example.org"

    manifest_record = @cookbook.preferred_manifest_record(node, :files, "bfile.rb")
    expect(manifest_record).not_to be_nil
    expect(manifest_record[:checksum]).to eq("csum3-platver-full")
  end

  it "should return a manifest record based on priority preference: platform & full version - platform_version variant 3" do
    node = Chef::Node.new
    node.automatic_attrs[:platform] = "fakeos"
    node.automatic_attrs[:platform_version] = "1"
    node.automatic_attrs[:fqdn] = "differenthost.example.org"

    manifest_record = @cookbook.preferred_manifest_record(node, :files, "bfile.rb")
    expect(manifest_record).not_to be_nil
    expect(manifest_record[:checksum]).to eq("csum4-platver-full")
  end

  it "should raise a FileNotFound exception without match" do
    node = Chef::Node.new

    expect do
      @cookbook.preferred_manifest_record(node, :files, "doesn't_exist.rb")
    end.to raise_error(Chef::Exceptions::FileNotFound)
  end
  it "should raise a FileNotFound exception consistently without match" do
    node = Chef::Node.new

    expect do
      @cookbook.preferred_manifest_record(node, :files, "doesn't_exist.rb")
    end.to raise_error(Chef::Exceptions::FileNotFound)

    expect do
      @cookbook.preferred_manifest_record(node, :files, "doesn't_exist.rb")
    end.to raise_error(Chef::Exceptions::FileNotFound)

    expect do
      @cookbook.preferred_manifest_record(node, :files, "doesn't_exist.rb")
    end.to raise_error(Chef::Exceptions::FileNotFound)
  end

  describe "when fetching the contents of a directory by file specificity" do

    it "should return a directory of manifest records based on priority preference: host" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "ubuntu"
      node.automatic_attrs[:platform_version] = "9.10"
      node.automatic_attrs[:fqdn] = "examplehost.example.org"

      manifest_records = @cookbook.preferred_manifest_records_for_directory(node, :files, "adirectory")
      expect(manifest_records).not_to be_nil
      expect(manifest_records.size).to eq(2)

      checksums = manifest_records.map { |manifest_record| manifest_record[:checksum] }
      expect(checksums.sort).to eq(["csum-host-1", "csum-host-2"])
    end

    it "should return a directory of manifest records based on priority preference: platform & full version" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "ubuntu"
      node.automatic_attrs[:platform_version] = "9.10"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      manifest_records = @cookbook.preferred_manifest_records_for_directory(node, :files, "adirectory")
      expect(manifest_records).not_to be_nil
      expect(manifest_records.size).to eq(2)

      checksums = manifest_records.map { |manifest_record| manifest_record[:checksum] }
      expect(checksums.sort).to eq(["csum-platver-full-1", "csum-platver-full-2"])
    end

    it "should return a directory of manifest records based on priority preference: platform & partial version" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "newubuntu"
      node.automatic_attrs[:platform_version] = "9.10"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      manifest_records = @cookbook.preferred_manifest_records_for_directory(node, :files, "adirectory")
      expect(manifest_records).not_to be_nil
      expect(manifest_records.size).to eq(2)

      checksums = manifest_records.map { |manifest_record| manifest_record[:checksum] }
      expect(checksums.sort).to eq(["csum-platver-partial-1", "csum-platver-partial-2"])
    end

    it "should return a directory of manifest records based on priority preference: platform only" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "ubuntu"
      node.automatic_attrs[:platform_version] = "1.0"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      manifest_records = @cookbook.preferred_manifest_records_for_directory(node, :files, "adirectory")
      expect(manifest_records).not_to be_nil
      expect(manifest_records.size).to eq(2)

      checksums = manifest_records.map { |manifest_record| manifest_record[:checksum] }
      expect(checksums.sort).to eq(["csum-plat-1", "csum-plat-2"])
    end

    it "should return a directory of manifest records based on priority preference: default" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "notubuntu"
      node.automatic_attrs[:platform_version] = "1.0"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      manifest_records = @cookbook.preferred_manifest_records_for_directory(node, :files, "adirectory")
      expect(manifest_records).not_to be_nil
      expect(manifest_records.size).to eq(2)

      checksums = manifest_records.map { |manifest_record| manifest_record[:checksum] }
      expect(checksums.sort).to eq(["csum-default-1", "csum-default-2"])
    end

    it "should return a manifest record based on priority preference: platform & full version - platform_version variant 1" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "fakeos"
      node.automatic_attrs[:platform_version] = "2.0.rc.1"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      manifest_records = @cookbook.preferred_manifest_records_for_directory(node, :files, "adirectory")
      expect(manifest_records).not_to be_nil
      expect(manifest_records.size).to eq(2)

      checksums = manifest_records.map { |manifest_record| manifest_record[:checksum] }
      expect(checksums.sort).to eq(["csum2-platver-full-1", "csum2-platver-full-2"])
    end

    it "should return a manifest record based on priority preference: platform & partial version - platform_version variant 1" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "newfakeos"
      node.automatic_attrs[:platform_version] = "2.0.rc.1"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      manifest_records = @cookbook.preferred_manifest_records_for_directory(node, :files, "adirectory")
      expect(manifest_records).not_to be_nil
      expect(manifest_records.size).to eq(2)

      checksums = manifest_records.map { |manifest_record| manifest_record[:checksum] }
      expect(checksums.sort).to eq(["csum2-platver-partial-1", "csum2-platver-partial-2"])
    end

    it "should return a manifest record based on priority preference: platform & full version - platform_version variant 2" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "fakeos"
      node.automatic_attrs[:platform_version] = "maple tree"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      manifest_records = @cookbook.preferred_manifest_records_for_directory(node, :files, "adirectory")
      expect(manifest_records).not_to be_nil
      expect(manifest_records.size).to eq(2)

      checksums = manifest_records.map { |manifest_record| manifest_record[:checksum] }
      expect(checksums.sort).to eq(["csum3-platver-full-1", "csum3-platver-full-2"])
    end

    it "should return a manifest record based on priority preference: platform & full version - platform_version variant 3" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "fakeos"
      node.automatic_attrs[:platform_version] = "1"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      manifest_records = @cookbook.preferred_manifest_records_for_directory(node, :files, "adirectory")
      expect(manifest_records).not_to be_nil
      expect(manifest_records.size).to eq(2)

      checksums = manifest_records.map { |manifest_record| manifest_record[:checksum] }
      expect(checksums.sort).to eq(["csum4-platver-full-1", "csum4-platver-full-2"])
    end
  end

  ## Globbing the relative paths out of the manifest records ##

  describe "when globbing for relative file paths based on filespecificity" do
    it "should return a list of relative paths based on priority preference: host" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "ubuntu"
      node.automatic_attrs[:platform_version] = "9.10"
      node.automatic_attrs[:fqdn] = "examplehost.example.org"

      filenames = @cookbook.relative_filenames_in_preferred_directory(node, :files, "adirectory")
      expect(filenames).not_to be_nil
      expect(filenames.size).to eq(2)

      expect(filenames.sort).to eq(["anotherfile1.rb.host", "anotherfile2.rb.host"])
    end

    it "should return a list of relative paths based on priority preference: platform & full version" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "ubuntu"
      node.automatic_attrs[:platform_version] = "9.10"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      filenames = @cookbook.relative_filenames_in_preferred_directory(node, :files, "adirectory")
      expect(filenames).not_to be_nil
      expect(filenames.size).to eq(2)

      expect(filenames.sort).to eq(["anotherfile1.rb.platform-full-version", "anotherfile2.rb.platform-full-version"])
    end

    it "should return a list of relative paths based on priority preference: platform & partial version" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "newubuntu"
      node.automatic_attrs[:platform_version] = "9.10"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      filenames = @cookbook.relative_filenames_in_preferred_directory(node, :files, "adirectory")
      expect(filenames).not_to be_nil
      expect(filenames.size).to eq(2)

      expect(filenames.sort).to eq(["anotherfile1.rb.platform-partial-version", "anotherfile2.rb.platform-partial-version"])
    end

    it "should return a list of relative paths based on priority preference: platform only" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "ubuntu"
      node.automatic_attrs[:platform_version] = "1.0"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      filenames = @cookbook.relative_filenames_in_preferred_directory(node, :files, "adirectory")
      expect(filenames).not_to be_nil
      expect(filenames.size).to eq(2)

      expect(filenames.sort).to eq(["anotherfile1.rb.platform", "anotherfile2.rb.platform"])
    end

    it "should return a list of relative paths based on priority preference: default" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "notubuntu"
      node.automatic_attrs[:platform_version] = "1.0"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      filenames = @cookbook.relative_filenames_in_preferred_directory(node, :files, "adirectory")
      expect(filenames).not_to be_nil
      expect(filenames.size).to eq(2)

      expect(filenames.sort).to eq(["anotherfile1.rb.default", "anotherfile2.rb.default"])
    end

    it "should return a list of relative paths based on priority preference: platform & full version - platform_version variant 1" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "fakeos"
      node.automatic_attrs[:platform_version] = "2.0.rc.1"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      filenames = @cookbook.relative_filenames_in_preferred_directory(node, :files, "adirectory")
      expect(filenames).not_to be_nil
      expect(filenames.size).to eq(2)

      expect(filenames.sort).to eq(["anotherfile1.rb.platform-full-version", "anotherfile2.rb.platform-full-version"])
    end

    it "should return a list of relative paths based on priority preference: platform & partial version - platform_version variant 1" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "newfakeos"
      node.automatic_attrs[:platform_version] = "2.0.rc.1"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      filenames = @cookbook.relative_filenames_in_preferred_directory(node, :files, "adirectory")
      expect(filenames).not_to be_nil
      expect(filenames.size).to eq(2)

      expect(filenames.sort).to eq(["anotherfile1.rb.platform-partial-version", "anotherfile2.rb.platform-partial-version"])
    end

    it "should return a list of relative paths based on priority preference: platform & full version - platform_version variant 2" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "fakeos"
      node.automatic_attrs[:platform_version] = "maple tree"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      filenames = @cookbook.relative_filenames_in_preferred_directory(node, :files, "adirectory")
      expect(filenames).not_to be_nil
      expect(filenames.size).to eq(2)

      expect(filenames.sort).to eq(["anotherfile1.rb.platform-full-version", "anotherfile2.rb.platform-full-version"])
    end

    it "should return a list of relative paths based on priority preference: platform & full version - platform_version variant 3" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "fakeos"
      node.automatic_attrs[:platform_version] = "1"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      filenames = @cookbook.relative_filenames_in_preferred_directory(node, :files, "adirectory")
      expect(filenames).not_to be_nil
      expect(filenames.size).to eq(2)

      expect(filenames.sort).to eq(["anotherfile1.rb.platform-full-version", "anotherfile2.rb.platform-full-version"])
    end
  end
end
