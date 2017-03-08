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

require 'chef/mixin/shell_out'
require 'rexml/document'

class Chef
  class Provider
    class WindowsTask < Chef::Provider
      use_inline_resources
      include Chef::Mixin::ShellOut

      provides :windows_task, os: "windows"

      def load_current_resource
        @current_resource = Chef::Resource::WindowsTask.new(new_resource.name)
        pathed_task_name = new_resource.task_name.start_with?('\\') ? new_resource.task_name : "\\#{new_resource.task_name}"

        @current_resource.task_name(pathed_task_name)
        task_hash = load_task_hash(pathed_task_name)

        if task_hash.respond_to?(:[]) && task_hash[:TaskName] == pathed_task_name
          @current_resource.exists = true
          @current_resource.status = :running if task_hash[:Status] == 'Running'
          if task_hash[:ScheduledTaskState] == 'Enabled'
            @current_resource.enabled = true
          end
          @current_resource.cwd(task_hash[:StartIn]) unless task_hash[:StartIn] == 'N/A'
          @current_resource.command(task_hash[:TaskToRun])
          @current_resource.user(task_hash[:RunAsUser])
        end
      end

      def action_create
        if @current_resource.exists && !(task_need_update? || @new_resource.force)
          Chef::Log.info "#{@new_resource} task already exists - nothing to do"
        else
          validate_user_and_password
          validate_interactive_setting
          validate_create_frequency_modifier
          validate_create_day
          validate_create_months
          validate_idle_time

          options = {}
          options['F'] = '' if @new_resource.force || task_need_update?
          options['SC'] = schedule
          options['MO'] = @new_resource.frequency_modifier if frequency_modifier_allowed
          options['I']  = @new_resource.idle_time unless @new_resource.idle_time.nil?
          options['SD'] = @new_resource.start_day unless @new_resource.start_day.nil?
          options['ST'] = @new_resource.start_time unless @new_resource.start_time.nil?
          options['TR'] = @new_resource.command
          options['RU'] = @new_resource.user
          options['RP'] = @new_resource.password if use_password?
          options['RL'] = 'HIGHEST' if @new_resource.run_level == :highest
          options['IT'] = '' if @new_resource.interactive_enabled
          options['D'] = @new_resource.day if @new_resource.day
          options['M'] = @new_resource.months unless @new_resource.months.nil?

          run_schtasks 'CREATE', options
          set_cwd(new_resource.cwd) if new_resource.cwd
          new_resource.updated_by_last_action true
          Chef::Log.info "#{@new_resource} task created"
        end
      end

      def action_run
        if @current_resource.exists
          if @current_resource.status == :running
            Chef::Log.info "#{@new_resource} task is currently running, skipping run"
          else
            run_schtasks 'RUN'
            new_resource.updated_by_last_action true
            Chef::Log.info "#{@new_resource} task ran"
          end
        else
          Chef::Log.debug "#{@new_resource} task doesn't exists - nothing to do"
        end
      end

      def action_change
        if @current_resource.exists
          validate_user_and_password
          validate_interactive_setting

          options = {}
          options['TR'] = @new_resource.command if @new_resource.command
          options['RU'] = @new_resource.user if @new_resource.user
          options['RP'] = @new_resource.password if @new_resource.password
          options['SD'] = @new_resource.start_day unless @new_resource.start_day.nil?
          options['ST'] = @new_resource.start_time unless @new_resource.start_time.nil?
          options['IT'] = '' if @new_resource.interactive_enabled

          run_schtasks 'CHANGE', options
          set_cwd(new_resource.cwd) if new_resource.cwd != @current_resource.cwd
          new_resource.updated_by_last_action true
          Chef::Log.info "Change #{@new_resource} task ran"
        else
          Chef::Log.debug "#{@new_resource} task doesn't exists - nothing to do"
        end
      end

      def action_delete
        if @current_resource.exists
          # always need to force deletion
          run_schtasks 'DELETE', 'F' => ''
          new_resource.updated_by_last_action true
          Chef::Log.info "#{@new_resource} task deleted"
        else
          Chef::Log.debug "#{@new_resource} task doesn't exists - nothing to do"
        end
      end

      def action_end
        if @current_resource.exists
          if @current_resource.status != :running
            Chef::Log.debug "#{@new_resource} is not running - nothing to do"
          else
            run_schtasks 'END'
            @new_resource.updated_by_last_action true
            Chef::Log.info "#{@new_resource} task ended"
          end
        else
          Chef::Log.fatal "#{@new_resource} task doesn't exist - nothing to do"
          raise Errno::ENOENT, "#{@new_resource}: task does not exist, cannot end"
        end
      end

      def action_enable
        if @current_resource.exists
          if @current_resource.enabled
            Chef::Log.debug "#{@new_resource} already enabled - nothing to do"
          else
            run_schtasks 'CHANGE', 'ENABLE' => ''
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
            run_schtasks 'CHANGE', 'DISABLE' => ''
            @new_resource.updated_by_last_action true
            Chef::Log.info "#{@new_resource} task disabled"
          else
            Chef::Log.debug "#{@new_resource} already disabled - nothing to do"
          end
        else
          Chef::Log.debug "#{@new_resource} task doesn't exist - nothing to do"
        end
      end

      private

      # rubocop:disable Style/StringLiteralsInInterpolation
      def run_schtasks(task_action, options = {})
        cmd = "schtasks /#{task_action} /TN \"#{@new_resource.task_name}\" "
        options.keys.each do |option|
          cmd += "/#{option} "
          cmd += "\"#{options[option].to_s.gsub('"', "\\\"")}\" " unless options[option] == ''
        end
        Chef::Log.debug('running: ')
        Chef::Log.debug("    #{cmd}")
        shell_out!(cmd, returns: [0])
      end
      # rubocop:enable Style/StringLiteralsInInterpolation

      def task_need_update?
        # gsub needed as schtasks converts single quotes to double quotes on creation
        @current_resource.command != @new_resource.command.tr("'", '"') ||
          @current_resource.user != @new_resource.user
      end

      def set_cwd(folder)
        Chef::Log.debug 'looking for existing tasks'

        # we use shell_out here instead of shell_out! because a failure implies that the task does not exist
        xml_cmd = shell_out("schtasks /Query /TN \"#{@new_resource.task_name}\" /XML")

        return if xml_cmd.exitstatus != 0

        doc = REXML::Document.new(xml_cmd.stdout)

        Chef::Log.debug 'Removing former CWD if any'
        doc.root.elements.delete('Actions/Exec/WorkingDirectory')

        unless folder.nil?
          Chef::Log.debug 'Setting CWD as #folder'
          cwd_element = REXML::Element.new('WorkingDirectory')
          cwd_element.add_text(folder)
          exec_element = doc.root.elements['Actions/Exec']
          exec_element.add_element(cwd_element)
        end

        temp_task_file = ::File.join(ENV['TEMP'], 'windows_task.xml')
        begin
          ::File.open(temp_task_file, 'w:UTF-16LE') do |f|
            doc.write(f)
          end

          options = {}
          options['RU'] = @new_resource.user if @new_resource.user
          options['RP'] = @new_resource.password if @new_resource.password
          options['IT'] = '' if @new_resource.interactive_enabled
          options['XML'] = temp_task_file

          run_schtasks('DELETE', 'F' => '')
          run_schtasks('CREATE', options)
        ensure
          ::File.delete(temp_task_file)
        end
      end

      def load_task_hash(task_name)
        Chef::Log.debug 'Looking for existing tasks'

        # we use shell_out here instead of shell_out! because a failure implies that the task does not exist
        output = shell_out("schtasks /Query /FO LIST /V /TN \"#{task_name}\"").stdout
        if output.empty?
          task = false
        else
          task = {}

          output.split("\n").map! do |line|
            line.split(':', 2).map!(&:strip)
          end.each do |field|
            if field.is_a?(Array) && field[0].respond_to?(:to_sym)
              task[field[0].gsub(/\s+/, '').to_sym] = field[1]
            end
          end
        end

        task
      end

      SYSTEM_USERS = ['NT AUTHORITY\SYSTEM', 'SYSTEM', 'NT AUTHORITY\LOCALSERVICE', 'NT AUTHORITY\NETWORKSERVICE'].freeze

      def validate_user_and_password
        if @new_resource.user && use_password?
          if @new_resource.password.nil?
            Chef::Log.fatal "#{@new_resource.task_name}: Can't specify a non-system user without a password!"
          end
        end
      end

      def validate_interactive_setting
        if @new_resource.interactive_enabled && @new_resource.password.nil?
          Chef::Log.fatal "#{new_resource} did not provide a password when attempting to set interactive/non-interactive."
        end
      end

      def validate_create_day
        return unless @new_resource.day
        unless [:weekly, :monthly].include?(@new_resource.frequency)
          raise 'day attribute is only valid for tasks that run weekly or monthly'
        end
        if @new_resource.day.is_a?(String) && @new_resource.day.to_i.to_s != @new_resource.day
          days = @new_resource.day.split(',')
          days.each do |day|
            unless ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun', '*'].include?(day.strip.downcase)
              raise 'day attribute invalid.  Only valid values are: MON, TUE, WED, THU, FRI, SAT, SUN and *.  Multiple values must be separated by a comma.'
            end
          end
        end
      end

      def validate_create_months
        return unless @new_resource.months
        unless [:monthly].include?(@new_resource.frequency)
          raise 'months attribute is only valid for tasks that run monthly'
        end
        if @new_resource.months.is_a? String
          months = @new_resource.months.split(',')
          months.each do |month|
            unless ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC', '*'].include?(month.strip.upcase)
              raise 'months attribute invalid. Only valid values are: JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC and *. Multiple values must be separated by a comma.'
            end
          end
        end
      end

      def validate_idle_time
        return unless @new_resource.frequency == :on_idle
        unless @new_resource.idle_time.to_i > 0 && @new_resource.idle_time.to_i <= 999
          raise "idle_time value #{@new_resource.idle_time} is invalid.  Valid values for :on_idle frequency are 1 - 999."
        end
      end

      def validate_create_frequency_modifier
        # Currently is handled in create action 'frequency_modifier_allowed' line. Does not allow for frequency_modifier for once,onstart,onlogon,onidle
        # Note that 'OnEvent' is not a supported frequency.
        unless @new_resource.frequency.nil? || @new_resource.frequency_modifier.nil?
          case @new_resource.frequency
          when :minute
            unless @new_resource.frequency_modifier.to_i > 0 && @new_resource.frequency_modifier.to_i <= 1439
              raise "frequency_modifier value #{@new_resource.frequency_modifier} is invalid.  Valid values for :minute frequency are 1 - 1439."
            end
          when :hourly
            unless @new_resource.frequency_modifier.to_i > 0 && @new_resource.frequency_modifier.to_i <= 23
              raise "frequency_modifier value #{@new_resource.frequency_modifier} is invalid.  Valid values for :hourly frequency are 1 - 23."
            end
          when :daily
            unless @new_resource.frequency_modifier.to_i > 0 && @new_resource.frequency_modifier.to_i <= 365
              raise "frequency_modifier value #{@new_resource.frequency_modifier} is invalid.  Valid values for :daily frequency are 1 - 365."
            end
          when :weekly
            unless @new_resource.frequency_modifier.to_i > 0 && @new_resource.frequency_modifier.to_i <= 52
              raise "frequency_modifier value #{@new_resource.frequency_modifier} is invalid.  Valid values for :weekly frequency are 1 - 52."
            end
          when :monthly
            unless ('1'..'12').to_a.push('FIRST', 'SECOND', 'THIRD', 'FOURTH', 'LAST', 'LASTDAY').include?(@new_resource.frequency_modifier.to_s.upcase)
              raise "frequency_modifier value #{@new_resource.frequency_modifier} is invalid.  Valid values for :monthly frequency are 1 - 12, 'FIRST', 'SECOND', 'THIRD', 'FOURTH', 'LAST', 'LASTDAY'."
            end
          end
        end
      end

      def use_password?
        @use_password ||= !SYSTEM_USERS.include?(@new_resource.user.upcase)
      end

      def schedule
        case @new_resource.frequency
        when :on_logon
          'ONLOGON'
        when :on_idle
          'ONIDLE'
        else
          @new_resource.frequency
        end
      end

      def frequency_modifier_allowed
        case @new_resource.frequency
        when :minute, :hourly, :daily, :weekly
          true
        when :monthly
          @new_resource.months.nil? || %w(FIRST SECOND THIRD FOURTH LAST LASTDAY).include?(@new_resource.frequency_modifier)
        else
          false
        end
      end

    end
  end
end
