#
# Author:: AJ Christensen (<aj@junglist.gen.nz>)
# Author:: John Keiser (<jkeiser@opscode.com>)
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

if Chef::Platform.windows?
  require 'chef/win32/file' #probably need this in spec_helper
end

describe Chef::Resource::Link, :not_supported_on_win2k3 do
  let(:provider) do
    node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, @events)
    Chef::Provider::Link.new(new_resource, run_context)
  end
  let(:new_resource) do
    result = Chef::Resource::Link.new("#{CHEF_SPEC_DATA}/fofile-link")
    result.to "#{CHEF_SPEC_DATA}/fofile"
    result
  end

  def canonicalize(path)
    Chef::Platform.windows? ? path.gsub('/', '\\') : path
  end

  describe "when the target is a symlink" do
    before(:each) do
      lstat = mock("stats", :ino => 5)
      lstat.stub!(:uid).and_return(501)
      lstat.stub!(:gid).and_return(501)
      lstat.stub!(:mode).and_return(0777)
      File.stub!(:lstat).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(lstat)
      provider.file_class.stub!(:symlink?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(true)
      provider.file_class.stub!(:readlink).with("#{CHEF_SPEC_DATA}/fofile-link").and_return("#{CHEF_SPEC_DATA}/fofile")
    end

    describe "to a file that exists" do
      before do
        File.stub(:exist?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(true)
        new_resource.owner 501 # only loaded in current_resource if present in new
        new_resource.group 501
        provider.load_current_resource
      end

      it "should set the symlink target" do
        provider.current_resource.target_file.should == "#{CHEF_SPEC_DATA}/fofile-link"
      end
      it "should set the link type" do
        provider.current_resource.link_type.should == :symbolic
      end
      it "should update the source of the existing link with the links target" do
        provider.current_resource.to.should == canonicalize("#{CHEF_SPEC_DATA}/fofile")
      end
      it "should set the owner" do
        provider.current_resource.owner.should == 501
      end
      it "should set the group" do
        provider.current_resource.group.should == 501
      end

      # We test create in unit tests because there is no other way to ensure
      # it does no work.  Other create and delete scenarios are covered in
      # the functional tests for links.
      context 'when the desired state is identical' do
        let(:new_resource) do
          result = Chef::Resource::Link.new("#{CHEF_SPEC_DATA}/fofile-link")
          result.to "#{CHEF_SPEC_DATA}/fofile"
          result
        end
        it 'create does no work' do
          provider.access_controls.should_not_receive(:set_all)
          provider.run_action(:create)
        end
      end
    end

    describe "to a file that doesn't exist" do
      before do
        File.stub!(:exist?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(false)
        provider.file_class.stub!(:symlink?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(true)
        provider.file_class.stub!(:readlink).with("#{CHEF_SPEC_DATA}/fofile-link").and_return("#{CHEF_SPEC_DATA}/fofile")
        new_resource.owner "501" # only loaded in current_resource if present in new
        new_resource.group "501"
        provider.load_current_resource
      end

      it "should set the symlink target" do
        provider.current_resource.target_file.should == "#{CHEF_SPEC_DATA}/fofile-link"
      end
      it "should set the link type" do
        provider.current_resource.link_type.should == :symbolic
      end
      it "should update the source of the existing link to the link's target" do
        provider.current_resource.to.should == canonicalize("#{CHEF_SPEC_DATA}/fofile")
      end
      it "should not set the owner" do
        provider.current_resource.owner.should be_nil
      end
      it "should not set the group" do
        provider.current_resource.group.should be_nil
      end
    end
  end

  describe "when the target doesn't exist" do
    before do
      File.stub!(:exists?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(false)
      provider.file_class.stub!(:symlink?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(false)
      provider.load_current_resource
    end

    it "should set the symlink target" do
      provider.current_resource.target_file.should == "#{CHEF_SPEC_DATA}/fofile-link"
    end
    it "should update the source of the existing link to nil" do
      provider.current_resource.to.should be_nil
    end
    it "should not set the owner" do
      provider.current_resource.owner.should == nil
    end
    it "should not set the group" do
      provider.current_resource.group.should == nil
    end
  end

  describe "when the target is a regular old file" do
    before do
      stat = mock("stats", :ino => 5)
      stat.stub!(:uid).and_return(501)
      stat.stub!(:gid).and_return(501)
      stat.stub!(:mode).and_return(0755)
      provider.file_class.stub!(:stat).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(stat)

      File.stub!(:exists?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(true)
      provider.file_class.stub!(:symlink?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(false)
    end

    describe "and the source does not exist" do
      before do
        File.stub!(:exists?).with("#{CHEF_SPEC_DATA}/fofile").and_return(false)
        provider.load_current_resource
      end

      it "should set the symlink target" do
        provider.current_resource.target_file.should == "#{CHEF_SPEC_DATA}/fofile-link"
      end
      it "should update the current source of the existing link with an empty string" do
        provider.current_resource.to.should == ''
      end
      it "should not set the owner" do
        provider.current_resource.owner.should == nil
      end
      it "should not set the group" do
        provider.current_resource.group.should == nil
      end
    end

    describe "and the source exists" do
      before do
        stat = mock("stats", :ino => 6)
        stat.stub!(:uid).and_return(502)
        stat.stub!(:gid).and_return(502)
        stat.stub!(:mode).and_return(0644)

        provider.file_class.stub!(:stat).with("#{CHEF_SPEC_DATA}/fofile").and_return(stat)

        File.stub!(:exists?).with("#{CHEF_SPEC_DATA}/fofile").and_return(true)
        provider.load_current_resource
      end

      it "should set the symlink target" do
        provider.current_resource.target_file.should == "#{CHEF_SPEC_DATA}/fofile-link"
      end
      it "should update the current source of the existing link with an empty string" do
        provider.current_resource.to.should == ''
      end
      it "should not set the owner" do
        provider.current_resource.owner.should == nil
      end
      it "should not set the group" do
        provider.current_resource.group.should == nil
      end
    end

    describe "and is hardlinked to the source" do
      before do
        stat = mock("stats", :ino => 5)
        stat.stub!(:uid).and_return(502)
        stat.stub!(:gid).and_return(502)
        stat.stub!(:mode).and_return(0644)

        provider.file_class.stub!(:stat).with("#{CHEF_SPEC_DATA}/fofile").and_return(stat)

        File.stub!(:exists?).with("#{CHEF_SPEC_DATA}/fofile").and_return(true)
        provider.load_current_resource
      end

      it "should set the symlink target" do
        provider.current_resource.target_file.should == "#{CHEF_SPEC_DATA}/fofile-link"
      end
      it "should set the link type" do
        provider.current_resource.link_type.should == :hard
      end
      it "should update the source of the existing link to the link's target" do
        provider.current_resource.to.should == canonicalize("#{CHEF_SPEC_DATA}/fofile")
      end
      it "should not set the owner" do
        provider.current_resource.owner.should == nil
      end
      it "should not set the group" do
        provider.current_resource.group.should == nil
      end

      # We test create in unit tests because there is no other way to ensure
      # it does no work.  Other create and delete scenarios are covered in
      # the functional tests for links.
      context 'when the desired state is identical' do
        let(:new_resource) do
          result = Chef::Resource::Link.new("#{CHEF_SPEC_DATA}/fofile-link")
          result.to "#{CHEF_SPEC_DATA}/fofile"
          result.link_type :hard
          result
        end
        it 'create does no work' do
          provider.file_class.should_not_receive(:symlink) 
          provider.file_class.should_not_receive(:link) 
          provider.access_controls.should_not_receive(:set_all)
          provider.run_action(:create)
        end
      end
    end
  end
end
