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

require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Chef::Config do
  before(:each) do
    @config = Chef::Config.new
  end
  
  it "should load a .rb file in context" do    
    lambda { 
      Chef::Config.load_file(File.join(File.dirname(__FILE__), "..", "data", "config.rb"))
    }.should_not raise_error    
  end
  
  it "should raise a NoMethodError with an explanation if you have a bad config file" do
    lambda { 
      Chef::Config.load_file(File.join(File.dirname(__FILE__), "..", "data", "bad-config.rb")) 
    }.should raise_error(NoMethodError)
  end
  
  it "should raise an IOError if it can't find the file" do
    lambda { 
      Chef::Config.load_file("/tmp/timmytimmytimmy")
    }.should raise_error(IOError)
  end
  
  it "should have a default cookbook_path" do
    @config.cookbook_path.should be_kind_of(Array)
  end
  
  it "should allow you to set a cookbook_path with a string" do
    @config.cookbook_path("/etc/chef/cookbook")
    @config.cookbook_path.should eql(["/etc/chef/cookbook"])
  end
  
  it "should allow you to set a cookbook_path with multiple strings" do
    @config.cookbook_path("/etc/chef/cookbook", "/etc/chef/upstream-cookbooks")
    @config.cookbook_path.should eql([ 
      "/etc/chef/cookbook", 
      "/etc/chef/upstream-cookbooks" 
    ])
  end
  
  it "should allow you to set a cookbook_path with an array" do
    @config.cookbook_path ["one", "two"]
    @config.cookbook_path.should eql(["one", "two"])
  end
  
  it "should not allow you to set a cookbook_path with anything else" do
    lambda { @config.cookbook_path :symbol }.should raise_error(ArgumentError)
  end
  
end