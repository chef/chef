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

      allowed_actions :create, :delete, :run, :end, :change, :enable, :disable
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
      property :user, String, default: 'SYSTEM'
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
                                       :on_idle], default: :hourly
      property :start_day, String
      property :start_time, String
      property :day, [String, Integer]
      property :months, String
      property :idle_time, Integer
      property :random_delay, String
      property :execution_time_limit, String

      attr_accessor :exists, :status, :enabled

      def after_created
        validate_random_delay(random_delay, frequency) if random_delay
        validate_start_day(start_day, frequency) if start_day
        validate_user_and_password(user,password)
        validate_interactive_setting(interactive_enabled, password)
        validate_create_frequency_modifier(frequency, frequency_modifier)
        validate_create_day(day, frequency) if day
        validate_create_months(months, frequency) if months
        validate_idle_time(idle_time) if frequency == :on_idle
      end

      private

      def validate_random_delay(random_delay, frequency)
        if [:once, :on_logon, :onstart, :on_idle].include? frequency
          raise ArgumentError, "`start_day` property is not supported with frequency: #{frequency}"
        end
      end

      def validate_start_day(start_day, frequency)
        if [:once, :on_logon, :onstart, :on_idle].include? frequency
          raise ArgumentError, "`start_day` property is not supported with frequency: #{frequency}"
        end
      end

      SYSTEM_USERS = ['NT AUTHORITY\SYSTEM', 'SYSTEM', 'NT AUTHORITY\LOCALSERVICE', 'NT AUTHORITY\NETWORKSERVICE'].freeze

      def validate_user_and_password(user,password)
        if user && use_password?(user)
          if password.nil?
            raise ArgumentError, "Can't specify a non-system user without a password!"
          end
        end
      end

      def use_password?(user)
        @use_password ||= !SYSTEM_USERS.include?(user.upcase)
      end

      def validate_interactive_setting(interactive_enabled, password)
        if interactive_enabled && password.nil?
          raise ArgumentError, "Please provide the password when attempting to set interactive/non-interactive."
        end
      end

      def validate_create_frequency_modifier(frequency, frequency_modifier)
        # Currently is handled in create action 'frequency_modifier_allowed' line. Does not allow for frequency_modifier for once,onstart,onlogon,onidle
        # Note that 'OnEvent' is not a supported frequency.
        unless frequency.nil? || frequency_modifier.nil?
          case frequency
          when :minute
            unless frequency_modifier.to_i > 0 && frequency_modifier.to_i <= 1439
              raise ArgumentError, "frequency_modifier value #{frequency_modifier} is invalid.  Valid values for :minute frequency are 1 - 1439."
            end
          when :hourly
            unless frequency_modifier.to_i > 0 && frequency_modifier.to_i <= 23
              raise ArgumentError, "frequency_modifier value #{frequency_modifier} is invalid.  Valid values for :hourly frequency are 1 - 23."
            end
          when :daily
            unless frequency_modifier.to_i > 0 && frequency_modifier.to_i <= 365
              raise ArgumentError, "frequency_modifier value #{frequency_modifier} is invalid.  Valid values for :daily frequency are 1 - 365."
            end
          when :weekly
            unless frequency_modifier.to_i > 0 && frequency_modifier.to_i <= 52
              raise ArgumentError, "frequency_modifier value #{frequency_modifier} is invalid.  Valid values for :weekly frequency are 1 - 52."
            end
          when :monthly
            unless ('1'..'12').to_a.push('FIRST', 'SECOND', 'THIRD', 'FOURTH', 'LAST', 'LASTDAY').include?(frequency_modifier.to_s.upcase)
              raise ArgumentError, "frequency_modifier value #{frequency_modifier} is invalid.  Valid values for :monthly frequency are 1 - 12, 'FIRST', 'SECOND', 'THIRD', 'FOURTH', 'LAST', 'LASTDAY'."
            end
          end
        end
      end

      def validate_create_day(day, frequency)
        unless [:weekly, :monthly].include?(frequency)
          raise 'day attribute is only valid for tasks that run weekly or monthly'
        end
        if day.is_a?(String) && day.to_i.to_s != day
          days = day.split(',')
          days.each do |d|
            unless ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun', '*'].include?(d.strip.downcase)
              raise 'day attribute invalid.  Only valid values are: MON, TUE, WED, THU, FRI, SAT, SUN and *.  Multiple values must be separated by a comma.'
            end
          end
        end
      end

      def validate_create_months(months, frequency)
        unless [:monthly].include?(frequency)
          raise 'months attribute is only valid for tasks that run monthly'
        end
        if months.is_a? String
          months.split(',').each do |month|
            unless ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC', '*'].include?(month.strip.upcase)
              raise 'months attribute invalid. Only valid values are: JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC and *. Multiple values must be separated by a comma.'
            end
          end
        end
      end

      def validate_idle_time(idle_time)
        unless idle_time.to_i > 0 && idle_time.to_i <= 999
          raise "idle_time value #{idle_time} is invalid.  Valid values for :on_idle frequency are 1 - 999."
        end
      end

    end
  end
end
