#
# Author:: Joe Williams (<joe@joetify.com>)
# Copyright:: Copyright (c) 2009 Joe Williams
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
    class ErlCall < Chef::Provider
      include Chef::Mixin::Command

      def initialize(node, new_resource)
        super(node, new_resource)
      end

      def whyrun_supported?
        true
      end
      
      def load_current_resource
        true
      end

      def action_run
        case @new_resource.name_type
        when "sname"
          node = "-sname #{@new_resource.node_name}"
        when "name"
          node = "-name #{@new_resource.node_name}"
        end

        if @new_resource.cookie
          cookie = "-c #{@new_resource.cookie}"
        else
          cookie = ""
        end

        if @new_resource.distributed
          distributed = "-s"
        else
          distributed = ""
        end

        command = "erl_call -e #{distributed} #{node} #{cookie}"

        converge_by("run erlang block") do
          begin
            pid, stdin, stdout, stderr = popen4(command, :waitlast => true)

            Chef::Log.debug("#{@new_resource} running")
            Chef::Log.debug("#{@new_resource} command: #{command}")
            Chef::Log.debug("#{@new_resource} code: #{@new_resource.code}")

            @new_resource.code.each_line { |line| stdin.puts(line.chomp) }

            stdin.close

            Chef::Log.debug("#{@new_resource} output: ")

            stdout_output = ""
            stdout.each_line { |line| stdout_output << line }
            stdout.close

            stderr_output = ""
            stderr.each_line { |line| stderr_output << line }
            stderr.close

            # fail if stderr contains anything
            if stderr_output.length > 0
              raise Chef::Exceptions::ErlCall, stderr_output
            end

            # fail if the first 4 characters aren't "{ok,"
            unless stdout_output[0..3].include?('{ok,')
              raise Chef::Exceptions::ErlCall, stdout_output
            end

            @new_resource.updated_by_last_action(true)

            Chef::Log.debug("#{@new_resource} #{stdout_output}")
            Chef::Log.info("#{@new_resouce} ran successfully")
          ensure
            Process.wait(pid) if pid
          end
        end
      end

    end
  end
end
