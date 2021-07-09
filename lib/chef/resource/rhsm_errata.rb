#
# Copyright:: Copyright (c) Chef Software Inc.
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
    class RhsmErrata < Chef::Resource
      unified_mode true
      provides(:rhsm_errata) { true }

      description "Use the **rhsm_errata** resource to install packages associated with a given Red Hat Subscription Manager Errata ID. This is helpful if packages to mitigate a single vulnerability must be installed on your hosts."
      introduced "14.0"
      examples <<~DOC
        **Install a package from an Errata ID**

        ```ruby
        rhsm_errata 'RHSA:2018-1234'
        ```

        **Specify an Errata ID that differs from the resource name**

        ```ruby
        rhsm_errata 'errata-install'
          errata_id 'RHSA:2018-1234'
        end
        ```
      DOC

      property :errata_id, String,
        description: "An optional property for specifying the errata ID if it differs from the resource block's name.",
        name_property: true

      action :install, description: "Install a package for a specific errata ID." do
        execute "Install errata packages for #{new_resource.errata_id}" do
          command "#{package_manager_command} update --advisory #{new_resource.errata_id} -y"
          default_env true
          action :run
        end
      end

      action_class do
        def package_manager_command
          node["platform_version"].to_i >= 8 ? "dnf" : "yum"
        end
      end
    end
  end
end
