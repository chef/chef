#
# Author:: Jess Mink (<jmink@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software Inc.
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
require "chef/exceptions"
require "lib/chef/chef_fs/config.rb"

describe Chef::ChefFS::Config do
  describe "initialize" do
    it "warns when hosted setups use 'everything'" do
      base_config = Hash.new()
      base_config[:repo_mode] = "everything"
      base_config[:chef_server_url] = "http://foo.com/organizations/fake_org/"

      ui = double("ui")
      expect(ui).to receive(:warn)

      Chef::ChefFS::Config.new(base_config, Dir.pwd, {}, ui)
    end

    it "doesn't warn when hosted setups use 'hosted_everything'" do
      base_config = Hash.new()
      base_config[:repo_mode] = "hosted_everything"
      base_config[:chef_server_url] = "http://foo.com/organizations/fake_org/"

      ui = double("ui")
      expect(ui).to receive(:warn).exactly(0).times

      Chef::ChefFS::Config.new(base_config, Dir.pwd, {}, ui)
    end

    it "doesn't warn when non-hosted setups use 'everything'" do
      base_config = Hash.new()
      base_config[:repo_mode] = "everything"
      base_config[:chef_server_url] = "http://foo.com/"

      ui = double("ui")
      expect(ui).to receive(:warn).exactly(0).times

      Chef::ChefFS::Config.new(base_config, Dir.pwd, {}, ui)
    end
  end

  describe "local FS configuration" do

    let(:chef_config) do
      Mash.new({
        client_path: "/base_path/clients",
        cookbook_path: "/base_path/cookbooks",
        data_bag_path: "/base_path/data_bags",
        environment_path: "/base_path/environments",
        node_path: "/base_path/nodes",
        role_path: "/base_path/roles",
        user_path: "/base_path/users",
        policy_path: "/base_path/policies",
      })
    end

    let(:chef_fs_config) { Chef::ChefFS::Config.new(chef_config, Dir.pwd) }

    subject(:local_fs) { chef_fs_config.local_fs }

    def platform_path(*args)
      File.expand_path(*args)
    end

    it "sets the correct nodes path on the local FS object" do
      expect(local_fs.child_paths["nodes"]).to eq([platform_path("/base_path/nodes")])
    end

    it "sets the correct cookbook path on the local FS object" do
      expect(local_fs.child_paths["cookbooks"]).to eq([platform_path("/base_path/cookbooks")])
    end

    it "sets the correct data bag path on the local FS object" do
      expect(local_fs.child_paths["data_bags"]).to eq([platform_path("/base_path/data_bags")])
    end

    it "sets the correct environment path on the local FS object" do
      expect(local_fs.child_paths["environments"]).to eq([platform_path("/base_path/environments")])
    end

    it "sets the correct role path on the local FS object" do
      expect(local_fs.child_paths["roles"]).to eq([platform_path("/base_path/roles")])
    end

    it "sets the correct user path on the local FS object" do
      expect(local_fs.child_paths["users"]).to eq([platform_path("/base_path/users")])
    end
  end

  describe "formats paths", :unix_only do

    let(:single_repo_path) do
      Mash.new({
        chef_repo_path: "/base_path",
      })
    end

    let(:double_repo_path) do
      Mash.new({
        chef_repo_path: %w{ /base_path /second_base_path },
      })
    end

    describe "#server_path" do
      it "returns nil if no paths match" do
        cfg = Chef::ChefFS::Config.new(single_repo_path, "/my_repo/cookbooks")
        expect(cfg.server_path("foo")).to be_nil
      end

      context "with only repo paths" do
        it "returns / if in the repo path" do
          cwd = "/base_path/cookbooks"
          cfg = Chef::ChefFS::Config.new(single_repo_path, cwd)
          expect(Chef::ChefFS::PathUtils).to receive(:realest_path).with("/base_path/cookbooks", cwd).and_return("/base_path/cookbooks")
          expect(Chef::ChefFS::PathUtils).to receive(:realest_path).with("/base_path", cwd).and_return("/base_path/cookbooks")
          expect(cfg.server_path("/base_path/cookbooks")).to eq("/")
        end

        it "checks all the repo paths" do
          cwd = "/second_base_path/cookbooks"
          cfg = Chef::ChefFS::Config.new(double_repo_path, cwd)
          expect(Chef::ChefFS::PathUtils).to receive(:realest_path).with("/second_base_path/cookbooks", cwd).and_return("/second_base_path/cookbooks")
          expect(Chef::ChefFS::PathUtils).to receive(:realest_path).with("/base_path", cwd).and_return("/base_path/cookbooks")
          expect(Chef::ChefFS::PathUtils).to receive(:realest_path).with("/second_base_path", cwd).and_return("/second_base_path/cookbooks")
          expect(cfg.server_path("/second_base_path/cookbooks")).to eq("/")
        end
      end

      context "with specific object locations" do
        let(:single_cookbook_path) do
          Mash.new({
            cookbook_path: "/base_path/cookbooks",
            role_path: "/base_path/roles",
          })
        end

        let(:cwd) { "/base_path/cookbooks" }
        let(:cfg) { Chef::ChefFS::Config.new(single_cookbook_path, cwd) }

        before do
          expect(Chef::ChefFS::PathUtils).to receive(:realest_path).with("/base_path/cookbooks", cwd).and_return("/base_path/cookbooks")
          allow(Chef::ChefFS::PathUtils).to receive(:realest_path).with("/base_path/roles", cwd).and_return("/base_path/roles")
        end

        it "resolves a relative path" do
          expect(Chef::ChefFS::PathUtils).to receive(:realest_path).with("blah", cwd).and_return("/base_path/cookbooks/blah")
          expect(cfg.server_path("blah")).to eql("/cookbooks/blah")
        end

        it "resolves a relative path in a parent directory" do
          expect(Chef::ChefFS::PathUtils).to receive(:realest_path).with("../roles/blah", cwd).and_return("/base_path/roles/blah")
          expect(Chef::ChefFS::PathUtils).to receive(:realest_path).with("/base_path/roles", cwd).and_return("/base_path/roles")
          expect(cfg.server_path("../roles/blah")).to eql("/roles/blah")
        end

        it "ignores a relative path that's outside the repository" do
          expect(Chef::ChefFS::PathUtils).to receive(:realest_path).with("../../readme.txt", cwd).and_return("/readme.txt")
          expect(cfg.server_path("../../readme.txt")).to be_nil
        end

        it "deals with splat paths" do
          expect(Chef::ChefFS::PathUtils).to receive(:realest_path).with("*/*ab*", cwd).and_return("/base_path/cookbooks/*/*ab*")
          expect(cfg.server_path("*/*ab*")).to eql("/cookbooks/*/*ab*")
        end

        it "resolves an absolute path" do
          expect(Chef::ChefFS::PathUtils).to receive(:realest_path).with("/base_path/cookbooks/blah", cwd).and_return("/base_path/cookbooks/blah")
          expect(cfg.server_path("/base_path/cookbooks/blah")).to eql("/cookbooks/blah")
        end

        it "deals with an absolute path with splats" do
          expect(Chef::ChefFS::PathUtils).to receive(:realest_path).with("/*/cookbooks/blah", cwd).and_return("/*/cookbooks/blah")
          expect(cfg.server_path("/*/cookbooks/blah")).to be_nil
        end
      end
    end

    describe "#format_path" do
      Entry = Struct.new(:path)

      let(:config) do
        Mash.new({
          chef_repo_path: "/base_path",
          cookbook_path: "/base_path/cookbooks",
          role_path: "/base_path/roles",
        })
      end

      let (:path) { "/roles/foo.json" }
      let (:entry) { Entry.new(path) }

      it "returns the entry's path if the cwd isn't in the config" do
        cfg = Chef::ChefFS::Config.new(config, "/my_repo/cookbooks")
        expect(cfg).to receive(:base_path).and_return(nil)
        expect(cfg.format_path(entry)).to eq(path)
      end

      it "returns . if the cwd is the same as the entry's path" do
        cfg = Chef::ChefFS::Config.new(config, "/base_path/roles/foo.json")
        expect(cfg).to receive(:base_path).and_return("/roles/foo.json").at_least(:once)
        expect(cfg.format_path(entry)).to eq(".")
      end

      it "returns a relative path if the cwd is in the repo" do
        cfg = Chef::ChefFS::Config.new(config, "/base_path/roles")
        expect(cfg).to receive(:base_path).and_return("/roles").at_least(:once)
        expect(cfg.format_path(entry)).to eq("foo.json")
      end

      it "returns a relative path if the cwd is at the root of repo" do
        cfg = Chef::ChefFS::Config.new(config, "/base_path")
        expect(cfg).to receive(:base_path).and_return("/").at_least(:once)
        expect(cfg.format_path(entry)).to eq("roles/foo.json")
      end

    end
  end
end
