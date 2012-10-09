#
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

require 'spec_helper'

describe "Chef::CookbookVersion manifest" do
  before(:each) do
    @cookbook = Chef::CookbookVersion.new "test-cookbook"
    @cookbook.manifest = {
      "files" =>
      [
       # afile.rb
       {
         :name => "afile.rb",
         :path => "files/host-examplehost.example.org/afile.rb",
         :checksum => "csum-host",
         :specificity => "host-examplehost.example.org"
       },
       {
         :name => "afile.rb",
         :path => "files/ubuntu-9.10/afile.rb",
         :checksum => "csum-platver-full",
         :specificity => "ubuntu-9.10"
       },
       {
         :name => "afile.rb",
         :path => "files/newubuntu-9/afile.rb",
         :checksum => "csum-platver-partial",
         :specificity => "newubuntu-9"
       },
       {
         :name => "afile.rb",
         :path => "files/ubuntu/afile.rb",
         :checksum => "csum-plat",
         :specificity => "ubuntu"
       },
       {
         :name => "afile.rb",
         :path => "files/default/afile.rb",
         :checksum => "csum-default",
         :specificity => "default"
       },

       # for different/odd platform_versions
       {
         :name => "bfile.rb",
         :path => "files/fakeos-2.0.rc.1/bfile.rb",
         :checksum => "csum2-platver-full",
         :specificity => "fakeos-2.0.rc.1"
       },
       {
         :name => "bfile.rb",
         :path => "files/newfakeos-2.0.rc/bfile.rb",
         :checksum => "csum2-platver-partial",
         :specificity => "newfakeos-2.0.rc"
       },
       {
         :name => "bfile.rb",
         :path => "files/fakeos-maple tree/bfile.rb",
         :checksum => "csum3-platver-full",
         :specificity => "maple tree"
       },
       {
         :name => "bfile.rb",
         :path => "files/fakeos-1/bfile.rb",
         :checksum => "csum4-platver-full",
         :specificity => "fakeos-1"
       },

       # directory adirectory
       {
         :name => "anotherfile1.rb",
         :path => "files/host-examplehost.example.org/adirectory/anotherfile1.rb.host",
         :checksum => "csum-host-1",
         :specificity => "host-examplehost.example.org"
       },
       {
         :name => "anotherfile2.rb",
         :path => "files/host-examplehost.example.org/adirectory/anotherfile2.rb.host",
         :checksum => "csum-host-2",
         :specificity => "host-examplehost.example.org"
       },
       
       {
         :name => "anotherfile1.rb",
         :path => "files/ubuntu-9.10/adirectory/anotherfile1.rb.platform-full-version",
         :checksum => "csum-platver-full-1",
         :specificity => "ubuntu-9.10"
       },
       {
         :name => "anotherfile2.rb",
         :path => "files/ubuntu-9.10/adirectory/anotherfile2.rb.platform-full-version",
         :checksum => "csum-platver-full-2",
         :specificity => "ubuntu-9.10"
       },

       {
         :name => "anotherfile1.rb",
         :path => "files/newubuntu-9/adirectory/anotherfile1.rb.platform-partial-version",
         :checksum => "csum-platver-partial-1",
         :specificity => "newubuntu-9"
       },
       {
         :name => "anotherfile2.rb",
         :path => "files/newubuntu-9/adirectory/anotherfile2.rb.platform-partial-version",
         :checksum => "csum-platver-partial-2",
         :specificity => "nweubuntu-9"
       },
       
       {
         :name => "anotherfile1.rb",
         :path => "files/ubuntu/adirectory/anotherfile1.rb.platform",
         :checksum => "csum-plat-1",
         :specificity => "ubuntu"
       },
       {
         :name => "anotherfile2.rb",
         :path => "files/ubuntu/adirectory/anotherfile2.rb.platform",
         :checksum => "csum-plat-2",
         :specificity => "ubuntu"
       },
       
       {
         :name => "anotherfile1.rb",
         :path => "files/default/adirectory/anotherfile1.rb.default",
         :checksum => "csum-default-1",
         :specificity => "default"
       },
       {
         :name => "anotherfile2.rb",
         :path => "files/default/adirectory/anotherfile2.rb.default",
         :checksum => "csum-default-2",
         :specificity => "default"
       },
       # for different/odd platform_versions
       {
         :name => "anotherfile1.rb",
         :path => "files/fakeos-2.0.rc.1/adirectory/anotherfile1.rb.platform-full-version",
         :checksum => "csum2-platver-full-1",
         :specificity => "fakeos-2.0.rc.1"
       },
       {
         :name => "anotherfile2.rb",
         :path => "files/fakeos-2.0.rc.1/adirectory/anotherfile2.rb.platform-full-version",
         :checksum => "csum2-platver-full-2",
         :specificity => "fakeos-2.0.rc.1"
       },
       {
         :name => "anotherfile1.rb",
         :path => "files/newfakeos-2.0.rc.1/adirectory/anotherfile1.rb.platform-partial-version",
         :checksum => "csum2-platver-partial-1",
         :specificity => "newfakeos-2.0.rc"
       },
       {
         :name => "anotherfile2.rb",
         :path => "files/newfakeos-2.0.rc.1/adirectory/anotherfile2.rb.platform-partial-version",
         :checksum => "csum2-platver-partial-2",
         :specificity => "newfakeos-2.0.rc"
       },
       {
         :name => "anotherfile1.rb",
         :path => "files/fakeos-maple tree/adirectory/anotherfile1.rb.platform-full-version",
         :checksum => "csum3-platver-full-1",
         :specificity => "fakeos-maple tree"
       },
       {
         :name => "anotherfile2.rb",
         :path => "files/fakeos-maple tree/adirectory/anotherfile2.rb.platform-full-version",
         :checksum => "csum3-platver-full-2",
         :specificity => "fakeos-maple tree"
       },
       {
         :name => "anotherfile1.rb",
         :path => "files/fakeos-1/adirectory/anotherfile1.rb.platform-full-version",
         :checksum => "csum4-platver-full-1",
         :specificity => "fakeos-1"
       },
       {
         :name => "anotherfile2.rb",
         :path => "files/fakeos-1/adirectory/anotherfile2.rb.platform-full-version",
         :checksum => "csum4-platver-full-2",
         :specificity => "fakeos-1"
       },
      ]
    }

  end
  
  
  it "should return a manifest record based on priority preference: host" do
    node = Chef::Node.new
    node.automatic_attrs[:platform] = "ubuntu"
    node.automatic_attrs[:platform_version] = "9.10"
    node.automatic_attrs[:fqdn] = "examplehost.example.org"

    manifest_record = @cookbook.preferred_manifest_record(node, :files, "afile.rb")
    manifest_record.should_not be_nil
    manifest_record[:checksum].should == "csum-host"
  end
  
  it "should return a manifest record based on priority preference: platform & full version" do
    node = Chef::Node.new
    node.automatic_attrs[:platform] = "ubuntu"
    node.automatic_attrs[:platform_version] = "9.10"
    node.automatic_attrs[:fqdn] = "differenthost.example.org"

    manifest_record = @cookbook.preferred_manifest_record(node, :files, "afile.rb")
    manifest_record.should_not be_nil
    manifest_record[:checksum].should == "csum-platver-full"
  end

  it "should return a manifest record based on priority preference: platform & partial version" do
    node = Chef::Node.new
    node.automatic_attrs[:platform] = "newubuntu"
    node.automatic_attrs[:platform_version] = "9.10"
    node.automatic_attrs[:fqdn] = "differenthost.example.org"

    manifest_record = @cookbook.preferred_manifest_record(node, :files, "afile.rb")
    manifest_record.should_not be_nil
    manifest_record[:checksum].should == "csum-platver-partial"
  end
  
  it "should return a manifest record based on priority preference: platform only" do
    node = Chef::Node.new
    node.automatic_attrs[:platform] = "ubuntu"
    node.automatic_attrs[:platform_version] = "1.0"
    node.automatic_attrs[:fqdn] = "differenthost.example.org"

    manifest_record = @cookbook.preferred_manifest_record(node, :files, "afile.rb")
    manifest_record.should_not be_nil
    manifest_record[:checksum].should == "csum-plat"
  end
  
  it "should return a manifest record based on priority preference: default" do
    node = Chef::Node.new
    node.automatic_attrs[:platform] = "notubuntu"
    node.automatic_attrs[:platform_version] = "1.0"
    node.automatic_attrs[:fqdn] = "differenthost.example.org"

    manifest_record = @cookbook.preferred_manifest_record(node, :files, "afile.rb")
    manifest_record.should_not be_nil
    manifest_record[:checksum].should == "csum-default"
  end

  it "should return a manifest record based on priority preference: platform & full version - platform_version variant 1" do
    node = Chef::Node.new
    node.automatic_attrs[:platform] = "fakeos"
    node.automatic_attrs[:platform_version] = "2.0.rc.1"
    node.automatic_attrs[:fqdn] = "differenthost.example.org"

    manifest_record = @cookbook.preferred_manifest_record(node, :files, "bfile.rb")
    manifest_record.should_not be_nil
    manifest_record[:checksum].should == "csum2-platver-full"
  end

  it "should return a manifest record based on priority preference: platform & partial version - platform_version variant 1" do
    node = Chef::Node.new
    node.automatic_attrs[:platform] = "newfakeos"
    node.automatic_attrs[:platform_version] = "2.0.rc.1"
    node.automatic_attrs[:fqdn] = "differenthost.example.org"

    manifest_record = @cookbook.preferred_manifest_record(node, :files, "bfile.rb")
    manifest_record.should_not be_nil
    manifest_record[:checksum].should == "csum2-platver-partial"
  end

  it "should return a manifest record based on priority preference: platform & full version - platform_version variant 2" do
    node = Chef::Node.new
    node.automatic_attrs[:platform] = "fakeos"
    node.automatic_attrs[:platform_version] = "maple tree"
    node.automatic_attrs[:fqdn] = "differenthost.example.org"

    manifest_record = @cookbook.preferred_manifest_record(node, :files, "bfile.rb")
    manifest_record.should_not be_nil
    manifest_record[:checksum].should == "csum3-platver-full"
  end

  it "should return a manifest record based on priority preference: platform & full version - platform_version variant 3" do
    node = Chef::Node.new
    node.automatic_attrs[:platform] = "fakeos"
    node.automatic_attrs[:platform_version] = "1"
    node.automatic_attrs[:fqdn] = "differenthost.example.org"

    manifest_record = @cookbook.preferred_manifest_record(node, :files, "bfile.rb")
    manifest_record.should_not be_nil
    manifest_record[:checksum].should == "csum4-platver-full"
  end
  
  describe "when fetching the contents of a directory by file specificity" do

    it "should return a directory of manifest records based on priority preference: host" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "ubuntu"
      node.automatic_attrs[:platform_version] = "9.10"
      node.automatic_attrs[:fqdn] = "examplehost.example.org"

      manifest_records = @cookbook.preferred_manifest_records_for_directory(node, :files, "adirectory")
      manifest_records.should_not be_nil
      manifest_records.size.should == 2

      checksums = manifest_records.map{ |manifest_record| manifest_record[:checksum] }
      checksums.sort.should == ["csum-host-1", "csum-host-2"]
    end

    it "should return a directory of manifest records based on priority preference: platform & full version" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "ubuntu"
      node.automatic_attrs[:platform_version] = "9.10"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      manifest_records = @cookbook.preferred_manifest_records_for_directory(node, :files, "adirectory")
      manifest_records.should_not be_nil
      manifest_records.size.should == 2

      checksums = manifest_records.map{ |manifest_record| manifest_record[:checksum] }
      checksums.sort.should == ["csum-platver-full-1", "csum-platver-full-2"]
    end

    it "should return a directory of manifest records based on priority preference: platform & partial version" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "newubuntu"
      node.automatic_attrs[:platform_version] = "9.10"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      manifest_records = @cookbook.preferred_manifest_records_for_directory(node, :files, "adirectory")
      manifest_records.should_not be_nil
      manifest_records.size.should == 2

      checksums = manifest_records.map{ |manifest_record| manifest_record[:checksum] }
      checksums.sort.should == ["csum-platver-partial-1", "csum-platver-partial-2"]
    end

    it "should return a directory of manifest records based on priority preference: platform only" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "ubuntu"
      node.automatic_attrs[:platform_version] = "1.0"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      manifest_records = @cookbook.preferred_manifest_records_for_directory(node, :files, "adirectory")
      manifest_records.should_not be_nil
      manifest_records.size.should == 2

      checksums = manifest_records.map{ |manifest_record| manifest_record[:checksum] }
      checksums.sort.should == ["csum-plat-1", "csum-plat-2"]
    end

    it "should return a directory of manifest records based on priority preference: default" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "notubuntu"
      node.automatic_attrs[:platform_version] = "1.0"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      manifest_records = @cookbook.preferred_manifest_records_for_directory(node, :files, "adirectory")
      manifest_records.should_not be_nil
      manifest_records.size.should == 2

      checksums = manifest_records.map{ |manifest_record| manifest_record[:checksum] }
      checksums.sort.should == ["csum-default-1", "csum-default-2"]
    end

    it "should return a manifest record based on priority preference: platform & full version - platform_version variant 1" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "fakeos"
      node.automatic_attrs[:platform_version] = "2.0.rc.1"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      manifest_records = @cookbook.preferred_manifest_records_for_directory(node, :files, "adirectory")
      manifest_records.should_not be_nil
      manifest_records.size.should == 2

      checksums = manifest_records.map{ |manifest_record| manifest_record[:checksum] }
      checksums.sort.should == ["csum2-platver-full-1", "csum2-platver-full-2"]
    end

    it "should return a manifest record based on priority preference: platform & partial version - platform_version variant 1" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "newfakeos"
      node.automatic_attrs[:platform_version] = "2.0.rc.1"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      manifest_records = @cookbook.preferred_manifest_records_for_directory(node, :files, "adirectory")
      manifest_records.should_not be_nil
      manifest_records.size.should == 2

      checksums = manifest_records.map{ |manifest_record| manifest_record[:checksum] }
      checksums.sort.should == ["csum2-platver-partial-1", "csum2-platver-partial-2"]
    end

    it "should return a manifest record based on priority preference: platform & full version - platform_version variant 2" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "fakeos"
      node.automatic_attrs[:platform_version] = "maple tree"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      manifest_records = @cookbook.preferred_manifest_records_for_directory(node, :files, "adirectory")
      manifest_records.should_not be_nil
      manifest_records.size.should == 2

      checksums = manifest_records.map{ |manifest_record| manifest_record[:checksum] }
      checksums.sort.should == ["csum3-platver-full-1", "csum3-platver-full-2"]
    end

    it "should return a manifest record based on priority preference: platform & full version - platform_version variant 3" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "fakeos"
      node.automatic_attrs[:platform_version] = "1"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      manifest_records = @cookbook.preferred_manifest_records_for_directory(node, :files, "adirectory")
      manifest_records.should_not be_nil
      manifest_records.size.should == 2

      checksums = manifest_records.map{ |manifest_record| manifest_record[:checksum] }
      checksums.sort.should == ["csum4-platver-full-1", "csum4-platver-full-2"]
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
      filenames.should_not be_nil
      filenames.size.should == 2

      filenames.sort.should == ['anotherfile1.rb.host', 'anotherfile2.rb.host']
    end

    it "should return a list of relative paths based on priority preference: platform & full version" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "ubuntu"
      node.automatic_attrs[:platform_version] = "9.10"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      filenames = @cookbook.relative_filenames_in_preferred_directory(node, :files, "adirectory")
      filenames.should_not be_nil
      filenames.size.should == 2

      filenames.sort.should == ['anotherfile1.rb.platform-full-version', 'anotherfile2.rb.platform-full-version']
    end

    it "should return a list of relative paths based on priority preference: platform & partial version" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "newubuntu"
      node.automatic_attrs[:platform_version] = "9.10"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      filenames = @cookbook.relative_filenames_in_preferred_directory(node, :files, "adirectory")
      filenames.should_not be_nil
      filenames.size.should == 2

      filenames.sort.should == ['anotherfile1.rb.platform-partial-version', 'anotherfile2.rb.platform-partial-version']
    end

    it "should return a list of relative paths based on priority preference: platform only" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "ubuntu"
      node.automatic_attrs[:platform_version] = "1.0"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      filenames = @cookbook.relative_filenames_in_preferred_directory(node, :files, "adirectory")
      filenames.should_not be_nil
      filenames.size.should == 2

      filenames.sort.should == ['anotherfile1.rb.platform', 'anotherfile2.rb.platform']
    end

    it "should return a list of relative paths based on priority preference: default" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "notubuntu"
      node.automatic_attrs[:platform_version] = "1.0"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      filenames = @cookbook.relative_filenames_in_preferred_directory(node, :files, "adirectory")
      filenames.should_not be_nil
      filenames.size.should == 2

      filenames.sort.should == ['anotherfile1.rb.default', 'anotherfile2.rb.default']
    end

    it "should return a list of relative paths based on priority preference: platform & full version - platform_version variant 1" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "fakeos"
      node.automatic_attrs[:platform_version] = "2.0.rc.1"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      filenames = @cookbook.relative_filenames_in_preferred_directory(node, :files, "adirectory")
      filenames.should_not be_nil
      filenames.size.should == 2

      filenames.sort.should == ['anotherfile1.rb.platform-full-version', 'anotherfile2.rb.platform-full-version']
    end

    it "should return a list of relative paths based on priority preference: platform & partial version - platform_version variant 1" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "newfakeos"
      node.automatic_attrs[:platform_version] = "2.0.rc.1"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      filenames = @cookbook.relative_filenames_in_preferred_directory(node, :files, "adirectory")
      filenames.should_not be_nil
      filenames.size.should == 2

      filenames.sort.should == ['anotherfile1.rb.platform-partial-version', 'anotherfile2.rb.platform-partial-version']
    end

    it "should return a list of relative paths based on priority preference: platform & full version - platform_version variant 2" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "fakeos"
      node.automatic_attrs[:platform_version] = "maple tree"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      filenames = @cookbook.relative_filenames_in_preferred_directory(node, :files, "adirectory")
      filenames.should_not be_nil
      filenames.size.should == 2

      filenames.sort.should == ['anotherfile1.rb.platform-full-version', 'anotherfile2.rb.platform-full-version']
    end

    it "should return a list of relative paths based on priority preference: platform & full version - platform_version variant 3" do
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "fakeos"
      node.automatic_attrs[:platform_version] = "1"
      node.automatic_attrs[:fqdn] = "differenthost.example.org"

      filenames = @cookbook.relative_filenames_in_preferred_directory(node, :files, "adirectory")
      filenames.should_not be_nil
      filenames.size.should == 2

      filenames.sort.should == ['anotherfile1.rb.platform-full-version', 'anotherfile2.rb.platform-full-version']
    end
  end
end
