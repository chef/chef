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

require "chef/provider"
require "chef/resource/launchd"
require "chef/resource/file"
require "chef/resource/cookbook_file"
require "chef/resource/macosx_service"
require "plist"
require "forwardable"

class Chef
  class Provider
    class Launchd < Chef::Provider
      extend Forwardable
      provides :launchd, os: "darwin"

      def_delegators :new_resource, *[
        :backup,
        :cookbook,
        :group,
        :label,
        :mode,
        :owner,
        :path,
        :source,
        :session_type,
        :type,
      ]

      def load_current_resource
        current_resource = Chef::Resource::Launchd.new(new_resource.name)
        @path = path ? path : gen_path_from_type
      end

      def gen_path_from_type
        types = {
          "daemon" => "/Library/LaunchDaemons/#{label}.plist",
          "agent" => "/Library/LaunchAgents/#{label}.plist",
        }
        types[type]
      end

      def action_create
        manage_plist(:create)
      end

      def action_create_if_missing
        manage_plist(:create_if_missing)
      end

      def action_delete
        # If you delete a service you want to make sure its not loaded or
        # the service will be in memory and you wont be able to stop it.
        if ::File.exists?(@path)
          manage_service(:disable)
        end
        manage_plist(:delete)
      end

      def action_enable
        if manage_plist(:create)
          manage_service(:restart)
        else
          manage_service(:enable)
        end
      end

      def action_disable
        manage_service(:disable)
      end

      def action_restart
        manage_service(:restart)
      end

      def manage_plist(action)
        if source
          res = cookbook_file_resource
        else
          res = file_resource
        end
        res.run_action(action)
        new_resource.updated_by_last_action(true) if res.updated?
        res.updated
      end

      def manage_service(action)
        res = service_resource
        res.run_action(action)
        new_resource.updated_by_last_action(true) if res.updated?
      end

      def service_resource
        res = Chef::Resource::MacosxService.new(label, run_context)
        res.name(label) if label
        res.service_name(label) if label
        res.plist(@path) if @path
        res.session_type(session_type) if session_type
        res
      end

      def file_resource
        res = Chef::Resource::File.new(@path, run_context)
        res.name(@path) if @path
        res.backup(backup) if backup
        res.content(content) if content?
        res.group(group) if group
        res.mode(mode) if mode
        res.owner(owner) if owner
        res
      end

      def cookbook_file_resource
        res = Chef::Resource::CookbookFile.new(@path, run_context)
        res.cookbook_name = cookbook if cookbook
        res.name(@path) if @path
        res.backup(backup) if backup
        res.group(group) if group
        res.mode(mode) if mode
        res.owner(owner) if owner
        res.source(source) if source
        res
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

      def content?
        !!content
      end

      def content
        plist_hash = new_resource.plist_hash || gen_hash
        Plist::Emit.dump(plist_hash) unless plist_hash.nil?
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
          "hard_resource_limits" => "HardreSourceLimits",
          "inetd_compatibility" => "inetdCompatibility",
          "init_groups" => "InitGroups",
          "keep_alive" => "KeepAlive",
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
    end
  end
end
