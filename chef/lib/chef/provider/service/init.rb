#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
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

require File.join(File.dirname(__FILE__), "..", "service")
require File.join(File.dirname(__FILE__), "..", "..", "mixin", "command")

class Chef
  class Provider
    class Service
      class Init < Chef::Provider::Service

        def load_current_resource
          @current_resource = Chef::Resource::Service.new(@new_resource.name)
          @current_resource.service_name(@new_resource.service_name)
          @current_resource.running = false
          if @new_resource.supports[:status]
            if run_command(:command => "/etc/init.d/#{@current_resource.service_name} status") == 0
              @current_resource.running = true 
            end
          elsif @new_resource.status_command
            if run_command(:command => @new_resource.status_command) == 0
              @current_resource.running = true
            end
          else
            Chef::Log.debug("#{@new_resource} does not support status and you have not specified a status command, falling back to process table inspection")
            if @new_resource.pattern == @new_resource.service_name
              Chef::Log.debug("#{@new_resource} defaulting pattern to #{Regex.new(@new_resource.pattern)}") 
            elsif @node[:ps] == ""
              raise Chef::Exception::Service, "#{@new_resource}: Facter could not determine how to call `ps` on your system (#{@node[:ps]})"
            end

            process_pid = nil
            status = popen4(@node[:ps]) do |pid, stdin, stdout, stderr|
              stdin.close
              r = Regexp.new(@new_resource.pattern)
              Chef::Log.debug("#{@new_resource}: attempting to match #{@new_resource.pattern} (#{r}) against process table")
              stdout.each_line do |line|
                if r.match(line)
                  process_pid = line.sub(/^\s+/, '').split(/\s+/)[1]
                  @current_resource.running = true
                end
              end
            end
            unless status.exitstatus == 0
              raise Chef::Exception::Service, "Command #{@node[:ps]} failed"
            else
              Chef::Log.debug("#{@new_resource}: #{@node[:ps]} exited and parsed succesfully, process running: #{@current_resource.running}")
            end
          end

          @current_resource
        end

        def start_service(name)
          if @new_resource.start_command
            run_command(:command => @new_resource.start_command)
          else
            run_command(:command => "/etc/init.d/#{name} start")
          end
        end

        def stop_service(name)
          if @new_resource.stop_command
            run_command(:command => @new_resource.stop_command)
          else
            run_command(:command => "/etc/init.d/#{name} stop")
          end
        end

        def restart_service(name)
          if @new_resource.supports[:restart]
            run_command(:command => "/etc/init.d/#{name} restart")
          elsif @new_resource.restart_command
            run_command(:command => @new_resource.restart_command)
          else
            stop_service
            start_service
          end
        end

      end
    end
  end
end
