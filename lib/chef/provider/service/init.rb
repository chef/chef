#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
# Copyright:: Copyright 2008-2016, Chef Software, Inc.
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

require "chef/provider/service/simple"
require "chef/platform/service_helpers"

class Chef
  class Provider
    class Service
      class Init < Chef::Provider::Service::Simple

        attr_accessor :init_command

        provides :service, os: "!windows"

        def self.supports?(resource, action)
          Chef::Platform::ServiceHelpers.config_for_service(resource.service_name).include?(:initd)
        end

        def initialize(new_resource, run_context)
          super
          @init_command = "/etc/init.d/#{@new_resource.service_name}"
        end

        def define_resource_requirements
          # do not call super here, inherit only shared_requirements
          shared_resource_requirements
          requirements.assert(:start, :stop, :restart, :reload) do |a|
            a.assertion do
              custom_command_for_action?(action) || ::File.exist?(default_init_command)
            end
            a.failure_message(Chef::Exceptions::Service, "#{default_init_command} does not exist!")
            a.whyrun("Init script '#{default_init_command}' doesn't exist, assuming a prior action would have created it.") do
              # blindly assume that the service exists but is stopped in why run mode:
              @status_load_success = false
            end
          end
        end

        def start_service
          if @new_resource.start_command
            super
          else
            shell_out_with_systems_locale!("#{default_init_command} start")
          end
        end

        def stop_service
          if @new_resource.stop_command
            super
          else
            shell_out_with_systems_locale!("#{default_init_command} stop")
          end
        end

        def restart_service
          if @new_resource.restart_command
            super
          elsif supports[:restart]
            shell_out_with_systems_locale!("#{default_init_command} restart")
          else
            stop_service
            sleep 1
            start_service
          end
        end

        def reload_service
          if @new_resource.reload_command
            super
          elsif supports[:reload]
            shell_out_with_systems_locale!("#{default_init_command} reload")
          end
        end
      end
    end
  end
end
