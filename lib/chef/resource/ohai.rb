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

class Chef
  class Resource
    class Ohai < Chef::Resource
      unified_mode true

      provides :ohai

      description "Use the **ohai** resource to reload the Ohai configuration on a node. This allows recipes that change system attributes (like a recipe that adds a user) to refer to those attributes later on during the #{ChefUtils::Dist::Infra::CLIENT} run."

      property :plugin, String,
        description: "The name of an Ohai plugin to be reloaded. If this property is not specified, #{ChefUtils::Dist::Infra::PRODUCT} will reload all plugins."

      def load_current_resource
        true
      end

      action :reload do
        converge_by("re-run ohai and merge results into node attributes") do
          ohai = ::Ohai::System.new

          # If new_resource.plugin is nil, ohai will reload all the plugins
          # Otherwise it will only reload the specified plugin
          # Note that any changes to plugins, or new plugins placed on
          # the path are picked up by ohai.
          ohai.all_plugins new_resource.plugin
          node.automatic_attrs.merge! ohai.data
          logger.info("#{new_resource} reloaded")
        end
      end
    end
  end
end
