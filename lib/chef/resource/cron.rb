#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2009-2016, Bryan McLellan
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
require_relative "helpers/cron_validations"
require_relative "../provider/cron" # do not remove. we actually need this below

class Chef
  class Resource
    class Cron < Chef::Resource
      unified_mode true
      provides :cron

      description "Use the **cron** resource to manage cron entries for time-based job scheduling. Properties for a schedule will default to * if not provided. The cron resource requires access to a crontab program, typically cron."

      state_attrs :minute, :hour, :day, :month, :weekday, :user

      default_action :create
      allowed_actions :create, :delete

      def initialize(name, run_context = nil)
        super
        @month = "*"
        @weekday = "*"
      end

      property :minute, [Integer, String],
        description: "The minute at which the cron entry should run (`0 - 59`).",
        default: "*", callbacks: {
          "should be a valid minute spec" => ->(spec) { Chef::ResourceHelpers::CronValidations.validate_numeric(spec, 0, 59) },
        }

      property :hour, [Integer, String],
        description: "The hour at which the cron entry is to run (`0 - 23`).",
        default: "*", callbacks: {
          "should be a valid hour spec" => ->(spec) { Chef::ResourceHelpers::CronValidations.validate_numeric(spec, 0, 23) },
        }

      property :day, [Integer, String],
        description: "The day of month at which the cron entry should run (`1 - 31`).",
        default: "*", callbacks: {
          "should be a valid day spec" => ->(spec) { Chef::ResourceHelpers::CronValidations.validate_numeric(spec, 1, 31) },
        }

      property :month, [Integer, String],
        description: "The month in the year on which a cron entry is to run (`1 - 12`, `jan-dec`, or `*`).",
        default: "*", callbacks: {
          "should be a valid month spec" => ->(spec) { Chef::ResourceHelpers::CronValidations.validate_month(spec) },
        }

      def weekday(arg = nil)
        if arg.is_a?(Integer)
          converted_arg = arg.to_s
        else
          converted_arg = arg
        end
        begin
          error_message = "You provided '#{arg}' as a weekday, acceptable values are "
          error_message << Provider::Cron::WEEKDAY_SYMBOLS.map { |sym| ":#{sym}" }.join(", ")
          error_message << " and a string in crontab format"
          if (arg.is_a?(Symbol) && !Provider::Cron::WEEKDAY_SYMBOLS.include?(arg)) ||
              (!arg.is_a?(Symbol) && integerize(arg) > 7) ||
              (!arg.is_a?(Symbol) && integerize(arg) < 0)
            raise RangeError, error_message
          end
        rescue ArgumentError
        end
        set_or_return(
          :weekday,
          converted_arg,
          kind_of: [String, Symbol]
        )
      end

      property :time, Symbol,
        description: "A time interval.",
        equal_to: Chef::Provider::Cron::SPECIAL_TIME_VALUES

      property :mailto, String,
        description: "Set the `MAILTO` environment variable."

      property :path, String,
        description: "Set the `PATH` environment variable."

      property :home, String,
        description: "Set the `HOME` environment variable."

      property :shell, String,
        description: "Set the `SHELL` environment variable."

      property :command, String,
        description: "The command to be run, or the path to a file that contains the command to be run.",
        identity: true

      property :user, String,
        description: "The name of the user that runs the command. If the user property is changed, the original user for the crontab program continues to run until that crontab program is deleted. This property is not applicable on the AIX platform.",
        default: "root"

      property :environment, Hash,
        description: "A Hash containing additional arbitrary environment variables under which the cron job will be run in the form of `({'ENV_VARIABLE' => 'VALUE'})`.",
        default: lazy { {} }

      TIMEOUT_OPTS = %w{duration preserve-status foreground kill-after signal}.freeze
      TIMEOUT_REGEX = /\A\S+/.freeze

      property :time_out, Hash,
        description: "A Hash of timeouts in the form of `({'OPTION' => 'VALUE'})`.
        Accepted valid options are:
        `preserve-status` (BOOL, default: 'false'),
        `foreground` (BOOL, default: 'false'),
        `kill-after` (in seconds),
        `signal` (a name like 'HUP' or a number)",
        default: lazy { {} },
        introduced: "15.7",
        coerce: proc { |h|
          if h.is_a?(Hash)
            invalid_keys = h.keys - TIMEOUT_OPTS
            unless invalid_keys.empty?
              error_msg = "Key of option time_out must be equal to one of: \"#{TIMEOUT_OPTS.join('", "')}\"!  You passed \"#{invalid_keys.join(", ")}\"."
              raise Chef::Exceptions::ValidationFailed, error_msg
            end
            unless h.values.all? { |x| x =~ TIMEOUT_REGEX }
              error_msg = "Values of option time_out should be non-empty string without any leading whitespaces."
              raise Chef::Exceptions::ValidationFailed, error_msg
            end
            h
          elsif h.is_a?(Integer) || h.is_a?(String)
            { "duration" => h }
          end
        }

      private

      def integerize(integerish)
        Integer(integerish)
      rescue TypeError
        0
      end
    end
  end
end
