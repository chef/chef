#
# Author:: Kartik Null Cating-Subramanian (<ksubramanian@chef.io>)
# Copyright:: Copyright 2015-2016, Chef Software Inc.
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
require "chef/chef_fs/path_utils"

describe Chef::ChefFS::PathUtils do
  context "invoking join" do
    it "joins well-behaved distinct path elements" do
      expect(Chef::ChefFS::PathUtils.join("a", "b", "c")).to eq("a/b/c")
    end

    it "strips extraneous slashes in the middle of paths" do
      expect(Chef::ChefFS::PathUtils.join("a/", "/b", "/c/")).to eq("a/b/c")
      expect(Chef::ChefFS::PathUtils.join("a/", "/b", "///c/")).to eq("a/b/c")
    end

    it "preserves the whether the first element was absolute or not" do
      expect(Chef::ChefFS::PathUtils.join("/a/", "/b", "c/")).to eq("/a/b/c")
      expect(Chef::ChefFS::PathUtils.join("///a/", "/b", "c/")).to eq("/a/b/c")
    end
  end

  context "invoking is_absolute?" do
    it "confirms that paths starting with / are absolute" do
      expect(Chef::ChefFS::PathUtils.is_absolute?("/foo/bar/baz")).to be true
      expect(Chef::ChefFS::PathUtils.is_absolute?("/foo")).to be true
    end

    it "confirms that paths starting with // are absolute even though that looks like some windows network path" do
      expect(Chef::ChefFS::PathUtils.is_absolute?("//foo/bar/baz")).to be true
    end

    it "confirms that root is indeed absolute" do
      expect(Chef::ChefFS::PathUtils.is_absolute?("/")).to be true
    end

    it "confirms that paths starting without / are relative" do
      expect(Chef::ChefFS::PathUtils.is_absolute?("foo/bar/baz")).to be false
      expect(Chef::ChefFS::PathUtils.is_absolute?("a")).to be false
    end

    it "returns false for an empty path." do
      expect(Chef::ChefFS::PathUtils.is_absolute?("")).to be false
    end
  end

  context "invoking realest_path" do
    let(:good_path) { File.dirname(__FILE__) }
    let(:parent_path) { File.dirname(good_path) }

    it "handles paths with no wildcards or globs" do
      expect(Chef::ChefFS::PathUtils.realest_path(good_path)).to eq(File.expand_path(good_path))
    end

    it "handles paths with .. and ." do
      expect(Chef::ChefFS::PathUtils.realest_path(good_path + "/../.")).to eq(File.expand_path(parent_path))
    end

    it "handles paths with *" do
      expect(Chef::ChefFS::PathUtils.realest_path(good_path + "/*/foo")).to eq(File.expand_path(good_path + "/*/foo"))
    end

    it "handles directories that do not exist" do
      expect(Chef::ChefFS::PathUtils.realest_path(good_path + "/something/or/other")).to eq(File.expand_path(good_path + "/something/or/other"))
    end

    it "handles root correctly" do
      if Chef::Platform.windows?
        expect(Chef::ChefFS::PathUtils.realest_path("C:/")).to eq("C:/")
      else
        expect(Chef::ChefFS::PathUtils.realest_path("/")).to eq("/")
      end
    end
  end

  context "invoking descendant_path" do
    it "handles paths with various casing on windows" do
      allow(Chef::ChefFS).to receive(:windows?) { true }
      expect(Chef::ChefFS::PathUtils.descendant_path("C:/ab/b/c", "C:/AB/B")).to eq("c")
      expect(Chef::ChefFS::PathUtils.descendant_path("C:/ab/b/c", "c:/ab/B")).to eq("c")
    end

    it "returns nil if the path does not have the given ancestor" do
      expect(Chef::ChefFS::PathUtils.descendant_path("/D/E/F", "/A/B/C")).to be_nil
      expect(Chef::ChefFS::PathUtils.descendant_path("/A/B/D", "/A/B/C")).to be_nil
    end

    it "returns blank if the ancestor equals the path" do
      expect(Chef::ChefFS::PathUtils.descendant_path("/A/B/D", "/A/B/D")).to eq("")
    end
  end
end
