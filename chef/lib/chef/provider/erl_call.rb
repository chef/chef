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
require 'chef/mixin/shell_out'
require 'chef/provider'

class Chef
  class Provider
    class ErlCall < Chef::Provider
      include Chef::Mixin::ShellOut

      def initialize(node, new_resource)
        super(node, new_resource)
      end

      def load_current_resource
        true
      end

      def action_run
        Chef::Log.debug("#{@new_resource} running")
        Chef::Log.debug("#{@new_resource} command: #{erl_call_cmd}")
        Chef::Log.debug("#{@new_resource} code: #{@new_resource.code}")

        status = shell_out!(erl_call_cmd, :input => @new_resource.code)

        Chef::Log.debug("#{@new_resource} output: ")

        # fail if stderr contains anything
        raise Chef::Exceptions::ErlCall, status.stderr unless status.stderr.empty?

        # fail if the first 4 characters aren't "{ok,"
        raise Chef::Exceptions::ErlCall, status.stdout unless status.stdout[0..3].include?('{ok,')

        @new_resource.updated_by_last_action(true)

        Chef::Log.debug("#{@new_resource} #{status.stdout}")
        Chef::Log.info("#{@new_resouce} ran successfully")
      end

      def erl_call_cmd
        @_erl_call_cmd ||= "erl_call -e #{erl_distributed} #{erl_node_name} #{erl_cookie}"
      end

      def erl_node_name
        case @new_resource.name_type
        when "sname" then "-sname #{@new_resource.node_name}"
        when "name"  then "-name #{@new_resource.node_name}"
        end
      end

      def erl_cookie
        @new_resource.cookie ? "-c #{@new_resource.cookie}" : ""
      end

      def erl_distributed
        @new_resource.distributed ? "-s" : ""
      end
    end
  end
end
