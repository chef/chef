#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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

describe Chef::Util::Backup do

  let (:tempfile) do
    Tempfile.new("chef-util-backup-spec-test")
  end

  before(:each) do
    @new_resource = double("new_resource")
    expect(@new_resource).to receive(:path).at_least(:once).and_return(tempfile.path)
    @backup = Chef::Util::Backup.new(@new_resource)
  end

  it "should store the resource passed to new as new_resource" do
    expect(@backup.new_resource).to eql(@new_resource)
  end

  describe "for cases when we don't want to back anything up" do

    before(:each) do
      expect(@backup).not_to receive(:do_backup)
    end

    it "should not attempt to backup a file if :backup is false" do
      expect(@new_resource).to receive(:backup).at_least(:once).and_return(false)
      @backup.backup!
    end

    it "should not attempt to backup a file if :backup == 0" do
      expect(@new_resource).to receive(:backup).at_least(:once).and_return(0)
      @backup.backup!
    end

    it "should not attempt to backup a file if it does not exist" do
      expect(@new_resource).to receive(:backup).at_least(:once).and_return(1)
      expect(File).to receive(:exist?).with(tempfile.path).at_least(:once).and_return(false)
      @backup.backup!
    end

  end

  describe "for cases when we want to back things up" do
    before(:each) do
      expect(@backup).to receive(:do_backup)
    end

    describe "when the number of backups is specified as 1" do
      before(:each) do
        expect(@new_resource).to receive(:backup).at_least(:once).and_return(1)
      end

      it "should not delete anything if this is the only backup" do
        expect(@backup).to receive(:sorted_backup_files).and_return(["a"])
        expect(@backup).not_to receive(:delete_backup)
        @backup.backup!
      end

      it "should keep only 1 backup copy" do
        expect(@backup).to receive(:sorted_backup_files).and_return(%w{a b c})
        expect(@backup).to receive(:delete_backup).with("b")
        expect(@backup).to receive(:delete_backup).with("c")
        @backup.backup!
      end
    end

    describe "when the number of backups is specified as 2" do
      before(:each) do
        expect(@new_resource).to receive(:backup).at_least(:once).and_return(2)
      end

      it "should not delete anything if we only have one other backup" do
        expect(@backup).to receive(:sorted_backup_files).and_return(%w{a b})
        expect(@backup).not_to receive(:delete_backup)
        @backup.backup!
      end

      it "should keep only 2 backup copies" do
        expect(@backup).to receive(:sorted_backup_files).and_return(%w{a b c d})
        expect(@backup).to receive(:delete_backup).with("c")
        expect(@backup).to receive(:delete_backup).with("d")
        @backup.backup!
      end
    end
  end

  describe "backup_filename" do
    it "should return a timestamped path" do
      expect(@backup).to receive(:path).and_return("/a/b/c.txt")
      expect(@backup.send(:backup_filename)).to match(%r|^/a/b/c.txt.chef-\d{14}.\d{6}$|)
    end
    it "should strip the drive letter off for windows" do
      expect(@backup).to receive(:path).and_return('c:\a\b\c.txt')
      expect(@backup.send(:backup_filename)).to match(%r|^\\a\\b\\c.txt.chef-\d{14}.\d{6}$|)
    end
    it "should strip the drive letter off for windows (with forwardslashes)" do
      expect(@backup).to receive(:path).and_return("c:/a/b/c.txt")
      expect(@backup.send(:backup_filename)).to match(%r|^/a/b/c.txt.chef-\d{14}.\d{6}$|)
    end
  end

  describe "backup_path" do
    it "uses the file's directory when Chef::Config[:file_backup_path] is nil" do
      expect(@backup).to receive(:path).and_return("/a/b/c.txt")
      Chef::Config[:file_backup_path] = nil
      expect(@backup.send(:backup_path)).to match(%r|^/a/b/c.txt.chef-\d{14}.\d{6}$|)
    end

    it "uses the configured Chef::Config[:file_backup_path]" do
      expect(@backup).to receive(:path).and_return("/a/b/c.txt")
      Chef::Config[:file_backup_path] = "/backupdir"
      expect(@backup.send(:backup_path)).to match(%r|^/backupdir[\\/]+a/b/c.txt.chef-\d{14}.\d{6}$|)
    end

    it "uses the configured Chef::Config[:file_backup_path] and strips the drive on windows" do
      expect(@backup).to receive(:path).and_return('c:\\a\\b\\c.txt')
      Chef::Config[:file_backup_path] = 'c:\backupdir'
      expect(@backup.send(:backup_path)).to match(%r|^c:\\backupdir[\\/]+a\\b\\c.txt.chef-\d{14}.\d{6}$|)
    end
  end

end
