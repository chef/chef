#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'chef/run_list'
class Chef
  class Knife
    module Core
      # Instances of BootstrapContext are the context objects (i.e., +self+) for
      # bootstrap templates. For backwards compatability, they +must+ set the
      # following instance variables:
      # * @config   - a hash of knife's config values
      # * @run_list - the run list for the node to boostrap
      # 
      class BootstrapContext

        def initialize(config, run_list, chef_config)
          @config       = config
          @run_list     = run_list
          @chef_config  = chef_config
        end

        def bootstrap_version_string
          if @config[:prerelease]
            "--prerelease"
          else
            version = knife_config[:bootstrap_version] || Chef::VERSION
            "--version #{version}"
          end
        end

        def bootstrap_environment
          @chef_config[:environment] || '_default'
        end

        def validation_key
          IO.read(@chef_config[:validation_key])
        end

        def config_content
          client_rb = <<-CONFIG
log_level        :info
log_location     STDOUT
chef_server_url  "#{@chef_config[:chef_server_url]}"
validation_client_name "#{@chef_config[:validation_client_name]}"
CONFIG
          if @config[:chef_node_name]
            client_rb << %Q{node_name "#{@config[:chef_node_name]}"\n}
          else
            client_rb << "# Using default node name (fqdn)\n"
          end
          client_rb
        end

        def start_chef
          "/usr/bin/chef-client -j /etc/chef/first-boot.json -E #{bootstrap_environment}"
        end

        def knife_config
          @chef_config.key?(:knife) ? @chef_config[:knife] : {}
        end

      end
    end
  end
end

