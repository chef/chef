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
  end

  it "should set the symink target" do
    @current_resource.should_receive(:target_file).with("/tmp/fofile-link").and_return(true)
    @provider.load_current_resource
  end
  
  it "should set the link type" do
    @current_resource.should_recieve(:link_type).with(:symbolic).and_return(true)
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
        @current_resource.stub!(:target_file).and_return("/tmp/fofile")
      end
      
      it "should update the source of the existing link with the links target" do
        @current_resource.should_recieve(:to).with("/tmp/fofile").and_return(true)
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
          @current_resource.should_recieve(:to).with("").and_return(true)
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
    @provider.stub!(:run_command).and_return(true)
    @new_resource.stub!(:to_s).and_return("link[/tmp/fofile]")
    File.stub!(:link).and_return(true)
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
      
      it "should run 'ln' with the parameters to create the link" do
        @provider.should_receive(:run_command).with({:command => "ln -nfs /tmp/lolololol /tmp/fofile-link"}).and_return(true)
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
  
  describe "when the file exists" do
    before do
      File.should_receive(:exists?).with("/tmp/fofile-link").and_return(true)
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
  
  describe "when the file exists but is not a symbolic link" do
    before(:each) do
      File.should_receive(:symlink?).with("/tmp/fofile-link").and_return(false)
    end
    
    it "should raise a Link error" do
      lambda { @provider.action_delete }.should raise_error(Chef::Exceptions::Link)
    end
  end
  
  describe "when the file does not exist" do
    before do
      File.should_receive(:exists?).with("/tmp/fofile-link").and_return(false)
    end
    
    it "should not raise a Link error" do
      lambda { @provider.action_delete }.should_not raise_error(Chef::Exceptions::Link)
    end
  end

end
