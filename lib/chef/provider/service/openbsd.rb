#
# Author:: Scott Bonds (<scott@ggr.com>)
# Copyright:: Copyright 2014-2016, Scott Bonds
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

require "chef/mixin/command"
require "chef/mixin/shell_out"
require "chef/provider/service/init"
require "chef/resource/service"

class Chef
  class Provider
    class Service
      class Openbsd < Chef::Provider::Service::Init

        provides :service, os: "openbsd"

        include Chef::Mixin::ShellOut

        attr_reader :init_command, :rc_conf, :rc_conf_local, :enabled_state_found

        RC_CONF_PATH = "/etc/rc.conf"
        RC_CONF_LOCAL_PATH = "/etc/rc.conf.local"

        def initialize(new_resource, run_context)
          super
          @rc_conf = ::File.read(RC_CONF_PATH) rescue ""
          @rc_conf_local = ::File.read(RC_CONF_LOCAL_PATH) rescue ""
          @init_command = ::File.exist?(rcd_script_path) ? rcd_script_path : nil
          new_resource.status_command("#{default_init_command} check")
        end

        def load_current_resource
          supports[:status] = true if supports[:status].nil?

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
            a.assertion { enabled_state_found }
            # for consistency with original behavior, this will not fail in non-whyrun mode;
            # rather it will silently set enabled state=>false
            a.whyrun "Unable to determine enabled/disabled state, assuming this will be correct for an actual run.  Assuming disabled."
          end

          requirements.assert(:start, :enable, :reload, :restart) do |a|
            a.assertion { init_command && !builtin_service_enable_variable_name.nil? }
            a.failure_message Chef::Exceptions::Service, "Could not find the service name in #{init_command} and rcvar"
            # No recovery in whyrun mode - the init file is present but not correct.
          end
        end

        def enable_service
          if !is_enabled?
            if is_builtin?
              if is_enabled_by_default?
                update_rcl rc_conf_local.sub(/^#{Regexp.escape(builtin_service_enable_variable_name)}=.*/, "")
              else
                # add line with blank string, which means enable
                update_rcl rc_conf_local + "\n" + "#{builtin_service_enable_variable_name}=\"\"\n"
              end
            else
              # add to pkg_scripts, most recent addition goes last
              old_services_list = rc_conf_local.match(/^pkg_scripts="(.*)"/)
              old_services_list = old_services_list ? old_services_list[1].split(" ") : []
              new_services_list = old_services_list + [new_resource.service_name]
              if rc_conf_local =~ /^pkg_scripts="(.*)"/
                new_rcl = rc_conf_local.sub(/^pkg_scripts="(.*)"/, "pkg_scripts=\"#{new_services_list.join(' ')}\"")
              else
                new_rcl = rc_conf_local + "\n" + "pkg_scripts=\"#{new_services_list.join(' ')}\"\n"
              end
              update_rcl new_rcl
            end
          end
        end

        def disable_service
          if is_enabled?
            if is_builtin?
              if is_enabled_by_default?
                # add line to disable
                update_rcl rc_conf_local + "\n" + "#{builtin_service_enable_variable_name}=\"NO\"\n"
              else
                # remove line to disable
                update_rcl rc_conf_local.sub(/^#{Regexp.escape(builtin_service_enable_variable_name)}=.*/, "")
              end
            else
              # remove from pkg_scripts
              old_list = rc_conf_local.match(/^pkg_scripts="(.*)"/)
              old_list = old_list ? old_list[1].split(" ") : []
              new_list = old_list - [new_resource.service_name]
              update_rcl rc_conf_local.sub(/^pkg_scripts="(.*)"/, pkg_scripts = "#{new_list.join(' ')}")
            end
          end
        end

        private

        def rcd_script_found?
          !init_command.nil?
        end

        def rcd_script_path
          "/etc/rc.d/#{new_resource.service_name}"
        end

        def update_rcl(value)
          FileUtils.touch RC_CONF_LOCAL_PATH if !::File.exists? RC_CONF_LOCAL_PATH
          ::File.write(RC_CONF_LOCAL_PATH, value)
          @rc_conf_local = value
        end

        # The variable name used in /etc/rc.conf.local for enabling this service
        def builtin_service_enable_variable_name
          @bsevn ||= begin
            result = nil
            if rcd_script_found?
              ::File.open(init_command) do |rcscript|
                if m = rcscript.read.match(/^# \$OpenBSD: (\w+)[(.rc),]?/)
                  result = m[1] + "_flags"
                end
              end
            end
            # Fallback allows us to keep running in whyrun mode when
            # the script does not exist.
            result || new_resource.service_name
          end
        end

        def is_builtin?
          result = false
          var_name = builtin_service_enable_variable_name
          if var_name
            if rc_conf =~ /^#{Regexp.escape(var_name)}=(.*)/
              result = true
            end
          end
          result
        end

        def is_enabled_by_default?
          result = false
          var_name = builtin_service_enable_variable_name
          if var_name
            if m = rc_conf.match(/^#{Regexp.escape(var_name)}=(.*)/)
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
          if is_builtin?
            var_name = builtin_service_enable_variable_name
            if var_name
              if m = rc_conf_local.match(/^#{Regexp.escape(var_name)}=(.*)/)
                @enabled_state_found = true
                if !(m[1] =~ /"?[Nn][Oo]"?/) # e.g. looking for httpd_flags=NO
                  result = true
                end
              end
            end
            if !@enabled_state_found
              result = is_enabled_by_default?
            end
          else
            var_name = @new_resource.service_name
            if var_name
              if m = rc_conf_local.match(/^pkg_scripts="(.*)"/)
                @enabled_state_found = true
                if m[1].include?(var_name) # e.g. looking for 'gdm' in pkg_scripts="gdm unbound"
                  result = true
                end
              end
            end
          end

          current_resource.enabled result
        end
        alias :is_enabled? :determine_enabled_status!

      end
    end
  end
end
