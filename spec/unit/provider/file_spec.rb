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
require 'tmpdir'

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

  describe "examining file security metadata on Unix" do
    it "should collect the current state of the file on the filesystem and populate current_resource" do
      # test setup
      stat_struct = mock("::File.stat", :mode => 0600, :uid => 0, :gid => 0, :mtime => 10000)
      ::File.should_receive(:stat).exactly(1).times.with(@resource.path).and_return(stat_struct)

      # test execution

      Etc.should_receive(:getgrgid).with(0).and_return(mock("Group Ent", :name => "wheel"))
      Etc.should_receive(:getpwuid).with(0).and_return(mock("User Ent", :name => "root"))

      # test execution 
      @provider.load_current_resource

      # post-condition checks
      @provider.current_resource.mode.should == "0600"
      @provider.current_resource.owner.should == "root"
      @provider.current_resource.group.should == "wheel"
    end

    it "should NOT update the new_resource state with the current_resourse state if new_resource state is already specified" do
      # test setup
      stat_struct = mock("::File.stat", :mode => 0600, :uid => 0, :gid => 0, :mtime => 10000)
      ::File.should_receive(:stat).exactly(1).times.with(@resource.path).and_return(stat_struct)

      @provider.new_resource.group(1)
      @provider.new_resource.owner(1)
      @provider.new_resource.mode(0644)

      # test execution
      @provider.load_current_resource

      # post-condition checks
      @provider.new_resource.group.should == 1
      @provider.new_resource.owner.should == 1
      @provider.new_resource.mode.should == 0644
    end

    context "when the new_resource does not specify the desired access control" do
      it "records access control information in the new resource after modifying the file" do
        # test setup
        stat_struct = mock("::File.stat", :mode => 0600, :uid => 0, :gid => 0, :mtime => 10000) 
        # called once in update_new_file_state and once in checksum
        ::File.should_receive(:stat).once.with(@provider.new_resource.path).and_return(stat_struct)  
        ::File.should_receive(:directory?).once.with(@provider.new_resource.path).and_return(false)

        Etc.should_receive(:getpwuid).with(0).and_return(mock("User Ent", :name => "root"))
        Etc.should_receive(:getgrgid).with(0).and_return(mock("Group Ent", :name => "wheel"))

        @provider.new_resource.group(nil)
        @provider.new_resource.owner(nil)
        @provider.new_resource.mode(nil)

        # test exectution
        @provider.update_new_file_state

        # post-condition checks
        @provider.new_resource.group.should == "wheel"
        @provider.new_resource.owner.should == "root"
        @provider.new_resource.mode.should == "0600"
      end
    end
  end

  describe "when reporting security metadata on windows" do

    it "records the file owner" do
      pending
    end

    it "records rights for each user in the ACL" do
      pending
    end

    it "records deny_rights for each user in the ACL" do
      pending
    end
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
    @provider.should_receive(:diff_current_from_content).and_return("")
    @provider.should_receive(:backup)
    # checksum check
    File.should_receive(:open).with(@provider.new_resource.path, "rb").and_yield(io)
    File.should_receive(:open).with(@provider.new_resource.path, "w").and_yield(io)
    @provider.set_content
    io.string.should == "foobar"
  end

  it "should not set the content of the file if it already matches the requested content" do
    @provider.load_current_resource
    @provider.new_resource.content IO.read(@resource.path)
    # Checksum check:
    File.should_receive(:open).with(@resource.path, "rb").and_yield(StringIO.new(@resource.content))
    File.should_not_receive(:open).with(@provider.new_resource.path, "w")
    lambda { @provider.set_content }.should_not raise_error
    @resource.should_not be_updated_by_last_action
  end

  it "should create the file if it is missing, then set the attributes on action_create" do
    @provider.load_current_resource
    @provider.stub!(:update_new_file_state)
    @provider.new_resource.stub!(:path).and_return(File.join(Dir.tmpdir, "monkeyfoo"))
    @provider.access_controls.should_receive(:set_all)
    @provider.should_receive(:diff_current_from_content).and_return("")
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
    @provider.new_resource.stub!(:path).and_return(File.join(Dir.tmpdir, "monkeyfoo"))
    @provider.should_receive(:diff_current_from_content).and_return("")
    @provider.stub!(:update_new_file_state)
    File.should_receive(:open).with(@provider.new_resource.path, "w+").and_yield(io)
    @provider.access_controls.should_receive(:set_all)
    @provider.run_action(:create)
    io.string.should == "foobar"
    @resource.should be_updated_by_last_action
  end

  it "should delete the file if it exists and is writable on action_delete" do
    @provider.new_resource.stub!(:path).and_return(File.join(Dir.tmpdir, "monkeyfoo"))
    @provider.stub!(:backup).and_return(true)
    File.should_receive("exists?").exactly(2).times.with(@provider.new_resource.path).and_return(true)
    File.should_receive("writable?").with(@provider.new_resource.path).and_return(true)
    File.should_receive(:delete).with(@provider.new_resource.path).and_return(true)
    @provider.run_action(:delete)
    @resource.should be_updated_by_last_action
  end

  it "should not raise an error if it cannot delete the file because it does not exist" do
    @provider.new_resource.stub!(:path).and_return(File.join(Dir.tmpdir, "monkeyfoo"))
    @provider.stub!(:backup).and_return(true)
    File.should_receive("exists?").exactly(2).times.with(@provider.new_resource.path).and_return(false)
    lambda { @provider.run_action(:delete) }.should_not raise_error()
    @resource.should_not be_updated_by_last_action
  end

  it "should update the atime/mtime on action_touch" do
    @provider.load_current_resource
    @provider.new_resource.stub!(:path).and_return(File.join(Dir.tmpdir, "monkeyfoo"))
    @provider.should_receive(:diff_current_from_content).and_return("")
    @provider.stub!(:update_new_file_state)
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
      @resource.path("/tmp/example-dir/non_existant_file")
      @provider = Chef::Provider::File.new(@resource, @run_context)
      @provider.should_receive(:diff_current_from_content).and_return("")
      ::File.stub!(:exists?).with(@resource.path).and_return(false)
      ::File.stub!(:directory?).with("/tmp/example-dir/non_existant_file").and_return(false)
      ::File.stub!(:directory?).with("/tmp/example-dir").and_return(true)
      @provider.stub!(:update_new_file_state)
      io = StringIO.new
      File.should_receive(:open).with(@provider.new_resource.path, "w+").and_yield(io)
      #@provider.should_receive(:action_create).and_return(true)
      @provider.run_action(:create_if_missing)
      @resource.should be_updated_by_last_action
    end
  end

  describe "when a diff is requested", :uses_diff => true do

    before(:each) do
      @original_config = Chef::Config.hash_dup
    end

    after(:each) do
      Chef::Config.configuration = @original_config if @original_config
    end

    describe "when identifying files as binary or text" do

      it "should identify zero-length files as text" do
        Tempfile.open("some-temp") do |file|
          @resource.path(file.path)
          @provider = Chef::Provider::File.new(@resource, @run_context)
          @provider.is_binary?(file.path).should be_false
        end
      end

      it "should correctly identify text files as being text" do
        Tempfile.open("some-temp") do |file|
          @resource.path(file.path)
          file.puts("This is a text file.")
          file.puts("That has a couple of lines in it.")
          file.puts("And lets make sure that other printable chars work too: ~!@\#$%^&*()`:\"<>?{}|_+,./;'[]\\-=")
          file.close
          @provider = Chef::Provider::File.new(@resource, @run_context)
          @provider.is_binary?(file.path).should be_false
        end
      end

      it "should identify a null-terminated string as binary" do
        Tempfile.open("some-temp") do |file|
          @resource.path(file.path)
          file.write("This is a binary file.\0")
          file.close
          @provider = Chef::Provider::File.new(@resource, @run_context)
          @provider.is_binary?(file.path).should be_true
        end
      end

    end

    it "should not return diff output when chef config has disabled it" do
      Chef::Config[:diff_disabled] = true
      Tempfile.open("some-temp") do |file|
        @resource.path(file.path)
        @provider = Chef::Provider::File.new(@resource, @run_context)
        @provider.load_current_resource
        result = @provider.diff_current_from_content "foo baz"
        result.should == [ "(diff output suppressed by config)" ]
        @resource.diff.should be_nil
      end
    end

    it "should not return diff output when there is no new file to compare it to" do
      Tempfile.open("some-temp") do |file|
        Tempfile.open("other-temp") do |missing_file|
          missing_path = missing_file.path
          missing_file.close
          missing_file.unlink
          @resource.path(file.path)
          @provider = Chef::Provider::File.new(@resource, @run_context)
          @provider.load_current_resource
          result = @provider.diff_current missing_path
          result.should == [ "(no temp file with new content, diff output suppressed)" ]
          @resource.diff.should be_nil
        end
      end
    end

    it "should produce diff output when the file does not exist yet, but suppress reporting it" do
      Tempfile.open("some-temp") do |file|
        @resource.path(file.path)
        file.close
        file.unlink
        @provider = Chef::Provider::File.new(@resource, @run_context)
        @provider.load_current_resource
        result = @provider.diff_current_from_content "foo baz"
        result.length.should == 4
        @resource.diff.should be_nil
      end
    end

    it "should not produce a diff when the current resource file is above the filesize threshold" do
      Chef::Config[:diff_filesize_threshold] = 5
      Tempfile.open("some-temp") do |file|
        @resource.path(file.path)
        file.puts("this is a line which is longer than 5 characters")
        file.flush
        @provider = Chef::Provider::File.new(@resource, @run_context)
        @provider.load_current_resource
        result = @provider.diff_current_from_content "foo"  # not longer than 5
        result.should == [ "(file sizes exceed 5 bytes, diff output suppressed)" ]
        @resource.diff.should be_nil
      end
    end

    it "should not produce a diff when the new content is above the filesize threshold" do
      Chef::Config[:diff_filesize_threshold] = 5
      Tempfile.open("some-temp") do |file|
        @resource.path(file.path)
        file.puts("foo")
        file.flush
        @provider = Chef::Provider::File.new(@resource, @run_context)
        @provider.load_current_resource
        result = @provider.diff_current_from_content "this is a line that is longer than 5 characters"
        result.should == [ "(file sizes exceed 5 bytes, diff output suppressed)" ]
        @resource.diff.should be_nil
      end
    end

    it "should not produce a diff when the generated diff size is above the diff size threshold" do
      Chef::Config[:diff_output_threshold] = 5
      Tempfile.open("some-temp") do |file|
        @resource.path(file.path)
        file.puts("some text to increase the size of the diff")
        file.flush
        @provider = Chef::Provider::File.new(@resource, @run_context)
        @provider.load_current_resource
        result = @provider.diff_current_from_content "this is a line that is longer than 5 characters"
        result.should == [ "(long diff of over 5 characters, diff output suppressed)" ]
        @resource.diff.should be_nil
      end
    end

    it "should return valid diff output when content does not match the string content provided" do
       Tempfile.open("some-temp") do |file|
         @resource.path file.path
         @provider = Chef::Provider::File.new(@resource, @run_context)
         @provider.load_current_resource
         result = @provider.diff_current_from_content "foo baz"
         # remove the file name info which varies.
         result.shift(2)
         # Result appearance seems to vary slightly under solaris diff
         # So we'll compare the second line which is common to both.
         # Solaris: -1,1 +1,0 @@, "+foo baz"
         # Linux/Mac: -1,0, +1 @@, "+foo baz"
         result.length.should == 2
         result[1].should == "+foo baz"
         @resource.diff.should_not be_nil
       end
    end
  end
end
