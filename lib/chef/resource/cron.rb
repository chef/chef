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
require_relative "../provider/cron" # do not remove. we actually need this below

class Chef
  class Resource
    class Cron < Chef::Resource
      resource_name :cron
      provides :cron

      description "Use the cron resource to manage cron entries for time-based job scheduling. Properties for a schedule will default to * if not provided. The cron resource requires access to a crontab program, typically cron."

      state_attrs :minute, :hour, :day, :month, :weekday, :user

      default_action :create
      allowed_actions :create, :delete

      def initialize(name, run_context = nil)
        super
        @minute = "*"
        @hour = "*"
        @day = "*"
        @month = "*"
        @weekday = "*"
      end

      def minute(arg = nil)
        if arg.is_a?(Integer)
          converted_arg = arg.to_s
        else
          converted_arg = arg
        end
        begin
          if integerize(arg) > 59 then raise RangeError end
        rescue ArgumentError
        end
        set_or_return(
          :minute,
          converted_arg,
          kind_of: String
        )
      end

      def hour(arg = nil)
        if arg.is_a?(Integer)
          converted_arg = arg.to_s
        else
          converted_arg = arg
        end
        begin
          if integerize(arg) > 23 then raise RangeError end
        rescue ArgumentError
        end
        set_or_return(
          :hour,
          converted_arg,
          kind_of: String
        )
      end

      def day(arg = nil)
        if arg.is_a?(Integer)
          converted_arg = arg.to_s
        else
          converted_arg = arg
        end
        begin
          if integerize(arg) > 31 then raise RangeError end
        rescue ArgumentError
        end
        set_or_return(
          :day,
          converted_arg,
          kind_of: String
        )
      end

      def month(arg = nil)
        if arg.is_a?(Integer)
          converted_arg = arg.to_s
        else
          converted_arg = arg
        end
        begin
          if integerize(arg) > 12 then raise RangeError end
        rescue ArgumentError
        end
        set_or_return(
          :month,
          converted_arg,
          kind_of: String
        )
      end

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
               description: "A time interval. Possible values: :annually, :daily, :hourly, :midnight, :monthly, :reboot, :weekly, or :yearly.",
               equal_to: Chef::Provider::Cron::SPECIAL_TIME_VALUES

      property :mailto, String,
               description: "Set the MAILTO environment variable."

      property :path, String,
               description: "Set the PATH environment variable."

      property :home, String,
               description: "Set the HOME environment variable."

      property :shell, String,
               description: "Set the SHELL environment variable."

      property :command, String,
               description: "The command to be run, or the path to a file that contains the command to be run.",
               identity: true

      property :user, String,
               description: "The name of the user that runs the command. If the user property is changed, the original user for the crontab program continues to run until that crontab program is deleted. This property is not applicable on the AIX platform.",
               default: "root"

      property :environment, Hash,
               description: "A Hash of environment variables in the form of ({'ENV_VARIABLE' => 'VALUE'}).",
               default: lazy { Hash.new }

      private

      def integerize(integerish)
        Integer(integerish)
      rescue TypeError
        0
      end
    end
  end
end
