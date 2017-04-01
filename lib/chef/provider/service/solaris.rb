#
# Author:: Toomas Pelberg (<toomasp@gmx.net>)
# Copyright:: Copyright 2010-2016, Chef Software Inc.
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
require "chef/resource/service"

class Chef
  class Provider
    class Service
      class Solaris < Chef::Provider::Service
        attr_reader :maintenance

        provides :service, os: "solaris2"

        def initialize(new_resource, run_context = nil)
          super
          @init_command   = "/usr/sbin/svcadm"
          @status_command = "/bin/svcs"
          @maintenace     = false
        end

        def load_current_resource
          @current_resource = Chef::Resource::Service.new(@new_resource.name)
          @current_resource.service_name(@new_resource.service_name)

          [@init_command, @status_command].each do |cmd|
            unless ::File.executable? cmd
              raise Chef::Exceptions::Service, "#{cmd} not executable!"
            end
          end
          @status = service_status.enabled

          @current_resource
        end

        def define_resource_requirements
          # FIXME? need reload from service.rb
          shared_resource_requirements
        end

        def enable_service
          shell_out!(default_init_command, "clear", @new_resource.service_name) if @maintenance
          enable_flags = [ "-s", @new_resource.options ].flatten.compact
          shell_out!(default_init_command, "enable", *enable_flags, @new_resource.service_name)
        end

        def disable_service
          disable_flags = [ "-s", @new_resource.options ].flatten.compact
          shell_out!(default_init_command, "disable", *disable_flags, @new_resource.service_name)
        end

        alias_method :stop_service, :disable_service
        alias_method :start_service, :enable_service

        def reload_service
          shell_out!(default_init_command, "refresh", @new_resource.service_name)
        end

        def restart_service
          ## svcadm restart doesn't supports sync(-s) option
          disable_service
          enable_service
        end

        def service_status
          cmd = shell_out!(@status_command, "-l", @current_resource.service_name, :returns => [0, 1])
          # Example output
          # $ svcs -l rsyslog
          # fmri         svc:/application/rsyslog:default
          # name         rsyslog logging utility
          # enabled      true
          # state        online
          # next_state   none
          # state_time   April  2, 2015 04:25:19 PM EDT
          # logfile      /var/svc/log/application-rsyslog:default.log
          # restarter    svc:/system/svc/restarter:default
          # contract_id  1115271
          # dependency   require_all/error svc:/milestone/multi-user:default (online)
          # $

          # load output into hash
          status = {}
          cmd.stdout.each_line do |line|
            key, value = line.strip.split(/\s+/, 2)
            status[key] = value
          end

          # check service state
          @maintenance = false
          case status["state"]
          when "online"
            @current_resource.enabled(true)
            @current_resource.running(true)
          when "maintenance"
            @maintenance = true
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
