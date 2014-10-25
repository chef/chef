#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'ostruct'

require 'spec_helper'
require 'tmpdir'

describe Chef::Provider::Directory do
  before(:each) do
    @new_resource = Chef::Resource::Directory.new(Dir.tmpdir)
    if !windows?
      @new_resource.owner(500)
      @new_resource.group(500)
      @new_resource.mode(0644)
    end
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @directory = Chef::Provider::Directory.new(@new_resource, @run_context)
  end


  describe "scanning file security metadata on windows" do
    before do
    end

    it "describes the directory's access rights" do
      pending
    end
  end

  describe "scanning file security metadata on unix" do
    before do
      allow(Chef::Platform).to receive(:windows?).and_return(false)
    end
    let(:mock_stat) do
      cstats = double("stats")
      allow(cstats).to receive(:uid).and_return(500)
      allow(cstats).to receive(:gid).and_return(500)
      allow(cstats).to receive(:mode).and_return(0755)
      cstats
    end

    it "describes the access mode as a String of octal integers" do
      allow(File).to receive(:exists?).and_return(true)
      expect(File).to receive(:stat).and_return(mock_stat)
      @directory.load_current_resource
      expect(@directory.current_resource.mode).to eq("0755")
    end

    context "when user and group are specified with UID/GID" do
      it "describes the current owner and group as UID and GID" do
        allow(File).to receive(:exists?).and_return(true)
        expect(File).to receive(:stat).and_return(mock_stat)
        @directory.load_current_resource
        expect(@directory.current_resource.path).to eql(@new_resource.path)
        expect(@directory.current_resource.owner).to eql(500)
        expect(@directory.current_resource.group).to eql(500)
      end
    end

    context "when user/group are specified with user/group names" do
    end
  end

  # Unix only for now. While file security attribute reporting for windows is
  # disabled, unix and windows differ in the number of exists? calls that are
  # made by the provider.
  it "should create a new directory on create, setting updated to true", :unix_only do
    @new_resource.path "/tmp/foo"

    expect(File).to receive(:exists?).at_least(:once).and_return(false)
    expect(File).to receive(:directory?).with("/tmp").and_return(true)
    expect(Dir).to receive(:mkdir).with(@new_resource.path).once.and_return(true)

    expect(@directory).to receive(:do_acl_changes)
    allow(@directory).to receive(:do_selinux)
    @directory.run_action(:create)
    expect(@directory.new_resource).to be_updated
  end

  it "should raise an exception if the parent directory does not exist and recursive is false" do
    @new_resource.path "/tmp/some/dir"
    @new_resource.recursive false
    expect { @directory.run_action(:create) }.to raise_error(Chef::Exceptions::EnclosingDirectoryDoesNotExist)
  end

  # Unix only for now. While file security attribute reporting for windows is
  # disabled, unix and windows differ in the number of exists? calls that are
  # made by the provider.
  it "should create a new directory when parent directory does not exist if recursive is true and permissions are correct", :unix_only do
    @new_resource.path "/path/to/dir"
    @new_resource.recursive true
    expect(File).to receive(:exists?).with(@new_resource.path).ordered.and_return(false)

    expect(File).to receive(:exists?).with('/path/to').ordered.and_return(false)
    expect(File).to receive(:exists?).with('/path').ordered.and_return(true)
    expect(File).to receive(:writable?).with('/path').ordered.and_return(true)
    expect(File).to receive(:exists?).with(@new_resource.path).ordered.and_return(false)

    expect(FileUtils).to receive(:mkdir_p).with(@new_resource.path).and_return(true)
    expect(@directory).to receive(:do_acl_changes)
    allow(@directory).to receive(:do_selinux)
    @directory.run_action(:create)
    expect(@new_resource).to be_updated
  end


  it "should raise an error when creating a directory when parent directory is a file" do
    expect(File).to receive(:directory?).and_return(false)
    expect(Dir).not_to receive(:mkdir).with(@new_resource.path)
    expect { @directory.run_action(:create) }.to raise_error(Chef::Exceptions::EnclosingDirectoryDoesNotExist)
    expect(@directory.new_resource).not_to be_updated
  end

  # Unix only for now. While file security attribute reporting for windows is
  # disabled, unix and windows differ in the number of exists? calls that are
  # made by the provider.
  it "should not create the directory if it already exists", :unix_only do
    stub_file_cstats
    @new_resource.path "/tmp/foo"
    expect(File).to receive(:directory?).at_least(:once).and_return(true)
    expect(File).to receive(:writable?).with("/tmp").and_return(true)
    expect(File).to receive(:exists?).at_least(:once).and_return(true)
    expect(Dir).not_to receive(:mkdir).with(@new_resource.path)
    expect(@directory).to receive(:do_acl_changes)
    @directory.run_action(:create)
  end

  it "should delete the directory if it exists, and is writable with action_delete" do
    expect(File).to receive(:directory?).and_return(true)
    expect(File).to receive(:writable?).once.and_return(true)
    expect(Dir).to receive(:delete).with(@new_resource.path).once.and_return(true)
    @directory.run_action(:delete)
  end

  it "should raise an exception if it cannot delete the directory due to bad permissions" do
    allow(File).to receive(:exists?).and_return(true)
    allow(File).to receive(:writable?).and_return(false)
    expect {  @directory.run_action(:delete) }.to raise_error(RuntimeError)
  end

  it "should take no action when deleting a target directory that does not exist" do
    @new_resource.path "/an/invalid/path"
    allow(File).to receive(:exists?).and_return(false)
    expect(Dir).not_to receive(:delete).with(@new_resource.path)
    @directory.run_action(:delete)
    expect(@directory.new_resource).not_to be_updated
  end

  it "should raise an exception when deleting a directory when target directory is a file" do
    stub_file_cstats
    @new_resource.path "/an/invalid/path"
    allow(File).to receive(:exists?).and_return(true)
    expect(File).to receive(:directory?).and_return(false)
    expect(Dir).not_to receive(:delete).with(@new_resource.path)
    expect { @directory.run_action(:delete) }.to raise_error(RuntimeError)
    expect(@directory.new_resource).not_to be_updated
  end

  def stub_file_cstats
    cstats = double("stats")
    allow(cstats).to receive(:uid).and_return(500)
    allow(cstats).to receive(:gid).and_return(500)
    allow(cstats).to receive(:mode).and_return(0755)
    # File.stat is called in:
    # - Chef::Provider::File.load_current_resource_attrs
    # - Chef::ScanAccessControl via Chef::Provider::File.setup_acl
    allow(File).to receive(:stat).and_return(cstats)
  end
end
