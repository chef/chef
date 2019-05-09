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
    class RhsmErrata < Chef::Resource
      resource_name :rhsm_errata
      provides(:rhsm_errata) { true }

      description "Use the rhsm_errata resource to install packages associated with a given Red"\
                  " Hat Subscription Manager Errata ID. This is helpful if packages"\
                  " to mitigate a single vulnerability must be installed on your hosts."
      introduced "14.0"

      property :errata_id, String,
               description: "An optional property for specifying the errata ID if it differs from the resource block's name.",
               name_property: true

      action :install do
        description "Installs a package for a specific errata ID."

        execute "Install errata packages for #{new_resource.errata_id}" do
          command "yum update --advisory #{new_resource.errata_id} -y"
          default_env true
          action :run
        end
      end
    end
  end
end
