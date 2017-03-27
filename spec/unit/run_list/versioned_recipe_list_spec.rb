#
# Author:: Stephen Delano (<stephen@chef.io>)
# Copyright:: Copyright 2010-2017, Chef Software Inc.
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

require "spec_helper"

describe Chef::RunList::VersionedRecipeList do

  describe "initialize" do
    it "should create an empty array" do
      l = Chef::RunList::VersionedRecipeList.new
      expect(l).to eq([])
    end
  end

  let(:list) { described_class.new }

  let(:versioned_recipes) { [] }

  let(:recipes) { [] }

  before do
    recipes.each { |r| list << r }
    versioned_recipes.each { |r| list.add_recipe r[:name], r[:version] }
  end

  describe "add_recipe" do

    let(:recipes) { %w{ apt god apache2 } }

    it "should append the recipe to the end of the list" do
      list.add_recipe "rails"
      expect(list).to eq(%w{apt god apache2 rails})
    end

    it "should not duplicate entries" do
      list.add_recipe "apt"
      expect(list).to eq(%w{apt god apache2})
    end

    it "should allow you to specify a version" do
      list.add_recipe "rails", "1.0.0"
      expect(list).to eq(%w{apt god apache2 rails})
      expect(list.with_versions).to include({ :name => "rails", :version => "1.0.0" })
    end

    it "should allow you to specify a version for a recipe that already exists" do
      list.add_recipe "apt", "1.2.3"
      expect(list).to eq(%w{apt god apache2})
      expect(list.with_versions).to include({ :name => "apt", :version => "1.2.3" })
    end

    it "should allow you to specify the same version of a recipe twice" do
      list.add_recipe "rails", "1.0.0"
      list.add_recipe "rails", "1.0.0"
      expect(list.with_versions).to include({ :name => "rails", :version => "1.0.0" })
    end

    it "should allow you to spcify no version, even when a version already exists" do
      list.add_recipe "rails", "1.0.0"
      list.add_recipe "rails"
      expect(list.with_versions).to include({ :name => "rails", :version => "1.0.0" })
    end

    it "should not allow multiple versions of the same recipe" do
      list.add_recipe "rails", "1.0.0"
      expect { list.add_recipe "rails", "0.1.0" }.to raise_error Chef::Exceptions::CookbookVersionConflict
    end
  end

  describe "with_versions" do

    let(:versioned_recipes) do
      [
        { :name => "apt", :version => "1.0.0" },
        { :name => "god", :version => nil },
        { :name => "apache2", :version => "0.0.1" },
      ]
    end
    it "should return an array of hashes with :name and :version" do
      expect(list.with_versions).to eq(versioned_recipes)
    end

    it "should retain the same order as the version-less list" do
      with_versions = list.with_versions
      list.each_with_index do |item, index|
        expect(with_versions[index][:name]).to eq(item)
      end
    end
  end

  describe "with_version_constraints" do

    let(:versioned_recipes) do
      [
        { :name => "apt", :version => "~> 1.2.0" },
        { :name => "god", :version => nil },
        { :name => "apache2", :version => "0.0.1" },
      ]
    end

    it "should return an array of hashes with :name and :version_constraint" do
      list.with_version_constraints.each_with_index do |recipe_spec, i|

        expected_recipe = versioned_recipes[i]

        expect(recipe_spec[:name]).to eq(expected_recipe[:name])
        expect(recipe_spec[:version_constraint]).to eq(Chef::VersionConstraint.new(expected_recipe[:version]))
      end
    end
  end

  describe "with_fully_qualified_names_and_version_constraints" do

    let(:fq_names) { list.with_fully_qualified_names_and_version_constraints }

    context "with bare cookbook names" do

      let(:recipes) { %w{ apache2 } }

      it "gives $cookbook_name::default" do
        expect(fq_names).to eq( %w{ apache2::default } )
      end

    end

    context "with qualified recipe names but no versions" do

      let(:recipes) { %w{ mysql::server } }

      it "returns the qualified recipe names" do
        expect(fq_names).to eq( %w{ mysql::server } )
      end

    end

    context "with unqualified names that have version constraints" do

      let(:versioned_recipes) do
        [
          { :name => "apt", :version => "~> 1.2.0" },
        ]
      end

      it "gives qualified names with their versions" do
        expect(fq_names).to eq([ "apt::default@~> 1.2.0" ])
      end

      it "does not mutate the recipe name" do
        expect(fq_names).to eq([ "apt::default@~> 1.2.0" ])
        expect(list).to eq( [ "apt" ] )
      end

    end

    context "with fully qualified names that have version constraints" do

      let(:versioned_recipes) do
        [
          { :name => "apt::cacher", :version => "~> 1.2.0" },
        ]
      end

      it "gives qualified names with their versions" do
        expect(fq_names).to eq([ "apt::cacher@~> 1.2.0" ])
      end

      it "does not mutate the recipe name" do
        expect(fq_names).to eq([ "apt::cacher@~> 1.2.0" ])
        expect(list).to eq( [ "apt::cacher" ] )
      end

    end
  end

  context "with duplicate names" do
    let(:fq_names) { list.with_duplicate_names }
    let(:recipes) { %w{ foo bar::default } }

    it "expands default recipes" do
      expect(fq_names).to eq(%w{foo foo::default bar bar::default})
    end
  end
end
