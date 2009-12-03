#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require 'chef/knife'
require 'chef/node'
require 'json'

class Chef
  class Knife
    class NodeBulkDelete < Knife

      banner "Sub-Command: node bulk delete (options)"

      option :regex,
        :short => "-r [REGEX]",
        :long  => "--regex [REGEX]",
        :description => "Narrow the operation via regular expression"

      def run 
        nodes = Chef::Node.list(true)

        if config[:regex]
          to_delete = Hash.new
          nodes.each_key do |node_name|
            next if config[:regex] && node_name !~ /#{config[:regex]}/
            to_delete[node_name] = nodes[node_name]
          end
        else
          to_delete = nodes 
        end

        json_pretty_print(format_list_for_display(to_delete))
       
        confirm("Do you really want to delete the above nodes")
      
        to_delete.each do |name, node|
          node.destroy
          json_pretty_print(format_for_display(node)) if config[:print_after]
          Chef::Log.warn("Deleted node #{name}")
        end
      end

    end
  end
end




