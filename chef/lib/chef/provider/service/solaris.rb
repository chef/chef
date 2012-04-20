#
# Author:: Toomas Pelberg (<toomasp@gmx.net>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

require 'chef/provider/service'

class Chef
  class Provider
    class Service
      class Solaris < Chef::Provider::Service
        attr_reader :init_command, :status_command

        def initialize(new_resource, run_context=nil)
          super
          @init_command = "/usr/sbin/svcadm"
          @status_command = "/bin/svcs -l"
        end

        def load_current_resource
          @current_resource = Chef::Resource::Service.new(@new_resource.name)
          @current_resource.service_name(@new_resource.service_name)

          raise Chef::Exceptions::Service, "/bin/svcs does not exist!" unless svcs_exists?

          @status = service_status?
          @current_resource.enabled @status
          @current_resource.running @status
          @current_resource
        end

        def enable_service
          shell_out!("#{@init_command} enable #{@new_resource.service_name}")
          return service_status?
        end

        def disable_service
          shell_out!("#{@init_command} disable #{@new_resource.service_name}")
          return !service_status?
        end

        alias_method :stop_service, :disable_service
        alias_method :start_service, :enable_service

        def reload_service
          shell_out!("#{@init_command} refresh #{@new_resource.service_name}")
        end

        def restart_service
          disable_service
          return enable_service
        end

        def svcs_exists?
          ::File.exists? "/bin/svcs"
        end

        # Looks like on Solaris, running and enabled are in tandem.
        def service_status?
          shell_out!("#{@status_command} #{@current_resource.service_name}").stdout.each_line do |line|
            return true if line =~ /state\sonline/
          end
          return false
        end

      end
    end
  end
end
