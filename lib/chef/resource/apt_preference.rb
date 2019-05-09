#
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: 2016-2017, Chef Software, Inc.
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
    # @since 13.3
    class AptPreference < Chef::Resource
      resource_name :apt_preference
      provides(:apt_preference) { true }

      description "The apt_preference resource allows for the creation of APT preference files. Preference files are used to control which package versions and sources are prioritized during installation."
      introduced "13.3"

      property :package_name, String,
               name_property: true,
               description: "An optional property to set the package name if it differs from the resource block's name.",
               regex: [/^([a-z]|[A-Z]|[0-9]|_|-|\.|\*|\+)+$/],
               validation_message: "The provided package name is not valid. Package names can only contain alphanumeric characters as well as _, -, +, or *!"

      property :glob, String,
               description: "Pin by glob() expression or with regular expressions surrounded by /."

      property :pin, String,
               description: "The package version or repository to pin.",
               required: true

      property :pin_priority, [String, Integer],
               description: "Sets the Pin-Priority for a package.",
               required: true

      default_action :add
      allowed_actions :add, :remove
    end
  end
end
