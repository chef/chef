#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

require "chef/provider/service/init"

class Chef
  class Provider
    class Service
      class Invokercd < Chef::Provider::Service::Init

        provides :service, platform_family: "debian", override: true do |node|
          Chef::Platform::ServiceHelpers.service_resource_providers.include?(:invokercd)
        end

        def self.supports?(resource, action)
          Chef::Platform::ServiceHelpers.config_for_service(resource.service_name).include?(:initd)
        end

        def initialize(new_resource, run_context)
          super
          @init_command = "/usr/sbin/invoke-rc.d #{@new_resource.service_name}"
        end
      end
    end
  end
end
