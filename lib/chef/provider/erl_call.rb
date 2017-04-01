#
# Author:: Joe Williams (<joe@joetify.com>)
# Copyright:: Copyright 2009-2016, Joe Williams
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
    class ErlCall < Chef::Provider

      provides :erl_call

      def initialize(node, new_resource)
        super(node, new_resource)
      end

      def load_current_resource
        true
      end

      def action_run
        case new_resource.name_type
        when "sname"
          node = "-sname #{new_resource.node_name}"
        when "name"
          node = "-name #{new_resource.node_name}"
        end

        if new_resource.cookie
          cookie = "-c #{new_resource.cookie}"
        else
          cookie = ""
        end

        if new_resource.distributed
          distributed = "-s"
        else
          distributed = ""
        end

        command = "erl_call -e #{distributed} #{node} #{cookie}"

        converge_by("run erlang block") do
          so = shell_out!(command, input: new_resource.code)

          # fail if stderr contains anything
          if so.stderr.length > 0
            raise Chef::Exceptions::ErlCall, so.stderr
          end

          # fail if the first 4 characters aren't "{ok,"
          unless so.stdout[0..3].include?("{ok,")
            raise Chef::Exceptions::ErlCall, so.stdout
          end

        end
      end

    end
  end
end
