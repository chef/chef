#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Copyright:: Copyright (c) 2009 Bryan McLellan
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

require 'chef/log'
require 'chef/mixin/command'
require 'chef/provider'

class Chef
  class Provider
    class Cron < Chef::Provider
      include Chef::Mixin::Command

      CRON_PATTERN = /\A([-0-9*,\/]+)\s([-0-9*,\/]+)\s([-0-9*,\/]+)\s([-0-9*,\/]+|[a-zA-Z]{3})\s([-0-9*,\/]+|[a-zA-Z]{3})\s(.*)/
      ENV_PATTERN = /\A(\S+)=(\S*)/

      CRON_ATTRIBUTES = [:minute, :hour, :day, :month, :weekday, :command, :mailto, :path, :shell, :home, :environment]

      def initialize(new_resource, run_context)
        super(new_resource, run_context)
        @cron_exists = false
        @cron_empty = false
      end
      attr_accessor :cron_exists, :cron_empty

      def whyrun_supported?
        true
      end
      
      def load_current_resource
        crontab_lines = []
        @current_resource = Chef::Resource::Cron.new(@new_resource.name)
        @current_resource.user(@new_resource.user)
        if crontab = read_crontab
          cron_found = false
          crontab.each_line do |line|
            case line.chomp
            when "# Chef Name: #{@new_resource.name}"
              Chef::Log.debug("Found cron '#{@new_resource.name}'")
              cron_found = true
              @cron_exists = true
              next
            when ENV_PATTERN
              set_environment_var($1, $2) if cron_found
              next
            when CRON_PATTERN
              if cron_found
                @current_resource.minute($1)
                @current_resource.hour($2)
                @current_resource.day($3)
                @current_resource.month($4)
                @current_resource.weekday($5)
                @current_resource.command($6)
                cron_found=false
              end
              next
            else
              cron_found=false # We've got a Chef comment with no following crontab line
              next
            end
          end
          Chef::Log.debug("Cron '#{@new_resource.name}' not found") unless @cron_exists
        else
          Chef::Log.debug("Cron empty for '#{@new_resource.user}'")
          @cron_empty = true
        end

        @current_resource
      end
      
      def cron_different?
        CRON_ATTRIBUTES.any? do |cron_var|
          !@new_resource.send(cron_var).nil? && @new_resource.send(cron_var) != @current_resource.send(cron_var)
        end
      end

      def action_create
        crontab = String.new
        newcron = String.new
        cron_found = false

        newcron << "# Chef Name: #{new_resource.name}\n"
        [ :mailto, :path, :shell, :home ].each do |v|
          newcron << "#{v.to_s.upcase}=#{@new_resource.send(v)}\n" if @new_resource.send(v)
        end
        @new_resource.environment.each do |name, value|
          newcron << "#{name}=#{value}\n"
        end
        newcron << "#{@new_resource.minute} #{@new_resource.hour} #{@new_resource.day} #{@new_resource.month} #{@new_resource.weekday} #{@new_resource.command}\n"

        if @cron_exists
          unless cron_different?
            Chef::Log.debug("Skipping existing cron entry '#{@new_resource.name}'")
            return
          end
          read_crontab.each_line do |line|
            case line.chomp
            when "# Chef Name: #{@new_resource.name}"
              cron_found = true
              next
            when ENV_PATTERN
              crontab << line unless cron_found
              next
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

          converge_by("update crontab entry for #{@new_resource}") do
            write_crontab crontab
            Chef::Log.info("#{@new_resource} updated crontab entry")
          end

        else
          crontab = read_crontab unless @cron_empty
          crontab << newcron

          converge_by("add crontab entry for #{@new_resource}") do
            write_crontab crontab
            Chef::Log.info("#{@new_resource} added crontab entry")
          end
        end
      end

      def action_delete
        if @cron_exists
          crontab = String.new
          cron_found = false
          read_crontab.each_line do |line|
            case line.chomp
            when "# Chef Name: #{@new_resource.name}"
              cron_found = true
              next
            when ENV_PATTERN
              next if cron_found
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
          description = cron_found ? "remove #{@new_resource.name} from crontab" : 
            "save unmodified crontab"
          converge_by(description) do
            write_crontab crontab
            Chef::Log.info("#{@new_resource} deleted crontab entry")
          end
        end
      end

      private

      def set_environment_var(attr_name, attr_value)
        if %w(MAILTO PATH SHELL HOME).include?(attr_name)
          @current_resource.send(attr_name.downcase.to_sym, attr_value)
        else
          @current_resource.environment(@current_resource.environment.merge(attr_name => attr_value))
        end
      end

      def read_crontab
        crontab = nil
        status = popen4("crontab -l -u #{@new_resource.user}") do |pid, stdin, stdout, stderr|
          crontab = stdout.read
        end
        if status.exitstatus > 1
          raise Chef::Exceptions::Cron, "Error determining state of #{@new_resource.name}, exit: #{status.exitstatus}"
        end
        crontab
      end

      def write_crontab(crontab)
        status = popen4("crontab -u #{@new_resource.user} -", :waitlast => true) do |pid, stdin, stdout, stderr|
          stdin.write crontab
        end
        if status.exitstatus > 0
          raise Chef::Exceptions::Cron, "Error updating state of #{@new_resource.name}, exit: #{status.exitstatus}"
        end
      end
    end
  end
end
