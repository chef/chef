#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'spec_helper'

describe Chef::CookbookVersion do
#  COOKBOOK_PATH = File.expand_path(File.join(File.dirname(__FILE__), "..", "data", "cookbooks", "openldap"))
  before(:each) do
    @cookbook_repo = File.expand_path(File.join(File.dirname(__FILE__), "..", "data", "cookbooks"))
    cl = Chef::CookbookLoader.new(@cookbook_repo)
    cl.load_cookbooks
    @cookbook_collection = Chef::CookbookCollection.new(cl)
    @cookbook = @cookbook_collection[:openldap]
    @node = Chef::Node.new
    @node.name "JuliaChild"
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, @cookbook_collection, @events)
  end

  it "should have a name" do
    @cookbook.name.should == :openldap
  end

  it "should allow you to set the list of attribute files and create the mapping from short names to paths" do
    @cookbook.attribute_filenames = [ "attributes/one.rb", "attributes/two.rb" ]
    @cookbook.attribute_filenames.should == [ "attributes/one.rb", "attributes/two.rb" ]
    @cookbook.attribute_filenames_by_short_filename.keys.sort.should eql(["one", "two"])
    @cookbook.attribute_filenames_by_short_filename["one"].should == "attributes/one.rb"
    @cookbook.attribute_filenames_by_short_filename["two"].should == "attributes/two.rb"
  end

  it "should allow you to set the list of recipe files and create the mapping of recipe short name to filename" do
    @cookbook.recipe_filenames = [ "recipes/one.rb", "recipes/two.rb" ]
    @cookbook.recipe_filenames.should == [ "recipes/one.rb", "recipes/two.rb" ]
    @cookbook.recipe_filenames_by_name.keys.sort.should eql(["one", "two"])
    @cookbook.recipe_filenames_by_name["one"].should == "recipes/one.rb"
    @cookbook.recipe_filenames_by_name["two"].should == "recipes/two.rb"
  end

  it "should generate a list of recipes by fully-qualified name" do
    @cookbook.recipe_filenames = [ "recipes/one.rb", "/recipes/two.rb", "three.rb" ]
    @cookbook.fully_qualified_recipe_names.include?("openldap::one").should == true
    @cookbook.fully_qualified_recipe_names.include?("openldap::two").should == true
    @cookbook.fully_qualified_recipe_names.include?("openldap::three").should == true
  end

  it "should find a preferred file" do
    pending
  end

  it "should not return an unchanged preferred file" do
    pending
    @cookbook.preferred_filename(@node, :files, 'a-filename', 'the-checksum').should be_nil
  end

  it "should allow you to include a fully-qualified recipe using the DSL" do
    # DSL method include_recipe allows multiple arguments, so extract the first
    recipe = @run_context.include_recipe("openldap::gigantor").first

    recipe.recipe_name.should == "gigantor"
    recipe.cookbook_name.should == :openldap
    @run_context.resource_collection[0].name.should == "blanket"
  end

  it "should raise an ArgumentException if you try to load a bad recipe name" do
    lambda { @cookbook.load_recipe("doesnt_exist", @node) }.should raise_error(ArgumentError)
  end

end
