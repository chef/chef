#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

require "chef/resource"
require "shellwords"

class Chef
  class Resource
    class Service < Chef::Resource
      identity_attr :service_name

      state_attrs :enabled, :running, :masked

      default_action :nothing
      allowed_actions :enable, :disable, :start, :stop, :restart, :reload,
                      :mask, :unmask

      # this is a poor API please do not re-use this pattern
      property :supports, Hash, default: { restart: nil, reload: nil, status: nil },
                                coerce: proc { |x| x.is_a?(Array) ? x.each_with_object({}) { |i, m| m[i] = true } : x }

      def initialize(name, run_context = nil)
        super
        @service_name = name
        @enabled = nil
        @running = nil
        @masked = nil
        @options = nil
        @parameters = nil
        @pattern = service_name
        @start_command = nil
        @stop_command = nil
        @status_command = nil
        @restart_command = nil
        @reload_command = nil
        @init_command = nil
        @priority = nil
        @timeout = nil
        @run_levels = nil
        @user = nil
      end

      def service_name(arg = nil)
        set_or_return(
          :service_name,
          arg,
          :kind_of => [ String ]
        )
      end

      # regex for match against ps -ef when !supports[:has_status] && status == nil
      def pattern(arg = nil)
        set_or_return(
          :pattern,
          arg,
          :kind_of => [ String ]
        )
      end

      # command to call to start service
      def start_command(arg = nil)
        set_or_return(
          :start_command,
          arg,
          :kind_of => [ String, NilClass, FalseClass ]
        )
      end

      # command to call to stop service
      def stop_command(arg = nil)
        set_or_return(
          :stop_command,
          arg,
          :kind_of => [ String, NilClass, FalseClass ]
        )
      end

      # command to call to get status of service
      def status_command(arg = nil)
        set_or_return(
          :status_command,
          arg,
          :kind_of => [ String, NilClass, FalseClass ]
        )
      end

      # command to call to restart service
      def restart_command(arg = nil)
        set_or_return(
          :restart_command,
          arg,
          :kind_of => [ String, NilClass, FalseClass ]
        )
      end

      def reload_command(arg = nil)
        set_or_return(
          :reload_command,
          arg,
          :kind_of => [ String, NilClass, FalseClass ]
        )
      end

      # The path to the init script associated with the service. On many
      # distributions this is '/etc/init.d/SERVICE_NAME' by default. In
      # non-standard configurations setting this value will save having to
      # specify overrides for the start_command, stop_command and
      # restart_command attributes.
      def init_command(arg = nil)
        set_or_return(
          :init_command,
          arg,
          :kind_of => [ String ]
        )
      end

      # if the service is enabled or not
      def enabled(arg = nil)
        set_or_return(
          :enabled,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      # if the service is running or not
      def running(arg = nil)
        set_or_return(
          :running,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      # if the service is masked or not
      def masked(arg = nil)
        set_or_return(
          :masked,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def options(arg = nil)
        set_or_return(
          :options,
          arg.respond_to?(:split) ? arg.shellsplit : arg,
          :kind_of => [ Array, String ]
        )
      end

      # Priority arguments can have two forms:
      #
      # - a simple number, in which the default start runlevels get
      #   that as the start value and stop runlevels get 100 - value.
      #
      # - a hash like { 2 => [:start, 20], 3 => [:stop, 55] }, where
      #   the service will be marked as started with priority 20 in
      #   runlevel 2, stopped in 3 with priority 55 and no symlinks or
      #   similar for other runlevels
      #
      def priority(arg = nil)
        set_or_return(
          :priority,
          arg,
          :kind_of => [ Integer, String, Hash ]
        )
      end

      # timeout only applies to the windows service manager
      def timeout(arg = nil)
        set_or_return(
          :timeout,
          arg,
          :kind_of => Integer
        )
      end

      def parameters(arg = nil)
        set_or_return(
          :parameters,
          arg,
          :kind_of => [ Hash ]
        )
      end

      def run_levels(arg = nil)
        set_or_return(
          :run_levels,
          arg,
          :kind_of => [ Array ] )
      end

      def user(arg = nil)
        set_or_return(
          :user,
          arg,
          :kind_of => [ String ]
        )
      end
    end
  end
end
