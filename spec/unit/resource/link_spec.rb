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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Resource::Link do

  before(:each) do
    @resource = Chef::Resource::Link.new("fakey_fakerton")
  end  

  it "should create a new Chef::Resource::Link" do
    @resource.should be_a_kind_of(Chef::Resource)
    @resource.should be_a_kind_of(Chef::Resource::Link)
  end
  
  it "should have a name" do
    @resource.name.should eql("fakey_fakerton")
  end
  
  it "should have a default action of 'create'" do
    @resource.action.should eql(:create)
  end
  
  it "should accept create or delete for action" do
    lambda { @resource.action "create" }.should_not raise_error(ArgumentError)
    lambda { @resource.action "delete" }.should_not raise_error(ArgumentError)
    lambda { @resource.action "blues" }.should raise_error(ArgumentError)
  end
    
  it "should use the object name as the source_file by default" do
    @resource.source_file.should eql("fakey_fakerton")
  end
  
  it "should accept a string as the source_file" do
    lambda { @resource.source_file "/tmp" }.should_not raise_error(ArgumentError)
    lambda { @resource.source_file Hash.new }.should raise_error(ArgumentError)
  end
  
  it "should allow you to set a target_file" do
    @resource.target_file "/tmp/foo"
    @resource.target_file.should eql("/tmp/foo")
  end
  
  it "should allow you to specify the link type" do
    @resource.link_type "symbolic"
    @resource.link_type.should eql(:symbolic)
  end
  
  it "should default to a symbolic link" do
    @resource.link_type.should eql(:symbolic)
  end
  
  it "should accept a hard link_type" do
    @resource.link_type :hard
    @resource.link_type.should eql(:hard)
  end
  
  it "should reject any other link_type but :hard and :symbolic" do
    lambda { @resource.link_type "x-men" }.should raise_error(ArgumentError)
  end
  
end