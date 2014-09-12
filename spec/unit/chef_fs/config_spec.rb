#
# Author:: Jess Mink (<jmink@getchef.com>)
# Copyright:: Copyright (c) 2014 Opscode, Inc.
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

require 'spec_helper'
require 'chef/exceptions'
require 'lib/chef/chef_fs/config.rb'

describe Chef::ChefFS::Config do
  describe "initialize" do
    it "warns when hosted setups use 'everything'" do
      base_config = Hash.new()
      base_config[:repo_mode] = 'everything'
      base_config[:chef_server_url] = 'http://foo.com/organizations/fake_org/'

      ui = double("ui")
      expect(ui).to receive(:warn)

      Chef::ChefFS::Config.new(base_config, Dir.pwd, {}, ui)
    end

    it "doesn't warn when hosted setups use 'hosted_everything'" do
      base_config = Hash.new()
      base_config[:repo_mode] = 'hosted_everything'
      base_config[:chef_server_url] = 'http://foo.com/organizations/fake_org/'

      ui = double("ui")
      expect(ui).to receive(:warn).exactly(0).times

      Chef::ChefFS::Config.new(base_config, Dir.pwd, {}, ui)
    end

    it "doesn't warn when non-hosted setups use 'everything'" do
      base_config = Hash.new()
      base_config[:repo_mode] = 'everything'
      base_config[:chef_server_url] = 'http://foo.com/'

      ui = double("ui")
      expect(ui).to receive(:warn).exactly(0).times

      Chef::ChefFS::Config.new(base_config, Dir.pwd, {}, ui)
    end
  end
end
