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
describe Chef::Compile do
  before(:each) do
    Chef::Config.node_path(File.join(File.dirname(__FILE__), "..", "data", "compile", "nodes"))
    Chef::Config.cookbook_path(File.join(File.dirname(__FILE__), "..", "data", "compile", "cookbooks"))
    @compile = Chef::Compile.new
  end
  
  it "should create a new Chef::Compile" do
    @compile.should be_a_kind_of(Chef::Compile)
  end
  
  it "should have a Chef::CookbookLoader" do
    @compile.cookbook_loader.should be_a_kind_of(Chef::CookbookLoader)
  end
  
  it "should have a Chef::ResourceCollection" do
    @compile.resource_collection.should be_a_kind_of(Chef::ResourceCollection)
  end
  
  it "should have a hash of Definitions" do
    @compile.definitions.should be_a_kind_of(Hash)
  end

  it "should load a node by name" do
    lambda { 
      @compile.load_node("compile")
    }.should_not raise_error
    @compile.node.name.should == "compile"
  end
  
  it "should load all the definitions" do
    lambda { @compile.load_definitions }.should_not raise_error
    @compile.definitions.should have_key(:new_cat)
  end
  
  it "should load all the recipes specified for this node" do
    @compile.load_node("compile")
    @compile.load_definitions
    lambda { @compile.load_recipes }.should_not raise_error
    puts @compile.resource_collection.inspect
    
    @compile.resource_collection[0].to_s.should == "cat[loulou]"
    @compile.resource_collection[1].to_s.should == "cat[birthday]"
    @compile.resource_collection[2].to_s.should == "cat[peanut]"
    @compile.resource_collection[3].to_s.should == "cat[fat peanut]"
  end

end