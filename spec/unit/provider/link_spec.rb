#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
# License:: GNU General Public License version 2 or later
# 
# This program and entire repository is free software; you can
# redistribute it and/or modify it under the terms of the GNU 
# General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#

require 'ostruct'

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Provider::Link do
  before(:each) do
    @new_resource = mock("New Resource", :null_object => true)
    @new_resource.stub!(:name).and_return("symlink")
    @new_resource.stub!(:source_file).and_return("/tmp/fofile")
    @new_resource.stub!(:target_file).and_return("/tmp/fofile-link")
    @new_resource.stub!(:link_type).and_return(:symbolic)
    @new_resource.stub!(:updated).and_return(false)
    @node = Chef::Node.new
    @node.name "latte"
    @provider = Chef::Provider::Link.new(@node, @new_resource)
  end
  
  it "should load the current resource based on the new resource" do
    File.should_receive(:exists?).once.and_return(true)
    File.should_receive(:symlink?).once.and_return(true)
    File.should_receive(:readlink).once.and_return("/tmp/fofile")
    @provider.load_current_resource
    @provider.current_resource.name.should eql("symlink")
    @provider.current_resource.source_file.should eql("/tmp/fofile")
    @provider.current_resource.target_file.should eql("/tmp/fofile-link")
    @provider.current_resource.link_type.should eql(:symbolic)
  end
  
  it "should set the current resource's source_file to '' if the target_file doesn't exist" do
    File.should_receive(:exists?).once.and_return(true)
    File.should_receive(:symlink?).once.and_return(false)
    @provider.load_current_resource
    @provider.current_resource.source_file.should eql("")
  end
  
  it "should load the current resource if it is a hard link" do
    @new_resource.stub!(:link_type).and_return(:hard)
    File.should_receive(:exists?).twice.and_return(true)
    cstat = mock("stats", :null_object => true)
    cstat.stub!(:ino).and_return(1)
    File.should_receive(:stat).with("/tmp/fofile-link").and_return(cstat)
    File.should_receive(:stat).with("/tmp/fofile").and_return(cstat)
    @provider.load_current_resource
    @provider.current_resource.name.should eql("symlink")
    @provider.current_resource.source_file.should eql("/tmp/fofile")
    @provider.current_resource.target_file.should eql("/tmp/fofile-link")
    @provider.current_resource.link_type.should eql(:hard)
  end
  
  it "should set the current resource's source_file to '' if the target_file doesn't exist" do
    @new_resource.stub!(:link_type).and_return(:hard)
    File.should_receive(:exists?).once.and_return(false)
    @provider.load_current_resource
    @provider.current_resource.source_file.should eql("")
  end
  
  it "should set the current resource's source_file to '' if the two files arent hardlinked" do
    @new_resource.stub!(:link_type).and_return(:hard)
    File.stub!(:exists?).and_return(true)
    cstat = mock("stats", :null_object => true)
    cstat.stub!(:ino).and_return(0)
    bstat = mock("stats", :null_object => true)
    bstat.stub!(:ino).and_return(1)
    File.should_receive(:stat).with("/tmp/fofile-link").and_return(cstat)
    File.should_receive(:stat).with("/tmp/fofile").and_return(bstat)
    @provider.load_current_resource
    @provider.current_resource.source_file.should eql("")
  end
  
  it "should create a new symlink on create, setting updated to true" do
    load_mock_symlink_provider
    @provider.current_resource.source_file("nil")
    File.should_receive(:symlink).with(@new_resource.source_file, @new_resource.target_file).once.and_return(true)
    @provider.new_resource.should_receive(:updated=).with(true)
    @provider.action_create
  end
  
  it "should not create a new symlink on create if it already exists" do
    load_mock_symlink_provider
    File.should_not_receive(:symlink).with(@new_resource.source_file, @new_resource.target_file)
    @provider.action_create
  end 

  it "should create a new hard link on create, setting updated to true" do
    load_mock_hardlink_provider
    @provider.current_resource.source_file("nil")
    File.should_receive(:link).with(@new_resource.source_file, @new_resource.target_file).once.and_return(true)
    @provider.new_resource.should_receive(:updated=).with(true)
    @provider.action_create
  end
  
  it "should not create a new hard link on create if it already exists" do
    load_mock_symlink_provider
    File.should_not_receive(:link).with(@new_resource.source_file, @new_resource.target_file)
    @provider.action_create
  end
  
  it "should delete the link if it exists, and is writable with action_delete" do
    load_mock_symlink_provider
    File.should_receive(:exists?).once.and_return(true)
    File.should_receive(:writable?).once.and_return(true)
    File.should_receive(:delete).with(@new_resource.target_file).once.and_return(true)
    @provider.action_delete
  end
  
  it "should raise an exception if it cannot delete the link due to bad permissions" do
    load_mock_symlink_provider
    File.stub!(:exists?).and_return(true)
    File.stub!(:writable?).and_return(false)
    lambda { @provider.action_delete }.should raise_error(RuntimeError)
  end
  
  def load_mock_symlink_provider
    File.stub!(:exists?).and_return(true)
    File.stub!(:symlink?).and_return(true)
    File.stub!(:readlink).and_return("/tmp/fofile")
    @provider.load_current_resource
  end
  
  def load_mock_hardlink_provider
    @new_resource.stub!(:link_type).and_return(:hard)
    File.stub!(:exists?).twice.and_return(true)
    cstat = mock("stats", :null_object => true)
    cstat.stub!(:ino).and_return(1)
    File.stub!(:stat).with("/tmp/fofile-link").and_return(cstat)
    File.stub!(:stat).with("/tmp/fofile").and_return(cstat)
    @provider.load_current_resource
  end
end