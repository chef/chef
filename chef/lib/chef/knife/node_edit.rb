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
    class NodeEdit < Knife

      banner "Sub-Command: node edit NODE (options)"

      option :attribute,
        :short => "-a [ATTR]",
        :long => "--attribute [ATTR]",
        :description => "Edit only one attribute"

      def run 
        node = Chef::Node.load(@name_args[0])

        if config[:attribute]
          attr_bits = config[:attribute].split(".")
          to_edit = node
          attr_bits.each do |attr|
            to_edit = to_edit[attr]
          end

          edited_data = edit_data(to_edit)

          walker = node
          attr_bits.each_index do |i|
            if (attr_bits.length - 1) == i
              walker[attr_bits[i]] = edited_data
            else
              walker = walker[attr_bits[i]]
            end
          end
          new_node = node
        else
          new_node = edit_data(node)
        end
        
        new_node.save

        Chef::Log.info("Saved #{new_node}")

        json_pretty_print(format_for_display(node)) if config[:print_after]
      end
    end
  end
end


