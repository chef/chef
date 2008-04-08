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

describe Chef::Provider do
  before(:each) do
    @resource = Chef::Resource.new("funk")
    @node = Chef::Node.new
    @node.name "latte"
    @provider = Chef::Provider.new(@node, @resource)
  end
  
  it "should return a Chef::Provider" do
    @provider.should be_a_kind_of(Chef::Provider)
  end
  
  it "should store the resource passed to new as new_resource" do
    @provider.new_resource.should eql(@resource)
  end
  
  it "should store the node passed to new as node" do
    @provider.node.should eql(@node)
  end
  
  it "should have nil for current_resource by default" do
    @provider.current_resource.should eql(nil)
  end    
end