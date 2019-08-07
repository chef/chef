#
# Copyright:: 2015-2018 Chef Software, Inc.
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

class Chef
  class Resource
    class RhsmSubscription < Chef::Resource
      resource_name :rhsm_subscription
      provides(:rhsm_subscription) { true }

      description "Use the rhsm_subscription resource to add or remove Red Hat Subscription Manager"\
                  " subscriptions from your host. This can be used when a host's activation_key"\
                  " does not attach all necessary subscriptions to your host."
      introduced "14.0"

      property :pool_id, String,
        description: "An optional property for specifying the Pool ID if it differs from the resource block's name.",
        name_property: true

      action :attach do
        description "Attach the node to a subscription pool."

        execute "Attach subscription pool #{new_resource.pool_id}" do
          command "subscription-manager attach --pool=#{new_resource.pool_id}"
          default_env true
          action :run
          not_if { subscription_attached?(new_resource.pool_id) }
        end
      end

      action :remove do
        description "Remove the node from a subscription pool."

        execute "Remove subscription pool #{new_resource.pool_id}" do
          command "subscription-manager remove --serial=#{pool_serial(new_resource.pool_id)}"
          default_env true
          action :run
          only_if { subscription_attached?(new_resource.pool_id) }
        end
      end

      action_class do
        def subscription_attached?(subscription)
          cmd = Mixlib::ShellOut.new("subscription-manager list --consumed | grep #{subscription}", env: { LANG: "en_US" })
          cmd.run_command
          !cmd.stdout.match(/Pool ID:\s+#{subscription}$/).nil?
        end

        def serials_by_pool
          serials = {}
          pool = nil
          serial = nil

          cmd = Mixlib::ShellOut.new("subscription-manager list --consumed", env: { LANG: "en_US" })
          cmd.run_command
          cmd.stdout.lines.each do |line|
            line.strip!
            key, value = line.split(/:\s+/, 2)
            next unless ["Pool ID", "Serial"].include?(key)

            if key == "Pool ID"
              pool = value
            elsif key == "Serial"
              serial = value
            end

            next unless pool && serial

            serials[pool] = serial
            pool = nil
            serial = nil
          end

          serials
        end

        def pool_serial(pool_id)
          serials_by_pool[pool_id]
        end
      end
    end
  end
end
