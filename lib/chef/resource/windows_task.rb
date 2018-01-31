#
# Author:: Nimisha Sharad (<nimisha.sharad@msystechnologies.com>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

class Chef
  class Resource
    class WindowsTask < Chef::Resource
      resource_name :windows_task
      provides(:windows_task) { true }

      description "Use the windows_task resource to create, delete or run a Windows"\
                  " scheduled task. Requires Windows Server 2008 or later due to API usage."
      introduced "13.0"

      allowed_actions :create, :delete, :run, :end, :enable, :disable, :change
      default_action :create

      property :task_name, String, regex: [/\A[^\/\:\*\?\<\>\|]+\z/], name_property: true
      property :command, String
      property :cwd, String
      property :user, String, default: "SYSTEM"
      property :password, String
      property :run_level, equal_to: [:highest, :limited], default: :limited
      property :force, [TrueClass, FalseClass], default: false
      property :interactive_enabled, [TrueClass, FalseClass], default: false
      property :frequency_modifier, [Integer, String], default: 1
      property :frequency, equal_to: [:minute,
                                      :hourly,
                                      :daily,
                                      :weekly,
                                      :monthly,
                                      :once,
                                      :on_logon,
                                      :onstart,
                                      :on_idle,
                                      :none]
      property :start_day, String
      property :start_time, String
      property :day, [String, Integer]
      property :months, String
      property :idle_time, Integer
      property :random_delay, [String, Integer]
      property :execution_time_limit, [String, Integer], default: "PT72H" # 72 hours in ISO8601 duration format
      property :minutes_duration, [String, Integer]
      property :minutes_interval, [String, Integer]

      attr_accessor :exists, :task

      SYSTEM_USERS = ['NT AUTHORITY\SYSTEM', "SYSTEM", 'NT AUTHORITY\LOCALSERVICE', 'NT AUTHORITY\NETWORKSERVICE', 'BUILTIN\USERS', "USERS"].freeze
      VALID_WEEK_DAYS = %w{ mon tue wed thu fri sat sun * }
      VALID_DAYS_OF_MONTH = ("1".."31").to_a << "last" << "lastday"
      VALID_MONTHS = %w{JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC *}
      VALID_WEEKS = %w{FIRST SECOND THIRD FOURTH LAST LASTDAY}

      def after_created
        if random_delay
          validate_random_delay(random_delay, frequency)
          random_delay(sec_to_min(random_delay))
        end

        if execution_time_limit
          execution_time_limit(259200) if execution_time_limit == "PT72H"
          raise ArgumentError, "Invalid value passed for `execution_time_limit`. Please pass seconds as an Integer (e.g. 60) or a String with numeric values only (e.g. '60')." unless numeric_value_in_string?(execution_time_limit)
          execution_time_limit(sec_to_min(execution_time_limit))
        end

        # Removed the default value :hourly for frequency in Chef 14 following code added for backward compatibility
        chef_version = ::Chef::VERSION.split(".")
        if chef_version[0].to_i > 13 || (chef_version[0].to_i >= 0)
          validate_frequency(frequency) if action.include?(:create) || action.include?(:change)
        else
          frequency(:hourly) if frequency.nil?
        end
        validate_start_time(start_time, frequency)
        validate_start_day(start_day, frequency) if start_day
        validate_user_and_password(user, password)
        validate_interactive_setting(interactive_enabled, password)
        validate_create_frequency_modifier(frequency, frequency_modifier) if frequency_modifier
        validate_create_day(day, frequency, frequency_modifier) if day
        validate_create_months(months, frequency) if months
        validate_frequency_monthly(frequency_modifier, months, day) if frequency == :monthly
        validate_idle_time(idle_time, frequency)
        idempotency_warning_for_frequency_weekly(day, start_day) if frequency == :weekly
      end

      private

      ## Resource is not idempotent when day, start_day is not provided with frequency :weekly
      ## we set start_day when not given by user as current date based on which we set the day property for current current date day is monday ..
      ## we set the monday as the day so at next run when  new_resource.day is nil and current_resource day is monday due to which udpate gets called
      def idempotency_warning_for_frequency_weekly(day, start_day)
        if start_day.nil? && day.nil?
          logger.warn "To maintain idempotency for frequency :weekly provide start_day, start_time and day."
        end
      end

      # Validate the passed value is numeric values only if it is a string
      def numeric_value_in_string?(val)
        return true if Integer(val)
      rescue ArgumentError
        false
      end

      def validate_frequency(frequency)
        if frequency.nil? || !([:minute, :hourly, :daily, :weekly, :monthly, :once, :on_logon, :onstart, :on_idle, :none].include?(frequency))
          raise ArgumentError, "Frequency needs to be provided. Valid frequencies are :minute, :hourly, :daily, :weekly, :monthly, :once, :on_logon, :onstart, :on_idle, :none."
        end
      end

      def validate_frequency_monthly(frequency_modifier, months, day)
        # validates the frequency :monthly and raises error if frequency_modifier is first, second, thrid etc and day is not provided
        if (frequency_modifier != 1) && (frequency_modifier_includes_days_of_weeks?(frequency_modifier)) && !(day)
          raise ArgumentError, "Please select day on which you want to run the task e.g. 'Mon, Tue'. Multiple values must be seprated by comma."
        end

        # frequency_modifer 2-12 is used to set every (n) months, so using :months propety with frequency_modifer is not valid since they both used to set months.
        # Not checking value 1 here for frequecy_modifier since we are setting that as default value it won't break anything since preference is given to months property
        if (frequency_modifier.to_i.between?(2, 12)) && !(months.nil?)
          raise ArgumentError, "For frequency :monthly either use property months or frequency_modifier to set months."
        end
      end

      # returns true if frequency_modifer has values First, second, third, fourth, last, lastday
      def frequency_modifier_includes_days_of_weeks?(frequency_modifier)
        frequency_modifier = frequency_modifier.to_s.split(",")
        frequency_modifier.map! { |value| value.strip.upcase }
        (frequency_modifier - VALID_WEEKS).empty?
      end

      def validate_random_delay(random_delay, frequency)
        if [:on_logon, :onstart, :on_idle, :none].include? frequency
          raise ArgumentError, "`random_delay` property is supported only for frequency :once, :minute, :hourly, :daily, :weekly and :monthly"
        end

        raise ArgumentError, "Invalid value passed for `random_delay`. Please pass seconds as an Integer (e.g. 60) or a String with numeric values only (e.g. '60')." unless numeric_value_in_string?(random_delay)
      end

      # @todo when we drop ruby 2.3 support this should be converted to .match?() instead of =~f
      def validate_start_day(start_day, frequency)
        if start_day && frequency == :none
          raise ArgumentError, "`start_day` property is not supported with frequency: #{frequency}"
        end

        # make sure the start_day is in MM/DD/YYYY format: http://rubular.com/r/cgjHemtWl5
        if start_day
          raise ArgumentError, "`start_day` property must be in the MM/DD/YYYY format." unless /^(0[1-9]|1[012])[- \/.](0[1-9]|[12][0-9]|3[01])[- \/.](19|20)\d\d$/ =~ start_day
        end
      end

      # @todo when we drop ruby 2.3 support this should be converted to .match?() instead of =~
      def validate_start_time(start_time, frequency)
        if start_time
          raise ArgumentError, "`start_time` property is not supported with `frequency :none`" if frequency == :none
          raise ArgumentError, "`start_time` property must be in the HH:mm format (e.g. 6:20pm -> 18:20)." unless /^[0-2][0-9]:[0-5][0-9]$/ =~ start_time
        else
          raise ArgumentError, "`start_time` needs to be provided with `frequency :once`" if frequency == :once
        end
      end

      def validate_user_and_password(user, password)
        if password_required?(user) && password.nil?
          raise ArgumentError, %q{Cannot specify a user other than the system users without specifying a password!. Valid passwordless users: 'NT AUTHORITY\SYSTEM', 'SYSTEM', 'NT AUTHORITY\LOCALSERVICE', 'NT AUTHORITY\NETWORKSERVICE', 'BUILTIN\USERS', 'USERS'}
        end
      end

      def password_required?(user)
        return false if user.nil?
        @password_required ||= !SYSTEM_USERS.include?(user.upcase)
      end

      def validate_interactive_setting(interactive_enabled, password)
        raise ArgumentError, "Please provide the password when attempting to set interactive/non-interactive." if interactive_enabled && password.nil?
      end

      def validate_create_frequency_modifier(frequency, frequency_modifier)
        if ([:on_logon, :onstart, :on_idle, :none].include?(frequency)) && ( frequency_modifier != 1)
          raise ArgumentError, "frequency_modifier property not supported with frequency :#{frequency}"
        end

        if frequency == :monthly
          unless (1..12).cover?(frequency_modifier.to_i) || frequency_modifier_includes_days_of_weeks?(frequency_modifier)
            raise ArgumentError, "frequency_modifier value #{frequency_modifier} is invalid. Valid values for :monthly frequency are 1 - 12, 'FIRST', 'SECOND', 'THIRD', 'FOURTH', 'LAST'."
          end
        else
          unless frequency.nil? || frequency_modifier.nil?
            frequency_modifier = frequency_modifier.to_i
            min = 1
            max = case frequency
                    when :minute
                      1439
                    when :hourly
                      23
                    when :daily
                      365
                    when :weekly
                      52
                    else
                      min
                  end
            unless frequency_modifier.between?(min, max)
              raise ArgumentError, "frequency_modifier value #{frequency_modifier} is invalid. Valid values for :#{frequency} frequency are #{min} - #{max}."
            end
          end
        end
      end

      def validate_create_day(day, frequency, frequency_modifier)
        raise ArgumentError, "day property is only valid for tasks that run monthly or weekly" unless [:weekly, :monthly].include?(frequency)

        # This has been verified with schtask.exe https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/schtasks#d-dayday--
        # verified with earlier code if day "*" is given with frequency it raised exception Invalid value for /D option
        raise ArgumentError, "day wild card (*) is only valid with frequency :weekly" if frequency == :monthly && day == "*"

        if day.is_a?(String) && day.to_i.to_s != day
          days = day.split(",")
          if days_includes_days_of_months?(days)
            # Following error will be raise if day is set as 1-31 and frequency is selected as :weekly since those values are valid with only frequency :monthly
            raise ArgumentError, "day values 1-31 or last is only valid with frequency :monthly" if frequency == :weekly
          else
            days.map! { |day| day.to_s.strip.downcase }
            unless (days - VALID_WEEK_DAYS).empty?
              raise ArgumentError, "day property invalid. Only valid values are: #{VALID_WEEK_DAYS.map(&:upcase).join(', ')}. Multiple values must be separated by a comma."
            end
          end
        end
      end

      def validate_create_months(months, frequency)
        raise ArgumentError, "months property is only valid for tasks that run monthly" if frequency != :monthly
        if months.is_a?(String)
          months = months.split(",")
          months.map! { |month| month.strip.upcase }
          unless (months - VALID_MONTHS).empty?
            raise ArgumentError, "months property invalid. Only valid values are: #{VALID_MONTHS.join(', ')}. Multiple values must be separated by a comma."
          end
        end
      end

      # This method returns true if day has values from 1-31 which is a days of moths and used with frequency :monthly
      def days_includes_days_of_months?(days)
        days.map! { |day| day.to_s.strip.downcase }
        (days - VALID_DAYS_OF_MONTH).empty?
      end

      def validate_idle_time(idle_time, frequency)
        if !idle_time.nil? && frequency != :on_idle
          raise ArgumentError, "idle_time property is only valid for tasks that run on_idle"
        end
        if idle_time.nil? && frequency == :on_idle
          raise ArgumentError, "idle_time value should be set for :on_idle frequency."
        end
        unless idle_time.nil? || idle_time > 0 && idle_time <= 999
          raise ArgumentError, "idle_time value #{idle_time} is invalid. Valid values for :on_idle frequency are 1 - 999."
        end
      end

      # Converts the number of seconds to an ISO8601 duration format and returns it.
      # Ref : https://github.com/arnau/ISO8601/blob/master/lib/iso8601/duration.rb#L18-L23
      # e.g.
      # ISO8601::Duration.new(65707200)
      # returns 'P65707200S'
      def sec_to_dur(seconds)
        ISO8601::Duration.new(seconds.to_i).to_s
      end

      def sec_to_min(seconds)
        seconds.to_i / 60
      end
    end
  end
end
