#
# Author:: kaustubh (<kaustubh@clogeny.com>)
# Copyright:: Copyright 2014-2017, Chef Software Inc.
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

require "chef/provider/service"

class Chef
  class Provider
    class Service
      class Aix < Chef::Provider::Service
        attr_reader :status_load_success

        provides :service, os: "aix"

        def initialize(new_resource, run_context)
          super
        end

        def load_current_resource
          @current_resource = Chef::Resource::Service.new(@new_resource.name)
          @current_resource.service_name(@new_resource.service_name)

          @status_load_success = true
          @priority_success = true
          @is_resource_group = false

          determine_current_status!

          @current_resource
        end

        def start_service
          if @is_resource_group
            shell_out!("startsrc -g #{@new_resource.service_name}")
          else
            shell_out!("startsrc -s #{@new_resource.service_name}")
          end
        end

        def stop_service
          if @is_resource_group
            shell_out!("stopsrc -g #{@new_resource.service_name}")
          else
            shell_out!("stopsrc -s #{@new_resource.service_name}")
          end
        end

        def restart_service
          stop_service
          start_service
        end

        def reload_service
          if @is_resource_group
            shell_out!("refresh -g #{@new_resource.service_name}")
          else
            shell_out!("refresh -s #{@new_resource.service_name}")
          end
        end

        def shared_resource_requirements
          super
          requirements.assert(:all_actions) do |a|
            a.assertion { @status_load_success }
            a.whyrun ["Service status not available. Assuming a prior action would have installed the service.", "Assuming status of not running."]
          end
        end

        def define_resource_requirements
          # FIXME? need reload from service.rb
          shared_resource_requirements
        end

        protected

        def determine_current_status!
          Chef::Log.debug "#{@new_resource} using lssrc to check the status"
          begin
            if is_resource_group?
              # Groups as a whole have no notion of whether they're running
              @current_resource.running false
            else
              service = shell_out!("lssrc -s #{@new_resource.service_name}").stdout
              if service.split(" ").last == "active"
                @current_resource.running true
              else
                @current_resource.running false
              end
            end
            Chef::Log.debug "#{@new_resource} running: #{@current_resource.running}"
            # ShellOut sometimes throws different types of Exceptions than ShellCommandFailed.
            # Temporarily catching different types of exceptions here until we get Shellout fixed.
            # TODO: Remove the line before one we get the ShellOut fix.
          rescue Mixlib::ShellOut::ShellCommandFailed, SystemCallError
            @status_load_success = false
            @current_resource.running false
            nil
          end
        end

        def is_resource_group?
          so = shell_out("lssrc -g #{@new_resource.service_name}")
          if so.exitstatus == 0
            Chef::Log.debug("#{@new_resource.service_name} is a group")
            @is_resource_group = true
          end
        end
      end
    end
  end
end
