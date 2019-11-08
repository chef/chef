#
# Copyright:: 2019, Chef Software Inc.
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
require_relative "../dist"

class Chef
  class Resource
    class ChefSleep < Chef::Resource
      resource_name :chef_sleep
      provides :chef_sleep

      unified_mode true

      description "Use the chef_sleep resource to sleep for a number of seconds during a #{Chef::Dist::PRODUCT} run."
      introduced "15.5"

      property :seconds, [String, Integer],
        description: "The number of seconds to sleep.",
        coerce: proc { |s| Integer(s) },
        name_property: true

      action :sleep do
        sleep(new_resource.seconds)
      end
    end
  end
end
