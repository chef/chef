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

require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")

describe Chef::Provider::File do
  before(:each) do
    @resource = Chef::Resource::File.new("seattle")
    @resource.path(File.join(File.dirname(__FILE__), "..", "..", "data", "seattle.txt"))
    @node = Chef::Node.new
    @node.name "latte"
    @provider = Chef::Provider::File.new(@node, @resource)
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
    @provider.current_resource.owner.should_not eql(nil) 
    @provider.current_resource.group.should_not eql(nil)
    @provider.current_resource.mode.should_not eql(nil)
  end
  
  it "should load a mostly blank current resource if the file specified in new_resource doesn't exist/isn't readable" do
    resource = Chef::Resource::File.new("seattle")
    resource.path(File.join(File.dirname(__FILE__), "..", "..", "data", "woot.txt"))
    node = Chef::Node.new
    node.name "latte"
    provider = Chef::Provider::File.new(node, resource)
    provider.load_current_resource
    provider.current_resource.should be_a_kind_of(Chef::Resource::File)
    provider.current_resource.name.should eql(resource.name)
    provider.current_resource.path.should eql(resource.path)
    provider.current_resource.owner.should eql(nil) 
    provider.current_resource.group.should eql(nil)
    provider.current_resource.mode.should eql(nil)
  end
  
  it "should load the correct value for owner of the current resource" do
    stats = File.stat(@resource.path)
    @provider.load_current_resource
    @provider.current_resource.owner.should eql(stats.uid)
  end
  
  it "should load an md5 sum for an existing file" do
    @provider.load_current_resource
    @provider.current_resource.checksum("8d6152c7d62ea9188eda596c4d31e732")
  end
  
  it "should compare the current owner with the requested owner" do
    @provider.load_current_resource
    @provider.new_resource.stub!(:owner).and_return("adam")
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
    @provider.current_resource.owner(501)
    @provider.compare_owner.should eql(true)
    
    @provider.current_resource.owner(777)
    @provider.compare_owner.should eql(false)
    
    @provider.new_resource.stub!(:owner).and_return(501)
    @provider.current_resource.owner(501)
    @provider.compare_owner.should eql(true)
    
    @provider.new_resource.stub!(:owner).and_return("501")
    @provider.current_resource.owner(501)
    @provider.compare_owner.should eql(true)
  end
  
  it "should set the ownership on the file to the requested owner" do
    @provider.load_current_resource
    @provider.new_resource.stub!(:owner).and_return(9982398)
    File.stub!(:chown).and_return(1)
    File.should_receive(:chown).with(9982398, nil, @provider.current_resource.path)
    lambda { @provider.set_owner }.should_not raise_error
  end
  
  it "should raise an exception if you are not root and try to change ownership" do
    @provider.load_current_resource
    @provider.new_resource.stub!(:owner).and_return(0)
    if Process.uid != 0
      lambda { @provider.set_owner }.should raise_error
    end
  end
  
  it "should compare the current group with the requested group" do
    @provider.load_current_resource
    @provider.new_resource.stub!(:group).and_return("adam")
    Etc.stub!(:getgrnam).and_return(
      OpenStruct.new(
        :name => "adam",
        :gid => 501
      )
    )
    @provider.current_resource.group(501)
    @provider.compare_group.should eql(true)
    
    @provider.current_resource.group(777)
    @provider.compare_group.should eql(false)
    
    @provider.new_resource.stub!(:group).and_return(501)
    @provider.current_resource.group(501)
    @provider.compare_group.should eql(true)
    
    @provider.new_resource.stub!(:group).and_return("501")
    @provider.current_resource.group(501)
    @provider.compare_group.should eql(true)
  end
  
  it "should set the group on the file to the requested group" do
    @provider.load_current_resource
    @provider.new_resource.stub!(:group).and_return(9982398)
    File.stub!(:chown).and_return(1)
    File.should_receive(:chown).with(nil, 9982398, @provider.current_resource.path)
    lambda { @provider.set_group }.should_not raise_error
  end
  
  it "should raise an exception if you are not root and try to change the group" do
    @provider.load_current_resource
    @provider.new_resource.stub!(:group).and_return(0)
    if Process.uid != 0
      lambda { @provider.set_group }.should raise_error
    end
  end
  
  it "should create the file if it is missing, then set the attributes on action_create" do
    @provider.load_current_resource
    @provider.new_resource.stub!(:owner).and_return(9982398)
    @provider.new_resource.stub!(:group).and_return(9982398)
    @provider.new_resource.stub!(:path).and_return("/tmp/monkeyfoo")
    File.stub!(:chown).and_return(1)
    File.should_receive(:chown).with(nil, 9982398, @provider.new_resource.path)
    File.stub!(:chown).and_return(1)
    File.should_receive(:chown).with(9982398, nil, @provider.new_resource.path)
    File.stub!(:open).and_return(1)
    File.should_receive(:open).with(@provider.new_resource.path, "w+")
    @provider.action_create
  end
  
  it "should delete the file if it exists and is writable on action_delete" do
    @provider.load_current_resource
    @provider.new_resource.stub!(:path).and_return("/tmp/monkeyfoo")
    File.should_receive("exists?").with(@provider.new_resource.path).and_return(true)
    File.should_receive("writable?").with(@provider.new_resource.path).and_return(true)
    File.should_receive(:delete).with(@provider.new_resource.path).and_return(true)
    @provider.action_delete
  end
  
end