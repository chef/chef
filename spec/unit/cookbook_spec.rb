#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

require "spec_helper"

describe Chef::CookbookVersion do
  COOKBOOK_PATH = File.expand_path(File.join(File.dirname(__FILE__), "..", "data", "cookbooks", "openldap"))

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
    expect(@cookbook.name).to eq(:openldap)
  end

  it "should allow you to set the list of attribute files and create the mapping from short names to paths" do
    expect(@cookbook.attribute_filenames_by_short_filename.keys.sort).to eql(%w{default smokey})
    expect(@cookbook.attribute_filenames_by_short_filename["default"]).to eq(File.join(COOKBOOK_PATH, "attributes/default.rb"))
    expect(@cookbook.attribute_filenames_by_short_filename["smokey"]).to eq(File.join(COOKBOOK_PATH, "attributes/smokey.rb"))
  end

  it "should allow you to set the list of recipe files and create the mapping of recipe short name to filename" do
    expect(@cookbook.recipe_filenames_by_name.keys.sort).to eql(%w{default gigantor one return})
    expect(@cookbook.recipe_filenames_by_name["one"]).to eq(File.join(COOKBOOK_PATH, "recipes/one.rb"))
    expect(@cookbook.recipe_filenames_by_name["gigantor"]).to eq(File.join(COOKBOOK_PATH, "recipes/gigantor.rb"))
  end

  it "should generate a list of recipes by fully-qualified name" do
    expect(@cookbook.fully_qualified_recipe_names.include?("openldap::one")).to eq(true)
    expect(@cookbook.fully_qualified_recipe_names.include?("openldap::gigantor")).to eq(true)
    expect(@cookbook.fully_qualified_recipe_names.include?("openldap::return")).to eq(true)
  end

  it "should raise an ArgumentException if you try to load a bad recipe name" do
    expect { @cookbook.load_recipe("doesnt_exist", @node) }.to raise_error(ArgumentError)
  end

end
