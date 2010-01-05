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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Provider::Link, "initialize" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource", :null_object => true)
  end
  
  it "should return a Chef::Provider::Link object" do
    provider = Chef::Provider::Link.new(@node, @new_resource)
    provider.should be_a_kind_of(Chef::Provider::Link)
  end
end

describe Chef::Provider::Link, "load_current_resource" do
  before do
    @node = mock("Chef::Node", :null_object => true)

    @new_resource = mock("Chef::Resource::Link",
      :null_object => true,
      :name => "linkytimes",
      :to => "/tmp/fofile",
      :target_file => "/tmp/fofile-link",
      :link_type => :symbolic,
      :updated => false
    )

    @current_resource = mock("Chef::Resource::Link",
      :null_object => true,
      :name => "linkytimes",
      :to => "/tmp/fofile",
      :target_file => "/tmp/fofile-link",
      :link_type => :symbolic,
      :updated => false
    )

    @provider = Chef::Provider::Link.new(@node, @new_resource)
    Chef::Resource::Link.stub!(:new).and_return(@current_resource)  
    File.stub!(:exists?).and_return(true)
    File.stub!(:symlink?).and_return(true)
    File.stub!(:readlink).and_return("")

    lstat = mock("stats", :null_object => true)
    lstat.stub!(:uid).and_return(501)
    lstat.stub!(:gid).and_return(501)

    File.stub!(:lstat).and_return(lstat)
end

  it "should set the symlink target" do
    @current_resource.should_receive(:target_file).with("/tmp/fofile-link").and_return(true)
    @provider.load_current_resource
  end
  
  it "should set the link type" do
    @current_resource.should_receive(:link_type).with(:symbolic).and_return(true)
    @provider.load_current_resource
  end
  
  describe "when the link type is symbolic" do
    
    before do
      @new_resource.stub(:link_type).and_return(:symbolic)
    end
    
    describe "and the target exists and is a symlink" do
      before do
        File.stub!(:exists?).with("/tmp/fofile-link").and_return(true)
        File.stub!(:symlink?).with("/tmp/fofile-link").and_return(true)
        File.stub!(:readlink).with("/tmp/fofile-link").and_return("/tmp/fofile")
      end
      
      it "should update the source of the existing link with the links target" do
        @current_resource.should_receive(:to).with("/tmp/fofile").and_return(true)
        @provider.load_current_resource
      end
      it "should set the owner" do
        @current_resource.should_receive(:owner).with(501).and_return(true)
        @provider.load_current_resource
      end
      
      it "should set the group" do
        @current_resource.should_receive(:group).with(501).and_return(true)
        @provider.load_current_resource
      end
    end
    
    describe "and the target doesn't exist" do
      before do
        File.should_receive(:exists?).with("/tmp/fofile-link").and_return(false)
      end
      
      it "should update the source of the existing link to an empty string" do
        @current_resource.should_receive(:to).with("").and_return(true)
        @provider.load_current_resource
      end
      
    end
    
    describe "and the target isn't a symlink" do
      before do
        File.should_receive(:symlink?).with("/tmp/fofile-link").and_return(false)
      end
      
      it "should update the current source of the existing link with an empty string" do
        @current_resource.should_receive(:to).with("").and_return(true)
        @provider.load_current_resource
      end
    end
  end
  
  describe "when the link type is hard, " do
    before do
      @new_resource.stub!(:link_type).and_return(:hard)
    end
    
    describe "the target file and source file both exist" do
      before do
        File.should_receive(:exists?).with("/tmp/fofile-link").and_return(true)
        File.should_receive(:exists?).with("/tmp/fofile").and_return(true)
      end
      
      describe "and the inodes match" do
        before do
          stat = mock("stats", :null_object => true)
          stat.stub!(:ino).and_return(1)
          File.should_receive(:stat).with("/tmp/fofile-link").and_return(stat)
          File.should_receive(:stat).with("/tmp/fofile").and_return(stat)
        end
        
        it "should update the source of the existing link to the target file" do
          @current_resource.should_receive(:to).with("/tmp/fofile").and_return(true)
          @provider.load_current_resource
        end
      end
      
      describe "and the inodes don't match" do
        before do
          stat = mock("stats", :null_object => true)
          stat.stub!(:ino).and_return(1)
          stat_two = mock("stats", :null_object => true)
          stat.stub!(:ino).and_return(2)
          File.should_receive(:stat).with("/tmp/fofile-link").and_return(stat)
          File.should_receive(:stat).with("/tmp/fofile").and_return(stat_two)
        end
        
        it "should set the source of the existing link to an empty string" do
          @current_resource.should_receive(:to).with("").and_return(true)
          @provider.load_current_resource
        end
      end
    end
    describe "but the target does not exist" do
      before do
        File.should_receive(:exists?).with("/tmp/fofile-link").and_return(false)
      end
      
      it "should set the source of the existing link to an empty string" do
        @current_resource.should_receive(:to).with("").and_return(true)
        @provider.load_current_resource
      end
    end
    describe "but the source does not exist" do
      before do
        File.should_receive(:exists?).with("/tmp/fofile").and_return(false)
      end
      
      it "should set the source of the existing link to an empty string" do
        @current_resource.should_receive(:to).with("").and_return(true)
        @provider.load_current_resource
      end
    end
  end
  
  it "should return the current resource" do
    @provider.load_current_resource.should eql(@current_resource)
  end
