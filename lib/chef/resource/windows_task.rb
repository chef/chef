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

      provides :windows_task, os: "windows"

      allowed_actions :create, :delete, :run, :end, :enable, :disable
      default_action :create

      def initialize(name, run_context = nil)
        super
        @resource_name = :windows_task
        @task_name = name
        @action = :create
      end

      property :task_name, String, regex: [/\A[^\/\:\*\?\<\>\|]+\z/]
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
      property :execution_time_limit, [String, Integer], default: "PT72H" # 72 hours in ISO08601 duration format

      attr_accessor :exists, :status, :enabled

      def after_created
        if random_delay
          validate_random_delay(random_delay, frequency)
          duration = sec_to_dur(random_delay)
          random_delay(duration)
        end

        if execution_time_limit
          unless execution_time_limit == "PT72H" # don't double convert an iso08601 format duration
            raise ArgumentError, "Invalid value passed for `execution_time_limit`. Please pass seconds an Integer or a String with numeric values only e.g. '60'." unless numeric_value_in_string?(execution_time_limit)
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
        validate_idle_time(idle_time, frequency) if idle_time
      end

      private

      # Validate the passed value is numeric values only if it is a string
      def numeric_value_in_string?(val)
        return false if val.is_a?(String) && /\D/ =~ val # \D is any non-numeric value
        true
      end

      def validate_random_delay(random_delay, frequency)
        if [:once, :on_logon, :onstart, :on_idle, :none].include? frequency
          raise ArgumentError, "`random_delay` property is supported only for frequency :minute, :hourly, :daily, :weekly and :monthly"
        end

        raise ArgumentError, "Invalid value passed for `random_delay`. Please pass seconds an Integer or a String with numeric values only e.g. '60'." unless numeric_value_in_string?(random_delay)
      end

      def validate_start_day(start_day, frequency)
        if [:once, :on_logon, :onstart, :on_idle, :none].include? frequency
          raise ArgumentError, "`start_day` property is not supported with frequency: #{frequency}"
        end
      end

      def validate_start_time(start_time, frequency)
        if start_time
          raise ArgumentError, "`start_time` property is not supported with `frequency :none`" if frequency == :none
          raise ArgumentError, "`start_time` property must be in the HH:mm format." unless /^[0-2][0-3]:[0-5][0-9]$/ =~ start_time
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
              raise "day property invalid. Only valid values are: MON, TUE, WED, THU, FRI, SAT, SUN and *. Multiple values must be separated by a comma."
            end
          end
        end
      end

      def validate_create_months(months, frequency)
        unless [:monthly].include?(frequency)
          raise "months property is only valid for tasks that run monthly"
        end
        if months.is_a? String
          months.split(",").each do |month|
            unless ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC", "*"].include?(month.strip.upcase)
              raise "months property invalid. Only valid values are: JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC and *. Multiple values must be separated by a comma."
            end
          end
        end
      end

      def validate_idle_time(idle_time, frequency)
        unless [:on_idle].include?(frequency)
          raise "idle_time property is only valid for tasks that run on_idle"
        end

        unless idle_time > 0 && idle_time <= 999
          raise "idle_time value #{idle_time} is invalid. Valid values for :on_idle frequency are 1 - 999."
        end
      end

      # Convert the number of seconds to an ISO8601 duration format
      # @see http://tools.ietf.org/html/rfc2445#section-4.3.6
      # @param [Integer] seconds The amount of seconds for this duration
      def sec_to_dur(seconds)
        seconds = seconds.to_i
        return if seconds == 0
        iso_str = "P"
        if seconds > 604_800 # more than a week
          weeks = seconds / 604_800
          seconds -= (604_800 * weeks)
          iso_str << "#{weeks}W"
        end
        if seconds > 86_400 # more than a day
          days = seconds / 86_400
          seconds -= (86_400 * days)
          iso_str << "#{days}D"
        end
        if seconds > 0
          iso_str << "T"
          if seconds > 3600 # more than an hour
            hours = seconds / 3600
            seconds -= (3600 * hours)
            iso_str << "#{hours}H"
          end
          if seconds > 60 # more than a minute
            minutes = seconds / 60
            seconds -= (60 * minutes)
            iso_str << "#{minutes}M"
          end
          iso_str << "#{seconds}S"
        end

        iso_str
      end

    end
  end
end
