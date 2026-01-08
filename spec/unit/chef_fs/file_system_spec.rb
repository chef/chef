#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
require "chef/chef_fs/file_system/chef_server/cookbook_dir"

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

  # Need to add the test case for copy_to method - not able to do the implimentation with Dir.mktmpdir

  describe ".create_cookbook_status_file" do
    let(:chef_server_cookbook_dir) { double("Chef::ChefFS::FileSystem::ChefServer::CookbookDir") }
    let(:local_cookbook_dir) { double("LocalCookbookDir") }
    let(:status_file) { double("StatusFile") }
    let(:non_cookbook_dir) { double("RegularDir") }

    before do
      allow(Chef::ChefFS::FileSystem).to receive(:create_cookbook_status_file).and_call_original
    end

    context "when source is a CookbookDir" do
      before do
        allow(chef_server_cookbook_dir).to receive(:is_a?).with(Chef::ChefFS::FileSystem::ChefServer::CookbookDir).and_return(true)
        allow(local_cookbook_dir).to receive(:child).with("status.json").and_return(status_file)
      end

      it "does not create status.json file by default (skip_frozen_cookbook_status defaults to true)" do
        allow(chef_server_cookbook_dir).to receive(:cookbook_frozen?).and_return(true)
        expect(local_cookbook_dir).not_to receive(:child)
        expect(status_file).not_to receive(:write)

        Chef::ChefFS::FileSystem.send(:create_cookbook_status_file, chef_server_cookbook_dir, local_cookbook_dir, {}, nil)
      end

      it "does not create status.json file when skip_frozen_cookbook_status is true" do
        allow(chef_server_cookbook_dir).to receive(:cookbook_frozen?).and_return(true)
        expect(local_cookbook_dir).not_to receive(:child)
        expect(status_file).not_to receive(:write)

        Chef::ChefFS::FileSystem.send(:create_cookbook_status_file, chef_server_cookbook_dir, local_cookbook_dir, { skip_frozen_cookbook_status: true }, nil)
      end

      it "creates status.json file with frozen: true when skip_frozen_cookbook_status is false and cookbook is frozen" do
        allow(chef_server_cookbook_dir).to receive(:cookbook_frozen?).and_return(true)
        expect(status_file).to receive(:write).with('{"frozen":true}')

        Chef::ChefFS::FileSystem.send(:create_cookbook_status_file, chef_server_cookbook_dir, local_cookbook_dir, { skip_frozen_cookbook_status: false }, nil)
      end

      it "creates status.json file with frozen: false when skip_frozen_cookbook_status is false and cookbook is not frozen" do
        allow(chef_server_cookbook_dir).to receive(:cookbook_frozen?).and_return(false)
        expect(status_file).to receive(:write).with('{"frozen":false}')

        Chef::ChefFS::FileSystem.send(:create_cookbook_status_file, chef_server_cookbook_dir, local_cookbook_dir, { skip_frozen_cookbook_status: false }, nil)
      end
    end

    context "when source is not a CookbookDir" do
      before do
        allow(non_cookbook_dir).to receive(:is_a?).with(Chef::ChefFS::FileSystem::ChefServer::CookbookDir).and_return(false)
      end

      it "does not create status.json file when source is not a CookbookDir" do
        expect(local_cookbook_dir).not_to receive(:child)
        expect(status_file).not_to receive(:write)

        Chef::ChefFS::FileSystem.send(:create_cookbook_status_file, non_cookbook_dir, local_cookbook_dir, { skip_frozen_cookbook_status: false }, nil)
      end
    end

    context "when cookbook_frozen? returns nil" do
      before do
        allow(chef_server_cookbook_dir).to receive(:is_a?).with(Chef::ChefFS::FileSystem::ChefServer::CookbookDir).and_return(true)
        allow(chef_server_cookbook_dir).to receive(:cookbook_frozen?).and_return(nil)
        allow(local_cookbook_dir).to receive(:child).with("status.json").and_return(status_file)
      end

      it "creates status.json file with frozen: false when cookbook_frozen? returns nil and skip_frozen_cookbook_status is false" do
        expect(status_file).to receive(:write).with('{"frozen":false}')

        Chef::ChefFS::FileSystem.send(:create_cookbook_status_file, chef_server_cookbook_dir, local_cookbook_dir, { skip_frozen_cookbook_status: false }, nil)
      end
    end
  end
end
