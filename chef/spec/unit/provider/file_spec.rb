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


require 'spec_helper'

describe Chef::Provider::File do
  before(:each) do
    @node = Chef::Node.new
    @node.name "latte"
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @resource = Chef::Resource::File.new("seattle")
    @resource.path(File.expand_path(File.join(CHEF_SPEC_DATA, "templates", "seattle.txt")))
    @provider = Chef::Provider::File.new(@resource, @run_context)
  end

  it "should return a Chef::Provider::File" do
    @provider.should be_a_kind_of(Chef::Provider::File)
  end

  it "should store the resource passed to new as new_resource" do
    @provider.new_resource.should eql(@resource)
  end

  it "should store the node passed to new as node" do
    @provider.node.should eql(@node)
  end

  it "should load a current resource based on the one specified at construction" do
    @provider.load_current_resource
    @provider.current_resource.should be_a_kind_of(Chef::Resource::File)
    @provider.current_resource.name.should eql(@resource.name)
    @provider.current_resource.path.should eql(@resource.path)
    @provider.current_resource.content.should eql(nil)
  end

  it "should load a mostly blank current resource if the file specified in new_resource doesn't exist/isn't readable" do
    resource = Chef::Resource::File.new("seattle")
    resource.path(File.expand_path(File.join(CHEF_SPEC_DATA, "templates", "woot.txt")))
    node = Chef::Node.new
    node.name "latte"
    provider = Chef::Provider::File.new(resource, @run_context)
    provider.load_current_resource
    provider.current_resource.should be_a_kind_of(Chef::Resource::File)
    provider.current_resource.name.should eql(resource.name)
    provider.current_resource.path.should eql(resource.path)
  end

  it "should not backup symbolic links on delete" do
    path = File.expand_path(File.join(CHEF_SPEC_DATA, "detroit.txt"))
    ::File.open(path, "w") do |file|
      file.write("Detroit's not so nice, so you should come to Seattle instead and buy me a beer instead.")
    end
    @resource = Chef::Resource::File.new("detroit")
    @resource.path(path)
    @node = Chef::Node.new
    @node.name "latte"
    @provider = Chef::Provider::File.new(@resource, @run_context)

    ::File.stub!(:symlink?).and_return(true)
    @provider.should_not_receive(:backup)
    @provider.run_action(:delete)
    @resource.should be_updated_by_last_action
  end

  it "should compare the current content with the requested content" do
    @provider.load_current_resource

    @provider.new_resource.content "foobar"
    @provider.compare_content.should eql(false)

    @provider.new_resource.content IO.read(@resource.path)
    @provider.compare_content.should eql(true)
  end

  it "should set the content of the file to the requested content" do
    io = StringIO.new
    @provider.load_current_resource
    @provider.new_resource.content "foobar"
    @provider.should_receive(:backup)
    File.should_receive(:open).with(@provider.new_resource.path, "w").and_yield(io)
    @provider.set_content
    lambda { @provider.send(:converge_actions).converge! }.should_not raise_error
    io.string.should == "foobar"
  end

  it "should not set the content of the file if it already matches the requested content" do
    @provider.load_current_resource
    @provider.new_resource.content IO.read(@resource.path)
    File.stub!(:open).and_return(1)
    File.should_not_receive(:open).with(@provider.new_resource.path, "w")
    lambda { @provider.set_content }.should_not raise_error
    @resource.should_not be_updated_by_last_action
  end

  it "should create the file if it is missing, then set the attributes on action_create" do
    @provider.load_current_resource
    @provider.new_resource.stub!(:path).and_return("/tmp/monkeyfoo")
    @provider.access_controls.should_receive(:set_all)
    File.stub!(:open).and_return(1)
    #File.should_receive(:directory?).with("/tmp").and_return(true)
    File.should_receive(:open).with(@provider.new_resource.path, "w+")
    @provider.run_action(:create)
    @resource.should be_updated_by_last_action
  end

  it "should create the file with the proper content if it is missing, then set attributes on action_create" do
    io = StringIO.new
    @provider.load_current_resource
    @provider.new_resource.content "foobar"
    @provider.new_resource.stub!(:path).and_return("/tmp/monkeyfoo")
    File.should_receive(:open).with(@provider.new_resource.path, "w+").and_yield(io)
    @provider.access_controls.should_receive(:set_all)
    @provider.run_action(:create)
    io.string.should == "foobar"
    @resource.should be_updated_by_last_action
  end

  it "should delete the file if it exists and is writable on action_delete" do
    @provider.new_resource.stub!(:path).and_return("/tmp/monkeyfoo")
    @provider.stub!(:backup).and_return(true)
    File.should_receive("exists?").exactly(2).times.with(@provider.new_resource.path).and_return(true)
    File.should_receive("writable?").with(@provider.new_resource.path).and_return(true)
    File.should_receive(:delete).with(@provider.new_resource.path).and_return(true)
    @provider.run_action(:delete)
    @resource.should be_updated_by_last_action
  end

  it "should not raise an error if it cannot delete the file because it does not exist" do
    @provider.new_resource.stub!(:path).and_return("/tmp/monkeyfoo")
    @provider.stub!(:backup).and_return(true)
    File.should_receive("exists?").exactly(2).times.with(@provider.new_resource.path).and_return(false)
    lambda { @provider.run_action(:delete) }.should_not raise_error()
    @resource.should_not be_updated_by_last_action
  end

  it "should update the atime/mtime on action_touch" do
    @provider.load_current_resource
    @provider.new_resource.stub!(:path).and_return("/tmp/monkeyfoo")
    #File.should_receive(:directory?).with("/tmp").and_return(true)
    File.should_receive(:utime).once.and_return(1)
    File.stub!(:open).and_return(1)
    @provider.access_controls.should_receive(:set_all).once
    @provider.run_action(:touch)
    @resource.should be_updated_by_last_action
  end

  it "should keep 1 backup copy if specified" do
    @provider.load_current_resource
    @provider.new_resource.stub!(:path).and_return("/tmp/s-20080705111233")
    @provider.new_resource.stub!(:backup).and_return(1)
    Dir.stub!(:[]).and_return([ "/tmp/s-20080705111233", "/tmp/s-20080705111232", "/tmp/s-20080705111223"])
    FileUtils.should_receive(:rm).with("/tmp/s-20080705111223").once.and_return(true)
    FileUtils.should_receive(:rm).with("/tmp/s-20080705111232").once.and_return(true)
    FileUtils.stub!(:cp).and_return(true)
    FileUtils.stub!(:mkdir_p).and_return(true)
    File.stub!(:exist?).and_return(true)
    @provider.backup
  end

  it "should backup a file no more than :backup times" do
    @provider.load_current_resource
    @provider.new_resource.stub!(:path).and_return("/tmp/s-20080705111233")
    @provider.new_resource.stub!(:backup).and_return(2)
    Dir.stub!(:[]).and_return([ "/tmp/s-20080705111233", "/tmp/s-20080705111232", "/tmp/s-20080705111223"])
    FileUtils.should_receive(:rm).with("/tmp/s-20080705111223").once.and_return(true)
    FileUtils.stub!(:cp).and_return(true)
    FileUtils.stub!(:mkdir_p).and_return(true)
    File.stub!(:exist?).and_return(true)
    @provider.backup
  end

  it "should not attempt to backup a file if :backup == 0" do
    @provider.load_current_resource
    @provider.new_resource.stub!(:path).and_return("/tmp/s-20080705111233")
    @provider.new_resource.stub!(:backup).and_return(0)
    FileUtils.stub!(:cp).and_return(true)
    File.stub!(:exist?).and_return(true)
    FileUtils.should_not_receive(:cp)
    @provider.backup
  end

  it "should put the backup backup file in the directory specified by Chef::Config[:file_backup_path]" do
    @provider.load_current_resource
    @provider.new_resource.stub!(:path).and_return("/tmp/s-20080705111233")
    @provider.new_resource.stub!(:backup).and_return(1)
    Chef::Config.stub!(:[]).with(:file_backup_path).and_return("/some_prefix")
    Dir.stub!(:[]).and_return([ "/some_prefix/tmp/s-20080705111233", "/some_prefix/tmp/s-20080705111232", "/some_prefix/tmp/s-20080705111223"])
    FileUtils.should_receive(:mkdir_p).with("/some_prefix/tmp").once
    FileUtils.should_receive(:rm).with("/some_prefix/tmp/s-20080705111232").once.and_return(true)
    FileUtils.should_receive(:rm).with("/some_prefix/tmp/s-20080705111223").once.and_return(true)
    FileUtils.stub!(:cp).and_return(true)
    File.stub!(:exist?).and_return(true)
    @provider.backup
  end

  it "should strip the drive letter from the backup resource path (for Windows platforms)" do
    @provider.load_current_resource
    @provider.new_resource.stub!(:path).and_return("C:/tmp/s-20080705111233")
    @provider.new_resource.stub!(:backup).and_return(1)
    Chef::Config.stub!(:[]).with(:file_backup_path).and_return("C:/some_prefix")
    Dir.stub!(:[]).and_return([ "C:/some_prefix/tmp/s-20080705111233", "C:/some_prefix/tmp/s-20080705111232", "C:/some_prefix/tmp/s-20080705111223"])
    FileUtils.should_receive(:mkdir_p).with("C:/some_prefix/tmp").once
    FileUtils.should_receive(:rm).with("C:/some_prefix/tmp/s-20080705111232").once.and_return(true)
    FileUtils.should_receive(:rm).with("C:/some_prefix/tmp/s-20080705111223").once.and_return(true)
    FileUtils.stub!(:cp).and_return(true)
    File.stub!(:exist?).and_return(true)
    @provider.backup
  end

  it "should keep the same ownership on backed up files" do
    @provider.load_current_resource
    @provider.new_resource.stub!(:path).and_return("/tmp/s-20080705111233")
    @provider.new_resource.stub!(:backup).and_return(1)
    Chef::Config.stub!(:[]).with(:file_backup_path).and_return("/some_prefix")
    Dir.stub!(:[]).and_return([ "/some_prefix/tmp/s-20080705111233", "/some_prefix/tmp/s-20080705111232", "/some_prefix/tmp/s-20080705111223"])
    FileUtils.stub!(:mkdir_p).and_return(true)
    FileUtils.stub!(:rm).and_return(true)
    File.stub!(:exist?).and_return(true)
    Time.stub!(:now).and_return(Time.at(1272147455).getgm)
    FileUtils.should_receive(:cp).with("/tmp/s-20080705111233", "/some_prefix/tmp/s-20080705111233.chef-20100424221735", {:preserve => true}).and_return(true)
    @provider.backup
  end

  describe "when the enclosing directory does not exist" do
    before do
      @resource.path("/tmp/no-such-path/file.txt")
    end

    it "raises a specific error describing the problem" do
      lambda {@provider.run_action(:create)}.should raise_error(Chef::Exceptions::EnclosingDirectoryDoesNotExist)
    end
  end

  describe "when creating a file which may be missing" do
    it "should not call action create if the file exists" do
      @resource.path(File.expand_path(File.join(CHEF_SPEC_DATA, "templates", "seattle.txt")))
      @provider = Chef::Provider::File.new(@resource, @run_context)
      File.should_not_receive(:open)
      @provider.run_action(:create_if_missing)
      @resource.should_not be_updated_by_last_action
    end

    it "should call action create if the does not file exist" do
      @resource.path("/tmp/non_existant_file")
      @provider = Chef::Provider::File.new(@resource, @run_context)
      ::File.stub!(:exists?).with(@resource.path).and_return(false)
      io = StringIO.new
      File.should_receive(:open).with(@provider.new_resource.path, "w+").and_yield(io)
      #@provider.should_receive(:action_create).and_return(true)
      @provider.run_action(:create_if_missing)
      @resource.should be_updated_by_last_action
    end
  end

  describe "when a diff is requested" do
   
    it "should return valid diff output when content does not match the string content provided" do
       Tempfile.open("some-temp") do |file|
         @resource.path file.path
         @provider = Chef::Provider::File.new(@resource, @run_context) 
         @provider.load_current_resource
         result = @provider.diff_current_from_content "foo baz\n"
         result.should == ["0a1", "> foo baz"]
       end
    end
    it "should return valid diff output when content does not match the string content provided and the content has new trailing newline" do
       Tempfile.open("some-temp") do |file|
         @resource.path file.path
         @provider = Chef::Provider::File.new(@resource, @run_context) 
         @provider.load_current_resource
         result = @provider.diff_current_from_content "foo baz"
         result.should == ["0a1", "> foo baz"]
       end
    end
  end
end

