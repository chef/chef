#
# Copyright:: Copyright (c) Chef Software Inc.
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
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class ChefSleep < Chef::Resource
      provides :chef_sleep

      unified_mode true

      description "Use the **chef_sleep** resource to pause (sleep) for a number of seconds during a #{ChefUtils::Dist::Infra::PRODUCT} run. Only use this resource when a command or service exits successfully but is not ready for the next step in a recipe."
      introduced "15.5"
      examples <<~DOC
        **Sleep for 10 seconds**:

        ```ruby
        chef_sleep '10'
        ```

        **Sleep for 10 seconds with a descriptive resource name for logging**:

        ```ruby
        chef_sleep 'wait for the service to start' do
          seconds 10
        end
        ```

        **Use a notification from another resource to sleep only when necessary**:

        ```ruby
        service 'Service that is slow to start and reports as started' do
          service_name 'my_database'
          action :start
          notifies :sleep, chef_sleep['wait for service start']
        end

        chef_sleep 'wait for service start' do
          seconds 30
          action :nothing
        end
        ```
      DOC

      property :seconds, [String, Integer],
        description: "The number of seconds to sleep.",
        coerce: proc { |s| Integer(s) },
        name_property: true

      action :sleep, description: "Pause the #{ChefUtils::Dist::Infra::PRODUCT} run for a specified number of seconds." do
        converge_by("sleep #{new_resource.seconds} seconds") do
          sleep(new_resource.seconds)
        end
      end
    end
  end
end
