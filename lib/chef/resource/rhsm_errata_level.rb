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
    class RhsmErrataLevel < Chef::Resource
      unified_mode true
      provides(:rhsm_errata_level) { true }

      description "Use the **rhsm_errata_level** resource to install all packages of a specified errata level from the Red Hat Subscription Manager. For example, you can ensure that all packages associated with errata marked at a 'Critical' security level are installed."
      introduced "14.0"
      examples <<~DOC
        **Specify an errata level that differs from the resource name**

        ```ruby
        rhsm_errata_level 'example_install_moderate' do
          errata_level 'moderate'
        end
        ```
      DOC

      property :errata_level, String,
        coerce: proc { |x| x.downcase },
        equal_to: %w{critical moderate important low},
        description: "An optional property for specifying the errata level of packages to install if it differs from the resource block's name.",
        name_property: true

      action :install, description: "Install all packages of the specified errata level." do
        yum_package "yum-plugin-security" if rhel6?

        execute "Install any #{new_resource.errata_level} errata" do
          command "#{package_manager_command} update --sec-severity=#{new_resource.errata_level.capitalize} -y"
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
