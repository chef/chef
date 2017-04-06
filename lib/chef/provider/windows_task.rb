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

require "chef/mixin/shell_out"
require "rexml/document"
require "iso8601"
require "chef/mixin/powershell_out"

class Chef
  class Provider
    class WindowsTask < Chef::Provider
      include Chef::Mixin::ShellOut
      include Chef::Mixin::PowershellOut

      provides :windows_task, os: "windows"

      def load_current_resource
        @current_resource = Chef::Resource::WindowsTask.new(new_resource.name)
        pathed_task_name = new_resource.task_name.start_with?('\\') ? new_resource.task_name : "\\#{new_resource.task_name}"

        @current_resource.task_name(pathed_task_name)
        task_hash = load_task_hash(pathed_task_name)

        set_current_resource(task_hash) if task_hash.respond_to?(:[]) && task_hash[:TaskName] == pathed_task_name
        @current_resource
      end

      def set_current_resource(task_hash)
        @current_resource.exists = true
        @current_resource.command(task_hash[:TaskToRun])
        @current_resource.cwd(task_hash[:StartIn]) unless task_hash[:StartIn] == "N/A"
        @current_resource.user(task_hash[:RunAsUser])
        set_current_run_level task_hash[:run_level]
        set_current_frequency task_hash
        @current_resource.day(task_hash[:day]) if task_hash[:day]
        @current_resource.months(task_hash[:months]) if task_hash[:months]
        set_current_idle_time(task_hash[:idle_time]) if task_hash[:idle_time]
        @current_resource.random_delay(task_hash[:random_delay]) if task_hash[:random_delay]
        @current_resource.execution_time_limit(task_hash[:execution_time_limit]) if task_hash[:execution_time_limit]

        @current_resource.status = :running if task_hash[:Status] == "Running"
        @current_resource.enabled = true if task_hash[:ScheduledTaskState] == "Enabled"
      end

      def action_create
        if @current_resource.exists && !(task_need_update? || @new_resource.force)
          Chef::Log.info "#{@new_resource} task already exists - nothing to do"
        else
          options = {}
          options["F"] = "" if @new_resource.force || task_need_update?
          options["SC"] = schedule
          options["MO"] = @new_resource.frequency_modifier if frequency_modifier_allowed
          options["I"]  = @new_resource.idle_time unless @new_resource.idle_time.nil?
          options["SD"] = @new_resource.start_day unless @new_resource.start_day.nil?
          options["ST"] = @new_resource.start_time unless @new_resource.start_time.nil?
          options["TR"] = @new_resource.command
          options["RU"] = @new_resource.user
          options["RP"] = @new_resource.password if use_password?
          options["RL"] = "HIGHEST" if @new_resource.run_level == :highest
          options["IT"] = "" if @new_resource.interactive_enabled
          options["D"] = @new_resource.day if @new_resource.day
          options["M"] = @new_resource.months unless @new_resource.months.nil?

          run_schtasks "CREATE", options
          xml_options = []
          xml_options << "cwd" if new_resource.cwd
          xml_options << "random_delay" if new_resource.random_delay
          xml_options << "execution_time_limit" if new_resource.execution_time_limit
          update_task_xml(xml_options) unless xml_options.empty?

          new_resource.updated_by_last_action true
          Chef::Log.info "#{@new_resource} task created"
        end
      end

      def action_run
        if @current_resource.exists
          if @current_resource.status == :running
            Chef::Log.info "#{@new_resource} task is currently running, skipping run"
          else
            run_schtasks "RUN"
            new_resource.updated_by_last_action true
            Chef::Log.info "#{@new_resource} task ran"
          end
        else
          Chef::Log.warn "#{@new_resource} task doesn't exists - nothing to do"
        end
      end

      def action_delete
        if @current_resource.exists
          # always need to force deletion
          run_schtasks "DELETE", "F" => ""
          new_resource.updated_by_last_action true
          Chef::Log.info "#{@new_resource} task deleted"
        else
          Chef::Log.warn "#{@new_resource} task doesn't exists - nothing to do"
        end
      end

      def action_end
        if @current_resource.exists
          if @current_resource.status != :running
            Chef::Log.debug "#{@new_resource} is not running - nothing to do"
          else
            run_schtasks "END"
            @new_resource.updated_by_last_action true
            Chef::Log.info "#{@new_resource} task ended"
          end
        else
          Chef::Log.warn "#{@new_resource} task doesn't exist - nothing to do"
        end
      end

      def action_enable
        if @current_resource.exists
          if @current_resource.enabled
            Chef::Log.debug "#{@new_resource} already enabled - nothing to do"
          else
            run_schtasks "CHANGE", "ENABLE" => ""
            @new_resource.updated_by_last_action true
            Chef::Log.info "#{@new_resource} task enabled"
          end
        else
          Chef::Log.fatal "#{@new_resource} task doesn't exist - nothing to do"
          raise Errno::ENOENT, "#{@new_resource}: task does not exist, cannot enable"
        end
      end

      def action_disable
        if @current_resource.exists
          if @current_resource.enabled
            run_schtasks "CHANGE", "DISABLE" => ""
            @new_resource.updated_by_last_action true
            Chef::Log.info "#{@new_resource} task disabled"
          else
            Chef::Log.warn "#{@new_resource} already disabled - nothing to do"
          end
        else
          Chef::Log.warn "#{@new_resource} task doesn't exist - nothing to do"
        end
      end

      private

      # rubocop:disable Style/StringLiteralsInInterpolation
      def run_schtasks(task_action, options = {})
        cmd = "schtasks /#{task_action} /TN \"#{@new_resource.task_name}\" "
        options.keys.each do |option|
          cmd += "/#{option} "
          cmd += "\"#{options[option].to_s.gsub('"', "\\\"")}\" " unless options[option] == ""
        end
        Chef::Log.debug("running: ")
        Chef::Log.debug("    #{cmd}")
        shell_out!(cmd, returns: [0])
      end
      # rubocop:enable Style/StringLiteralsInInterpolation

      def task_need_update?
        return true if @current_resource.command != @new_resource.command.tr("'", '"') ||
            @current_resource.user != @new_resource.user ||
            @current_resource.run_level != @new_resource.run_level ||
            @current_resource.cwd != @new_resource.cwd ||
            @current_resource.frequency_modifier != @new_resource.frequency_modifier ||
            @current_resource.frequency != @new_resource.frequency ||
            @current_resource.idle_time != @new_resource.idle_time ||
            @current_resource.random_delay != @new_resource.random_delay ||
            @current_resource.execution_time_limit != @new_resource.execution_time_limit ||
            !@new_resource.start_day.nil? || !@new_resource.start_time.nil?

        begin
          return true if @new_resource.day.to_s.casecmp(@current_resource.day.to_s) != 0 ||
              @new_resource.months.to_s.casecmp(@current_resource.months.to_s) != 0
        rescue
          Chef::Log.debug "caught a raise in task_needs_update?"
        end

        false
      end

      def update_task_xml(options = [])
        # random_delay xml element is different for different frequencies
        random_delay_xml_element = {
          :minute => "Triggers/TimeTrigger/RandomDelay",
          :hourly => "Triggers/TimeTrigger/RandomDelay",
          :once => "Triggers/TimeTrigger/RandomDelay",
          :daily => "Triggers/CalendarTrigger/RandomDelay",
          :weekly => "Triggers/CalendarTrigger/RandomDelay",
          :monthly => "Triggers/CalendarTrigger/RandomDelay",
        }

        xml_element_mapping = {
          "cwd" => "Actions/Exec/WorkingDirectory",
          "random_delay" => random_delay_xml_element[@new_resource.frequency],
          "execution_time_limit" => "Settings/ExecutionTimeLimit",
        }

        Chef::Log.debug "looking for existing tasks"

        task_script = <<-EOH
            [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
            schtasks /Query /TN \"#{@new_resource.task_name}\" /XML
        EOH
        xml_cmd = powershell_out(task_script)

        return if xml_cmd.exitstatus != 0

        doc = REXML::Document.new(xml_cmd.stdout)

        options.each do |option|
          Chef::Log.debug 'Removing former #{option} if any'
          doc.root.elements.delete(xml_element_mapping[option])
          option_value = @new_resource.send("#{option}")

          if option_value
            Chef::Log.debug "Setting #option as #option_value"
            split_xml_path = xml_element_mapping[option].split("/") # eg. if xml_element_mapping[option] = "Actions/Exec/WorkingDirectory"
            element_name = split_xml_path.last # element_name = "WorkingDirectory"
            cwd_element = REXML::Element.new(element_name)
            cwd_element.add_text(option_value)
            element_root = (split_xml_path - [element_name]).join("/") # element_root = 'Actions/Exec'
            exec_element = doc.root.elements[element_root]
            exec_element.add_element(cwd_element)
          end
        end

        temp_task_file = ::File.join(ENV["TEMP"], "windows_task.xml")
        begin
          ::File.open(temp_task_file, "w:UTF-16LE") do |f|
            doc.write(f)
          end

          options = {}
          options["RU"] = @new_resource.user if @new_resource.user
          options["RP"] = @new_resource.password if @new_resource.password
          options["IT"] = "" if @new_resource.interactive_enabled
          options["XML"] = temp_task_file

          run_schtasks("DELETE", "F" => "")
          run_schtasks("CREATE", options)
        ensure
          ::File.delete(temp_task_file)
        end
      end

      def load_task_hash(task_name)
        Chef::Log.debug "Looking for existing tasks"

        task_script = <<-EOH
          [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
          schtasks /Query /FO LIST /V /TN \"#{task_name}\"
        EOH

        output = powershell_out(task_script).stdout.force_encoding("UTF-8")
        if output.empty?
          task = false
        else
          task = {}

          output.split("\n").map! do |line|
            line.split(": ").map!(&:strip)
          end.each do |field|
            if field.is_a?(Array) && field[0].respond_to?(:to_sym)
              key = (field - [field.last]).join(": ")
              task[key.gsub(/\s+/, "").to_sym] = field.last
            end
          end
        end

        task_xml = load_task_xml task_name
        task.merge!(task_xml) if task && task_xml

        task
      end

      def load_task_xml(task_name)
        task_script = <<-EOH
            [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
            schtasks /Query /TN \"#{task_name}\" /XML
        EOH
        xml_cmd = powershell_out(task_script)

        return if xml_cmd.exitstatus != 0

        doc = REXML::Document.new(xml_cmd.stdout)
        root = doc.root

        task = {}
        task[:run_level] = root.elements["Principals/Principal/RunLevel"].text if root.elements["Principals/Principal/RunLevel"]

        # for frequency = :minutes, :hourly
        task[:repetition_interval] = root.elements["Triggers/TimeTrigger/Repetition/Interval"].text if root.elements["Triggers/TimeTrigger/Repetition/Interval"]

        # for frequency = :daily
        task[:schedule_by_day] = root.elements["Triggers/CalendarTrigger/ScheduleByDay/DaysInterval"].text if root.elements["Triggers/CalendarTrigger/ScheduleByDay/DaysInterval"]

        # for frequency = :weekly
        task[:schedule_by_week] = root.elements["Triggers/CalendarTrigger/ScheduleByWeek/WeeksInterval"].text if root.elements["Triggers/CalendarTrigger/ScheduleByWeek/WeeksInterval"]
        if root.elements["Triggers/CalendarTrigger/ScheduleByWeek/DaysOfWeek"]
          task[:day] = []
          root.elements["Triggers/CalendarTrigger/ScheduleByWeek/DaysOfWeek"].elements.each do |e|
            task[:day] << e.to_s[0..3].delete("<").delete("/>")
          end
          task[:day] = task[:day].join(", ")
        end

        # for frequency = :monthly
        task[:schedule_by_month] = root.elements["Triggers/CalendarTrigger/ScheduleByMonth/DaysOfMonth/Day"].text if root.elements["Triggers/CalendarTrigger/ScheduleByMonth/DaysOfMonth/Day"]
        if root.elements["Triggers/CalendarTrigger/ScheduleByMonth/Months"]
          task[:months] = []
          root.elements["Triggers/CalendarTrigger/ScheduleByMonth/Months"].elements.each do |e|
            task[:months] << e.to_s[0..3].delete("<").delete("/>")
          end
          task[:months] = task[:months].join(", ")
        end

        task[:on_logon] = true if root.elements["Triggers/LogonTrigger"]
        task[:onstart] = true if root.elements["Triggers/BootTrigger"]
        task[:on_idle] = true if root.elements["Triggers/IdleTrigger"]

        task[:idle_time] = root.elements["Settings/IdleSettings/Duration"].text if root.elements["Settings/IdleSettings/Duration"] && task[:on_idle]

        task[:once] = true if !(task[:repetition_interval] || task[:schedule_by_day] || task[:schedule_by_week] || task[:schedule_by_month] || task[:on_logon] || task[:onstart] || task[:on_idle])
        task[:execution_time_limit] = root.elements["Settings/ExecutionTimeLimit"].text if root.elements["Settings/ExecutionTimeLimit"] #by default PT72H
        task[:random_delay] = root.elements["Triggers/TimeTrigger/RandomDelay"].text if root.elements["Triggers/TimeTrigger/RandomDelay"]
        task[:random_delay] = root.elements["Triggers/CalendarTrigger/RandomDelay"].text if root.elements["Triggers/CalendarTrigger/RandomDelay"]
        task
      end

      SYSTEM_USERS = ['NT AUTHORITY\SYSTEM', "SYSTEM", 'NT AUTHORITY\LOCALSERVICE', 'NT AUTHORITY\NETWORKSERVICE', 'BUILTIN\USERS', "USERS"].freeze

      def use_password?
        @use_password ||= !SYSTEM_USERS.include?(@new_resource.user.upcase)
      end

      def schedule
        case @new_resource.frequency
        when :on_logon
          "ONLOGON"
        when :on_idle
          "ONIDLE"
        else
          @new_resource.frequency
        end
      end

      def frequency_modifier_allowed
        case @new_resource.frequency
        when :minute, :hourly, :daily, :weekly
          true
        when :monthly
          @new_resource.months.nil? || %w{ FIRST SECOND THIRD FOURTH LAST LASTDAY }.include?(@new_resource.frequency_modifier)
        else
          false
        end
      end

      def set_current_run_level(run_level)
        case run_level
        when "HighestAvailable"
          @current_resource.run_level(:highest)
        when "LeastPrivilege"
          @current_resource.run_level(:limited)
        end
      end

      def set_current_frequency(task_hash)
        if task_hash[:repetition_interval]
          duration = ISO8601::Duration.new(task_hash[:repetition_interval])
          if task_hash[:repetition_interval].include?("M")
            @current_resource.frequency(:minute)
            @current_resource.frequency_modifier(duration.minutes.atom.to_i)
          elsif task_hash[:repetition_interval].include?("H")
            @current_resource.frequency(:hourly)
            @current_resource.frequency_modifier(duration.hours.atom.to_i)
          end
        end

        if task_hash[:schedule_by_day]
          @current_resource.frequency(:daily)
          @current_resource.frequency_modifier(task_hash[:schedule_by_day].to_i)
        end

        if task_hash[:schedule_by_week]
          @current_resource.frequency(:weekly)
          @current_resource.frequency_modifier(task_hash[:schedule_by_week].to_i)
        end

        @current_resource.frequency(:monthly) if task_hash[:schedule_by_month]
        @current_resource.frequency(:on_logon) if task_hash[:on_logon]
        @current_resource.frequency(:onstart) if task_hash[:onstart]
        @current_resource.frequency(:on_idle) if task_hash[:on_idle]
        @current_resource.frequency(:once) if task_hash[:once]
      end

      def set_current_idle_time(idle_time)
        duration = ISO8601::Duration.new(idle_time)
        @current_resource.idle_time(duration.minutes.atom.to_i)
      end

    end
  end
end
