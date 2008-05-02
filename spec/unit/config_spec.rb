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

describe Chef::Config do
  
  it "should load a .rb file in context" do
    lambda { 
      Chef::Config.from_file(File.join(File.dirname(__FILE__), "..", "data", "config.rb"))
    }.should_not raise_error    
  end
  
  it "should raise an ArgumentError with an explanation if you try and set a non-existent variable" do
    lambda { 
      Chef::Config.from_file(File.join(File.dirname(__FILE__), "..", "data", "bad-config.rb")) 
    }.should raise_error(ArgumentError)
  end
  
  it "should raise an IOError if it can't find the file" do
    lambda { 
      Chef::Config.from_file("/tmp/timmytimmytimmy")
    }.should raise_error(IOError)
  end
  
  it "should have a default cookbook_path" do
    Chef::Config.cookbook_path.should be_kind_of(Array)
  end
  
  it "should allow you to set a cookbook_path with a string" do
    Chef::Config.cookbook_path("/etc/chef/cookbook")
    Chef::Config.cookbook_path.should eql("/etc/chef/cookbook")
  end
  
  it "should allow you to set a cookbook_path with multiple strings" do
    Chef::Config.cookbook_path("/etc/chef/cookbook", "/etc/chef/upstream-cookbooks")
    Chef::Config.cookbook_path.should eql([ 
      "/etc/chef/cookbook", 
      "/etc/chef/upstream-cookbooks" 
    ])
  end
  
  it "should allow you to set a cookbook_path with an array" do
    Chef::Config.cookbook_path ["one", "two"]
    Chef::Config.cookbook_path.should eql(["one", "two"])
  end
  
  it "should allow you to reference a value by index" do
    Chef::Config[:cookbook_path].should be_kind_of(Array)
  end
  
  it "should allow you to set a value by index" do
    Chef::Config[:cookbook_path] = "one"
    Chef::Config[:cookbook_path].should == "one"
  end
  
  it "should allow you to set config values with a block" do
    Chef::Config.configure do |c|
      c[:cookbook_path] = "monkey_rabbit"
      c[:otherthing] = "boo"
    end
    Chef::Config.cookbook_path.should == "monkey_rabbit"
    Chef::Config.otherthing.should == "boo"
  end
  
  it "should raise an ArgumentError if you access a config option that does not exist" do
    lambda { Chef::Config[:snob_hobbery] }.should raise_error(ArgumentError)
  end
  
end