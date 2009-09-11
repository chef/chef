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
        action_run
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

        status = popen4("erl_call -e #{distributed} #{cookie} #{node}") do |pid, stdin, stdout, stderr|
          Chef::Log.info("Running erl_call '#{@new_resource.name}' on '#{@new_resource.node_name}'")
          @new_resource.code.each { |line| stdin.puts "#{line}" }
          stdin.close
          Chef::Log.debug("Output from erl_call on '#{@new_resource.node_name}': ")
          stdout.each { |line| Chef::Log.debug("#{line}")}
        end
      end

    end
  end
end
