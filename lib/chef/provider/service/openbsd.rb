#
# Author:: Scott Bonds (<scott@ggr.com>)
# Copyright:: Copyright (c) 2014 Scott Bonds
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

require 'chef/mixin/command'
require 'chef/mixin/shell_out'
require 'chef/provider/service/init'
require 'chef/resource/service'

class Chef
  class Provider
    class Service
      class Openbsd < Chef::Provider::Service::Init

        include Chef::Mixin::ShellOut
        
        attr_reader :rcd_script_found

        def initialize(new_resource, run_context)
          super
          @rc_conf = ::File.read('/etc/rc.conf') if ::File.exists?('/etc/rc.conf')
          @rc_conf_local = ::File.read('/etc/rc.conf.local') if ::File.exists?('/etc/rc.conf.local')
          if ::File.exist?("/etc/rc.d/#{new_resource.service_name}")
            @init_command = "/etc/rc.d/#{new_resource.service_name}"
            @rcd_script_found = true
          else
            @init_command = nil
            @rcd_script_found = false
          end
        end

        def load_current_resource
          @current_resource = Chef::Resource::Service.new(new_resource.name)
          current_resource.service_name(new_resource.service_name)

          Chef::Log.debug("#{current_resource} found at #{init_command}")

          determine_current_status!
          determine_enabled_status!
          current_resource
        end

        def define_resource_requirements
          shared_resource_requirements

          requirements.assert(:start, :enable, :reload, :restart) do |a|
            a.assertion { init_command }
            a.failure_message Chef::Exceptions::Service, "#{new_resource}: unable to locate the rc.d script"
          end

          requirements.assert(:all_actions) do |a|
            a.assertion { @enabled_state_found }
            # for consistency with original behavior, this will not fail in non-whyrun mode;
            # rather it will silently set enabled state=>false
            a.whyrun "Unable to determine enabled/disabled state, assuming this will be correct for an actual run.  Assuming disabled."
          end

          requirements.assert(:start, :enable, :reload, :restart) do |a|
            a.assertion { init_command && builtin_service_enable_variable_name != nil }
            a.failure_message Chef::Exceptions::Service, "Could not find the service name in #{init_command} and rcvar"
            # No recovery in whyrun mode - the init file is present but not correct.
          end
        end
        def start_service
          if @new_resource.start_command
            super
          else
            shell_out_with_systems_locale!("#{init_command} start")
          end
        end

        def stop_service
          if @new_resource.stop_command
            super
          else
            shell_out_with_systems_locale!("#{init_command} stop")
          end
        end

        def restart_service
          if @new_resource.restart_command
            super
          elsif @new_resource.supports[:restart]
            shell_out_with_systems_locale!("#{init_command} restart")
          else
            stop_service
            sleep 1
            start_service
          end
        end

        def enable_service
          if !is_enabled
            if is_builtin
              if is_enabled_by_default
                update_rcl! @rc_conf_local.sub(/^#{Regexp.escape(builtin_service_enable_variable_name)}=.*/, '')
              else
                # add line with blank string, which means enable
                update_rcl! @rc_conf_local + "\n" + "#{builtin_service_enable_variable_name}=\"\""
              end
            else
              # add to pkg_scripts, most recent addition goes last
              old_services_list = @rc_conf_local.match(/^pkg_scripts="(.*)"/)
              old_services_list = old_services_list ? old_services_list[1].split(' ') : []
              new_services_list = old_services_list + [@new_resource.service_name]
              if @rc_conf_local.match(/^pkg_scripts="(.*)"/)
                new_rcl = @rc_conf_local.sub(/^pkg_scripts="(.*)"/, "pkg_scripts=\"#{new_services_list.join(' ')}\"")
              else
                new_rcl = @rc_conf_local + "\n" + "pkg_scripts=\"#{new_services_list.join(' ')}\""
                new_rcl.strip!
              end
              update_rcl! new_rcl
            end
          end
        end

        def disable_service
          if is_enabled
            if is_builtin
              if is_enabled_by_default
                # add line to disable
                update_rcl! @rc_conf_local + "\n" + "#{builtin_service_enable_variable_name}=\"NO\""
              else
                # remove line to disable
                update_rcl! @rc_conf_local.sub(/^#{Regexp.escape(builtin_service_enable_variable_name)}=.*/, '')
              end
            else
              # remove from pkg_scripts
              old_list = @rc_conf_local.match(/^pkg_scripts="(.*)"/)
              old_list = old_list ? old_list[1].split(' ') : []
              new_list = old_list - [@new_resource.service_name]
              update_rcl! @rc_conf_local.sub(/^pkg_scripts="(.*)"/, pkg_scripts="#{new_list.join(' ')}")
            end
          end
        end

        protected

        # copied from Chef::Provider::Service::Simple with one small change
        # ...the command 'status' is replaced with its OpenBSD equivalent: 'check'
        def determine_current_status!
          if !@new_resource.status_command && @new_resource.supports[:status]
            Chef::Log.debug("#{@new_resource} supports status, running")
            begin
              if shell_out("#{default_init_command} check").exitstatus == 0
                @current_resource.running true
                Chef::Log.debug("#{@new_resource} is running")
              end
            # ShellOut sometimes throws different types of Exceptions than ShellCommandFailed.
            # Temporarily catching different types of exceptions here until we get Shellout fixed.
            # TODO: Remove the line before one we get the ShellOut fix.
            rescue Mixlib::ShellOut::ShellCommandFailed, SystemCallError
              @status_load_success = false
              @current_resource.running false
              nil
            end
          else
            super
          end
        end

        private

        def update_rcl!(value)
          FileUtils.touch '/etc/rc.conf.local' if !::File.exists? '/etc/rc.conf.local'
          ::File.write('/etc/rc.conf.local', value)
          @rc_conf_local = value
        end

        # The variable name used in /etc/rc.conf.local for enabling this service
        def builtin_service_enable_variable_name
          @bsevn ||= begin
            result = nil
            if rcd_script_found
              ::File.open(init_command) do |rcscript|
                if m = rcscript.read.match(/^# \$OpenBSD: (\w+)[(.rc),]?/)
                  result = m[1] + "_flags"
                end
              end
            end
            # Fallback allows us to keep running in whyrun mode when
            # the script does not exist.
            result || @new_resource.service_name
          end
        end

        def is_builtin
          result = false
          var_name = builtin_service_enable_variable_name
          if @rc_conf && var_name
            if @rc_conf.match(/^#{Regexp.escape(var_name)}=(.*)/)
              result = true
            end
          end
          result
        end

        def is_enabled_by_default
          result = false
          var_name = builtin_service_enable_variable_name
          if @rc_conf && var_name
            if m = @rc_conf.match(/^#{Regexp.escape(var_name)}=(.*)/)
              if !(m[1] =~ /"?[Nn][Oo]"?/)
                result = true
              end
            end
          end
          result
        end

        def determine_enabled_status!
          result = false # Default to disabled if the service doesn't currently exist at all
          @enabled_state_found = false
          if is_builtin
            var_name = builtin_service_enable_variable_name
            if @rc_conf_local && var_name
              if m = @rc_conf_local.match(/^#{Regexp.escape(var_name)}=(.*)/)
                @enabled_state_found = true
                if !(m[1] =~ /"?[Nn][Oo]"?/) # e.g. looking for httpd_flags=NO
                  result = true
                end
              end
            end
            if !@enabled_state_found
              result = is_enabled_by_default
            end
          else
            var_name = @new_resource.service_name
            if @rc_conf_local && var_name
              if m = @rc_conf_local.match(/^pkg_scripts="(.*)"/)
                @enabled_state_found = true
                if m[1].include?(var_name) # e.g. looking for 'gdm' in pkg_scripts="gdm unbound"
                  result = true
                end
              end
            end
          end

          current_resource.enabled result
        end
        alias :is_enabled :determine_enabled_status!

      end
    end
  end
end
