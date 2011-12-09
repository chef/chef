#
# Author:: AJ Christensen (<aj@junglist.gen.nz>)
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

if Chef::Platform.windows?
  require 'chef/win32/file' #probably need this in spec_helper
end

describe Chef::Resource::Link do
  before do
    @node = Chef::Node.new
    @run_context = Chef::RunContext.new(@node, {})

    @new_resource = Chef::Resource::Link.new("#{CHEF_SPEC_DATA}/fofile-link")
    @new_resource.to "#{CHEF_SPEC_DATA}/fofile"

    @provider = Chef::Provider::Link.new(@new_resource, @run_context)
    File.stub!(:exists?).and_return(true)
    @provider.file_class.stub!(:symlink?).and_return(true)
    @provider.file_class.stub!(:readlink).and_return("")
    File.stub!(:unlink).and_return("")
    File.stub!(:delete).and_return("")
    File.stub!(:symlink).and_return("")

    lstat = mock("stats", :ino => 5)
    lstat.stub!(:uid).and_return(501)
    lstat.stub!(:gid).and_return(501)

    File.stub!(:lstat).and_return(lstat)
  end

  describe "when determining the current state of the symlink" do
    it "should set the symlink target" do
      @provider.load_current_resource
      @provider.current_resource.target_file.should == "#{CHEF_SPEC_DATA}/fofile-link"
    end

    it "should set the link type" do
      @provider.load_current_resource
      @provider.current_resource.link_type.should == :symbolic
    end

    describe "when the link type is symbolic" do

      before do
        @new_resource.link_type(:symbolic)
      end

      describe "and the target exists and is a symlink" do
        before do
          @provider.file_class.stub!(:exists?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(true)
          @provider.file_class.stub!(:symlink?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(true)
          @provider.file_class.stub!(:readlink).with("#{CHEF_SPEC_DATA}/fofile-link").and_return("#{CHEF_SPEC_DATA}/fofile")
        end

        it "should update the source of the existing link with the links target" do
          @provider.load_current_resource
          @provider.current_resource.to.should == "#{CHEF_SPEC_DATA}/fofile"
        end
        it "should set the owner" do
          @provider.load_current_resource
          @provider.current_resource.owner.should == 501
        end

        it "should set the group" do
          @provider.load_current_resource
          @provider.current_resource.group.should == 501
        end
      end

      describe "and the target doesn't exist" do
        before do
          File.should_receive(:exists?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(false)
        end

        it "should update the source of the existing link to an empty string" do
          @provider.load_current_resource
          @provider.current_resource.to.should == ''
        end

      end

      describe "and the target isn't a symlink" do
        before do
          @provider.file_class.stub!(:symlink?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(false)
        end

        it "should update the current source of the existing link with an empty string" do
          @provider.load_current_resource
          @provider.current_resource.to.should == ''
        end
      end
    end

    describe "when the link type is hard, " do
      before do
        @new_resource.stub!(:link_type).and_return(:hard)
      end

      describe "the target file and source file both exist" do
        before do
          File.should_receive(:exists?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(true)
          File.should_receive(:exists?).with("#{CHEF_SPEC_DATA}/fofile").and_return(true)
        end

        describe "and the inodes match" do
          before do
            stat = mock("stats")
            stat.stub!(:ino).and_return(1)
            File.should_receive(:stat).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(stat)
            File.should_receive(:stat).with("#{CHEF_SPEC_DATA}/fofile").and_return(stat)
          end

          it "should update the source of the existing link to the target file" do
            @provider.load_current_resource
            @provider.current_resource.to.should == "#{CHEF_SPEC_DATA}/fofile"
          end
        end

        describe "and the inodes don't match" do
          before do
            stat = mock("stats", :ino => 1)
            stat_two = mock("stats", :ino => 2)
            File.should_receive(:stat).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(stat)
            File.should_receive(:stat).with("#{CHEF_SPEC_DATA}/fofile").and_return(stat_two)
          end

          it "should set the source of the existing link to an empty string" do
            @provider.load_current_resource
            @provider.current_resource.to.should == ''
          end
        end
      end
      describe "but the target does not exist" do
        before do
          File.should_receive(:exists?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(false)
        end

        it "should set the source of the existing link to an empty string" do
          @provider.load_current_resource
          @provider.current_resource.to.should == ''
        end
      end
      describe "but the source does not exist" do
        before do
          File.should_receive(:exists?).with("#{CHEF_SPEC_DATA}/fofile").and_return(false)
        end

        it "should set the source of the existing link to an empty string" do
          @provider.load_current_resource
          @provider.current_resource.to.should == ''
        end
      end
    end
  end


  context "once the current state of the link is known" do
    before do
      @current_resource = Chef::Resource::Link.new("#{CHEF_SPEC_DATA}/fofile-link")
      @current_resource.to "#{CHEF_SPEC_DATA}/fofile"
      @provider.current_resource = @current_resource
    end

    describe "when the resource specifies the create action" do
      before do
        getpwnam = OpenStruct.new :name => "adam", :passwd => "foo", :uid => 501,
                                  :gid => 501,:gecos => "Adam Jacob",:dir => "/Users/adam",
                                  :shell => "/bin/zsh",:change => "0", :uclass => "",
                                  :expire => 0
        Etc.stub!(:getpwnam).and_return(getpwnam)
      end

      describe "when the source for the link contains expandable pieces" do
        before do
          @new_resource.target_file("#{CHEF_SPEC_DATA}/fofile-link")
          @new_resource.to("../foo")
          @provider.stub!(:enforce_ownership_and_permissions)

           @provider.file_class.stub!(:symlink)
        end

        it "should expand the path" do
          ::File.should_receive(:expand_path).with("../foo", "#{CHEF_SPEC_DATA}/fofile-link").and_return("#{CHEF_SPEC_DATA}/fofile-link")
          @provider.action_create
        end
      end

      describe "when the source for the link doesn't match" do
        before do
          @new_resource.to("#{CHEF_SPEC_DATA}/lolololol")
          @provider.stub!(:enforce_ownership_and_permissions)
          @provider.file_class.stub!(:symlink)
        end

        it "should log an appropriate message" do
          Chef::Log.should_receive(:info).with("link[#{CHEF_SPEC_DATA}/fofile-link] created")
          @provider.action_create
        end

        describe "and we're building a symbolic link" do
          before do
            @new_resource.group('wheel')

            @new_resource.link_type(:symbolic)
            @new_resource.owner('toor')
          end

          it "should call enforce_ownership_and_permissions" do
            @provider.should_receive(:enforce_ownership_and_permissions)
            @provider.action_create
          end

          it "should create link using the appropriate link function" do
            @provider.stub!(:enforce_ownership_and_permissions)
            @provider.file_class.should_receive(:symlink).with("#{CHEF_SPEC_DATA}/lolololol", "#{CHEF_SPEC_DATA}/fofile-link").and_return(true)
            @provider.action_create
          end
        end

        describe "and we're building a hard link" do
          before do
            @new_resource.stub!(:link_type).and_return(:hard)
          end

          it "should use the appropriate link method to create the link" do
            @provider.file_class.should_receive(:link).with("#{CHEF_SPEC_DATA}/lolololol", "#{CHEF_SPEC_DATA}/fofile-link").and_return(true)
            @provider.action_create
          end

          it "we should not attempt to set owner or group" do
            @provider.file_class.should_receive(:link).with("#{CHEF_SPEC_DATA}/lolololol", "#{CHEF_SPEC_DATA}/fofile-link")
            @provider.should_not_receive(:enforce_ownership_and_permissions)
            @provider.action_create
          end
        end

        it "should set updated to true" do
          @provider.action_create
          @new_resource.should be_updated
        end
      end

    end

    describe "when deleting the link" do
      describe "when we're building a symbolic link" do
        before do
          @new_resource.link_type(:symbolic)
        end

        describe "and when the symlink exists" do
          before do
            @provider.file_class.should_receive(:symlink?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(true)
          end

          it "should log an appropriate error message" do
            Chef::Log.should_receive(:info).with("link[#{CHEF_SPEC_DATA}/fofile-link] deleted")
            @provider.action_delete
          end

          it "deletes the link and marks the resource as updated" do
            File.should_receive(:delete).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(true)
            @provider.action_delete
            @new_resource.should be_updated
          end
        end

        describe "and when the file is not a symbolic link but does exist" do
          before(:each) do
            @provider.file_class.should_receive(:symlink?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(false)
            File.should_receive(:exists?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(true)
          end

          it "should raise a Link error" do
            lambda { @provider.action_delete }.should raise_error(Chef::Exceptions::Link)
          end
        end

        describe "and when the symbolic link and file do not exist" do
          before do
            @provider.file_class.should_receive(:symlink?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(false)
            File.should_receive(:exists?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(false)
          end

          it "should not raise a Link error" do
            lambda { @provider.action_delete }.should_not raise_error(Chef::Exceptions::Link)
          end
        end
      end

      describe "when we're building a hard link" do
        before do
          @new_resource.link_type(:hard)
        end

        describe "and when the file exists" do
          before do
            File.should_receive(:exists?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(true)
          end

          describe "and it appears to be a hardlink" do
            before do
              if Chef::Platform.windows?
                @provider.file_class.should_receive(:hardlink?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(true)
              else
                stat = mock("stats")
                stat.stub!(:ino).and_return(1)
                File.should_receive(:stat).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(stat)
                File.should_receive(:stat).with("#{CHEF_SPEC_DATA}/fofile").and_return(stat)
              end
            end

            it "deletes the link and marks the resource updated" do
              Chef::Log.should_receive(:info).with("link[#{CHEF_SPEC_DATA}/fofile-link] deleted")
              File.should_receive(:delete).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(true)
              @provider.action_delete
              @new_resource.should be_updated
            end
          end

          describe "and it does not appear to be a hardlink" do
            before do
              if Chef::Platform.windows?
                @provider.file_class.should_receive(:hardlink?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(false)
              else
                stat = mock("stats", :ino => 1)
                stat_two = mock("stats", :ino => 2)
                File.should_receive(:stat).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(stat)
                File.should_receive(:stat).with("#{CHEF_SPEC_DATA}/fofile").and_return(stat_two)
              end
            end

            it "should raise a Link error" do
              lambda { @provider.action_delete }.should raise_error(Chef::Exceptions::Link)
            end
          end

        end

        describe "and when file does not exist" do
          before do
            File.should_receive(:exists?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(false)
          end

          it "should not raise a Link error" do
            lambda { @provider.action_delete }.should_not raise_error(Chef::Exceptions::Link)
          end
        end
      end

    end
  end
end
