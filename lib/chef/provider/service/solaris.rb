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

require 'chef/mixin/shell_out'
require 'chef/provider/service'
require 'chef/mixin/command'

class Chef
  class Provider
    class Service
      class Solaris < Chef::Provider::Service
        include Chef::Mixin::ShellOut

        def initialize(new_resource, run_context=nil)
          super
          @init_command = "/usr/sbin/svcadm"
          @status_command = "/bin/svcs -l"
        end
        

        def load_current_resource
          @current_resource = Chef::Resource::Service.new(@new_resource.name)
          @current_resource.service_name(@new_resource.service_name)
          unless ::File.exists? "/bin/svcs"
            raise Chef::Exceptions::Service, "/bin/svcs does not exist!"
          end
          @status = service_status.enabled
          @current_resource
        end

        def enable_service
          shell_out!("#{default_init_command} enable -s #{@new_resource.service_name}")
        end

        def disable_service
          shell_out!("#{default_init_command} disable -s #{@new_resource.service_name}")
        end

        alias_method :stop_service, :disable_service
        alias_method :start_service, :enable_service

        def reload_service
          shell_out!("#{default_init_command} refresh #{@new_resource.service_name}")
        end

        def restart_service
          ## svcadm restart doesn't supports sync(-s) option
          disable_service
          return enable_service
        end

        def service_status
          status = popen4("#{@status_command} #{@current_resource.service_name}") do |pid, stdin, stdout, stderr|
            stdout.each do |line|
              case line
              when /state\s+online/
                @current_resource.enabled(true)
                @current_resource.running(true)
              end
            end
          end
          unless @current_resource.enabled
            @current_resource.enabled(false)
            @current_resource.running(false)
          end
          @current_resource
        end

      end
    end
  end
end
