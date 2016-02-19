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
end
