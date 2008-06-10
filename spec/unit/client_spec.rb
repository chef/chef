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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

describe Chef::Client, "initialize" do
  it "should create a new Chef::Client object" do
    Chef::Client.new.should be_kind_of(Chef::Client)
  end
end

describe Chef::Client, "build_node" do
  before(:each) do
    @mock_facter_fqdn = mock("Facter FQDN")
    @mock_facter_fqdn.stub!(:value).and_return("foo.bar.com")
    @mock_facter_hostname = mock("Facter Hostname")
    @mock_facter_hostname.stub!(:value).and_return("foo")
    Facter.stub!(:[]).with("fqdn").and_return(@mock_facter_fqdn)
    Facter.stub!(:[]).with("hostname").and_return(@mock_facter_hostname)
    Facter.stub!(:each).and_return(true)
    @client = Chef::Client.new
  end
  
  it "should set the name equal to the FQDN" do
    @client.build_node
    @client.node.name.should eql("foo.bar.com")
  end
  
  it "should set the name equal to the hostname if FQDN is not available" do
    @mock_facter_fqdn.stub!(:value).and_return(nil)
    @client.build_node
    @client.node.name.should eql("foo")
  end
end

describe Chef::Client, "register" do
  before(:each) do
    @client = Chef::Client.new
  end
  
  it "should check to see if it's already registered"
  
  it "should create a new passphrase if not registered"
  
  it "should create a new registration if it has not registered"
end