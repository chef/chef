#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: Copyright (c) 2016-2017, Chef Software Inc.
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
    class AptUpdate < Chef::Resource
      resource_name :apt_update
      provides(:apt_update) { true }

      description "Use the apt_update resource to manage APT repository updates on Debian and Ubuntu platforms."
      introduced "12.7"

      # allow bare apt_update with no name
      property :name, String, default: ""

      property :frequency, Integer,
                description: "Determines how frequently (in seconds) APT repository updates are made. Use this property when the :periodic action is specified.",
                default: 86_400

      default_action :periodic
      allowed_actions :update, :periodic
    end
  end
end
