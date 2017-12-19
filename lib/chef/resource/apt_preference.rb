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

require "chef/resource"

class Chef
  class Resource
    # The apt_preference resource allows for the creation of APT preference files. Preference files are used to control
    # which package versions and sources are prioritized during installation.
    #
    # @since 13.3
    class AptPreference < Chef::Resource
      resource_name :apt_preference
      provides :apt_preference

      property :package_name, String, name_property: true, regex: [/^([a-z]|[A-Z]|[0-9]|_|-|\.|\*|\+)+$/]
      property :glob, String
      property :pin, String, required: true
      property :pin_priority, [String, Integer], required: true

      default_action :add
      allowed_actions :add, :remove
    end
  end
end
