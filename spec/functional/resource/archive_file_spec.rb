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

  # These tests use archives that contain entries with path traversal
  # sequences. The resource must raise an error and NOT write any files outside
  # the destination directory.

  context "path traversal protection" do
    let(:parent_dir) { tmp_path }

    after do
      # Clean up any files that may have escaped (only relevant if fix is broken)
      File.delete(File.join(parent_dir, "pwned_dotdot.txt")) rescue nil
      File.delete(File.join(parent_dir, "pwned_deep.txt"))  rescue nil
      File.delete("/tmp/pwned_absolute.txt")                rescue nil
    end

    context "with an archive containing a dot-dot traversal entry (../pwned_dotdot.txt)" do
      let(:archive_path) { File.expand_path("archive_file/path_traversal_dotdot.tar.gz", CHEF_SPEC_DATA) }

      it "raises Chef::Exceptions::ValidationFailed and does not write outside the destination" do
        expect do
          archive_file archive_path do
            destination extract_destination
            overwrite true
          end.run_action(:extract)
        end.to raise_error(Chef::Exceptions::ValidationFailed, /path traversal/i)

        expect(File.exist?(File.join(parent_dir, "pwned_dotdot.txt"))).to eq(false),
          "traversal payload must not have escaped to #{parent_dir}"
      end

      it "does not write the safe_file.txt either (extraction aborts on traversal)" do
        archive_file(archive_path) { destination extract_destination; overwrite true }.run_action(:extract) rescue Chef::Exceptions::ValidationFailed
        # safe_file.txt comes BEFORE the traversal entry in the archive, so it may
        # have been extracted already. We only guarantee the traversal payload did not escape.
        expect(File.exist?(File.join(parent_dir, "pwned_dotdot.txt"))).to eq(false)
      end
    end

    context "with an archive containing an absolute-path entry (/tmp/pwned_absolute.txt)" do
      let(:archive_path) { File.expand_path("archive_file/path_traversal_absolute.tar.gz", CHEF_SPEC_DATA) }

      it "raises Chef::Exceptions::ValidationFailed and does not write to the absolute path" do
        expect do
          archive_file archive_path do
            destination extract_destination
            overwrite true
          end.run_action(:extract)
        end.to raise_error(Chef::Exceptions::ValidationFailed, /path traversal/i)

        expect(File.exist?("/tmp/pwned_absolute.txt")).to eq(false),
          "traversal payload must not have been written to /tmp/pwned_absolute.txt"
      end
    end

    context "with an archive containing a deep dot-dot traversal entry (subdir/../../pwned_deep.txt)" do
      let(:archive_path) { File.expand_path("archive_file/path_traversal_deep.tar.gz", CHEF_SPEC_DATA) }

      it "raises Chef::Exceptions::ValidationFailed and does not write outside the destination" do
        expect do
          archive_file archive_path do
            destination extract_destination
            overwrite true
          end.run_action(:extract)
        end.to raise_error(Chef::Exceptions::ValidationFailed, /path traversal/i)

        expect(File.exist?(File.join(parent_dir, "pwned_deep.txt"))).to eq(false),
          "traversal payload must not have escaped to #{parent_dir}"
      end
    end
  end
end
