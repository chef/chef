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
      allowed_actions :create, :create_if_missing, :delete, :enable, :disable, :restart

      property :label, String, default: lazy { name }, identity: true
      property :backup, [Integer, FalseClass]
      property :cookbook, String
      property :group, [String, Integer]
      property :plist_hash, Hash
      property :mode, [String, Integer]
      property :owner, [String, Integer]
      property :path, String
      property :source, String
      property :session_type, String

      # StartCalendarInterval has some gotchas so we coerce it to help sanity
      # check.  According to `man 5 launchd.plist`:
      #   StartCalendarInterval <dictionary of integers or array of dictionaries of integers>
      #     ... Missing arguments are considered to be wildcard.
      # What the man page doesn't state, but what was observed (OSX 10.11.5, launchctrl v3.4.0)
      # Is that keys that are specified, but invalid, will also be treated as a wildcard
      # this means that an entry like:
      #   { "Hour"=>0, "Weekday"=>"6-7"}
      # will not just run on midnight of Sat and Sun, rather it will run _every_ midnight.
      property :start_calendar_interval, [Hash, Array], coerce: proc { |type|
        # Coerce into an array of hashes to make validation easier
        array = if type.is_a?(Array)
                  type
                else
                  [type]
                end

        # Check to make sure that our array only has hashes
        unless array.all? { |obj| obj.is_a?(Hash) }
          error_msg = "start_calendar_interval must be a single hash or an array of hashes!"
          raise Chef::Exceptions::ValidationFailed, error_msg
        end

        # Make sure the hashes don't have any incorrect keys/values
        array.each do |entry|
          allowed_keys = %w{Minute Hour Day Weekday Month}
          unless entry.keys.all? { |key| allowed_keys.include?(key) }
            failed_keys = entry.keys.reject { |k| allowed_keys.include?(k) }.join(", ")
            error_msg = "The following key(s): #{failed_keys} are invalid for start_calendar_interval, must be one of: #{allowed_keys.join(", ")}"
            raise Chef::Exceptions::ValidationFailed, error_msg
          end

          unless entry.values.all? { |val| val.is_a?(Integer) }
            failed_values = entry.values.reject { |val| val.is_a?(Integer) }.join(", ")
            error_msg = "Invalid value(s) (#{failed_values}) for start_calendar_interval item.  Values must be integers!"
            raise Chef::Exceptions::ValidationFailed, error_msg
          end
        end

        # Don't return array if we only have one entry
        if array.size == 1
          array.first
        else
          array
        end
      }

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
      property :limit_load_to_session_type, [ Array, String ]
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
