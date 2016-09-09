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

require "chef/resource"
require "chef/provider/launchd"

class Chef
  class Resource
    class Launchd < Chef::Resource
      provides :launchd, os: "darwin"

      identity_attr :label

      default_action :create
      allowed_actions :create, :create_if_missing, :delete, :enable, :disable

      def initialize(name, run_context = nil)
        super
        provider = Chef::Provider::Launchd
        resource_name = :launchd
      end

      property :label, String, default: lazy { name }, identity: true
      property :backup, [Integer, FalseClass]
      property :cookbook, String
      property :group, [String, Integer]
      property :hash, Hash
      property :mode, [String, Integer]
      property :owner, [String, Integer]
      property :path, String
      property :source, String
      property :session_type, String

      property :type, String, default: "daemon", coerce: proc { |type|
        type = type ? type.downcase : "daemon"
        types = %w{daemon agent}

        unless types.include?(type)
          error_msg = "type must be daemon or agent"
          raise Chef::Exceptions::ValidationFailed, error_msg
        end
        type
      }

      # Apple LaunchD Keys
      property :abandon_process_group, [ TrueClass, FalseClass ]
      property :debug, [ TrueClass, FalseClass ]
      property :disabled, [ TrueClass, FalseClass ], default: false
      property :enable_globbing, [ TrueClass, FalseClass ]
      property :enable_transactions, [ TrueClass, FalseClass ]
      property :environment_variables, Hash
      property :exit_timeout, Integer
      property :hard_resource_limits, Hash
      property :inetd_compatibility, Hash
      property :init_groups, [ TrueClass, FalseClass ]
      property :keep_alive, [ TrueClass, FalseClass, Hash ]
      property :launch_only_once, [ TrueClass, FalseClass ]
      property :ld_group, String
      property :limit_load_from_hosts, Array
      property :limit_load_to_hosts, Array
      property :limit_load_to_session_type, String
      property :low_priority_io, [ TrueClass, FalseClass ]
      property :mach_services, Hash
      property :nice, Integer
      property :on_demand, [ TrueClass, FalseClass ]
      property :process_type, String
      property :program, String
      property :program_arguments, Array
      property :queue_directories, Array
      property :root_directory, String
      property :run_at_load, [ TrueClass, FalseClass ]
      property :sockets, Hash
      property :soft_resource_limits, Array
      property :standard_error_path, String
      property :standard_in_path, String
      property :standard_out_path, String
      property :start_calendar_interval, Hash
      property :start_interval, Integer
      property :start_on_mount, [ TrueClass, FalseClass ]
      property :throttle_interval, Integer
      property :time_out, Integer
      property :umask, Integer
      property :username, String
      property :wait_for_debugger, [ TrueClass, FalseClass ]
      property :watch_paths, Array
      property :working_directory, String
    end
  end
end
