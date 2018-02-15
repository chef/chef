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
    # Use the windows_task resource to create, delete or run a Windows scheduled task. Requires Windows Server 2008
    # or later due to API usage.
    # @since 13.0
    class WindowsTask < Chef::Resource

      resource_name :windows_task
      provides :windows_task, os: "windows"

      allowed_actions :create, :delete, :run, :end, :enable, :disable
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
                                      :none], default: :hourly
      property :start_day, String
      property :start_time, String
      property :day, [String, Integer]
      property :months, String
      property :idle_time, Integer
      property :random_delay, [String, Integer]
      property :execution_time_limit, [String, Integer], default: "PT72H" # 72 hours in ISO8601 duration format

      attr_accessor :exists, :status, :enabled

      def after_created
        if random_delay
          validate_random_delay(random_delay, frequency)
          duration = sec_to_dur(random_delay)
          random_delay(duration)
        end

        if execution_time_limit
          unless execution_time_limit == "PT72H" # don't double convert an ISO8601 format duration
            raise ArgumentError, "Invalid value passed for `execution_time_limit`. Please pass seconds as an Integer (e.g. 60) or a String with numeric values only (e.g. '60')." unless numeric_value_in_string?(execution_time_limit)
            duration = sec_to_dur(execution_time_limit)
            execution_time_limit(duration)
          end
        end

        validate_start_time(start_time, frequency)
        validate_start_day(start_day, frequency) if start_day
        validate_user_and_password(user, password)
        validate_interactive_setting(interactive_enabled, password)
        validate_create_frequency_modifier(frequency, frequency_modifier)
        validate_create_day(day, frequency) if day
        validate_create_months(months, frequency) if months
        validate_idle_time(idle_time, frequency)
      end

      private

      # Validate the passed value is numeric values only if it is a string
      def numeric_value_in_string?(val)
        return true if Integer(val)
      rescue ArgumentError
        false
      end

      def validate_random_delay(random_delay, frequency)
        if [:once, :on_logon, :onstart, :on_idle, :none].include? frequency
          raise ArgumentError, "`random_delay` property is supported only for frequency :minute, :hourly, :daily, :weekly and :monthly"
        end

        raise ArgumentError, "Invalid value passed for `random_delay`. Please pass seconds as an Integer (e.g. 60) or a String with numeric values only (e.g. '60')." unless numeric_value_in_string?(random_delay)
      end

      # @todo when we drop ruby 2.3 support this should be converted to .match?() instead of =~f
      def validate_start_day(start_day, frequency)
        if [:once, :on_logon, :onstart, :on_idle, :none].include? frequency
          raise ArgumentError, "`start_day` property is not supported with frequency: #{frequency}"
        end

        # make sure the start_day is in MM/DD/YYYY format: http://rubular.com/r/cgjHemtWl5
        raise ArgumentError, "`start_day` property must be in the MM/DD/YYYY format." unless /^(0[1-9]|1[012])[- \/.](0[1-9]|[12][0-9]|3[01])[- \/.](19|20)\d\d$/ =~ start_day
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

      SYSTEM_USERS = ['NT AUTHORITY\SYSTEM', "SYSTEM", 'NT AUTHORITY\LOCALSERVICE', 'NT AUTHORITY\NETWORKSERVICE', 'BUILTIN\USERS', "USERS"].freeze

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
        if interactive_enabled && password.nil?
          raise ArgumentError, "Please provide the password when attempting to set interactive/non-interactive."
        end
      end

      def validate_create_frequency_modifier(frequency, frequency_modifier)
        # Currently is handled in create action 'frequency_modifier_allowed' line. Does not allow for frequency_modifier for once,onstart,onlogon,onidle,none
        # Note that 'OnEvent' is not a supported frequency.
        unless frequency.nil? || frequency_modifier.nil?
          case frequency
          when :minute
            unless frequency_modifier.to_i > 0 && frequency_modifier.to_i <= 1439
              raise ArgumentError, "frequency_modifier value #{frequency_modifier} is invalid. Valid values for :minute frequency are 1 - 1439."
            end
          when :hourly
            unless frequency_modifier.to_i > 0 && frequency_modifier.to_i <= 23
              raise ArgumentError, "frequency_modifier value #{frequency_modifier} is invalid. Valid values for :hourly frequency are 1 - 23."
            end
          when :daily
            unless frequency_modifier.to_i > 0 && frequency_modifier.to_i <= 365
              raise ArgumentError, "frequency_modifier value #{frequency_modifier} is invalid. Valid values for :daily frequency are 1 - 365."
            end
          when :weekly
            unless frequency_modifier.to_i > 0 && frequency_modifier.to_i <= 52
              raise ArgumentError, "frequency_modifier value #{frequency_modifier} is invalid. Valid values for :weekly frequency are 1 - 52."
            end
          when :monthly
            unless ("1".."12").to_a.push("FIRST", "SECOND", "THIRD", "FOURTH", "LAST", "LASTDAY").include?(frequency_modifier.to_s.upcase)
              raise ArgumentError, "frequency_modifier value #{frequency_modifier} is invalid. Valid values for :monthly frequency are 1 - 12, 'FIRST', 'SECOND', 'THIRD', 'FOURTH', 'LAST', 'LASTDAY'."
            end
          end
        end
      end

      def validate_create_day(day, frequency)
        unless [:weekly, :monthly].include?(frequency)
          raise "day property is only valid for tasks that run monthly or weekly"
        end
        if day.is_a?(String) && day.to_i.to_s != day
          days = day.split(",")
          days.each do |d|
            unless ["mon", "tue", "wed", "thu", "fri", "sat", "sun", "*"].include?(d.strip.downcase)
              raise ArgumentError, "day property invalid. Only valid values are: MON, TUE, WED, THU, FRI, SAT, SUN and *. Multiple values must be separated by a comma."
            end
          end
        end
      end

      def validate_create_months(months, frequency)
        raise ArgumentError, "months property is only valid for tasks that run monthly" unless frequency == :monthly
        if months.is_a? String
          months.split(",").each do |month|
            unless ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC", "*"].include?(month.strip.upcase)
              raise ArgumentError, "months property invalid. Only valid values are: JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC and *. Multiple values must be separated by a comma."
            end
          end
        end
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

    end
  end
end
