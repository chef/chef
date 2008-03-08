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

require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")

describe Marionette::Resource::File do

  before(:each) do
    @resource = Marionette::Resource::File.new("fakey_fakerton")
  end  

  it "should create a new Marionette::Resource::File" do
    @resource.should be_a_kind_of(Marionette::Resource)
    @resource.should be_a_kind_of(Marionette::Resource::File)
  end
  
  it "should have a name" do
    @resource.name.should eql("fakey_fakerton")
  end
  
  it "should be set to back up files by default" do
    @resource.backup.should eql(true)
  end
  
  it "should only accept true, false, or a number for backup" do
    lambda { @resource.backup true }.should_not raise_error(ArgumentError)
    lambda { @resource.backup false }.should_not raise_error(ArgumentError)
    lambda { @resource.backup 10 }.should_not raise_error(ArgumentError)
    lambda { @resource.backup "blues" }.should raise_error(ArgumentError)
  end
  
  it "should use the md5sum for checking changes by default" do
    @resource.checksum.should eql("md5sum")
  end
  
  it "should accept md5sum or mtime for checksum" do
    lambda { @resource.checksum "md5sum" }.should_not raise_error(ArgumentError)
    lambda { @resource.checksum "mtime" }.should_not raise_error(ArgumentError)
    lambda { @resource.checksum "blues" }.should raise_error(ArgumentError)
  end
  
  it "should accept absent or present for insure" do
    lambda { @resource.insure "absent" }.should_not raise_error(ArgumentError)
    lambda { @resource.insure "present" }.should_not raise_error(ArgumentError)
    lambda { @resource.insure "blues" }.should raise_error(ArgumentError)
  end
  
  it "should accept a group name or id for group" do
    lambda { @resource.group "root" }.should_not raise_error(ArgumentError)
    lambda { @resource.group 123 }.should_not raise_error(ArgumentError)
    lambda { @resource.group "root*goo" }.should raise_error(ArgumentError)
  end
  
  it "should accept a valid unix file mode" do
    lambda { @resource.mode 0444 }.should_not raise_error(ArgumentError)
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
    lambda { @resource.path Hash.new }.should raise_error(ArgumentError)
  end
  
end