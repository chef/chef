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

        def initialize(new_resource, run_context)
          super
          @init_command = nil
          if ::File.exist?("/etc/rc.d/#{new_resource.service_name}")
            @init_command = "/etc/rc.d/#{new_resource.service_name}"
          end
        end

        def load_current_resource
          @current_resource = Chef::Resource::Service.new(@new_resource.name)
          @current_resource.service_name(@new_resource.service_name)
          @rcd_script_found = true

          if ::File.exists?("/etc/rc.d/#{current_resource.service_name}")
            @init_command = "/etc/rc.d/#{current_resource.service_name}"
          else
            @rcd_script_found = false
            return
          end
          Chef::Log.debug("#{@current_resource} found at #{@init_command}")
          determine_current_status!
          determine_enabled_status!

          @current_resource
        end

        def define_resource_requirements
          shared_resource_requirements
          requirements.assert(:start, :enable, :reload, :restart) do |a|
            a.assertion { @rcd_script_found }
            a.failure_message Chef::Exceptions::Service, "#{@new_resource}: unable to locate the rc.d script"
          end

          requirements.assert(:all_actions) do |a|
            a.assertion { @enabled_state_found }
            # for consistency with original behavior, this will not fail in non-whyrun mode;
            # rather it will silently set enabled state=>false
            a.whyrun "Unable to determine enabled/disabled state, assuming this will be correct for an actual run.  Assuming disabled."
          end

          requirements.assert(:start, :enable, :reload, :restart) do |a|
            a.assertion { @rcd_script_found && builtin_service_enable_variable_name != nil }
            a.failure_message Chef::Exceptions::Service, "Could not find the service name in #{@init_command} and rcvar"
            # No recovery in whyrun mode - the init file is present but not correct.
          end
        end

        def start_service
          if @new_resource.start_command
            super
          else
            shell_out_with_systems_locale!("#{@init_command} start")
          end
        end

        def stop_service
          if @new_resource.stop_command
            super
          else
            shell_out_with_systems_locale!("#{@init_command} stop")
          end
        end

        def restart_service
          if @new_resource.restart_command
            super
          elsif @new_resource.supports[:restart]
            shell_out_with_systems_locale!("#{@init_command} restart")
          else
            stop_service
            sleep 1
            start_service
          end
        end

        def enable_service()
          set_service_enable(true)
        end

        def disable_service()
          set_service_enable(false)
        end

        protected

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

        # The variable name used in /etc/rc.conf.local for enabling this service
        def builtin_service_enable_variable_name
          if @rcd_script_found
            ::File.open(@init_command) do |rcscript|
              rcscript.each_line do |line|
                if line =~ /^# \$OpenBSD: (\w+)[(.rc),]?/
                  return $1 + "_flags"
                end
              end
            end
          end
          # Fallback allows us to keep running in whyrun mode when
          # the script does not exist.
          @new_resource.service_name
        end

        def set_service_enable(enable)
          var_name = builtin_service_enable_variable_name
          if is_builtin
            # a builtin service is enabled when either <service>_flags is
            # set equal to something other than 'NO', can be blank or it can be
            # a set of options that should be passed to the startup script
            old_value = new_value = nil
            if enable
              if files['/etc/rc.conf.local'] && var_name
                files['/etc/rc.conf.local'].split("\n").each do |line|
                  if line =~ /^#{Regexp.escape(var_name)}=(.*)/
                    old_value = $1
                    break
                  end
                end
              end
              if files['/etc/rc.conf'] && var_name
                files['/etc/rc.conf'].split("\n").each do |line|
                  if line =~ /^#{Regexp.escape(var_name)}=(.*)/
                    old_value = $1
                    break
                  end
                end
              end
              if old_value && old_value =~ /"?[Nn][Oo]"?/
                new_value = ''
              else
                new_value = old_value
                Chef::Log.debug("service is already enabled and has parameters, skipping")
              end
            end
            # This is run immediately so the service can be started at any time
            # after the :enable action, during this Chef run.
            configurate(
              setting: builtin_service_enable_variable_name,
              value: new_value,
              remove: !enable
            )
          else
            configurate(
              setting: 'pkg_scripts',
              format: :space_delimited_list,
              value: @new_resource.service_name.clone,
              after: @new_resource.after ? @new_resource.after.clone : nil,
              remove: !enable
            )
          end
        end

        def is_builtin
          result = false
          var_name = builtin_service_enable_variable_name
          if files['/etc/rc.conf'] && var_name
            files['/etc/rc.conf'].split("\n").each do |line|
              case line
              when /^#{Regexp.escape(var_name)}=(.*)/
                result = true
              end
            end
          end
          result
        end

        def determine_enabled_status!
          result = false # Default to disabled if the service doesn't currently exist at all
          if is_builtin
            var_name = builtin_service_enable_variable_name
            if files['/etc/rc.conf.local'] && var_name
              files['/etc/rc.conf.local'].split("\n").each do |line|
                case line
                when /^#{Regexp.escape(var_name)}=(.*)/
                  @enabled_state_found = true
                  if $1 =~ /"?[Nn][Oo]"?/
                    result = false
                  else
                    result = true
                  end
                  break
                end
              end
            end
            if files['/etc/rc.conf'] && var_name && !@enabled_state_found
              files['/etc/rc.conf'].split("\n").each do |line|
                case line
                when /^#{Regexp.escape(var_name)}=(.*)/
                  @enabled_state_found = true
                  if $1 =~ /"?[Nn][Oo]"?/
                    result = false
                  else
                    result = true
                  end
                  break
                end
              end
            end
          else
            var_name = @new_resource.service_name
            if files['/etc/rc.conf'] && var_name
              files['/etc/rc.conf'].split("\n").each do |line|
                if line =~ /pkg_scripts="(.*)"/
                  @enabled_state_found = true
                  if $1.include?(var_name)
                    result = true
                  end
                  break
                end
              end
            end
          end

          current_resource.enabled result
        end

        # this is used for sorting lists of dependencies in configurate
        class TsortableHash < Hash
          include TSort
          alias tsort_each_node each_key
          def tsort_each_child(node, &block)
            fetch(node).each(&block)
          end
        end

        def afters
          @@afters ||= {}
        end

        def afters=(new_value)
          @@afters = new_value
        end

        def files
          return @@files if defined? @@files
          @@files = {}
          ['/etc/rc.conf', '/etc/rc.conf.local'].each do |file|
            if ::File.exists? file
              @@files[file] = ::File.read(file)
            end
          end
          @@files
        end

        def files=(new_value)
          @@files = new_value
        end

        def configurate(options)
          file = '/etc/rc.conf.local'

          Chef::Log.debug("Configurate: options[:setting] #{options[:setting]}")
          Chef::Log.debug("Configurate:   options[:value] #{options[:value]}")
          Chef::Log.debug("Configurate:   options[:after] #{options[:after]}")
          Chef::Log.debug("Configurate:  options[:remove] #{options[:remove]}")
          Chef::Log.debug("Configurate:  options[:prefix] #{options[:prefix]}")

          options[:comment]     ||= '#'
          options[:equals]      ||= '='

          # Store which values need to come 'after' which other values for a given
          # file + setting. For example, on OpenBSD the '/etc/rc.conf.local' file
          # has a setting called 'pkg_scripts' which specifies the order that
          # (addon) services should start up. In some cases, you need a certain
          # service to start only *after* some service it depends on has started.
          afters["#{file}##{options[:setting]}"] = TsortableHash.new if !afters["#{file}##{options[:setting]}"]
          Chef::Log.debug "AFTERS: #{afters}"
          if options[:after]
            if !afters["#{file}##{options[:setting]}"][options[:after]]
              raise KeyError, 'Cannot configurate a value before the value it comes after'
            end
            afters["#{file}##{options[:setting]}"][options[:value]] = [options[:after]]
          else
            afters["#{file}##{options[:setting]}"][options[:value]] = []
          end

          old_contents = ''
          new_contents = ''
          found = false

          old_contents = files[file]
          if old_contents
            old_contents.each_line do |old_line|
              new_line = ''
              if options[:setting]
                m = old_line.match(Regexp.new("(.*?)#{(options[:prefix] + '(\s*)') if options[:prefix]}#{options[:setting]}(\s*)#{options[:equals]}(\s*)(.*)"))
                if m
                  next if found # delete duplicate lines defining this same setting

                  line_prefix       = m[1]
                  if options[:prefix]
                    modifier        = 1
                    s_prefix_suffix = m[2]
                  else
                    modifier        = 0
                  end
                  equals_prefix     = m[2+modifier]
                  equals_suffix     = m[3+modifier]
                  line_value        = m[4+modifier].split(options[:comment])[0].strip
                  line_suffix       = m[4+modifier][line_value.size..-1]
                  # puts "ov: #{line_value}"
                  # puts "ss: #{line_suffix}"

                  # If the prefix includes anything besides a options[:comment] symbol or a
                  # specified prefix, or the suffix doesn't start with a options[:comment]
                  # symbol, the line is probably documentation
                  if (
                      line_prefix &&
                      !line_prefix.strip.empty? &&
                      options[:comment] && line_prefix.strip != options[:comment] &&
                      options[:prefix] && line_prefix.strip != options[:prefix]
                     ) ||
                     (
                      line_suffix &&
                      !line_suffix.strip.empty? &&
                      options[:comment] && line_suffix.strip[0] != options[:comment]
                     )
                    new_contents << old_line
                    next
                  end

                  # Return the setting's current value if no new value was passed
                  return line_value if !options[:value] && !options[:remove]
                  found = true

                  case options[:format]
                  when :space_delimited_list
                    list_items = line_value.gsub('"', '').split(' ').map{|a| a.strip}
                    list_items << options[:value]
                    list_items = list_items.uniq
                    if options[:remove]
                      list_items.delete_if {|a| a == options[:value]}
                    end
                    if afters["#{file}##{options[:setting]}"]
                      list_items.each do |item|
                        afters["#{file}##{options[:setting]}"][item] = [] if !afters["#{file}##{options[:setting]}"][item]
                      end
                      #Chef::Log.debug "afters: #{@@afters}"
                      new_value = "\"#{afters["#{file}##{options[:setting]}"].tsort.join(' ')}\""
                    else
                      #Chef::Log.debug "no afters found"
                      new_value = "\"#{list_items.sort.join(' ')}\""
                    end
                  else
                    if options[:value] == ''
                      new_value = '""' # print an empty string instead of leaving the value blank
                    else
                      new_value = "#{options[:value]}"
                    end
                  end
                  new_line  = "#{line_prefix.sub(options[:comment], '')}"
                  new_line += "#{options[:prefix]}#{s_prefix_suffix}" if options[:prefix]
                  new_line += "#{options[:setting]}#{equals_prefix}#{options[:equals]}#{equals_suffix}#{new_value}#{line_suffix}\n"
                else
                  new_line = old_line
                end
              else
                if old_line.gsub(/\s{2,}/, ' ').include?(options[:value].gsub(/\s{2,}/, ' '))
                  next if found
                  found = true
                end
                new_line = old_line
              end
              new_contents << new_line unless found && options[:remove]
      #        if old_line != new_line
      #          puts "old: #{old_line}"
      #          puts "new: #{new_line}"
      #        end
            end
          end

          if !found && !options[:remove]
            if options[:setting]
              case options[:format]
              when :space_delimited_list
                new_value = "\"#{options[:value]}\""
              else
                if options[:value] == ''
                  new_value = '""' # print an empty string instead of leaving the value blank
                else
                  new_value = "#{options[:value]}"
                end
              end
              new_line = "#{options[:prefix] + ' ' if options[:prefix]}#{options[:setting]}#{options[:equals]}#{new_value}\n"
            else
              new_line = "#{options[:value]}\n"
            end
            # puts "new: #{new_line}"
            new_contents << "\n" if old_contents && !old_contents.empty? && old_contents[-1] != "\n"
            new_contents << new_line
          end

          new_contents = new_contents.gsub(/\n{2,}/, "\n\n") # remove extra lines
          #Chef::Log.debug 'new_contents:'

          if old_contents != new_contents
            files[file] = new_contents
            ::File.write('/etc/rc.conf.local', new_contents)
          end
        end

      end
    end
  end
end
