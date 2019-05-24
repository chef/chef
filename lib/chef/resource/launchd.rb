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

require_relative "../resource"

class Chef
  class Resource
    class Launchd < Chef::Resource
      resource_name :launchd
      provides :launchd

      description "Use the launchd resource to manage system-wide services (daemons) and per-user services (agents) on the macOS platform."
      introduced "12.8"

      default_action :create
      allowed_actions :create, :create_if_missing, :delete, :enable, :disable, :restart

      property :label, String,
               identity: true, name_property: true,
               description: "The unique identifier for the job."

      property :backup, [Integer, FalseClass],
               desired_state: false,
               description: "The number of backups to be kept in /var/chef/backup. Set to false to prevent backups from being kept."

      property :cookbook, String,
               desired_state: false,
               description: "The name of the cookbook in which the source files are located."

      property :group, [String, Integer],
               description: "When launchd is run as the root user, the group to run the job as. If the username property is specified and this property is not, this value is set to the default group for the user."

      property :plist_hash, Hash,
               introduced: "12.19",
               description: "A Hash of key value pairs used to create the launchd property list."

      property :mode, [String, Integer],
               description: "A quoted 3-5 character string that defines the octal mode. For example: '755', '0755', or 00755."

      property :owner, [String, Integer],
               description: "A string or ID that identifies the group owner by user name, including fully qualified user names such as domain_user or user@domain. If this value is not specified, existing owners remain unchanged and new owner assignments use the current user (when necessary)."

      property :path, String,
               description: "The path to the directory. Using a fully qualified path is recommended, but is not always required."

      property :source, String,
               description: "The path to the launchd property list."

      property :session_type, String,
               description: "The type of launchd plist to be created. Possible values: system (default) or user."

      # StartCalendarInterval has some gotchas so we coerce it to help sanity
      # check.  According to `man 5 launchd.plist`:
      #   StartCalendarInterval <dictionary of integers or array of dictionaries of integers>
      #     ... Missing arguments are considered to be wildcard.
      # What the man page doesn't state, but what was observed (OSX 10.11.5, launchctrl v3.4.0)
      # Is that keys that are specified, but invalid, will also be treated as a wildcard
      # this means that an entry like:
      #   { "Hour"=>0, "Weekday"=>"6-7"}
      # will not just run on midnight of Sat and Sun, rather it will run _every_ midnight.
      property :start_calendar_interval, [Hash, Array],
               description: "A Hash (similar to crontab) that defines the calendar frequency at which a job is started or an Array.",
               coerce: proc { |type|
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

      property :type, String,
               description: "The type of resource. Possible values: daemon (default), agent.",
               default: "daemon", coerce: proc { |type|
                                            type = type ? type.downcase : "daemon"
                                            types = %w{daemon agent}

                                            unless types.include?(type)
                                              error_msg = "type must be daemon or agent"
                                              raise Chef::Exceptions::ValidationFailed, error_msg
                                            end
                                            type
                                          }

      # Apple LaunchD Keys
      property :abandon_process_group, [ TrueClass, FalseClass ],
               description: "If a job dies, all remaining processes with the same process ID may be kept running. Set to true to kill all remaining processes."

      property :debug, [ TrueClass, FalseClass ],
               description: "Sets the log mask to LOG_DEBUG for this job."

      property :disabled, [ TrueClass, FalseClass ], default: false,
               description: "Hints to launchctl to not submit this job to launchd."

      property :enable_globbing, [ TrueClass, FalseClass ],
               description: "Update program arguments before invocation."

      property :enable_transactions, [ TrueClass, FalseClass ],
               description: "Track in-progress transactions; if none, then send the SIGKILL signal."

      property :environment_variables, Hash,
               description: "Additional environment variables to set before running a job."

      property :exit_timeout, Integer,
               description: "The amount of time (in seconds) launchd waits before sending a SIGKILL signal."

      property :hard_resource_limits, Hash,
               description: "A Hash of resource limits to be imposed on a job."

      property :inetd_compatibility, Hash,
               description: "Specifies if a daemon expects to be run as if it were launched from inetd. Set to wait => true to pass standard input, output, and error file descriptors. Set to wait => false to call the accept system call on behalf of the job, and then pass standard input, output, and error file descriptors."

      property :init_groups, [ TrueClass, FalseClass ],
               description: "Specify if initgroups is called before running a job."

      property :keep_alive, [ TrueClass, FalseClass, Hash ],
               introduced: "12.14",
               description: "Keep a job running continuously (true) or allow demand and conditions on the node to determine if the job keeps running (false)."

      property :launch_events, [ Hash ],
               introduced: "15.1",
               description: "Specify higher-level event types to be used as launch-on-demand event sources."

      property :launch_only_once, [ TrueClass, FalseClass ],
               description: "Specify if a job can be run only one time. Set this value to true if a job cannot be restarted without a full machine reboot."

      property :ld_group, String,
               description: "The group name."

      property :limit_load_from_hosts, Array,
               description: "An array of hosts to which this configuration file does not apply, i.e. 'apply this configuration file to all hosts not specified in this array'."

      property :limit_load_to_hosts, Array,
               description: "An array of hosts to which this configuration file applies."

      property :limit_load_to_session_type, [ Array, String ],
               description: "The session type(s) to which this configuration file applies."

      property :low_priority_io, [ TrueClass, FalseClass ],
               description: "Specify if the kernel on the node should consider this daemon to be low priority during file system I/O."

      property :mach_services, Hash,
               description: "Specify services to be registered with the bootstrap subsystem."

      property :nice, Integer,
               description: "The program scheduling priority value in the range -20 to 20."

      property :on_demand, [ TrueClass, FalseClass ],
               description: "Keep a job alive. Only applies to macOS version 10.4 (and earlier); use keep_alive instead for newer versions."

      property :process_type, String,
               description: "The intended purpose of the job: Adaptive, Background, Interactive, or Standard."

      property :program, String,
               description: "The first argument of execvp, typically the file name associated with the file to be executed. This value must be specified if program_arguments is not specified, and vice-versa."

      property :program_arguments, Array,
               description: "The second argument of execvp. If program is not specified, this property must be specified and will be handled as if it were the first argument."

      property :queue_directories, Array,
               description: "An array of non-empty directories which, if any are modified, will cause a job to be started."

      property :root_directory, String,
               description: "chroot to this directory, and then run the job."

      property :run_at_load, [ TrueClass, FalseClass ],
               description: "Launch a job once (at the time it is loaded)."

      property :sockets, Hash,
               description: "A Hash of on-demand sockets that notify launchd when a job should be run."

      property :soft_resource_limits, Array,
               description: "A Hash of resource limits to be imposed on a job."

      property :standard_error_path, String,
               description: "The file to which standard error (stderr) is sent."

      property :standard_in_path, String,
               description: "The file to which standard input (stdin) is sent."

      property :standard_out_path, String,
               description: "The file to which standard output (stdout) is sent."

      property :start_interval, Integer,
               description: "The frequency (in seconds) at which a job is started."

      property :start_on_mount, [ TrueClass, FalseClass ],
               description: "Start a job every time a file system is mounted."

      property :throttle_interval, Integer,
               description: "The frequency (in seconds) at which jobs are allowed to spawn."

      property :time_out, Integer,
               description: "The amount of time (in seconds) a job may be idle before it times out. If no value is specified, the default timeout value for launchd will be used."

      property :umask, Integer,
               description: "A decimal value to pass to umask before running a job."

      property :username, String,
               description: "When launchd is run as the root user, the user to run the job as."

      property :wait_for_debugger, [ TrueClass, FalseClass ],
               description: "Specify if launchd has a job wait for a debugger to attach before executing code."

      property :watch_paths, Array,
               description: "An array of paths which, if any are modified, will cause a job to be started."

      property :working_directory, String,
               description: "Chdir to this directory, and then run the job."
    end
  end
end
