#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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
require "chef/dsl/recipe"

RecipeDSLExampleClass = Struct.new(:cookbook_name, :recipe_name)
class RecipeDSLExampleClass
  include Chef::DSL::Recipe
end

FullRecipeDSLExampleClass = Struct.new(:cookbook_name, :recipe_name)
class FullRecipeDSLExampleClass
  include Chef::DSL::Recipe::FullDSL
end

RecipeDSLBaseAPI = Struct.new(:cookbook_name, :recipe_name)
class RecipeDSLExampleSubclass < RecipeDSLBaseAPI
  include Chef::DSL::Recipe
end

# TODO: most of DSL::Recipe's implementation is tested in Chef::Recipe's tests,
# move those to here.
describe Chef::DSL::Recipe do

  let(:cookbook_name) { "example_cb" }
  let(:recipe_name) { "example_recipe" }

  it "tracks when it is included via FullDSL" do
    expect(Chef::DSL::Recipe::FullDSL.descendants).to include(FullRecipeDSLExampleClass)
  end

  it "doesn't track what is included via only the recipe DSL" do
    expect(Chef::DSL::Recipe::FullDSL.descendants).not_to include(RecipeDSLExampleClass)
  end

  shared_examples_for "A Recipe DSL Implementation" do

    it "responds to cookbook_name" do
      expect(recipe.cookbook_name).to eq(cookbook_name)
    end

    it "responds to recipe_name" do
      expect(recipe.recipe_name).to eq(recipe_name)
    end

    it "responds to shell_out" do
      expect(recipe.respond_to?(:shell_out)).to be true
    end

    it "responds to shell_out" do
      expect(recipe.respond_to?(:shell_out!)).to be true
    end

    it "responds to shell_out" do
      expect(recipe.respond_to?(:shell_out_with_systems_locale)).to be true
    end
  end

  context "when included in a class that defines the required interface directly" do

    let(:recipe) { RecipeDSLExampleClass.new(cookbook_name, recipe_name) }

    include_examples "A Recipe DSL Implementation"

  end

  # This is the situation that occurs when the Recipe DSL gets mixed in to a
  # resource, for example.
  context "when included in a class that defines the required interface in a superclass" do

    let(:recipe) { RecipeDSLExampleSubclass.new(cookbook_name, recipe_name) }

    include_examples "A Recipe DSL Implementation"

  end

end
