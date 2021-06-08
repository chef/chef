#
# Author:: Chris Doherty <cdoherty@chef.io>)
# Copyright:: Copyright 2014-2019, Chef, Inc.
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

class Chef
  class Resource
    class Reboot < Chef::Resource
      unified_mode true

      provides :reboot

      description "Use the **reboot** resource to reboot a node, a necessary step with some"\
                  " installations on certain platforms. This resource is supported for use on"\
                  " the Microsoft Windows, macOS, and Linux platforms.\n"\
                  "In using this resource via notifications, it's important to *only* use"\
                  " immediate notifications. Delayed notifications produce unintuitive and"\
                  " probably undesired results."
      introduced "12.0"
      examples <<~DOC
        **Reboot a node immediately**

        ```ruby
        reboot 'now' do
          action :nothing
          reason 'Cannot continue Chef run without a reboot.'
          delay_mins 2
        end

        execute 'foo' do
          command '...'
          notifies :reboot_now, 'reboot[now]', :immediately
        end
        ```

        **Reboot a node at the end of a Chef Infra Client run**

        ```ruby
        reboot 'app_requires_reboot' do
          action :request_reboot
          reason 'Need to reboot when the run completes successfully.'
          delay_mins 5
        end
        ```

        **Cancel a reboot**

        ```ruby
        reboot 'cancel_reboot_request' do
          action :cancel
          reason 'Cancel a previous end-of-run reboot request.'
        end
        ```
      DOC

      property :reason, String,
        description: "A string that describes the reboot action.",
        default: "Reboot by #{ChefUtils::Dist::Infra::PRODUCT}"

      property :delay_mins, Integer,
        description: "The amount of time (in minutes) to delay a reboot request.",
        default: 0

      action :request_reboot, description: "Reboot a node at the end of a #{ChefUtils::Dist::Infra::PRODUCT} run." do
        converge_by("request a system reboot to occur if the run succeeds") do
          logger.warn "Reboot requested:'#{new_resource.name}'"
          request_reboot
        end
      end

      action :reboot_now, description: "Reboot a node so that the #{ChefUtils::Dist::Infra::PRODUCT} may continue the installation process." do
        converge_by("rebooting the system immediately") do
          logger.warn "Rebooting system immediately, requested by '#{new_resource.name}'"
          request_reboot
          throw :end_client_run_early
        end
      end

      action :cancel, description: "Cancel a pending reboot request." do
        converge_by("cancel any existing end-of-run reboot request") do
          logger.warn "Reboot canceled: '#{new_resource.name}'"
          node.run_context.cancel_reboot
        end
      end

      # make sure people are quite clear what they want
      # we have to define this below the actions since setting default_action to :nothing is a no-op
      # and doesn't actually override the first action in the resource
      default_action :nothing

      action_class do
        # add a reboot to the node run_context
        # @return [void]
        def request_reboot
          node.run_context.request_reboot(
            delay_mins: new_resource.delay_mins,
            reason: new_resource.reason,
            timestamp: Time.now,
            requested_by: new_resource.name
          )
        end
      end
    end
  end
end
