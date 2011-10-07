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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'chef/checksum'

describe Chef::Checksum do

  before do
    Chef::Log.logger = Logger.new(StringIO.new)

    @now = Time.now

    Time.stub!(:now).and_return(@now)

    @checksum_of_the_file = "3fafecfb15585ede6b840158cbc2f399"
    @checksum = Chef::Checksum.new(@checksum_of_the_file)
  end

  it "has no original committed file location" do
    @checksum.original_committed_file_location.should be_nil
  end

  it "has the MD5 checksum of the file it represents" do
    @checksum.checksum.should == @checksum_of_the_file
  end

  it "stores the time it was created" do
    @checksum.create_time.should == @now.iso8601
  end

  it "commits a sandbox file from a given location to the checksum repo location" do
    @checksum.storage.should_receive(:commit).with("/tmp/arbitrary_file_location")
    @checksum.should_receive(:cdb_save)
    @checksum.commit_sandbox_file("/tmp/arbitrary_file_location")
    @checksum.original_committed_file_location.should == "/tmp/arbitrary_file_location"
  end

  it "reverts committing a sandbox file" do
    @checksum.storage.should_receive(:commit).with("/tmp/arbitrary_file_location")
    @checksum.should_receive(:cdb_save)
    @checksum.commit_sandbox_file("/tmp/arbitrary_file_location")
    @checksum.original_committed_file_location.should == "/tmp/arbitrary_file_location"

    @checksum.storage.should_receive(:revert).with("/tmp/arbitrary_file_location")
    @checksum.should_receive(:cdb_destroy)
    @checksum.revert_sandbox_file_commit
  end

  it "raises an error when trying to revert a checksum that was not previously committed" do
    lambda {@checksum.revert_sandbox_file_commit}.should raise_error(Chef::Exceptions::IllegalChecksumRevert)
  end

  it "deletes the file and its document from couchdb" do
    @checksum.should_receive(:cdb_destroy)
    @checksum.storage.should_receive(:purge)
    @checksum.purge
  end

  it "successfully purges even if its file has been deleted from the repo" do
    @checksum.should_receive(:cdb_destroy)
    @checksum.storage.should_receive(:purge).and_raise(Errno::ENOENT)
    lambda {@checksum.purge}.should_not raise_error
  end

  describe "when converted to json" do
    before do
      @checksum_as_json = @checksum.to_json
      @checksum_as_hash_from_json = Chef::JSONCompat.from_json(@checksum_as_json, :create_additions => false)
    end

    it "contains the file's MD5 checksum" do
      @checksum_as_hash_from_json["checksum"].should == @checksum_of_the_file
    end

    it "contains the creation time" do
      @checksum_as_hash_from_json["create_time"].should == @now.iso8601
    end

    it "uses the file's MD5 checksum for its 'name' property" do
      @checksum_as_hash_from_json["name"].should == @checksum_of_the_file
    end
  end

end