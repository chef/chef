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
    class SelinuxUser < Chef::Resource
      unified_mode true

      provides :selinux_user, target_mode: true
      target_mode support: :full

      description "Use the **selinux_user** resource to add, update, or remove SELinux users."
      introduced "18.1"
      examples <<~DOC
      **Manage test_u SELinux user with a level and range of s0 and roles sysadm_r and staff_r**:

      ```ruby
      selinux_user 'test_u' do
        level 's0'
        range 's0'
        roles %w(sysadm_r staff_r)
      end
      ```
      DOC

      property :user, String,
                name_property: true,
                description: "An optional property to set the SELinux user value if it differs from the resource block's name."

      property :level, String,
                description: "MLS/MCS security level for the SELinux user."

      property :range, String,
                description: "MLS/MCS security range for the SELinux user."

      property :roles, Array,
                description: "Associated SELinux roles for the user.",
                coerce: proc { |r| Array(r).sort }

      load_current_value do |new_resource|
        users = shell_out!("semanage user -l").stdout.split("\n")

        current_user = users.grep(/^#{Regexp.escape(new_resource.user)}\s+/) do |u|
          u.match(/^(?<user>[^\s]+)\s+(?<prefix>[^\s]+)\s+(?<level>[^\s]+)\s+(?<range>[^\s]+)\s+(?<roles>.*)$/)
          # match returns [<Match 'data'>] or [], shift converts that to <Match 'data'> or nil
        end.shift

        current_value_does_not_exist! unless current_user

        # Existing resources should maintain their current configuration unless otherwise specified
        new_resource.level ||= current_user[:level]
        new_resource.range ||= current_user[:range]
        new_resource.roles ||= current_user[:roles].to_s.split.sort

        level current_user[:level]
        range current_user[:range]
        roles current_user[:roles].to_s.split.sort
      end

      action_class do
        include Chef::SELinux::CommonHelpers

        def semanage_user_args
          # Generate arguments for semanage user -a or -m
          args = ""

          args += " -L #{new_resource.level}" if new_resource.level
          args += " -r #{new_resource.range}" if new_resource.range
          args += " -R '#{new_resource.roles.join(" ")}'" unless new_resource.roles.to_a.empty?

          args
        end
      end

      action :manage, description: "Sets the SELinux user to the desired settings regardless of previous state." do
        run_action(:add)
        run_action(:modify)
      end

      # Create if doesn't exist, do not touch if user already exists
      action :add, description: "Creates the SELinux user if not previously created." do
        raise "The roles property must be populated to create a new SELinux user" if new_resource.roles.to_a.empty?

        if selinux_disabled?
          Chef::Log.warn("Unable to add SELinux user #{new_resource.user} as SELinux is disabled")
          return
        end

        unless current_resource
          converge_if_changed do
            shell_out!("semanage user -a#{semanage_user_args} #{new_resource.user}")
          end
        end
      end

      # Only modify port if it exists & doesn't have the correct context already
      action :modify, description: "Updates the SELinux user if previously created." do
        if selinux_disabled?
          Chef::Log.warn("Unable to modify SELinux user #{new_resource.user} as SELinux is disabled")
          return
        end

        if current_resource
          converge_if_changed do
            shell_out!("semanage user -m#{semanage_user_args} #{new_resource.user}")
          end
        end
      end

      # Delete if exists
      action :delete, description: "Removes the SELinux user if previously created." do
        if selinux_disabled?
          Chef::Log.warn("Unable to delete SELinux user #{new_resource.user} as SELinux is disabled")
          return
        end

        if current_resource
          converge_by "deleting SELinux user #{new_resource.user}" do
            shell_out!("semanage user -d #{new_resource.user}")
          end
        end
      end
    end
  end
end
