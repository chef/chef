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

class Chef
  class Resource
    class SelinuxInstall < Chef::Resource
      unified_mode true

      provides :selinux_install, target_mode: true
      target_mode support: :full

      description "Use **selinux_install** resource to encapsulates the set of selinux packages to install in order to manage selinux. It also ensures the directory `/etc/selinux` is created."
      introduced "18.0"
      examples <<~DOC
      **Default installation**:

      ```ruby
      selinux_install 'example'
      ```

      **Install with custom packages**:

      ```ruby
      selinux_install 'example' do
        packages %w(policycoreutils selinux-policy selinux-policy-targeted)
      end
      ```

      **Uninstall**
      ```ruby
      selinux_install 'example' do
        action :remove
      end
      ```
      DOC

      property :packages, [String, Array],
                default: lazy { default_install_packages },
                description: "SELinux packages for system."

      action_class do
        def do_package_action(action)
          # friendly message for unsupported platforms
          raise "The platform #{node["platform"]} is not currently supported by the `selinux_install` resource. Please file an issue at https://github.com/chef/chef/issues with details on the platform this cookbook is running on." if new_resource.packages.nil?

          package "selinux" do
            package_name new_resource.packages
            action action
          end
        end
      end

      action :install, description: "Install required packages." do
        do_package_action(action)

        directory "/etc/selinux" do
          owner "root"
          group "root"
          mode "0755"
          action :create
        end
      end

      action :upgrade, description: "Upgrade required packages." do
        do_package_action(a)
      end

      action :remove, description: "Remove any SELinux-related packages." do
        do_package_action(a)
      end

      private

      #
      # Get an array of packages to be installed based upon node platform_family
      #
      # @return [Array] Array of string of package names
      def default_install_packages
        case node["platform_family"]
        when "rhel", "fedora", "amazon"
          %w{make policycoreutils selinux-policy selinux-policy-targeted selinux-policy-devel libselinux-utils setools-console}
        when "debian"
          if node["platform"] == "ubuntu"
            if node["platform_version"].to_f == 18.04
              %w{make policycoreutils selinux selinux-basics selinux-policy-default selinux-policy-dev auditd setools}
            else
              %w{make policycoreutils selinux-basics selinux-policy-default selinux-policy-dev auditd setools}
            end
          else
            %w{make policycoreutils selinux-basics selinux-policy-default selinux-policy-dev auditd setools}
          end
        end
      end
    end
  end
end
