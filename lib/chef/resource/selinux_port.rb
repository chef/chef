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

require_relative "../resource"
require_relative "selinux/common_helpers"

class Chef
  class Resource
    class SelinuxPort < Chef::Resource
      unified_mode true

      provides :selinux_port, target_mode: true
      target_mode support: :full

      description "Use the **selinux_port** resource to assign a network port to a specific SELinux context. For example, running a web server on a non-standard port."
      introduced "18.0"
      examples <<~DOC
      **Allow nginx/apache to bind to port 5678 by giving it the http_port_t context**:

      ```ruby
      selinux_port '5678' do
       protocol 'tcp'
       secontext 'http_port_t'
      end
      ```
      DOC

      property :port, [Integer, String],
                name_property: true,
                regex: /^\d+$/,
                description: "Port to modify."

      property :protocol, String,
                equal_to: %w{tcp udp},
                required: %i{manage add modify},
                description: "Protocol to modify."

      property :secontext, String,
                required: %i{manage add modify},
                description: "SELinux context to assign to the port."

      action_class do
        include Chef::SELinux::CommonHelpers
        def current_port_context
          # use awk to see if the given port is within a reported port range
          shell_out!(
            <<~CMD
              seinfo --portcon=#{new_resource.port} | grep 'portcon #{new_resource.protocol}' | \
              awk -F: '$(NF-1) !~ /reserved_port_t$/ && $(NF-3) !~ /[0-9]*-[0-9]*/ {print $(NF-1)}'
            CMD
          ).stdout.split
        end
      end

      action :manage, description: "Assign the port to the right context regardless of previous state." do
        run_action(:add)
        run_action(:modify)
      end

      action :addormodify, description: "Assigns the port context if not set. Updates the port context if previously set." do
        Chef::Log.warn("The :addormodify action for selinux_port is deprecated and will be removed in a future release. Use the :manage action instead.")
        run_action(:manage)
      end

      # Create if doesn't exist, do not touch if port is already registered (even under different type)
      action :add, description: "Assign the port context if not set." do
        if selinux_disabled?
          Chef::Log.warn("Unable to add SELinux port #{new_resource.name} as SELinux is disabled")
          return
        end

        if current_port_context.empty?
          converge_by "Adding context #{new_resource.secontext} to port #{new_resource.port}/#{new_resource.protocol}" do
            shell_out!("semanage port -a -t '#{new_resource.secontext}' -p #{new_resource.protocol} #{new_resource.port}")
          end
        end
      end

      # Only modify port if it exists & doesn't have the correct context already
      action :modify, description: "Update the port context if previously set." do
        if selinux_disabled?
          Chef::Log.warn("Unable to modify SELinux port #{new_resource.name} as SELinux is disabled")
          return
        end

        if !current_port_context.empty? && !current_port_context.include?(new_resource.secontext)
          converge_by "Modifying context #{new_resource.secontext} to port #{new_resource.port}/#{new_resource.protocol}" do
            shell_out!("semanage port -m -t '#{new_resource.secontext}' -p #{new_resource.protocol} #{new_resource.port}")
          end
        end
      end

      # Delete if exists
      action :delete, description: "Removes the port context if set." do
        if selinux_disabled?
          Chef::Log.warn("Unable to delete SELinux port #{new_resource.name} as SELinux is disabled")
          return
        end

        unless current_port_context.empty?
          converge_by "Deleting context from port #{new_resource.port}/#{new_resource.protocol}" do
            shell_out!("semanage port -d -p #{new_resource.protocol} #{new_resource.port}")
          end
        end
      end

    end
  end
end
