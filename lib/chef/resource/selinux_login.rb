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
    class SelinuxLogin < Chef::Resource
      unified_mode true

      provides :selinux_login, target_mode: true
      target_mode support: :full

      description "Use the **selinux_login** resource to add, update, or remove SELinux user to OS login mappings."
      introduced "18.1"
      examples <<~DOC
      **Manage test OS user mapping with a range of s0 and associated SELinux user test_u**:

      ```ruby
      selinux_login 'test' do
        user 'test_u'
        range 's0'
      end
      ```
      DOC

      property :login, String,
                name_property: true,
                description: "An optional property to set the OS user login value if it differs from the resource block's name."

      property :user, String,
                description: "SELinux user to be mapped."

      property :range, String,
                description: "MLS/MCS security range for the SELinux user."

      load_current_value do |new_resource|
        logins = shell_out!("semanage login -l").stdout.split("\n")

        current_login = logins.grep(/^#{Regexp.escape(new_resource.login)}\s+/) do |l|
          l.match(/^(?<login>[^\s]+)\s+(?<user>[^\s]+)\s+(?<range>[^\s]+)/)
          # match returns [<Match 'data'>] or [], shift converts that to <Match 'data'> or nil
        end.shift

        current_value_does_not_exist! unless current_login

        # Existing resources should maintain their current configuration unless otherwise specified
        new_resource.user ||= current_login[:user]
        new_resource.range ||= current_login[:range]

        user current_login[:user]
        range current_login[:range]
      end

      action_class do
        include Chef::SELinux::CommonHelpers

        def semanage_login_args
          # Generate arguments for semanage login -a or -m
          args = ""

          args += " -s #{new_resource.user}" if new_resource.user
          args += " -r #{new_resource.range}" if new_resource.range

          args
        end
      end

      action :manage, description: "Sets the SELinux login mapping to the desired settings regardless of previous state." do
        run_action(:add)
        run_action(:modify)
      end

      # Create if doesn't exist, do not touch if user already exists
      action :add, description: "Creates the SELinux login mapping if not previously created." do
        raise "The user property must be populated to create a new SELinux login" if new_resource.user.to_s.empty?

        if selinux_disabled?
          Chef::Log.warn("Unable to add SELinux login #{new_resource.login} as SELinux is disabled")
          return
        end

        unless current_resource
          converge_if_changed do
            shell_out!("semanage login -a#{semanage_login_args} #{new_resource.login}")
          end
        end
      end

      # Only modify port if it exists & doesn't have the correct context already
      action :modify, description: "Updates the SELinux login mapping if previously created." do
        if selinux_disabled?
          Chef::Log.warn("Unable to modify SELinux login #{new_resource.login} as SELinux is disabled")
          return
        end

        if current_resource
          converge_if_changed do
            shell_out!("semanage login -m#{semanage_login_args} #{new_resource.login}")
          end
        end
      end

      # Delete if exists
      action :delete, description: "Removes the SELinux login mapping if previously created." do
        if selinux_disabled?
          Chef::Log.warn("Unable to delete SELinux login #{new_resource.login} as SELinux is disabled")
          return
        end

        if current_resource
          converge_by "deleting SELinux login #{new_resource.login}" do
            shell_out!("semanage login -d #{new_resource.login}")
          end
        end
      end
    end
  end
end
