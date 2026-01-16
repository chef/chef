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
#

require "spec_helper"
require "tmpdir"

# AIX is broken, see https://github.com/chef/omnibus-software/issues/1566
# Windows tests are disbled since we'd need libarchive on windows testers in buildkite for PRs
describe Chef::Resource::ArchiveFile, :not_supported_on_aix, :not_supported_on_windows do
  include RecipeDSLHelper

  let(:tmp_path) { Dir.mktmpdir }
  let(:extract_destination) { "#{tmp_path}/extract_here" }
  let(:test_archive_path) { File.expand_path("archive_file/test_archive.tar.gz", CHEF_SPEC_DATA) }

  after do
    FileUtils.remove_entry_secure(extract_destination) if File.exist?(extract_destination)
  end

  context "when strip_components is 0" do
    it "extracts archive to destination" do
      af = archive_file test_archive_path do
        destination extract_destination
      end
      af.should_be_updated

      expect(af.strip_components).to eq(0) # Validate defaults haven't changed here
      expect(Dir.glob("#{extract_destination}/**/*").length).to eq(4)
      expect(Dir.exist?("#{extract_destination}/folder-1")).to eq(true)
      expect(File.exist?("#{extract_destination}/folder-1/file-1.txt")).to eq(true)
      expect(Dir.exist?("#{extract_destination}/folder-1/folder-2")).to eq(true)
      expect(File.exist?("#{extract_destination}/folder-1/folder-2/file-2.txt")).to eq(true)
    end
  end

  context "when strip_components is 1" do
    it "extracts archive to destination, with 1 component stripped" do
      archive_file test_archive_path do
        destination extract_destination
        strip_components 1
      end.should_be_updated

      expect(Dir.exist?("#{extract_destination}/folder-1")).to eq(false)
      expect(File.exist?("#{extract_destination}/folder-1/file-1.txt")).to eq(false)
      expect(Dir.exist?("#{extract_destination}/folder-1/folder-2")).to eq(false)
      expect(File.exist?("#{extract_destination}/folder-1/folder-2/file-2.txt")).to eq(false)

      expect(Dir.glob("#{extract_destination}/**/*").length).to eq(3)
      expect(File.exist?("#{extract_destination}/file-1.txt")).to eq(true)
      expect(Dir.exist?("#{extract_destination}/folder-2")).to eq(true)
      expect(File.exist?("#{extract_destination}/folder-2/file-2.txt")).to eq(true)
    end
  end

  context "when strip_components is 2" do
    it "extracts archive to destination, with 2 components stripped" do
      archive_file test_archive_path do
        destination extract_destination
        strip_components 2
      end.should_be_updated

      expect(Dir.exist?("#{extract_destination}/folder-1")).to eq(false)
      expect(File.exist?("#{extract_destination}/folder-1/file-1.txt")).to eq(false)
      expect(Dir.exist?("#{extract_destination}/folder-1/folder-2")).to eq(false)
      expect(File.exist?("#{extract_destination}/folder-1/folder-2/file-2.txt")).to eq(false)
      expect(File.exist?("#{extract_destination}/file-1.txt")).to eq(false)
      expect(Dir.exist?("#{extract_destination}/folder-2")).to eq(false)
      expect(File.exist?("#{extract_destination}/folder-2/file-2.txt")).to eq(false)

      expect(Dir.glob("#{extract_destination}/**/*").length).to eq(1)
      expect(File.exist?("#{extract_destination}/file-2.txt")).to eq(true)
    end
  end
end
