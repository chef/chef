#
# Author:: John Keiser (<jkeiser@chef.io>)
# Author:: Ho-Sheng Hsiao (<hosh@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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

require "tmpdir"
require "fileutils"
require "chef/config"
require "chef/json_compat"
require "chef/server_api"
require "support/shared/integration/knife_support"
require "support/shared/integration/app_server_support"
require "chef_zero/rspec"
require "cheffish/rspec/chef_run_support"
require "spec_helper"

module Cheffish
  class BasicChefClient
    def_delegators :@run_context, :before_notifications
  end
end

module IntegrationSupport
  def self.included(includer_class)
    includer_class.extend(ChefZero::RSpec)
    includer_class.extend(Cheffish::RSpec::ChefRunSupport)
    includer_class.extend(ClassMethods)
  end

  module ClassMethods
    def with_versioned_cookbooks(&block)
      context("with versioned cookbooks") do
        include_context "with versioned cookbooks"
        module_eval(&block)
      end
    end
  end

  def api
    Chef::ServerAPI.new
  end

  def cb_metadata(name, version, extra_text = "")
    "name #{name.inspect}; version #{version.inspect}#{extra_text}"
  end

  def cwd(relative_path)
    @old_cwd = Dir.pwd
    Dir.chdir(path_to(relative_path))
  end

  # Versioned cookbooks

  RSpec.shared_context "with versioned cookbooks", :versioned_cookbooks => true do
    before(:each) { Chef::Config[:versioned_cookbooks] = true }
    after(:each)  { Chef::Config.delete(:versioned_cookbooks) }
  end

  RSpec.shared_context "without versioned cookbooks", :versioned_cookbooks => false do
    # Just make sure this goes back to default
    before(:each) { Chef::Config[:versioned_cookbooks] = false }
    after(:each)  { Chef::Config.delete(:versioned_cookbooks) }
  end

end