end

describe Chef::Provider::Link, "action_create" do
  before do
    @node = mock("Chef::Node", :null_object => true)

    @new_resource = mock("Chef::Resource::Link",
      :null_object => true,
      :name => "linkytimes",
      :to => "/tmp/fofile",
      :target_file => "/tmp/fofile-link",
      :link_type => :symbolic,
      :updated => false,
      :owner => "adam",
      :group => "adam"
    )

    @current_resource = mock("Chef::Resource::Link",
      :null_object => true,
      :name => "linkytimes",
      :to => "/tmp/fofile",
      :target_file => "/tmp/fofile-link",
      :link_type => :symbolic,
      :updated => false,
      :owner => 501,
      :group => 501
    )

    @provider = Chef::Provider::Link.new(@node, @new_resource)
    Chef::Resource::Link.stub!(:new).and_return(@current_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:run_command).and_return(true)
    @new_resource.stub!(:to_s).and_return("link[/tmp/fofile]")
    File.stub!(:link).and_return(true)
    Etc.stub!(:getpwnam).and_return(
      OpenStruct.new(
        :name => "adam",
        :passwd => "foo",
        :uid => 501,
        :gid => 501,
        :gecos => "Adam Jacob",
        :dir => "/Users/adam",
        :shell => "/bin/zsh",
        :change => "0",
        :uclass => "",
        :expire => 0
      )
    )
    Etc.stub!(:getgrnam).and_return(
      OpenStruct.new(
        :name => "adam",
        :gid => 501
      )
    )
 end

  describe "when the source for the link contains expandable pieces" do
    before do
      @new_resource.stub!(:target_file).and_return("/etc/chef")
      @new_resource.stub!(:to).and_return("../foo")
    end

    it "should expand the path" do
      ::File.should_receive(:expand_path).with("../foo", "/etc/chef").and_return("/etc/foo")
      @provider.action_create
    end
  end
  
  describe "when the source for the link doesn't match" do
    before do
      @new_resource.stub!(:to).and_return("/tmp/lolololol")
    end
    
    it "should log an appropriate message" do
      Chef::Log.should_receive(:info).with("Creating a symbolic link from /tmp/lolololol -> /tmp/fofile-link for link[/tmp/fofile]")
      @provider.action_create
    end
    
    describe "and we're building a symbolic link" do
      before do
        @new_resource.stub!(:link_type).and_return(:symbolic)
      end
      
      it "should compare the current owner with the requested owner" do
        @provider.current_resource.stub!(:owner).and_return(501)
        @provider.compare_owner.should eql(true)
        
        @provider.current_resource.stub!(:owner).and_return(777)
        @provider.compare_owner.should eql(false)
        
        @provider.new_resource.stub!(:owner).and_return(501)
        @provider.current_resource.stub!(:owner).and_return(501)
        @provider.compare_owner.should eql(true)
        
        @provider.new_resource.stub!(:owner).and_return("501")
        @provider.current_resource.stub!(:owner).and_return(501)
        @provider.compare_owner.should eql(true)
      end

      it "should set the ownership on the file to the requested owner" do
        @provider.new_resource.stub!(:owner).and_return(9982398)
        File.stub!(:lchown).and_return(1)
        File.should_receive(:lchown).with(9982398, nil, @provider.current_resource.target_file)
        lambda { @provider.set_owner }.should_not raise_error
      end

      it "should raise an exception if you are not root and try to change ownership" do
        @provider.new_resource.stub!(:owner).and_return(0)
        if Process.uid != 0
          lambda { @provider.set_owner }.should raise_error
        end
      end

      it "should compare the current group with the requested group" do
        @provider.current_resource.stub!(:group).and_return(501)
        @provider.compare_group.should eql(true)
        
        @provider.current_resource.stub!(:group).and_return(777)
        @provider.compare_group.should eql(false)
        
        @provider.new_resource.stub!(:group).and_return(501)
        @provider.current_resource.stub!(:group).and_return(501)
        @provider.compare_group.should eql(true)
        
        @provider.new_resource.stub!(:group).and_return("501")
        @provider.current_resource.stub!(:group).and_return(501)
        @provider.compare_group.should eql(true)
      end
      
      it "should set the group on the file to the requested group" do
        @provider.new_resource.stub!(:group).and_return(9982398)
        File.stub!(:lchown).and_return(1)
        File.should_receive(:lchown).with(nil, 9982398, @provider.current_resource.target_file)
        lambda { @provider.set_group }.should_not raise_error
      end
      
      it "should raise an exception if you are not root and try to change the group" do
        @provider.new_resource.stub!(:group).and_return(0)
        if Process.uid != 0
          lambda { @provider.set_group }.should raise_error
        end
      end

      it "should run 'ln' with the parameters to create the link" do
        @provider.should_receive(:run_command).with({:command => "ln -nfs /tmp/lolololol /tmp/fofile-link"}).and_return(true)
        @provider.action_create
      end

      it "should create the link if it is missing, then set the attributes on action_create" do
        @provider.new_resource.stub!(:owner).and_return(9982398)
        @provider.new_resource.stub!(:group).and_return(9982398)
        File.stub!(:lchown).and_return(1)
        File.should_receive(:lchown).with(nil, 9982398, @provider.new_resource.target_file)
        File.stub!(:lchown).and_return(1)
        File.should_receive(:lchown).with(9982398, nil, @provider.new_resource.target_file)
        @provider.action_create
      end
    end
    
    describe "and we're building a hard link" do
      before do
        @new_resource.stub!(:link_type).and_return(:hard)
      end
      
      it "should use the ruby builtin to create the link" do
        File.should_receive(:link).with("/tmp/lolololol", "/tmp/fofile-link").and_return(true)
        @provider.action_create
      end
      
      it "we should not attempt to set owner or group" do
        @provider.should_not_receive(:set_owner)
        @provider.should_not_receive(:set_group)
        @provider.action_create
      end
    end
    
    it "should set updated to true" do
      @new_resource.should_receive(:updated=).with(true).and_return(true)
      @provider.action_create
    end
  end
  
