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

require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Marionette::Node do
  before(:each) do
    @node = Marionette::Node.new("latte")
  end
  
  it "should have a name" do
    @resource.name.should eql("latte")
  end
  
  it "should create a new Marionette::Node" do
    @resource.should be_a_kind_of(Marionette::Node)
  end
  
  it "should not be valid without a name" do
    lambda { @resource.name = nil }.should raise_error(ArgumentError)
  end
  
  it "should always have a string for name" do
    lambda { @resource.name = Hash.new }.should raise_error(ArgumentError)
  end

end