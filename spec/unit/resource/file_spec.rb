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

describe Chef::Resource::File do

  before(:each) do
    @resource = Chef::Resource::File.new("fakey_fakerton")
  end  

  it "should create a new Chef::Resource::File" do
    @resource.should be_a_kind_of(Chef::Resource)
    @resource.should be_a_kind_of(Chef::Resource::File)
  end
  
  it "should have a name" do
    @resource.name.should eql("fakey_fakerton")
  end
  
  it "should have a default action of 'create'" do
    @resource.action.should eql("create")
  end
  
  it "should be set to back up 5 files by default" do
    @resource.backup.should eql(5)
  end
  
  it "should only accept false or a number for backup" do
    lambda { @resource.backup true }.should raise_error(ArgumentError)
    lambda { @resource.backup false }.should_not raise_error(ArgumentError)
    lambda { @resource.backup 10 }.should_not raise_error(ArgumentError)
    lambda { @resource.backup "blues" }.should raise_error(ArgumentError)
  end
  
  it "should accept an md5sum for checksum" do
    lambda { @resource.checksum "bfda9e7a13afb123433667c2c7801d11" }.should_not raise_error(ArgumentError)
    lambda { @resource.checksum "monkey!" }.should raise_error(ArgumentError)
  end
  
  it "should accept create, delete or touch for action" do
    lambda { @resource.action "create" }.should_not raise_error(ArgumentError)
    lambda { @resource.action "delete" }.should_not raise_error(ArgumentError)
    lambda { @resource.action "touch" }.should_not raise_error(ArgumentError)
    lambda { @resource.action "blues" }.should raise_error(ArgumentError)
  end
  
  it "should accept a group name or id for group" do
    lambda { @resource.group "root" }.should_not raise_error(ArgumentError)
    lambda { @resource.group 123 }.should_not raise_error(ArgumentError)
    lambda { @resource.group "root*goo" }.should raise_error(ArgumentError)
  end
  
  it "should accept a valid unix file mode" do
    lambda { @resource.mode 0444 }.should_not raise_error(ArgumentError)
    @resource.mode.should eql(0444)
    lambda { @resource.mode 444 }.should_not raise_error(ArgumentError)
    lambda { @resource.mode 4 }.should raise_error(ArgumentError)
  end
  
  it "should accept a user name or id for owner" do
    lambda { @resource.owner "root" }.should_not raise_error(ArgumentError)
    lambda { @resource.owner 123 }.should_not raise_error(ArgumentError)
    lambda { @resource.owner "root*goo" }.should raise_error(ArgumentError)
  end
  
  it "should use the object name as the path by default" do
    @resource.path.should eql("fakey_fakerton")
  end
  
  it "should accept a string as the path" do
    lambda { @resource.path "/tmp" }.should_not raise_error(ArgumentError)
    @resource.path.should eql("/tmp")
    lambda { @resource.path Hash.new }.should raise_error(ArgumentError)
  end
  
end