end

describe Chef::Provider::Link, "action_delete" do
  before do
    @node = mock("Chef::Node", :null_object => true)

    @new_resource = mock("Chef::Resource::Link",
      :null_object => true,
      :name => "linkytimes",
      :to => "/tmp/fofile",
      :target_file => "/tmp/fofile-link",
      :link_type => :symbolic,
      :updated => false
    )

    @current_resource = mock("Chef::Resource::Link",
      :null_object => true,
      :name => "linkytimes",
      :to => "/tmp/fofile",
      :target_file => "/tmp/fofile-link",
      :link_type => :symbolic,
      :updated => false
    )

    @provider = Chef::Provider::Link.new(@node, @new_resource)
    Chef::Resource::Link.stub!(:new).and_return(@current_resource)
    @provider.current_resource = @current_resource
    @new_resource.stub!(:to_s).and_return("link[/tmp/fofile]")
    File.stub!(:symlink?).and_return(true)
    File.stub!(:exists?).and_return(true)
    File.stub!(:delete).and_return(true)
  end
  
  describe "when we're building a symbolic link" do
    before do
      @new_resource.stub!(:link_type).and_return(:symbolic)
    end
    
    describe "and when the symlink exists" do
      before do
        File.should_receive(:symlink?).with("/tmp/fofile-link").and_return(true)
      end
      
      it "should log an appropriate error message" do
        Chef::Log.should_receive(:info).with("Deleting link[/tmp/fofile] at /tmp/fofile-link")
        @provider.action_delete
      end
      
      it "should use the ruby builtin to delete the file" do
        File.should_receive(:delete).with("/tmp/fofile-link").and_return(true)
        @provider.action_delete
      end
      
      it "should set updated to true" do
        @new_resource.should_receive(:updated=).with(true).and_return(true)
        @provider.action_delete
      end
    end
    
    describe "and when the file is not a symbolic link but does exist" do
      before(:each) do
        File.should_receive(:symlink?).with("/tmp/fofile-link").and_return(false)
        File.should_receive(:exists?).with("/tmp/fofile-link").and_return(true)
      end
      
      it "should raise a Link error" do
        lambda { @provider.action_delete }.should raise_error(Chef::Exceptions::Link)
      end
    end
    
    describe "and when the symbolic link and file do not exist" do
      before do
        File.should_receive(:symlink?).with("/tmp/fofile-link").and_return(false)
        File.should_receive(:exists?).with("/tmp/fofile-link").and_return(false)
      end
      
      it "should not raise a Link error" do
        lambda { @provider.action_delete }.should_not raise_error(Chef::Exceptions::Link)
      end
    end
  end
  
  describe "when we're building a hard link" do
    before do
      @new_resource.stub!(:link_type).and_return(:hard)
    end
      
    describe "and when the file exists" do
      before do
        File.should_receive(:exists?).with("/tmp/fofile-link").and_return(true)
      end
      
      describe "and the inodes match" do
        before do
          stat = mock("stats", :null_object => true)
          stat.stub!(:ino).and_return(1)
          File.should_receive(:stat).with("/tmp/fofile-link").and_return(stat)
          File.should_receive(:stat).with("/tmp/fofile").and_return(stat)
        end
        
        it "should log an appropriate error message" do
          Chef::Log.should_receive(:info).with("Deleting link[/tmp/fofile] at /tmp/fofile-link")
          @provider.action_delete
        end
        it "should use the ruby builtin to delete the file" do
          File.should_receive(:delete).with("/tmp/fofile-link").and_return(true)
          @provider.action_delete
        end
        
        it "should set updated to true" do
          @new_resource.should_receive(:updated=).with(true).and_return(true)
          @provider.action_delete
        end
      end
      
      describe "and the inodes don't match" do
        before do
          stat = mock("stats", :null_object => true)
          stat.stub!(:ino).and_return(1)
          stat_two = mock("stats", :null_object => true)
          stat.stub!(:ino).and_return(2)
          File.should_receive(:stat).with("/tmp/fofile-link").and_return(stat)
          File.should_receive(:stat).with("/tmp/fofile").and_return(stat_two)
        end
        
        it "should raise a Link error" do
          lambda { @provider.action_delete }.should raise_error(Chef::Exceptions::Link)
        end
      end
      
    end
    
    describe "and when file does not exist" do
      before do
        File.should_receive(:exists?).with("/tmp/fofile-link").and_return(false)
      end
      
      it "should not raise a Link error" do
        lambda { @provider.action_delete }.should_not raise_error(Chef::Exceptions::Link)
      end
    end
  end

end
