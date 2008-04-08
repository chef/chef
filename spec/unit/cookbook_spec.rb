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

describe Chef::Cookbook do
  COOKBOOK_PATH = File.join(File.dirname(__FILE__), "..", "data", "cookbooks", "openldap")
  
  before(:each) do
    @cookbook = Chef::Cookbook.new("openldap")
  end
  
  it "should be a Chef::Cookbook object" do
    @cookbook.should be_kind_of(Chef::Cookbook)
  end
  
  it "should have a name" do
    @cookbook.name.should eql("openldap")
  end
  
  it "should have a list of attribute files" do
    @cookbook.attribute_files.should be_kind_of(Array)
  end
  
  it "should allow you to set the list of attribute files" do
    @cookbook.attribute_files = [ "one", "two" ]
    @cookbook.attribute_files.should eql(["one", "two"])
  end
  
  it "should allow you to load all the attributes" do
    node = Chef::Node.new
    node.name "Julia Child"
    node.chef_env false
    @cookbook.attribute_files = Dir[File.join(COOKBOOK_PATH, "attributes", "**", "*.rb")]
    node = @cookbook.load_attributes(node)
    node.ldap_server.should eql("ops1prod")
    node.ldap_basedn.should eql("dc=hjksolutions,dc=com")
    node.ldap_replication_password.should eql("forsure")
    node.smokey.should eql("robinson")
  end
  
  it "should raise an ArgumentError if you don't pass a node object to load_attributes" do
    lambda { @cookbook.load_attributes("snake oil") }.should raise_error(ArgumentError)    
  end
  
  it "should have a list of definition files" do
    @cookbook.definition_files.should be_a_kind_of(Array)
  end
  
  it "should allow you to set the list of definition files" do
    @cookbook.definition_files = [ "one", "two" ]
    @cookbook.definition_files.should eql(["one", "two"])
  end
  
  it "should allow you to load all the definitions, returning a hash of ResourceDefinitions by name" do
    @cookbook.definition_files = Dir[File.join(COOKBOOK_PATH, "definitions", "**", "*.rb")]
    defs = @cookbook.load_definitions
    defs.has_key?(:openldap_server).should eql(true)
    defs[:openldap_server].should be_a_kind_of(Chef::ResourceDefinition)
    defs.has_key?(:openldap_client).should eql(true)
    defs[:openldap_client].should be_a_kind_of(Chef::ResourceDefinition)
  end
  
  it "should have a list of recipe files" do
    @cookbook.recipe_files.should be_a_kind_of(Array)
  end
  
  it "should allow you to set the list of recipe files" do
    @cookbook.recipe_files = [ "one", "two" ]
    @cookbook.recipe_files.should eql(["one", "two"])
  end

  it "should have a list of recipes by name" do
    @cookbook.recipe_files = [ "one", "two" ]
    @cookbook.recipes.detect { |r| r == "openldap::one" }.should eql("openldap::one")
    @cookbook.recipes.detect { |r| r == "openldap::two" }.should eql("openldap::two")
  end
  
  it "should take a file /path.rb, and use the filename minus rb as a recipe name" do
    @cookbook.recipe_files = [ "/something/one.rb", "/otherthing/two.rb" ]
    @cookbook.recipes.detect { |r| r == "openldap::one" }.should eql("openldap::one")
    @cookbook.recipes.detect { |r| r == "openldap::two" }.should eql("openldap::two")
  end
  
  it "should take a file path.rb, and use the filename minus rb as a recipe name" do
    @cookbook.recipe_files = [ "one.rb", "two.rb" ]
    @cookbook.recipes.detect { |r| r == "openldap::one" }.should eql("openldap::one")
    @cookbook.recipes.detect { |r| r == "openldap::two" }.should eql("openldap::two")
  end
  
  it "should allow you to test for a recipe with recipe?" do
    @cookbook.recipe_files = [ "one", "two" ]
    @cookbook.recipe?("one").should eql(true)
    @cookbook.recipe?("shanghai").should eql(false)
  end
  
  it "should allow you to test for a recipe? with a fq recipe name" do
    @cookbook.recipe_files = [ "one", "two" ]
    @cookbook.recipe?("openldap::one").should eql(true)
    @cookbook.recipe?("shanghai::city").should eql(false)
  end
  
  it "should allow you to run a recipe by name via load_recipe" do
    @cookbook.recipe_files = Dir[File.join(COOKBOOK_PATH, "recipes", "**", "*.rb")]
    node = Chef::Node.new
    node.name "Julia Child"
    recipe = @cookbook.load_recipe("openldap::gigantor", node)
    recipe.recipe_name.should eql("gigantor")
    recipe.cookbook_name.should eql("openldap")
    recipe.collection[0].name.should eql("blanket")
  end
  
  it "should raise an ArgumentException if you try to load a bad recipe name" do
    node = Chef::Node.new
    node.name "Julia Child"
    lambda { @cookbook.load_recipe("smackdown", node) }.should raise_error(ArgumentError)
  end
  
  it "should load the attributes if it has not already when a recipe is loaded" do
    @cookbook.attribute_files = Dir[File.join(COOKBOOK_PATH, "attributes", "smokey.rb")]
    @cookbook.recipe_files = Dir[File.join(COOKBOOK_PATH, "recipes", "**", "*.rb")]
    node = Chef::Node.new
    node.name "Julia Child"
    recipe = @cookbook.load_recipe("openldap::gigantor", node)
    node.smokey.should == "robinson"
  end
end