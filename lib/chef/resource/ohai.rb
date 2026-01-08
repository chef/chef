#
# Author:: Michael Leinartas (<mleinartas@gmail.com>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2010-2016, Michael Leinartas
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

require_relative "../resource"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)
require "ohai" unless defined?(Ohai::System)

class Chef
  class Resource
    class Ohai < Chef::Resource

      provides :ohai, target_mode: true
      target_mode support: :full

      description "Use the **ohai** resource to reload the Ohai configuration on a node. This allows recipes that change system attributes (like a recipe that adds a user) to refer to those attributes later on during the #{ChefUtils::Dist::Infra::PRODUCT} run."

      examples <<~DOC
      Reload All Ohai Plugins

      ```ruby
      ohai 'reload' do
        action :reload
      end
      ```

      Reload A Single Ohai Plugin

      ```ruby
      ohai 'reload' do
        plugin 'ipaddress'
        action :reload
      end
      ```

      Reload Ohai after a new user is created

      ```ruby
      ohai 'reload_passwd' do
        action :nothing
        plugin 'etc'
      end

      user 'daemon_user' do
        home '/dev/null'
        shell '/sbin/nologin'
        system true
        notifies :reload, 'ohai[reload_passwd]', :immediately
      end

      ruby_block 'just an example' do
        block do
          # These variables will now have the new values
          puts node['etc']['passwd']['daemon_user']['uid']
          puts node['etc']['passwd']['daemon_user']['gid']
        end
      end
      ```
      DOC

      property :plugin, String,
        description: "Specific Ohai attribute data to reload. This property behaves similar to specifying attributes when running Ohai on the command line and takes the attribute that you wish to reload instead of the actual plugin name. For instance, you can pass `ipaddress` to reload `node['ipaddress']` even though that data comes from the `Network` plugin. If this property is not specified, #{ChefUtils::Dist::Infra::PRODUCT} will reload all plugins."

      def load_current_resource
        true
      end

      action :reload do
        converge_by("re-run ohai and merge results into node attributes") do
          ohai = ::Ohai::System.new

          # Load any custom plugins from cookbooks if they exist
          # This ensures that cookbook-provided Ohai plugins are available
          # when the resource reloads Ohai data
          ohai_plugin_path = Chef::Config[:ohai_segment_plugin_path]
          if ohai_plugin_path && Dir.exist?(ohai_plugin_path) && !Dir.empty?(ohai_plugin_path) && ohai.config[:plugin_path]
            # Configure Ohai to load plugins from the cookbook segment path
            ohai.config[:plugin_path] << ohai_plugin_path
            logger.trace("Added cookbook plugin path to ohai: #{ohai_plugin_path}")
          end

          # If new_resource.plugin is nil, ohai will reload all the plugins
          # Otherwise it will only reload the specified plugin
          # Note that any changes to plugins, or new plugins placed on
          # the path are picked up by ohai.
          ohai.all_plugins new_resource.plugin
          node.automatic_attrs.merge! ohai.data
          node.fix_automatic_attributes
          logger.info("#{new_resource} reloaded")
        end
      end
    end
  end
end
