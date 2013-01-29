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
      Chef::Platform.stub!(:windows?).and_return(false)
    end
    let(:mock_stat) do
      cstats = mock("stats")
      cstats.stub!(:uid).and_return(500)
      cstats.stub!(:gid).and_return(500)
      cstats.stub!(:mode).and_return(0755)
      cstats
    end

    it "describes the access mode as a String of octal integers" do
      File.stub!(:exist?).and_return(true)
      File.should_receive(:stat).and_return(mock_stat)
      @directory.load_current_resource
      @directory.current_resource.mode.should == "0755"
    end

    context "when user and group are specified with UID/GID" do
      it "describes the current owner and group as UID and GID" do
        File.stub!(:exist?).and_return(true)
        File.should_receive(:stat).and_return(mock_stat)
        @directory.load_current_resource
        @directory.current_resource.path.should eql(@new_resource.path)
        @directory.current_resource.owner.should eql(500)
        @directory.current_resource.group.should eql(500)
      end
    end

    context "when user/group are specified with user/group names" do
    end
  end

  # Unix only for now. While file security attribute reporting for windows is
  # disabled, unix and windows differ in the number of exist? calls that are
  # made by the provider.
  it "should create a new directory on create, setting updated to true", :unix_only do
    @new_resource.path "/tmp/foo"

    File.should_receive(:exist?).exactly(2).and_return(false)
    File.should_receive(:directory?).with("/tmp").and_return(true)
    Dir.should_receive(:mkdir).with(@new_resource.path).once.and_return(true)

    @directory.should_receive(:set_all_access_controls)
    @directory.stub!(:update_new_file_state)
    @directory.run_action(:create)
    @directory.new_resource.should be_updated
  end

  it "should raise an exception if the parent directory does not exist and recursive is false" do 
    @new_resource.path "/tmp/some/dir"
    @new_resource.recursive false
    lambda { @directory.run_action(:create) }.should raise_error(Chef::Exceptions::EnclosingDirectoryDoesNotExist) 
  end

  # Unix only for now. While file security attribute reporting for windows is
  # disabled, unix and windows differ in the number of exist? calls that are
  # made by the provider.
  it "should create a new directory when parent directory does not exist if recursive is true and permissions are correct", :unix_only do
    @new_resource.path "/path/to/dir"
    @new_resource.recursive true
    File.should_receive(:exist?).with(@new_resource.path).ordered.and_return(false)

    File.should_receive(:exist?).with('/path/to').ordered.and_return(false)
    File.should_receive(:exist?).with('/path').ordered.and_return(true)
    File.should_receive(:writable?).with('/path').ordered.and_return(true)
    File.should_receive(:exist?).with(@new_resource.path).ordered.and_return(false)

    FileUtils.should_receive(:mkdir_p).with(@new_resource.path).and_return(true) 
    @directory.should_receive(:set_all_access_controls)
    @directory.stub!(:update_new_file_state)
    @directory.run_action(:create)
    @new_resource.should be_updated
  end


  it "should raise an error when creating a directory when parent directory is a file" do
    File.should_receive(:directory?).and_return(false)
    Dir.should_not_receive(:mkdir).with(@new_resource.path)
    lambda { @directory.run_action(:create) }.should raise_error(Chef::Exceptions::EnclosingDirectoryDoesNotExist)
    @directory.new_resource.should_not be_updated
  end

  # Unix only for now. While file security attribute reporting for windows is
  # disabled, unix and windows differ in the number of exist? calls that are
  # made by the provider.
  it "should not create the directory if it already exists", :unix_only do
    stub_file_cstats
    @new_resource.path "/tmp/foo"
    File.should_receive(:directory?).twice.and_return(true)
    File.should_receive(:writable?).with("/tmp").and_return(true)
    File.should_receive(:exist?).exactly(3).and_return(true)
    Dir.should_not_receive(:mkdir).with(@new_resource.path)
    @directory.should_receive(:set_all_access_controls)
    @directory.run_action(:create)
  end

  it "should delete the directory if it exists, and is writable with action_delete" do
    File.should_receive(:directory?).and_return(true)
    File.should_receive(:writable?).once.and_return(true)
    Dir.should_receive(:delete).with(@new_resource.path).once.and_return(true)
    @directory.run_action(:delete)
  end

  it "should raise an exception if it cannot delete the directory due to bad permissions" do
    File.stub!(:exist?).and_return(true)
    File.stub!(:writable?).and_return(false)
    lambda {  @directory.run_action(:delete) }.should raise_error(RuntimeError)
  end

  it "should take no action when deleting a target directory that does not exist" do
    @new_resource.path "/an/invalid/path"
    File.stub!(:exist?).and_return(false)
    Dir.should_not_receive(:delete).with(@new_resource.path)
    @directory.run_action(:delete)
    @directory.new_resource.should_not be_updated
  end

  it "should raise an exception when deleting a directory when target directory is a file" do
    stub_file_cstats
    @new_resource.path "/an/invalid/path"
    File.stub!(:exist?).and_return(true)
    File.should_receive(:directory?).and_return(false)
    Dir.should_not_receive(:delete).with(@new_resource.path)
    lambda { @directory.run_action(:delete) }.should raise_error(RuntimeError)
    @directory.new_resource.should_not be_updated
  end

  def stub_file_cstats
    cstats = mock("stats")
    cstats.stub!(:uid).and_return(500)
    cstats.stub!(:gid).and_return(500)
    cstats.stub!(:mode).and_return(0755)
    # File.stat is called in:
    # - Chef::Provider::File.load_current_resource_attrs
    # - Chef::ScanAccessControl via Chef::Provider::File.setup_acl
    File.stub!(:stat).and_return(cstats)
  end
end
