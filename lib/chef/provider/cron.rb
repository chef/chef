#
# Author:: Bryan McLellan (btm@loftninjas.org)
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

require "chef/log"
require "chef/provider"

class Chef
  class Provider
    class Cron < Chef::Provider

      provides :cron, os: ["!aix", "!solaris2"]

      SPECIAL_TIME_VALUES = [:reboot, :yearly, :annually, :monthly, :weekly, :daily, :midnight, :hourly]
      CRON_ATTRIBUTES = [:minute, :hour, :day, :month, :weekday, :time, :command, :mailto, :path, :shell, :home, :environment]
      WEEKDAY_SYMBOLS = [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday]

      CRON_PATTERN = /\A([-0-9*,\/]+)\s([-0-9*,\/]+)\s([-0-9*,\/]+)\s([-0-9*,\/]+|[a-zA-Z]{3})\s([-0-9*,\/]+|[a-zA-Z]{3})\s(.*)/
      SPECIAL_PATTERN = /\A(@(#{SPECIAL_TIME_VALUES.join('|')}))\s(.*)/
      ENV_PATTERN = /\A(\S+)=(\S*)/

      def initialize(new_resource, run_context)
        super(new_resource, run_context)
        @cron_exists = false
        @cron_empty = false
      end
      attr_accessor :cron_exists, :cron_empty

      def load_current_resource
        crontab_lines = []
        @current_resource = Chef::Resource::Cron.new(new_resource.name)
        current_resource.user(new_resource.user)
        @cron_exists = false
        if crontab = read_crontab
          cron_found = false
          crontab.each_line do |line|
            case line.chomp
            when "# Chef Name: #{new_resource.name}"
              Chef::Log.debug("Found cron '#{new_resource.name}'")
              cron_found = true
              @cron_exists = true
              next
            when ENV_PATTERN
              set_environment_var($1, $2) if cron_found
              next
            when SPECIAL_PATTERN
              if cron_found
                current_resource.time($2.to_sym)
                current_resource.command($3)
                cron_found = false
              end
            when CRON_PATTERN
              if cron_found
                current_resource.minute($1)
                current_resource.hour($2)
                current_resource.day($3)
                current_resource.month($4)
                current_resource.weekday($5)
                current_resource.command($6)
                cron_found = false
              end
              next
            else
              cron_found = false # We've got a Chef comment with no following crontab line
              next
            end
          end
          Chef::Log.debug("Cron '#{new_resource.name}' not found") unless @cron_exists
        else
          Chef::Log.debug("Cron empty for '#{new_resource.user}'")
          @cron_empty = true
        end

        current_resource
      end

      def cron_different?
        CRON_ATTRIBUTES.any? do |cron_var|
          new_resource.send(cron_var) != current_resource.send(cron_var)
        end
      end

      def action_create
        crontab = String.new
        newcron = String.new
        cron_found = false

        newcron = get_crontab_entry

        if @cron_exists
          unless cron_different?
            Chef::Log.debug("Skipping existing cron entry '#{new_resource.name}'")
            return
          end
          read_crontab.each_line do |line|
            case line.chomp
            when "# Chef Name: #{new_resource.name}"
              cron_found = true
              next
            when ENV_PATTERN
              crontab << line unless cron_found
              next
            when SPECIAL_PATTERN
              if cron_found
                cron_found = false
                crontab << newcron
                next
              end
            when CRON_PATTERN
              if cron_found
                cron_found = false
                crontab << newcron
                next
              end
            else
              if cron_found # We've got a Chef comment with no following crontab line
                crontab << newcron
                cron_found = false
              end
            end
            crontab << line
          end

          # Handle edge case where the Chef comment is the last line in the current crontab
          crontab << newcron if cron_found

          converge_by("update crontab entry for #{new_resource}") do
            write_crontab crontab
            Chef::Log.info("#{new_resource} updated crontab entry")
          end

        else
          crontab = read_crontab unless @cron_empty
          crontab << newcron

          converge_by("add crontab entry for #{new_resource}") do
            write_crontab crontab
            Chef::Log.info("#{new_resource} added crontab entry")
          end
        end
      end

      def action_delete
        if @cron_exists
          crontab = String.new
          cron_found = false
          read_crontab.each_line do |line|
            case line.chomp
            when "# Chef Name: #{new_resource.name}"
              cron_found = true
              next
            when ENV_PATTERN
              next if cron_found
            when SPECIAL_PATTERN
              if cron_found
                cron_found = false
                next
              end
            when CRON_PATTERN
              if cron_found
                cron_found = false
                next
              end
            else
              # We've got a Chef comment with no following crontab line
              cron_found = false
            end
            crontab << line
          end
          description = cron_found ? "remove #{new_resource.name} from crontab" : "save unmodified crontab"
          converge_by(description) do
            write_crontab crontab
            Chef::Log.info("#{new_resource} deleted crontab entry")
          end
        end
      end

      private

      def set_environment_var(attr_name, attr_value)
        if %w{MAILTO PATH SHELL HOME}.include?(attr_name)
          current_resource.send(attr_name.downcase.to_sym, attr_value.gsub(/^"|"$/, ""))
        else
          current_resource.environment(current_resource.environment.merge(attr_name => attr_value))
        end
      end

      def read_crontab
        so = shell_out!("crontab -l -u #{new_resource.user}", returns: [0, 1])
        return nil if so.exitstatus == 1
        so.stdout
      rescue => e
        raise Chef::Exceptions::Cron, "Error determining state of #{new_resource.name}, error: #{e}"
      end

      def write_crontab(crontab)
        write_exception = false
        so = shell_out!("crontab -u #{new_resource.user} -", input: crontab)
      rescue => e
        raise Chef::Exceptions::Cron, "Error updating state of #{new_resource.name}, error: #{e}"
      end

      def get_crontab_entry
        newcron = ""
        newcron << "# Chef Name: #{new_resource.name}\n"
        [ :mailto, :path, :shell, :home ].each do |v|
          newcron << "#{v.to_s.upcase}=\"#{new_resource.send(v)}\"\n" if new_resource.send(v)
        end
        new_resource.environment.each do |name, value|
          newcron << "#{name}=#{value}\n"
        end
        if new_resource.time
          newcron << "@#{new_resource.time} #{new_resource.command}\n"
        else
          newcron << "#{new_resource.minute} #{new_resource.hour} #{new_resource.day} #{new_resource.month} #{new_resource.weekday} #{new_resource.command}\n"
        end
        newcron
      end

      def weekday_in_crontab
        weekday_in_crontab = WEEKDAY_SYMBOLS.index(new_resource.weekday)
        if weekday_in_crontab.nil?
          new_resource.weekday
        else
          weekday_in_crontab.to_s
        end
      end
    end
  end
end
