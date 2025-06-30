#
# Author:: Michael Leinartas (<mleinartas@gmail.com>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2010-2016, Michael Leinartas
# Copyright:: Copyright (c) Chef Software, Inc.
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
require_relative "../extensions/ohai_plugin_loader"

class Chef
  class Resource
    class Ohai < Chef::Resource

      provides :ohai

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

      property :ignore_failure, [TrueClass, FalseClass],
        description: "Continue running a recipe if a resource fails.",
        default: false,
        default_description: "false (a resource failure will halt the Chef run)"

      def load_current_resource
        true
      end

      action :reload do
        converge_by("re-run ohai to reload plugin data") do
          begin
            if new_resource.plugin
              # Reload only the specified plugin using our enhanced loader that handles errors
              logger.info("Reloading Ohai plugin: #{new_resource.plugin}")
              ohai = Chef::Extensions::OhaiPluginLoader.safe_reload_plugin(new_resource.plugin, node)
            else
              # Reload all plugins
              logger.info("Reloading all Ohai plugins")
              ohai = Chef::Extensions::OhaiPluginLoader.force_load_all_plugins
              node.automatic_attrs.merge!(ohai.data)
            end
            
            logger.info("#{new_resource} reloaded")
          rescue => e
            if new_resource.ignore_failure
              logger.error("Failed to reload Ohai plugin: #{e.class}: #{e.message}")
              logger.error("Ignoring failure and continuing.")
            else
              raise
            end
          end
        end
      end
    end
  end
end
