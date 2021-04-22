#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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
require "chef/chef_fs/file_system"
require "chef/chef_fs/file_pattern"

describe Chef::ChefFS::FileSystem, ruby: ">= 3.0" do
  include FileSystemSupport

  context "with empty filesystem" do
    let(:fs) { memory_fs("", {}) }

    context "list" do
      it "/" do
        list_should_yield_paths(fs, "/", "/")
      end
      it "/a" do
        list_should_yield_paths(fs, "/a", "/a")
      end
      it "/a/b" do
        list_should_yield_paths(fs, "/a/b", "/a/b")
      end
      it "/*" do
        list_should_yield_paths(fs, "/*", "/")
      end
    end

    context "resolve_path" do
      it "/" do
        expect(Chef::ChefFS::FileSystem.resolve_path(fs, "/").path).to eq("/")
      end
      it "nonexistent /a" do
        expect(Chef::ChefFS::FileSystem.resolve_path(fs, "/a").path).to eq("/a")
      end
      it "nonexistent /a/b" do
        expect(Chef::ChefFS::FileSystem.resolve_path(fs, "/a/b").path).to eq("/a/b")
      end
    end
  end

  context "with a populated filesystem" do
    let(:fs) do
      memory_fs("", {
        a: {
          aa: {
            c: "",
            zz: "",
          },
          ab: {
            c: "",
          },
        },
        x: "",
        y: {},
      })
    end
    context "list" do
      it "/**" do
        list_should_yield_paths(fs, "/**", "/", "/a", "/x", "/y", "/a/aa", "/a/aa/c", "/a/aa/zz", "/a/ab", "/a/ab/c")
      end
      it "/" do
        list_should_yield_paths(fs, "/", "/")
      end
      it "/*" do
        list_should_yield_paths(fs, "/*", "/", "/a", "/x", "/y")
      end
      it "/*/*" do
        list_should_yield_paths(fs, "/*/*", "/a/aa", "/a/ab")
      end
      it "/*/*/*" do
        list_should_yield_paths(fs, "/*/*/*", "/a/aa/c", "/a/aa/zz", "/a/ab/c")
      end
      it "/*/*/?" do
        list_should_yield_paths(fs, "/*/*/?", "/a/aa/c", "/a/ab/c")
      end
      it "/a/*/c" do
        list_should_yield_paths(fs, "/a/*/c", "/a/aa/c", "/a/ab/c")
      end
      it "/**b/c" do
        list_should_yield_paths(fs, "/**b/c", "/a/ab/c")
      end
      it "/a/ab/c" do
        no_blocking_calls_allowed
        list_should_yield_paths(fs, "/a/ab/c", "/a/ab/c")
      end
      it "nonexistent /a/ab/blah" do
        no_blocking_calls_allowed
        list_should_yield_paths(fs, "/a/ab/blah", "/a/ab/blah")
      end
      it "nonexistent /a/ab/blah/bjork" do
        no_blocking_calls_allowed
        list_should_yield_paths(fs, "/a/ab/blah/bjork", "/a/ab/blah/bjork")
      end
    end

    context "resolve_path" do
      before(:each) do
        no_blocking_calls_allowed
      end
      it "resolves /" do
        expect(Chef::ChefFS::FileSystem.resolve_path(fs, "/").path).to eq("/")
      end
      it "resolves /x" do
        expect(Chef::ChefFS::FileSystem.resolve_path(fs, "/x").path).to eq("/x")
      end
      it "resolves /a" do
        expect(Chef::ChefFS::FileSystem.resolve_path(fs, "/a").path).to eq("/a")
      end
      it "resolves /a/aa" do
        expect(Chef::ChefFS::FileSystem.resolve_path(fs, "/a/aa").path).to eq("/a/aa")
      end
      it "resolves /a/aa/zz" do
        expect(Chef::ChefFS::FileSystem.resolve_path(fs, "/a/aa/zz").path).to eq("/a/aa/zz")
      end
      it "resolves nonexistent /q/x/w" do
        expect(Chef::ChefFS::FileSystem.resolve_path(fs, "/q/x/w").path).to eq("/q/x/w")
      end
    end

    context "empty?" do
      it "is not empty /" do
        expect(Chef::ChefFS::FileSystem.resolve_path(fs, "/").empty?).to be false
      end
      it "is empty /y" do
        expect(Chef::ChefFS::FileSystem.resolve_path(fs, "/y").empty?).to be true
      end
      it "is not a directory and can't be tested /x" do
        expect { Chef::ChefFS::FileSystem.resolve_path(fs, "/x").empty? }.to raise_error(NoMethodError)
      end
    end
  end
end
