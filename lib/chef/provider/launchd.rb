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

require_relative "../provider"
require_relative "../resource/file"
require_relative "../resource/cookbook_file"
require_relative "../resource/macosx_service"
autoload :Plist, "plist"
require "forwardable" unless defined?(Forwardable)

class Chef
  class Provider
    class Launchd < Chef::Provider
      extend Forwardable
      provides :launchd, os: "darwin"

      def_delegators :new_resource, :backup, :cookbook, :group, :label, :mode, :owner, :source, :session_type, :type

      def load_current_resource
        current_resource = Chef::Resource::Launchd.new(new_resource.name)
      end

      def gen_path_from_type
        types = {
          "daemon" => "/Library/LaunchDaemons/#{label}.plist",
          "agent" => "/Library/LaunchAgents/#{label}.plist",
        }
        types[type]
      end

      action :create, description: "Create a launchd property list." do
        manage_plist(:create)
      end

      action :create_if_missing, description: "Create a launchd property list, if it does not already exist." do
        manage_plist(:create_if_missing)
      end

      action :delete, description: "Delete a launchd property list. This will unload a daemon or agent, if loaded." do
        if ::File.exists?(path)
          manage_service(:disable)
        end
        manage_plist(:delete)
      end

      action :enable, description: "Create a launchd property list, and then ensure that it is enabled. If a launchd property list already exists, but does not match, updates the property list to match, and then restarts the daemon or agent." do
        manage_service(:nothing)
        manage_plist(:create) do
          notifies :restart, "macosx_service[#{label}]", :immediately
        end
        manage_service(:enable)
      end

      action :disable, description: "Disable a launchd property list." do
        return unless ::File.exist?(path)

        manage_service(:disable)
      end

      action :restart, description: "Restart a launchd managed daemon or agent." do
        manage_service(:restart)
      end

      def manage_plist(action, &block)
        if source
          cookbook_file path do
            cookbook_name = new_resource.cookbook if new_resource.cookbook
            copy_properties_from(new_resource, :backup, :group, :mode, :owner, :source)
            action(action)
            only_if { manage_agent?(action) }
            instance_eval(&block) if block_given?
          end
        else
          file path do
            copy_properties_from(new_resource, :backup, :group, :mode, :owner)
            content(file_content) if file_content?
            action(action)
            only_if { manage_agent?(action) }
            instance_eval(&block) if block_given?
          end
        end
      end

      def manage_service(action)
        plist_path = path
        macosx_service label do
          service_name(new_resource.label) if new_resource.label
          plist(plist_path) if plist_path
          copy_properties_from(new_resource, :session_type)
          action(action)
          only_if { manage_agent?(action) }
        end
      end

      def manage_agent?(action)
        # Gets UID of console_user and converts to string.
        console_user = Etc.getpwuid(::File.stat("/dev/console").uid).name
        root = console_user == "root"
        agent = type == "agent"
        invalid_action = %i{delete disable enable restart}.include?(action)
        lltstype = ""
        if new_resource.limit_load_to_session_type
          lltstype = new_resource.limit_load_to_session_type
        end
        invalid_type = lltstype != "LoginWindow"
        if root && agent && invalid_action && invalid_type
          logger.trace("#{label}: Aqua LaunchAgents shouldn't be loaded as root")
          return false
        end
        true
      end

      def define_resource_requirements
        requirements.assert(
          :create, :create_if_missing, :delete, :enable, :disable
        ) do |a|
          type = new_resource.type
          a.assertion { %w{daemon agent}.include?(type.to_s) }
          error_msg = "type must be daemon or agent."
          a.failure_message Chef::Exceptions::ValidationFailed, error_msg
        end
      end

      def file_content?
        !!file_content
      end

      def file_content
        plist_hash = new_resource.plist_hash || gen_hash
        ::Plist::Emit.dump(plist_hash) unless plist_hash.nil?
      end

      def gen_hash
        return nil unless new_resource.program || new_resource.program_arguments

        {
          "label" => "Label",
          "program" => "Program",
          "program_arguments" => "ProgramArguments",
          "abandon_process_group" => "AbandonProcessGroup",
          "debug" => "Debug",
          "disabled" => "Disabled",
          "enable_globbing" => "EnableGlobbing",
          "enable_transactions" => "EnableTransactions",
          "environment_variables" => "EnvironmentVariables",
          "exit_timeout" => "ExitTimeout",
          "ld_group" => "GroupName",
          "hard_resource_limits" => "HardResourceLimits",
          "inetd_compatibility" => "inetdCompatibility",
          "init_groups" => "InitGroups",
          "keep_alive" => "KeepAlive",
          "launch_events" => "LaunchEvents",
          "launch_only_once" => "LaunchOnlyOnce",
          "limit_load_from_hosts" => "LimitLoadFromHosts",
          "limit_load_to_hosts" => "LimitLoadToHosts",
          "limit_load_to_session_type" => "LimitLoadToSessionType",
          "low_priority_io" => "LowPriorityIO",
          "mach_services" => "MachServices",
          "nice" => "Nice",
          "on_demand" => "OnDemand",
          "process_type" => "ProcessType",
          "queue_directories" => "QueueDirectories",
          "root_directory" => "RootDirectory",
          "run_at_load" => "RunAtLoad",
          "sockets" => "Sockets",
          "soft_resource_limits" => "SoftResourceLimits",
          "standard_error_path" => "StandardErrorPath",
          "standard_in_path" => "StandardInPath",
          "standard_out_path" => "StandardOutPath",
          "start_calendar_interval" => "StartCalendarInterval",
          "start_interval" => "StartInterval",
          "start_on_mount" => "StartOnMount",
          "throttle_interval" => "ThrottleInterval",
          "time_out" => "TimeOut",
          "umask" => "Umask",
          "username" => "UserName",
          "wait_for_debugger" => "WaitForDebugger",
          "watch_paths" => "WatchPaths",
          "working_directory" => "WorkingDirectory",
        }.each_with_object({}) do |(key, val), memo|
          memo[val] = new_resource.send(key) if new_resource.send(key)
        end
      end

      # @api private
      def path
        @path ||= new_resource.path || gen_path_from_type
      end
    end
  end
end
