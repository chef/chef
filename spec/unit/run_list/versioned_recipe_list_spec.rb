#
# Author:: Stephen Delano (<stephen@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

require 'spec_helper'

describe Chef::RunList::VersionedRecipeList do

  describe "initialize" do
    it "should create an empty array" do
      l = Chef::RunList::VersionedRecipeList.new
      l.should == []
    end
  end

  describe "add_recipe" do
    before(:each) do
      @list = Chef::RunList::VersionedRecipeList.new
      @list << "apt"
      @list << "god"
      @list << "apache2"
    end

    it "should append the recipe to the end of the list" do
      @list.add_recipe "rails"
      @list.should == ["apt", "god", "apache2", "rails"]
    end

    it "should not duplicate entries" do
      @list.add_recipe "apt"
      @list.should == ["apt", "god", "apache2"]
    end

    it "should allow you to specify a version" do
      @list.add_recipe "rails", "1.0.0"
      @list.should == ["apt", "god", "apache2", "rails"]
      @list.with_versions.should include({:name => "rails", :version => "1.0.0"})
    end

    it "should allow you to specify a version for a recipe that already exists" do
      @list.add_recipe "apt", "1.2.3"
      @list.should == ["apt", "god", "apache2"]
      @list.with_versions.should include({:name => "apt", :version => "1.2.3"})
    end

    it "should allow you to specify the same version of a recipe twice" do
      @list.add_recipe "rails", "1.0.0"
      @list.add_recipe "rails", "1.0.0"
      @list.with_versions.should include({:name => "rails", :version => "1.0.0"})
    end

    it "should allow you to spcify no version, even when a version already exists" do
      @list.add_recipe "rails", "1.0.0"
      @list.add_recipe "rails"
      @list.with_versions.should include({:name => "rails", :version => "1.0.0"})
    end

    it "should not allow multiple versions of the same recipe" do
      @list.add_recipe "rails", "1.0.0"
      lambda {@list.add_recipe "rails", "0.1.0"}.should raise_error Chef::Exceptions::CookbookVersionConflict
    end
  end

  describe "with_versions" do
    before(:each) do
      @recipes = [
        {:name => "apt", :version => "1.0.0"},
        {:name => "god", :version => nil},
        {:name => "apache2", :version => "0.0.1"}
      ]
      @list = Chef::RunList::VersionedRecipeList.new
      @recipes.each {|i| @list.add_recipe i[:name], i[:version]}
    end

    it "should return an array of hashes with :name and :version" do
      @list.with_versions.should == @recipes
    end

    it "should retain the same order as the version-less list" do
      with_versions = @list.with_versions
      @list.each_with_index do |item, index|
        with_versions[index][:name].should == item
      end
    end
  end

  describe "with_version_constraints" do
    before(:each) do
      @recipes = [
                  {:name => "apt", :version => "~> 1.2.0"},
                  {:name => "god", :version => nil},
                  {:name => "apache2", :version => "0.0.1"}
                 ]
      @list = Chef::RunList::VersionedRecipeList.new
      @recipes.each {|i| @list.add_recipe i[:name], i[:version]}
      @constraints = @recipes.map do |x|
        { :name => x[:name],
          :version_constraint => Chef::VersionConstraint.new(x[:version])
        }
      end
    end

    it "should return an array of hashes with :name and :version_constraint" do
      @list.with_version_constraints.each do |x|
        x.should have_key :name
        x[:version_constraint].should_not be nil
      end
    end
  end
end
