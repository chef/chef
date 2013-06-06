#
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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
require 'tmpdir'

describe Chef::Util::Backup do
  before(:all) do
    @original_config = Chef::Config.configuration
  end

  after(:all) do
    Chef::Config.configuration.replace(@original_config)
  end

  let (:tempfile) do
    Tempfile.new("chef-util-backup-spec-test")
  end

  before(:each) do
    @new_resource = mock("new_resource")
    @new_resource.should_receive(:path).at_least(:once).and_return(tempfile.path)
    @backup = Chef::Util::Backup.new(@new_resource)
  end

  it "should store the resource passed to new as new_resource" do
    @backup.new_resource.should eql(@new_resource)
  end

  describe "for cases when we don't want to back anything up" do

    before(:each) do
      @backup.should_not_receive(:do_backup)
    end

    it "should not attempt to backup a file if :backup is false" do
      @new_resource.should_receive(:backup).at_least(:once).and_return(false)
      @backup.backup!
    end

    it "should not attempt to backup a file if :backup == 0" do
      @new_resource.should_receive(:backup).at_least(:once).and_return(0)
      @backup.backup!
    end

    it "should not attempt to backup a file if it does not exist" do
      @new_resource.should_receive(:backup).at_least(:once).and_return(1)
      File.should_receive(:exist?).with(tempfile.path).at_least(:once).and_return(false)
      @backup.backup!
    end

  end

  describe "for cases when we want to back things up" do
    before(:each) do
      @backup.should_receive(:do_backup)
    end

    describe "when the number of backups is specified as 1" do
      before(:each) do
        @new_resource.should_receive(:backup).at_least(:once).and_return(1)
      end

      it "should not delete anything if this is the only backup" do
        @backup.should_receive(:sorted_backup_files).and_return(['a'])
        @backup.should_not_receive(:delete_backup)
        @backup.backup!
      end

      it "should keep only 1 backup copy" do
        @backup.should_receive(:sorted_backup_files).and_return(['a', 'b', 'c'])
        @backup.should_receive(:delete_backup).with('b')
        @backup.should_receive(:delete_backup).with('c')
        @backup.backup!
      end
    end

    describe "when the number of backups is specified as 2" do
      before(:each) do
        @new_resource.should_receive(:backup).at_least(:once).and_return(2)
      end

      it "should not delete anything if we only have one other backup" do
        @backup.should_receive(:sorted_backup_files).and_return(['a', 'b'])
        @backup.should_not_receive(:delete_backup)
        @backup.backup!
      end

      it "should keep only 2 backup copies" do
        @backup.should_receive(:sorted_backup_files).and_return(['a', 'b', 'c', 'd'])
        @backup.should_receive(:delete_backup).with('c')
        @backup.should_receive(:delete_backup).with('d')
        @backup.backup!
      end
    end
  end

  describe "backup_filename" do
    it "should return a timestamped path" do
      @backup.should_receive(:path).and_return('/a/b/c.txt')
      @backup.send(:backup_filename).should =~ %r|^/a/b/c.txt.chef-\d{14}$|
    end
    it "should strip the drive letter off for windows" do
      @backup.should_receive(:path).and_return('c:\a\b\c.txt')
      @backup.send(:backup_filename).should =~ %r|^\\a\\b\\c.txt.chef-\d{14}$|
    end
    it "should strip the drive letter off for windows (with forwardslashes)" do
      @backup.should_receive(:path).and_return('c:/a/b/c.txt')
      @backup.send(:backup_filename).should =~ %r|^/a/b/c.txt.chef-\d{14}$|
    end
  end

  describe "backup_path" do
    it "uses the file's directory when Chef::Config[:file_backup_path] is nil" do
      @backup.should_receive(:path).and_return('/a/b/c.txt')
      Chef::Config[:file_backup_path] = nil
      @backup.send(:backup_path).should =~ %r|^/a/b/c.txt.chef-\d{14}$|
    end

    it "uses the configured Chef::Config[:file_backup_path]" do
      @backup.should_receive(:path).and_return('/a/b/c.txt')
      Chef::Config[:file_backup_path] = '/backupdir'
      @backup.send(:backup_path).should =~ %r|^/backupdir[\\/]+a/b/c.txt.chef-\d{14}$|
    end

    it "uses the configured Chef::Config[:file_backup_path] and strips the drive on windows" do
      @backup.should_receive(:path).and_return('c:\\a\\b\\c.txt')
      Chef::Config[:file_backup_path] = 'c:\backupdir'
      @backup.send(:backup_path).should =~ %r|^c:\\backupdir[\\/]+a\\b\\c.txt.chef-\d{14}$|
    end
  end

end
