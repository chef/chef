#
# Author:: Nimisha Sharad (<nimisha.sharad@msystechnologies.com>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require "chef-utils" unless defined?(ChefUtils::CANARY)
require_relative "../resource"
require_relative "../win32/security" if ChefUtils.windows_ruby?
autoload :ISO8601, "iso8601" if ChefUtils.windows_ruby?
require_relative "../util/path_helper"
require_relative "../util/backup"
require "win32/taskscheduler" if ChefUtils.windows_ruby?

class Chef
  class Resource
    class WindowsTask < Chef::Resource
      unified_mode true

      provides(:windows_task) { true }

      description "Use the **windows_task** resource to create, delete or run a Windows scheduled task."
      introduced "13.0"
      examples <<~DOC
      **Create a scheduled task to run every 15 minutes as the Administrator user**:

      ```ruby
      windows_task 'chef-client' do
        user 'Administrator'
        password 'password'
        command 'chef-client'
        run_level :highest
        frequency :minute
        frequency_modifier 15
      end
      ```

      **Create a scheduled task to run every 2 days**:

      ```ruby
      windows_task 'chef-client' do
        command 'chef-client'
        run_level :highest
        frequency :daily
        frequency_modifier 2
      end
      ```

      **Create a scheduled task to run on specific days of the week**:

      ```ruby
      windows_task 'chef-client' do
        command 'chef-client'
        run_level :highest
        frequency :weekly
        day 'Mon, Thu'
      end
      ```

      **Create a scheduled task to run only once**:

      ```ruby
      windows_task 'chef-client' do
        command 'chef-client'
        run_level :highest
        frequency :once
        start_time '16:10'
      end
      ```

      **Create a scheduled task to run on current day every 3 weeks and delay upto 1 min**:

      ```ruby
      windows_task 'chef-client' do
        command 'chef-client'
        run_level :highest
        frequency :weekly
        frequency_modifier 3
        random_delay '60'
      end
      ```

      **Create a scheduled task to run weekly starting on Dec 28th 2018**:

      ```ruby
      windows_task 'chef-client 8' do
        command 'chef-client'
        run_level :highest
        frequency :weekly
        start_day '12/28/2018'
      end
      ```

      **Create a scheduled task to run every Monday, Friday every 2 weeks**:

      ```ruby
      windows_task 'chef-client' do
        command 'chef-client'
        run_level :highest
        frequency :weekly
        frequency_modifier 2
        day 'Mon, Fri'
      end
      ```

      **Create a scheduled task to run when computer is idle with idle duration 20 min**:

      ```ruby
      windows_task 'chef-client' do
        command 'chef-client'
        run_level :highest
        frequency :on_idle
        idle_time 20
      end
      ```

      **Delete a task named "old task"**:
      ```ruby
      windows_task 'old task' do
        action :delete
      end
      ```

      **Enable a task named "chef-client"**:
      ```ruby
      windows_task 'chef-client' do
        action :enable
      end
      ```

      **Disable a task named "ProgramDataUpdater" with TaskPath "\\Microsoft\\Windows\\Application Experience\\ProgramDataUpdater"**
      ```ruby
      windows_task '\\Microsoft\\Windows\\Application Experience\\ProgramDataUpdater' do
        action :disable
      end
      ```
      DOC

      allowed_actions :create, :delete, :run, :end, :enable, :disable, :change
      default_action :create

      property :task_name, String, regex: [%r{\A[^/\:\*\?\<\>\|]+\z}],
        description: "An optional property to set the task name if it differs from the resource block's name. Example: `Task Name` or `/Task Name`",
        name_property: true

      property :command, String,
        description: "The command to be executed by the windows scheduled task."

      property :cwd, String,
        description: "The directory the task will be run from."

      property :user, String,
        description: "The user to run the task as.",
        default: lazy { Chef::ReservedNames::Win32::Security::SID.LocalSystem.account_simple_name if ChefUtils.windows_ruby? },
        default_description: "The localized SYSTEM user for the node."

      property :password, String,
        description: "The user's password. The user property must be set if using this property."

      property :run_level, Symbol, equal_to: %i{highest limited},
        description: "Run with `:limited` or `:highest` privileges.",
        default: :limited

      property :force, [TrueClass, FalseClass],
        description: "When used with create, will update the task.",
        default: false

      property :interactive_enabled, [TrueClass, FalseClass],
        description: "Allow task to run interactively or non-interactively. Requires user and password to also be set.",
        default: false

      property :frequency_modifier, [Integer, String],
        default: 1

      property :frequency, Symbol, equal_to: %i{minute hourly daily weekly monthly once on_logon onstart on_idle none},
        description: "The frequency with which to run the task."

      property :start_day, String,
        description: "Specifies the first date on which the task runs in **MM/DD/YYYY** format.",
        default_description: "The current date."

      property :start_time, String,
        description: "Specifies the start time to run the task, in **HH:mm** format."

      property :day, [String, Integer],
        description: "The day(s) on which the task runs."

      property :months, String,
        description: "The Months of the year on which the task runs, such as: `JAN, FEB` or `*`. Multiple months should be comma delimited. e.g. `Jan, Feb, Mar, Dec`."

      property :idle_time, Integer,
        description: "For `:on_idle` frequency, the time (in minutes) without user activity that must pass to trigger the task, from `1` - `999`."

      property :random_delay, [String, Integer],
        description: "Delays the task up to a given time (in seconds)."

      property :execution_time_limit, [String, Integer],
        description: "The maximum time the task will run. This field accepts either seconds or an ISO8601 duration value.",
        default: "PT72H",
        default_description: "PT72H (72 hours in ISO8601 duration format)"

      property :minutes_duration, [String, Integer],
        description: ""

      property :minutes_interval, [String, Integer],
        description: ""

      property :priority, Integer,
        description: "Use to set Priority Levels range from 0 to 10.",
        default: 7, callbacks: { "should be in range of 0 to 10" => proc { |v| v >= 0 && v <= 10 } }

      property :disallow_start_if_on_batteries, [TrueClass, FalseClass],
        introduced: "14.4", default: false,
        description: "Disallow start of the task if the system is running on battery power."

      property :stop_if_going_on_batteries, [TrueClass, FalseClass],
        introduced: "14.4", default: false,
        description: "Scheduled task option when system is switching on battery."

      property :description, String,
        introduced: "14.7",
        description: "The task description."

      property :start_when_available, [TrueClass, FalseClass],
        introduced: "14.15", default: false,
        description: "To start the task at any time after its scheduled time has passed."

      property :backup, [Integer, FalseClass],
        introduced: "17.0", default: 5,
        description: "Number of backups to keep of the task when modified/deleted. Set to false to disable backups."

      attr_accessor :exists, :task, :command_arguments

      VALID_WEEK_DAYS = %w{ mon tue wed thu fri sat sun * }.freeze
      VALID_DAYS_OF_MONTH = ("1".."31").to_a << "last" << "lastday"
      VALID_MONTHS = %w{JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC *}.freeze
      VALID_WEEKS = %w{FIRST SECOND THIRD FOURTH LAST LASTDAY}.freeze

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

        validate_frequency(frequency) if action.include?(:create) || action.include?(:change)
        validate_start_time(start_time, frequency)
        validate_start_day(start_day, frequency) if start_day
        validate_user_and_password(user, password)
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
      ## we set the monday as the day so at next run when  new_resource.day is nil and current_resource day is monday due to which update gets called
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
        if frequency.nil? || !(%i{minute hourly daily weekly monthly once on_logon onstart on_idle none}.include?(frequency))
          raise ArgumentError, "Frequency needs to be provided. Valid frequencies are :minute, :hourly, :daily, :weekly, :monthly, :once, :on_logon, :onstart, :on_idle, :none."
        end
      end

      def validate_frequency_monthly(frequency_modifier, months, day)
        # validates the frequency :monthly and raises error if frequency_modifier is first, second, third etc and day is not provided
        if (frequency_modifier != 1) && (frequency_modifier_includes_days_of_weeks?(frequency_modifier)) && !(day)
          raise ArgumentError, "Please select day on which you want to run the task e.g. 'Mon, Tue'. Multiple values must be separated by comma."
        end

        # frequency_modifier 2-12 is used to set every (n) months, so using :months property with frequency_modifier is not valid since they both used to set months.
        # Not checking value 1 here for frequency_modifier since we are setting that as default value it won't break anything since preference is given to months property
        if (frequency_modifier.to_i.between?(2, 12)) && !(months.nil?)
          raise ArgumentError, "For frequency :monthly either use property months or frequency_modifier to set months."
        end
      end

      # returns true if frequency_modifier has values First, second, third, fourth, last, lastday
      def frequency_modifier_includes_days_of_weeks?(frequency_modifier)
        frequency_modifier = frequency_modifier.to_s.split(",")
        frequency_modifier.map! { |value| value.strip.upcase }
        (frequency_modifier - VALID_WEEKS).empty?
      end

      def validate_random_delay(random_delay, frequency)
        if %i{on_logon onstart on_idle none}.include? frequency
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
          raise ArgumentError, "`start_day` property must be in the MM/DD/YYYY format." unless %r{^(0[1-9]|1[012])[- /.](0[1-9]|[12][0-9]|3[01])[- /.](19|20)\d\d$}.match?(start_day)
        end
      end

      # @todo when we drop ruby 2.3 support this should be converted to .match?() instead of =~
      def validate_start_time(start_time, frequency)
        if start_time
          raise ArgumentError, "`start_time` property is not supported with `frequency :none`" if frequency == :none
          raise ArgumentError, "`start_time` property must be in the HH:mm format (e.g. 6:20pm -> 18:20)." unless /^[0-2][0-9]:[0-5][0-9]$/.match?(start_time)
        else
          raise ArgumentError, "`start_time` needs to be provided with `frequency :once`" if frequency == :once
        end
      end

      # System users will not require a password
      # Other users will require a password if the task is non-interactive.
      #
      # @param [String] user
      # @param [String] password
      #
      def validate_user_and_password(user, password)
        if non_system_user?(user)
          if password.nil? && !interactive_enabled
            raise ArgumentError, "Please provide a password or check if this task needs to be interactive! Valid passwordless users are: '#{Chef::ReservedNames::Win32::Security::SID::SYSTEM_USER.join("', '")}'"
          end
        else
          unless password.nil?
            raise ArgumentError, "Password is not required for system users."
          end
        end
      end

      # Password is not required for system user and required for non-system user.
      def password_required?(user)
        @password_required ||= (!user.nil? && !Chef::ReservedNames::Win32::Security::SID.system_user?(user))
      end

      alias non_system_user? password_required?

      def validate_create_frequency_modifier(frequency, frequency_modifier)
        if (%i{on_logon onstart on_idle none}.include?(frequency)) && ( frequency_modifier != 1)
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
        raise ArgumentError, "day property is only valid for tasks that run monthly or weekly" unless %i{weekly monthly}.include?(frequency)

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
              raise ArgumentError, "day property invalid. Only valid values are: #{VALID_WEEK_DAYS.map(&:upcase).join(", ")}. Multiple values must be separated by a comma."
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
            raise ArgumentError, "months property invalid. Only valid values are: #{VALID_MONTHS.join(", ")}. Multiple values must be separated by a comma."
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
      # ISO8601::Duration.new(65707200).to_s
      # returns 'PT65707200S'
      def sec_to_dur(seconds)
        ISO8601::Duration.new(seconds.to_i).to_s
      end

      def sec_to_min(seconds)
        seconds.to_i / 60
      end

      action_class do
        if ChefUtils.windows_ruby?
          include ::Win32

          MONTHS = {
            JAN: ::Win32::TaskScheduler::JANUARY,
            FEB: ::Win32::TaskScheduler::FEBRUARY,
            MAR: ::Win32::TaskScheduler::MARCH,
            APR: ::Win32::TaskScheduler::APRIL,
            MAY: ::Win32::TaskScheduler::MAY,
            JUN: ::Win32::TaskScheduler::JUNE,
            JUL: ::Win32::TaskScheduler::JULY,
            AUG: ::Win32::TaskScheduler::AUGUST,
            SEP: ::Win32::TaskScheduler::SEPTEMBER,
            OCT: ::Win32::TaskScheduler::OCTOBER,
            NOV: ::Win32::TaskScheduler::NOVEMBER,
            DEC: ::Win32::TaskScheduler::DECEMBER,
          }.freeze

          DAYS_OF_WEEK = { MON: ::Win32::TaskScheduler::MONDAY,
                           TUE: ::Win32::TaskScheduler::TUESDAY,
                           WED: ::Win32::TaskScheduler::WEDNESDAY,
                           THU: ::Win32::TaskScheduler::THURSDAY,
                           FRI: ::Win32::TaskScheduler::FRIDAY,
                           SAT: ::Win32::TaskScheduler::SATURDAY,
                           SUN: ::Win32::TaskScheduler::SUNDAY }.freeze

          WEEKS_OF_MONTH = {
            FIRST: ::Win32::TaskScheduler::FIRST_WEEK,
            SECOND: ::Win32::TaskScheduler::SECOND_WEEK,
            THIRD: ::Win32::TaskScheduler::THIRD_WEEK,
            FOURTH: ::Win32::TaskScheduler::FOURTH_WEEK,
          }.freeze

          DAYS_OF_MONTH = {
            1 => ::Win32::TaskScheduler::TASK_FIRST,
            2 => ::Win32::TaskScheduler::TASK_SECOND,
            3 => ::Win32::TaskScheduler::TASK_THIRD,
            4 => ::Win32::TaskScheduler::TASK_FOURTH,
            5 => ::Win32::TaskScheduler::TASK_FIFTH,
            6 => ::Win32::TaskScheduler::TASK_SIXTH,
            7 => ::Win32::TaskScheduler::TASK_SEVENTH,
            8 => ::Win32::TaskScheduler::TASK_EIGHTH,
            # cspell:disable-next-line
            9 => ::Win32::TaskScheduler::TASK_NINETH,
            10 => ::Win32::TaskScheduler::TASK_TENTH,
            11 => ::Win32::TaskScheduler::TASK_ELEVENTH,
            12 => ::Win32::TaskScheduler::TASK_TWELFTH,
            13 => ::Win32::TaskScheduler::TASK_THIRTEENTH,
            14 => ::Win32::TaskScheduler::TASK_FOURTEENTH,
            15 => ::Win32::TaskScheduler::TASK_FIFTEENTH,
            16 => ::Win32::TaskScheduler::TASK_SIXTEENTH,
            17 => ::Win32::TaskScheduler::TASK_SEVENTEENTH,
            18 => ::Win32::TaskScheduler::TASK_EIGHTEENTH,
            19 => ::Win32::TaskScheduler::TASK_NINETEENTH,
            20 => ::Win32::TaskScheduler::TASK_TWENTIETH,
            21 => ::Win32::TaskScheduler::TASK_TWENTY_FIRST,
            22 => ::Win32::TaskScheduler::TASK_TWENTY_SECOND,
            23 => ::Win32::TaskScheduler::TASK_TWENTY_THIRD,
            24 => ::Win32::TaskScheduler::TASK_TWENTY_FOURTH,
            25 => ::Win32::TaskScheduler::TASK_TWENTY_FIFTH,
            26 => ::Win32::TaskScheduler::TASK_TWENTY_SIXTH,
            27 => ::Win32::TaskScheduler::TASK_TWENTY_SEVENTH,
            28 => ::Win32::TaskScheduler::TASK_TWENTY_EIGHTH,
            29 => ::Win32::TaskScheduler::TASK_TWENTY_NINTH,
            # cspell:disable-next-line
            30 => ::Win32::TaskScheduler::TASK_THIRTYETH,
            31 => ::Win32::TaskScheduler::TASK_THIRTY_FIRST,
          }.freeze

          PRIORITY = { "critical" => 0, "highest" => 1,  "above_normal_2" => 2 , "above_normal_3" => 3, "normal_4" => 4,
                       "normal_5" => 5, "normal_6" => 6, "below_normal_7" => 7, "below_normal_8" => 8, "lowest" => 9, "idle" => 10 }.freeze
        end

        def load_current_resource
          @current_resource = Chef::Resource::WindowsTask.new(new_resource.name)
          task = ::Win32::TaskScheduler.new(new_resource.task_name, nil, "\\", false)
          @current_resource.exists = task.exists?(new_resource.task_name)
          if @current_resource.exists
            task.get_task(new_resource.task_name)
            @current_resource.task = task
            pathed_task_name = new_resource.task_name.start_with?("\\") ? new_resource.task_name : "\\#{new_resource.task_name}"
            @current_resource.task_name(pathed_task_name)
          end
          @current_resource
        end

        # separated command arguments from :command property
        def set_command_and_arguments
          cmd, *args = Chef::Util::PathHelper.split_args(new_resource.command)
          new_resource.command = cmd
          new_resource.command_arguments = args.join(" ")
        end

        def set_start_day_and_time
          new_resource.start_day = Time.now.strftime("%m/%d/%Y") unless new_resource.start_day
          new_resource.start_time = Time.now.strftime("%H:%M") unless new_resource.start_time
        end

        def update_task(task)
          converge_by("#{new_resource} task updated") do
            do_backup
            task.set_account_information(new_resource.user, new_resource.password, new_resource.interactive_enabled)
            task.application_name = new_resource.command if new_resource.command
            task.parameters = new_resource.command_arguments if new_resource.command_arguments
            task.working_directory = new_resource.cwd if new_resource.cwd
            task.trigger = trigger unless new_resource.frequency == :none
            task.configure_settings(config_settings)
            task.creator = new_resource.user
            task.description = new_resource.description unless new_resource.description.nil?
            task.configure_principals(principal_settings)
          end
        end

        def trigger
          start_month, start_day, start_year = new_resource.start_day.to_s.split("/")
          start_hour, start_minute = new_resource.start_time.to_s.split(":")
          # TODO currently end_month, end_year and end_year needs to be set to 0. If not set win32-taskscheduler throwing nil into integer error.
          trigger_hash = {
            start_year: start_year.to_i,
            start_month: start_month.to_i,
            start_day: start_day.to_i,
            start_hour: start_hour.to_i,
            start_minute: start_minute.to_i,
            end_month: 0,
            end_day: 0,
            end_year: 0,
            trigger_type: trigger_type,
            type: type,
            random_minutes_interval: new_resource.random_delay,
          }

          if new_resource.frequency == :minute
            trigger_hash[:minutes_interval] = new_resource.frequency_modifier
          end

          if new_resource.frequency == :hourly
            minutes = convert_hours_in_minutes(new_resource.frequency_modifier.to_i)
            trigger_hash[:minutes_interval] = minutes
          end

          if new_resource.minutes_interval
            trigger_hash[:minutes_interval] = new_resource.minutes_interval
          end

          if new_resource.minutes_duration
            trigger_hash[:minutes_duration] = new_resource.minutes_duration
          end

          if trigger_type == ::Win32::TaskScheduler::MONTHLYDOW && frequency_modifier_contains_last_week?(new_resource.frequency_modifier)
            trigger_hash[:run_on_last_week_of_month] = true
          else
            trigger_hash[:run_on_last_week_of_month] = false
          end

          if trigger_type == ::Win32::TaskScheduler::MONTHLYDATE && day_includes_last_or_lastday?(new_resource.day)
            trigger_hash[:run_on_last_day_of_month] = true
          else
            trigger_hash[:run_on_last_day_of_month] = false
          end
          trigger_hash
        end

        def frequency_modifier_contains_last_week?(frequency_modifier)
          frequency_modifier = frequency_modifier.to_s.split(",")
          frequency_modifier.map! { |value| value.strip.upcase }
          frequency_modifier.include?("LAST")
        end

        def day_includes_last_or_lastday?(day)
          day = day.to_s.split(",")
          day.map! { |value| value.strip.upcase }
          day.include?("LAST") || day.include?("LASTDAY")
        end

        def convert_hours_in_minutes(hours)
          hours.to_i * 60 if hours
        end

        # TODO : Try to optimize this method
        # known issue : Since start_day and time is not mandatory while updating weekly frequency for which start_day is not mentioned by user idempotency
        # is not getting maintained as new_resource.start_day is nil and we fetch the day of week from start_day to set and its currently coming as nil and don't match with current_task
        def task_needs_update?(task)
          flag = false
          if new_resource.frequency == :none
            flag = (task.author != new_resource.user ||
                    task.application_name != new_resource.command ||
                    description_needs_update?(task) ||
                    task.parameters != new_resource.command_arguments.to_s ||
                    task.principals[:run_level] != run_level ||
                    task.settings[:disallow_start_if_on_batteries] != new_resource.disallow_start_if_on_batteries ||
                    task.settings[:stop_if_going_on_batteries] != new_resource.stop_if_going_on_batteries ||
                    task.settings[:start_when_available] != new_resource.start_when_available)
          else
            current_task_trigger = task.trigger(0)
            new_task_trigger = trigger
            flag = (ISO8601::Duration.new(task.idle_settings[:idle_duration])) != (ISO8601::Duration.new(new_resource.idle_time * 60)) if new_resource.frequency == :on_idle
            flag = (ISO8601::Duration.new(task.execution_time_limit)) != (ISO8601::Duration.new(new_resource.execution_time_limit * 60)) unless new_resource.execution_time_limit.nil?

            # if trigger not found updating the task to add the trigger
            if current_task_trigger.nil?
              flag = true
            else
              flag = true if start_day_updated?(current_task_trigger, new_task_trigger) == true ||
                start_time_updated?(current_task_trigger, new_task_trigger) == true ||
                current_task_trigger[:trigger_type] != new_task_trigger[:trigger_type] ||
                current_task_trigger[:type] != new_task_trigger[:type] ||
                current_task_trigger[:random_minutes_interval].to_i != new_task_trigger[:random_minutes_interval].to_i ||
                current_task_trigger[:minutes_interval].to_i != new_task_trigger[:minutes_interval].to_i ||
                task.author.to_s.casecmp(new_resource.user.to_s) != 0 ||
                task.application_name != new_resource.command ||
                description_needs_update?(task) ||
                task.parameters != new_resource.command_arguments.to_s ||
                task.working_directory != new_resource.cwd.to_s ||
                task.principals[:logon_type] != logon_type ||
                task.principals[:run_level] != run_level ||
                PRIORITY[task.priority] != new_resource.priority ||
                task.settings[:disallow_start_if_on_batteries] != new_resource.disallow_start_if_on_batteries ||
                task.settings[:stop_if_going_on_batteries] != new_resource.stop_if_going_on_batteries ||
                task.settings[:start_when_available] != new_resource.start_when_available
              if trigger_type == ::Win32::TaskScheduler::MONTHLYDATE
                flag = true if current_task_trigger[:run_on_last_day_of_month] != new_task_trigger[:run_on_last_day_of_month]
              end

              if trigger_type == ::Win32::TaskScheduler::MONTHLYDOW
                flag = true if current_task_trigger[:run_on_last_week_of_month] != new_task_trigger[:run_on_last_week_of_month]
              end
            end
          end
          flag
        end

        def start_day_updated?(current_task_trigger, new_task_trigger)
          ( new_resource.start_day && (current_task_trigger[:start_year].to_i != new_task_trigger[:start_year] ||
                                       current_task_trigger[:start_month].to_i != new_task_trigger[:start_month] ||
                                       current_task_trigger[:start_day].to_i != new_task_trigger[:start_day]) )
        end

        def start_time_updated?(current_task_trigger, new_task_trigger)
          ( new_resource.start_time && ( current_task_trigger[:start_hour].to_i != new_task_trigger[:start_hour] ||
                                        current_task_trigger[:start_minute].to_i != new_task_trigger[:start_minute] ) )
        end

        def trigger_type
          case new_resource.frequency
          when :once, :minute, :hourly
            ::Win32::TaskScheduler::ONCE
          when :daily
            ::Win32::TaskScheduler::DAILY
          when :weekly
            ::Win32::TaskScheduler::WEEKLY
          when :monthly
            # If frequency modifier is set with frequency :monthly we are setting taskscheduler as monthlydow
            # Ref https://msdn.microsoft.com/en-us/library/windows/desktop/aa382061(v=vs.85).aspx
            new_resource.frequency_modifier.to_i.between?(1, 12) ? ::Win32::TaskScheduler::MONTHLYDATE : ::Win32::TaskScheduler::MONTHLYDOW
          when :on_idle
            ::Win32::TaskScheduler::ON_IDLE
          when :onstart
            ::Win32::TaskScheduler::AT_SYSTEMSTART
          when :on_logon
            ::Win32::TaskScheduler::AT_LOGON
          else
            raise ArgumentError, "Please set frequency"
          end
        end

        def type
          case trigger_type
          when ::Win32::TaskScheduler::ONCE
            { once: nil }
          when ::Win32::TaskScheduler::DAILY
            { days_interval: new_resource.frequency_modifier.to_i }
          when ::Win32::TaskScheduler::WEEKLY
            { weeks_interval: new_resource.frequency_modifier.to_i, days_of_week: days_of_week.to_i }
          when ::Win32::TaskScheduler::MONTHLYDATE
            { months: months_of_year.to_i, days: days_of_month.to_i }
          when ::Win32::TaskScheduler::MONTHLYDOW
            { months: months_of_year.to_i, days_of_week: days_of_week.to_i, weeks_of_month: weeks_of_month.to_i }
          when ::Win32::TaskScheduler::ON_IDLE
            # TODO: handle option for this trigger
          when ::Win32::TaskScheduler::AT_LOGON
            # TODO: handle option for this trigger
          when ::Win32::TaskScheduler::AT_SYSTEMSTART
            # TODO: handle option for this trigger
          end
        end

        # Deleting last from the array of weeks of month since last week is handled in :run_on_last_week_of_month parameter.
        def weeks_of_month
          weeks_of_month = []
          if new_resource.frequency_modifier
            weeks = new_resource.frequency_modifier.split(",")
            weeks.map! { |week| week.to_s.strip.upcase }
            weeks.delete("LAST") if weeks.include?("LAST")
            weeks_of_month = get_binary_values_from_constants(weeks, WEEKS_OF_MONTH)
          end
          weeks_of_month
        end

        # Deleting the "LAST" and "LASTDAY" from days since last day is handled in :run_on_last_day_of_month parameter.
        def days_of_month
          days_of_month = []
          if new_resource.day
            days = new_resource.day.to_s.split(",")
            days.map! { |day| day.to_s.strip.upcase }
            days.delete("LAST") if days.include?("LAST")
            days.delete("LASTDAY") if days.include?("LASTDAY")
            if days - (1..31).to_a
              days.each do |day|
                days_of_month << DAYS_OF_MONTH[day.to_i]
              end
              days_of_month = days_of_month.size > 1 ? days_of_month.inject(:|) : days_of_month[0]
            end
          else
            days_of_month = DAYS_OF_MONTH[1]
          end
          days_of_month
        end

        def days_of_week
          if new_resource.day
            # this line of code is just to support backward compatibility of wild card *
            new_resource.day = "mon, tue, wed, thu, fri, sat, sun" if new_resource.day == "*" && new_resource.frequency == :weekly
            days = new_resource.day.to_s.split(",")
            days.map! { |day| day.to_s.strip.upcase }
            weeks_days = get_binary_values_from_constants(days, DAYS_OF_WEEK)
          else
            # following condition will make the frequency :weekly idempotent if start_day is not provided by user setting day as the current_resource day
            if (current_resource) && (current_resource.task) && (current_resource.task.trigger(0)[:type][:days_of_week]) && (new_resource.start_day.nil?)
              weeks_days = current_resource.task.trigger(0)[:type][:days_of_week]
            else
              day = get_day(new_resource.start_day).to_sym if new_resource.start_day
              DAYS_OF_WEEK[day]
            end
          end
        end

        def months_of_year
          months_of_year = []
          if new_resource.frequency_modifier.to_i.between?(1, 12) && !(new_resource.months)
            new_resource.months = set_months(new_resource.frequency_modifier.to_i)
          end

          if new_resource.months
            # this line of code is just to support backward compatibility of wild card *
            new_resource.months = "jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec" if new_resource.months == "*" && new_resource.frequency == :monthly
            months = new_resource.months.split(",")
            months.map! { |month| month.to_s.strip.upcase }
            months_of_year = get_binary_values_from_constants(months, MONTHS)
          else
            MONTHS.each do |key, value|
              months_of_year << MONTHS[key]
            end
            months_of_year = months_of_year.inject(:|)
          end
          months_of_year
        end

        # This values are set for frequency_modifier set as 1-12
        # This is to give backward compatibility validated this values with earlier code and running schtask.exe
        # Used this as reference https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/schtasks#d-dayday--
        def set_months(frequency_modifier)
          case frequency_modifier
          when 1
            "jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec"
          when 2
            "feb, apr, jun, aug, oct, dec"
          when 3
            "mar, jun, sep, dec"
          when 4
            "apr, aug, dec"
          when 5
            "may, oct"
          when 6
            "jun, dec"
          when 7
            "jul"
          when 8
            "aug"
          when 9
            "sep"
          when 10
            "oct"
          when 11
            "nov"
          when 12
            "dec"
          end
        end

        def get_binary_values_from_constants(array_values, constant)
          data = []
          array_values.each do |value|
            value = value.to_sym
            data << constant[value]
          end
          data.size > 1 ? data.inject(:|) : data[0]
        end

        def run_level
          case new_resource.run_level
          when :highest
            ::Win32::TaskScheduler::TASK_RUNLEVEL_HIGHEST
          when :limited
            ::Win32::TaskScheduler::TASK_RUNLEVEL_LUA
          end
        end

        # TODO: while creating the configuration settings win32-taskscheduler it accepts execution time limit values in ISO8601 format
        def config_settings
          settings = {
            execution_time_limit: new_resource.execution_time_limit,
            enabled: true,
          }
          settings[:idle_duration] = new_resource.idle_time if new_resource.idle_time
          settings[:run_only_if_idle] = true if new_resource.idle_time
          settings[:priority] = new_resource.priority
          settings[:disallow_start_if_on_batteries] = new_resource.disallow_start_if_on_batteries
          settings[:stop_if_going_on_batteries] = new_resource.stop_if_going_on_batteries
          settings[:start_when_available] = new_resource.start_when_available
          settings
        end

        def principal_settings
          settings = {}
          settings[:run_level] = run_level
          settings[:logon_type] = logon_type
          settings
        end

        def description_needs_update?(task)
          task.description != new_resource.description unless new_resource.description.nil?
        end

        def logon_type
          # Ref: https://msdn.microsoft.com/en-us/library/windows/desktop/aa383566(v=vs.85).aspx
          # if nothing is passed as logon_type the TASK_LOGON_SERVICE_ACCOUNT is getting set as default so using that for comparison.
          user_id = new_resource.user.to_s
          password = new_resource.password.to_s
          if Chef::ReservedNames::Win32::Security::SID.service_account_user?(user_id)
            ::Win32::TaskScheduler::TASK_LOGON_SERVICE_ACCOUNT
          elsif Chef::ReservedNames::Win32::Security::SID.group_user?(user_id)
            ::Win32::TaskScheduler::TASK_LOGON_GROUP
          elsif !user_id.empty? && !password.empty?
            if new_resource.interactive_enabled
              ::Win32::TaskScheduler::TASK_LOGON_INTERACTIVE_TOKEN
            else
              ::Win32::TaskScheduler::TASK_LOGON_PASSWORD
            end
          else
            ::Win32::TaskScheduler::TASK_LOGON_INTERACTIVE_TOKEN
          end
        end

        # This method checks if task and command properties exist since those two are mandatory properties to create a schedules task.
        def basic_validation
          validate = []
          validate << "Command" if new_resource.command.nil? || new_resource.command.empty?
          validate << "Task Name" if new_resource.task_name.nil? || new_resource.task_name.empty?
          return true if validate.empty?

          raise Chef::Exceptions::ValidationFailed.new "Value for '#{validate.join(", ")}' option cannot be empty"
        end

        # rubocop:disable Style/StringLiteralsInInterpolation
        def run_schtasks(task_action, options = {})
          cmd = "schtasks /#{task_action} /TN \"#{new_resource.task_name}\" "
          options.each_key do |option|
            unless option == "TR"
              cmd += "/#{option} "
              cmd += "\"#{options[option].to_s.gsub('"', "\\\"")}\" " unless options[option] == ""
            end
          end
          # Appending Task Run [TR] option at the end since appending causing sometimes to append other options in option["TR"] value
          if options["TR"]
            cmd += "/TR \"#{options["TR"]} \" " unless task_action == "DELETE"
          end
          logger.trace("running: ")
          logger.trace("    #{cmd}")
          shell_out!(cmd, returns: [0])
        end
        # rubocop:enable Style/StringLiteralsInInterpolation

        def get_day(date)
          Date.strptime(date, "%m/%d/%Y").strftime("%a").upcase
        end

        def do_backup
          file = "C:/Windows/System32/Tasks/#{new_resource.task_name}"
          Chef::Util::Backup.new(new_resource, file).backup!
        end
      end

      action :create do
        set_command_and_arguments if new_resource.command

        if current_resource.exists
          logger.trace "#{new_resource} task exist."
          unless (task_needs_update?(current_resource.task)) || (new_resource.force)
            logger.info "#{new_resource} task does not need updating and force is not specified - nothing to do"
            return
          end

          # if start_day and start_time is not set by user current date and time will be set while updating any property
          set_start_day_and_time unless new_resource.frequency == :none
          update_task(current_resource.task)
        else
          basic_validation
          set_start_day_and_time
          converge_by("#{new_resource} task created") do
            task = ::Win32::TaskScheduler.new
            if new_resource.frequency == :none
              task.new_work_item(new_resource.task_name, {}, { user: new_resource.user, password: new_resource.password, interactive: new_resource.interactive_enabled })
              task.activate(new_resource.task_name)
            else
              task.new_work_item(new_resource.task_name, trigger, { user: new_resource.user, password: new_resource.password, interactive: new_resource.interactive_enabled })
            end
            task.application_name = new_resource.command
            task.parameters = new_resource.command_arguments if new_resource.command_arguments
            task.working_directory = new_resource.cwd if new_resource.cwd
            task.configure_settings(config_settings)
            task.configure_principals(principal_settings)
            task.set_account_information(new_resource.user, new_resource.password, new_resource.interactive_enabled)
            task.creator = new_resource.user
            task.description = new_resource.description unless new_resource.description.nil?
            task.activate(new_resource.task_name)
          end
        end
      end

      action :run do
        if current_resource.exists
          logger.trace "#{new_resource} task exists"
          if current_resource.task.status == "running"
            logger.info "#{new_resource} task is currently running, skipping run"
          else
            converge_by("run scheduled task #{new_resource}") do
              current_resource.task.run
            end
          end
        else
          logger.debug "#{new_resource} task does not exist - nothing to do"
        end
      end

      action :delete do
        if current_resource.exists
          logger.trace "#{new_resource} task exists"
          converge_by("delete scheduled task #{new_resource}") do
            do_backup
            ts = ::Win32::TaskScheduler.new
            ts.delete(current_resource.task_name)
          end
        else
          logger.debug "#{new_resource} task does not exist - nothing to do"
        end
      end

      action :end do
        if current_resource.exists
          logger.trace "#{new_resource} task exists"
          if current_resource.task.status != "running"
            logger.debug "#{new_resource} is not running - nothing to do"
          else
            converge_by("#{new_resource} task ended") do
              current_resource.task.stop
            end
          end
        else
          logger.debug "#{new_resource} task does not exist - nothing to do"
        end
      end

      action :enable do
        if current_resource.exists
          logger.trace "#{new_resource} task exists"
          if current_resource.task.status == "not scheduled"
            converge_by("#{new_resource} task enabled") do
              # TODO wind32-taskscheduler currently not having any method to handle this so using schtasks.exe here
              run_schtasks "CHANGE", "ENABLE" => ""
            end
          else
            logger.debug "#{new_resource} already enabled - nothing to do"
          end
        else
          logger.fatal "#{new_resource} task does not exist - nothing to do"
          raise Errno::ENOENT, "#{new_resource}: task does not exist, cannot enable"
        end
      end

      action :disable do
        if current_resource.exists
          logger.info "#{new_resource} task exists"
          if %w{ready running}.include?(current_resource.task.status)
            converge_by("#{new_resource} task disabled") do
              # TODO: in win32-taskscheduler there is no method which disables the task so currently calling disable with schtasks.exe
              run_schtasks "CHANGE", "DISABLE" => ""
            end
          else
            logger.warn "#{new_resource} already disabled - nothing to do"
          end
        else
          logger.warn "#{new_resource} task does not exist - nothing to do"
        end
      end

      action_class do
        alias_method :action_change, :action_create
      end
    end
  end
end
