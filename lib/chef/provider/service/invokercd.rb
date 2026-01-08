#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "init"

class Chef
  class Provider
    class Service
      class Invokercd < Chef::Provider::Service::Init

        provides :service, platform_family: "debian", override: true, target_mode: true do
          invokercd?
        end

        def self.supports?(resource, action)
          service_script_exist?(:initd, resource.service_name)
        end

        def initialize(new_resource, run_context)
          super
          @init_command = "/usr/sbin/invoke-rc.d #{@new_resource.service_name}"
        end
      end
    end
  end
end
