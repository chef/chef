#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2010-2016, Chef Software Inc.
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

describe Chef::RunList::RunListItem do

  describe "when creating from a Hash" do
    it "raises an exception when the hash doesn't have a :type key" do
      expect { Chef::RunList::RunListItem.new(name: "tatft") }.to raise_error(ArgumentError)
    end

    it "raises an exception when the hash doesn't have an :name key" do
      expect { Chef::RunList::RunListItem.new(type: "R") }.to raise_error(ArgumentError)
    end

    it "sets the name and type as given in the hash" do
      item = Chef::RunList::RunListItem.new(type: "fuuu", name: "uuuu")
      expect(item.to_s).to eq("fuuu[uuuu]")
    end

  end

  describe "when creating an item from a string" do
    it "parses a qualified recipe" do
      item = Chef::RunList::RunListItem.new("recipe[rage]")
      expect(item).to be_a_recipe
      expect(item).not_to be_a_role
      expect(item.to_s).to eq("recipe[rage]")
      expect(item.name).to eq("rage")
    end

    it "parses a qualified recipe with a version" do
      item = Chef::RunList::RunListItem.new("recipe[rage@0.1.0]")
      expect(item).to be_a_recipe
      expect(item).not_to be_a_role
      expect(item.to_s).to eq("recipe[rage@0.1.0]")
      expect(item.name).to eq("rage")
      expect(item.version).to eq("0.1.0")
    end

    it "parses a qualified role" do
      item = Chef::RunList::RunListItem.new("role[fist]")
      expect(item).to be_a_role
      expect(item).not_to be_a_recipe
      expect(item.to_s).to eq("role[fist]")
      expect(item.name).to eq("fist")
    end

    it "parses an unqualified recipe" do
      item = Chef::RunList::RunListItem.new("lobster")
      expect(item).to be_a_recipe
      expect(item).not_to be_a_role
      expect(item.to_s).to eq("recipe[lobster]")
      expect(item.name).to eq("lobster")
    end

    it "raises an exception when the string has typo on the type part" do
      expect { Chef::RunList::RunListItem.new("Recipe[lobster]") }.to raise_error(ArgumentError)
    end

    it "raises an exception when the string has extra space between the type and the name" do
      expect { Chef::RunList::RunListItem.new("recipe [lobster]") }.to raise_error(ArgumentError)
    end

    it "raises an exception when the string does not close the bracket" do
      expect { Chef::RunList::RunListItem.new("recipe[lobster") }.to raise_error(ArgumentError)
    end
  end

  describe "comparing to other run list items" do
    it "is equal to another run list item that has the same name and type" do
      item1 = Chef::RunList::RunListItem.new("recipe[lrf]")
      item2 = Chef::RunList::RunListItem.new("recipe[lrf]")
      expect(item1).to eq(item2)
    end

    it "is not equal to another run list item with the same name and different type" do
      item1 = Chef::RunList::RunListItem.new("recipe[lrf]")
      item2 = Chef::RunList::RunListItem.new("role[lrf]")
      expect(item1).not_to eq(item2)
    end

    it "is not equal to another run list item with the same type and different name" do
      item1 = Chef::RunList::RunListItem.new("recipe[lrf]")
      item2 = Chef::RunList::RunListItem.new("recipe[lobsterragefist]")
      expect(item1).not_to eq(item2)
    end

    it "is not equal to another run list item with the same name and type but different version" do
      item1 = Chef::RunList::RunListItem.new("recipe[lrf,0.1.0]")
      item2 = Chef::RunList::RunListItem.new("recipe[lrf,0.2.0]")
      expect(item1).not_to eq(item2)
    end
  end

  describe "comparing to strings" do
    it "is equal to a string if that string matches its to_s representation" do
      expect(Chef::RunList::RunListItem.new("recipe[lrf]")).to eq("recipe[lrf]")
    end
  end
end
