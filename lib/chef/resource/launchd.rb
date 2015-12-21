#
# Author:: Mike Dodge (<mikedodge04@gmail.com>)
# Copyright:: Copyright (c) 2015 Facebook, Inc.
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

require 'chef/resource'
require 'chef/provider/launchd'

class Chef
  class Resource
    class Launchd < Chef::Resource
      provides :launchd, os: "darwin"

      identity_attr :label

      default_action :create
      allowed_actions :create, :create_if_missing, :delete, :enable, :disable

      def initialize(name, run_context = nil)
        super
        @provider = Chef::Provider::Launchd
        @resource_name = :launchd
        @label = name
        @disabled = false
        @type = 'daemon'
        @path = "/Library/LaunchDaemons/#{name}.plist"
      end

      def label(arg = nil)
        set_or_return(
          :label, arg,
          :kind_of => String
        )
      end

      def source(arg = nil)
        set_or_return(
          :source, arg,
          :kind_of => [String, Array]
        )
      end

      def cookbook(arg = nil)
        set_or_return(
          :cookbook, arg,
          :kind_of => String
        )
      end

      def path(arg = nil)
        set_or_return(
          :path, arg,
          :kind_of => String
        )
      end

      def hash(arg = nil)
        set_or_return(
          :hash, arg,
          :kind_of => Hash
        )
      end

      def backup(arg=nil)
        set_or_return(
          :backup, arg,
          :kind_of => [Integer, FalseClass]
        )
      end

      def group(arg = nil)
        set_or_return(
          :group, arg,
          :kind_of => [String, Integer]
        )
      end

      def mode(arg = nil)
        set_or_return(
          :mode, arg,
          :kind_of => [String, Integer]
        )
      end

      def owner(arg = nil)
        set_or_return(
          :owner, arg,
          :kind_of => [String, Integer]
        )
      end

      def type(type = nil)
        type = type ? type.downcase : 'daemon'
        if type == 'daemon'
          @path = "/Library/LaunchDaemons/#{name}.plist"
        elsif type == 'agent'
          @path = "/Library/LaunchAgents/#{name}.plist"
        else
          error_msg = 'type must be daemon or agent'
          raise Chef::Exceptions::ValidationFailed, error_msg
        end
        type
      end

      def abandon_process_group(arg = nil)
        set_or_return(
          :abandon_process_group, arg,
          :kind_of => String
        )
      end

      def debug(arg = nil)
        set_or_return(
          :debug, arg,
          :kind_of => [TrueClass, FalseClass]
        )
      end

      def disabled(arg = nil)
        set_or_return(
          :disabled, arg,
          :kind_of => [TrueClass, FalseClass]
        )
      end

      def enable_globbing(arg = nil)
        set_or_return(
          :enable_globbing, arg,
          :kind_of => [TrueClass, FalseClass]
        )
      end

      def enable_transactions(arg = nil)
        set_or_return(
          :enable_transactions, arg,
          :kind_of => [TrueClass, FalseClass]
        )
      end

      def environment_variables(arg = nil)
        set_or_return(
          :environment_variables, arg,
          :kind_of => Hash
        )
      end

      def exit_timeout(arg = nil)
        set_or_return(
          :exit_timeout, arg,
          :kind_of => Integer
        )
      end

      def hard_resource_limits(arg = nil)
        set_or_return(
          :hardre_source_limits, arg,
          :kind_of => Hash
        )
      end

      def keep_alive(arg = nil)
        set_or_return(
          :keep_alive, arg,
          :kind_of => [TrueClass, FalseClass]
        )
      end

      def launch_only_once(arg = nil)
        set_or_return(
          :launch_only_once, arg,
          :kind_of => [TrueClass, FalseClass]
        )
      end

      def limit_load_from_hosts(arg = nil)
        set_or_return(
          :limit_load_from_hosts, arg,
          :kind_of => Array
        )
      end

      def limit_load_to_hosts(arg = nil)
        set_or_return(
          :limit_load_to_hosts, arg,
          :kind_of => Array
        )
      end

      def limit_load_to_session_type(arg = nil)
        set_or_return(
          :limit_load_to_session_type, arg,
          :kind_of => String
        )
      end

      def low_priority_io(arg = nil)
        set_or_return(
          :low_priority_io, arg,
          :kind_of => [TrueClass, FalseClass]
        )
      end

      def mach_services(arg = nil)
        set_or_return(
          :mach_services, arg,
          :kind_of => Hash
        )
      end

      def nice(arg = nil)
        set_or_return(
          :nice, arg,
          :kind_of => [TrueClass, FalseClass]
        )
      end

      def on_demand(arg = nil)
        set_or_return(
          :on_demand, arg,
          :kind_of => String
        )
      end

      def username(arg = nil)
        set_or_return(
          :username, arg,
          :kind_of => String
        )
      end

      def ld_group(arg = nil)
        set_or_return(
          :ld_group, arg,
          :kind_of => String
        )
      end

      def inetd_compatibility(arg = nil)
        set_or_return(
          :inetd_compatibility, arg,
          :kind_of => Hash
        )
      end

      def init_groups(arg = nil)
        set_or_return(
          :init_groups, arg,
          :kind_of => [TrueClass, FalseClass]
        )
      end

      def process_type(arg = nil)
        set_or_return(
          :process_type, arg,
          :kind_of => String
        )
      end

      def program(arg = nil)
        set_or_return(
          :program, arg,
          :kind_of => String
        )
      end

      def program_arguments(arg = nil)
        set_or_return(
          :program_arguments, arg,
          :kind_of => Array
        )
      end

      def queue_directories(arg = nil)
        set_or_return(
          :queue_directories, arg,
          :kind_of => Array
        )
      end

      def root_directory(arg = nil)
        set_or_return(
          :root_directory, arg,
          :kind_of => String
        )
      end

      def run_at_load(arg = nil)
        set_or_return(
          :run_at_load, arg,
          :kind_of => [TrueClass, FalseClass]
        )
      end

      def sockets(arg = nil)
        set_or_return(
          :sockets, arg,
          :kind_of => Hash
        )
      end

      def soft_resource_limits(arg = nil)
        set_or_return(
          :soft_resource_limits, arg,
          :kind_of => Array
        )
      end

      def standard_error_path(arg = nil)
        set_or_return(
          :standard_error_path, arg,
          :kind_of => String
        )
      end

      def standard_in_path(arg = nil)
        set_or_return(
          :standard_in_path, arg,
          :kind_of => String
        )
      end

      def standard_out_path(arg = nil)
        set_or_return(
          :standard_out_path, arg,
          :kind_of => String
        )
      end

      def start_calendar_interval(arg = nil)
        set_or_return(
          :start_calendar_interval, arg,
          :kind_of => Hash
        )
      end

      def start_interval(arg = nil)
        set_or_return(
          :start_interval, arg,
          :kind_of => Integer
        )
      end

      def start_on_mount(arg = nil)
        set_or_return(
          :start_on_mount, arg,
          :kind_of => [TrueClass, FalseClass]
        )
      end

      def throttle_interval(arg = nil)
        set_or_return(
          :throttle_interval, arg,
          :kind_of => Integer
        )
      end

      def time_out(arg = nil)
        set_or_return(
          :time_out, arg,
          :kind_of => Integer
        )
      end

      def umask(arg = nil)
        set_or_return(
          :umask, arg,
          :kind_of => Integer
        )
      end

      def wait_for_debugger(arg = nil)
        set_or_return(
          :wait_for_debugger, arg,
          :kind_of => [TrueClass, FalseClass]
        )
      end

      def watch_paths(arg = nil)
        set_or_return(
          :watch_paths, arg,
          :kind_of => Array
        )
      end

      def working_directory(arg = nil)
        set_or_return(
          :working_directory, arg,
          :kind_of => String
        )
      end
    end
  end
end
