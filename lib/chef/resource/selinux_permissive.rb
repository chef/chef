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
    class SelinuxPermissive < Chef::Resource
      unified_mode true

      provides :selinux_permissive, target_mode: true
      target_mode support: :full

      description "Use the **selinux_permissive** resource to allow some domains to misbehave without stopping them. This is not as good as setting specific policies, but better than disabling SELinux entirely."
      introduced "18.0"
      examples <<~DOC
      **Disable enforcement on Apache**:

      ```ruby
      selinux_permissive 'httpd_t' do
        notifies :restart, 'service[httpd]'
      end
      ```
      DOC

      property :context, String,
                name_property: true,
                description: "The SELinux context to permit."

      action_class do
        def current_permissives
          shell_out!("semanage permissive -ln").stdout.split("\n")
        end
      end

      # Create if doesn't exist, do not touch if permissive is already registered (even under different type)
      action :add, description: "Add a permissive, unless already set." do
        unless current_permissives.include? new_resource.context
          converge_by "adding permissive context #{new_resource.context}" do
            shell_out!("semanage permissive -a '#{new_resource.context}'")
          end
        end
      end

      # Delete if exists
      action :delete, description: "Remove a permissive, if set." do
        if current_permissives.include? new_resource.context
          converge_by "deleting permissive context #{new_resource.context}" do
            shell_out!("semanage permissive -d '#{new_resource.context}'")
          end
        end
      end
    end
  end
end
