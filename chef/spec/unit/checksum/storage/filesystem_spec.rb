#
# Author:: Daniel DeLeo (<dan@opscode.com>)
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')
require 'chef/checksum/storage/filesystem'

describe Chef::Checksum::Storage::Filesystem do

  before do
    Chef::Log.logger = Logger.new(StringIO.new)

    @now = Time.now

    Time.stub!(:now).and_return(@now)

    @checksum_of_the_file = "3fafecfb15585ede6b840158cbc2f399"
    @storage = Chef::Checksum::Storage::Filesystem.new(Chef::Config.checksum_path, @checksum_of_the_file)
  end

  it "has the path to the file in the checksum repo" do
    @storage.file_location.should == "/var/chef/checksums/3f/3fafecfb15585ede6b840158cbc2f399"
  end

  it "has the path the the file's subdirectory in the checksum repo" do
    @storage.checksum_repo_directory.should == "/var/chef/checksums/3f"
  end

  it "commits a file from a given location to the checksum repo location" do
    File.should_receive(:rename).with("/tmp/arbitrary_file_location", @storage.file_location)
    FileUtils.should_receive(:mkdir_p).with("/var/chef/checksums/3f")

    @storage.commit("/tmp/arbitrary_file_location")
  end

  it "reverts committing a file" do
    File.should_receive(:rename).with("/tmp/arbitrary_file_location", @storage.file_location)
    FileUtils.should_receive(:mkdir_p).with("/var/chef/checksums/3f")
    @storage.commit("/tmp/arbitrary_file_location")

    File.should_receive(:rename).with(@storage.file_location, "/tmp/arbitrary_file_location")
    @storage.revert("/tmp/arbitrary_file_location")
  end

  it "deletes the file" do
    FileUtils.should_receive(:rm).with(@storage.file_location)
    @storage.purge
  end

  it "successfully purges even if its file has been deleted from the repo" do
    FileUtils.should_receive(:rm).with(@storage.file_location).and_raise(Errno::ENOENT)
    lambda {@storage.purge}.should_not raise_error
  end

end
