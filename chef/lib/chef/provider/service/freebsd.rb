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

require 'chef/provider/service'
require 'chef/mixin/command'

class Chef
  class Provider
    class Service
      class Freebsd < Chef::Provider::Service

        def load_current_resource
          @current_resource = Chef::Resource::Service.new(@new_resource.name)
          @current_resource.service_name(@new_resource.service_name)

          # Determine if we're talking about /etc/rc.d or /usr/local/etc/rc.d
          if ::File.exists?("/etc/rc.d/#{current_resource.service_name}")
            @service_path = "/etc/rc.d"
          elsif ::File.exists?("/usr/local/etc/rc.d/#{current_resource.service_name}")
            @service_path = "/usr/local/etc/rc.d"
          else
            raise Chef::Exception::Service, "#{@new_resource}: unable to locate the rc.d script"
          end
          Chef::Log.debug("#{@current_resource.name} found at #{@service_path}/#{@current_resource.service_name}")
            
          if @new_resource.supports[:status]
            Chef::Log.debug("#{@new_resource} supports status, checking state")

            begin
              if run_command(:command => "#{@service_path}/#{@current_resource.service_name} status") == 0
                @current_resource.running true
              end
            rescue Chef::Exception::Exec
              @current_resource.running false
              nil
            end

          elsif @new_resource.status_command
            Chef::Log.debug("#{@new_resource} doesn't support status but you have specified a status command, running..")

            begin
              if run_command(:command => @new_resource.status_command) == 0
                @current_resource.running true
              end
            rescue Chef::Exception::Exec
              @current_resource.running false
              nil
            end

          else
            Chef::Log.debug("#{@new_resource} does not support status and you have not specified a status command, falling back to process table inspection")

            if @node[:command][:ps].nil? or @node[:command][:ps].empty?
              raise Chef::Exception::Service, "#{@new_resource}: could not determine how to inspect the process table, please set this nodes 'ps' attribute"
            end

            status = popen4(@node[:command][:ps]) do |pid, stdin, stdout, stderr|
              stdin.close
              r = Regexp.new(@new_resource.pattern)
              Chef::Log.debug("#{@new_resource}: attempting to match #{@new_resource.pattern} (#{r}) against process table")
              stdout.each_line do |line|
                if r.match(line)
                  @current_resource.running true
                  break
                end
              end
              @current_resource.running false unless @current_resource.running
            end
            unless status.exitstatus == 0
              raise Chef::Exception::Service, "Command #{@node[:command][:ps]} failed"
            else
              Chef::Log.debug("#{@new_resource}: #{@node[:command][:ps]} exited and parsed succesfully, process running: #{@current_resource.running}")
            end
          end

          if ::File.exists?("/etc/rc.conf")
            rcfile = ::File.open("/etc/rc.conf")
            rcfile.each do |line|
              case line
              when /#{current_resource.service_name}_enable="(\w+)"/
                if $1 =~ /[Yy][Ee][Ss]/
                  @current_resource.enabled true
                elsif $1 =~ /[Nn][Oo][Nn]?[Oo]?[Nn]?[Ee]?/
                  @current_resource.enabled false
                end
              end
            end
          end
          unless @current_resource.enabled
            Chef::Log.debug("#{@new_resource.name} enable/disable state unknown")
          end
                  
          @current_resource
        end

        def start_service(name)
          if @new_resource.start_command
            run_command(:command => @new_resource.start_command)
          else
            run_command(:command => "#{@service_path}/#{name} start")
          end
        end

        def stop_service(name)
          if @new_resource.stop_command
            run_command(:command => @new_resource.stop_command)
          else
            run_command(:command => "#{@service_path}/#{name} stop")
          end
        end

        def restart_service(name)
          if @new_resource.supports[:restart]
            run_command(:command => "#{@service_path}/#{name} restart")
          elsif @new_resource.restart_command
            run_command(:command => @new_resource.restart_command)
          else
            stop_service(name)
            sleep 1
            start_service(name)
          end
        end

        def reload_service(name)
          if @new_resource.supports[:reload]
            run_command(:command => "#{@service_path}/#{name} reload")
          elsif @new_resource.reload_command
            run_command(:command => @new_resource.reload_command)
          end
        end
   
        def enable_service(name)
          unless @current_resource.enabled 
            rcfile = ::File.open("/etc/rc.conf", 'r')
            lines = rcfile.readlines
            lines.collect! do |line|
              if line =~ /#{current_resource.service_name}_enable/
                line = "#{current_resource.service_name}_enable=\"YES\""
              else 
                line = line
              end
            end
            rcfile.close
            rcfile = ::File.open("/etc/rc.conf", 'w')
            lines.each { |line| rcfile.puts(line) }
            rcfile.close
          end
        end

        def disable_service(name)
          if @current_resource.enabled
            rcfile = ::File.open("/etc/rc.conf", 'r')
            lines = rcfile.readlines
            lines.collect! do |line|
              if line =~ /#{current_resource.service_name}_enable/
                line = "#{current_resource.service_name}_enable=\"NO\""
              else 
                line = line
              end
            end
            rcfile.close
            rcfile = ::File.open("/etc/rc.conf", 'w')
            lines.each { |line| rcfile.puts(line) }
            rcfile.close
          end 
        end
     
      end
    end
  end
end
