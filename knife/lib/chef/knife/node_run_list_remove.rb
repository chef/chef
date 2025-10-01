#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../knife"

class Chef
  class Knife
    class NodeRunListRemove < Knife

      deps do
        require "chef/node" unless defined?(Chef::Node)
        require "chef/json_compat" unless defined?(Chef::JSONCompat)
      end

      banner "knife node run_list remove [NODE] [ENTRY [ENTRY]] (options)"

      def run
        node = Chef::Node.load(@name_args[0])

        if @name_args.size > 2
          # Check for nested lists and create a single plain one
          entries = @name_args[1..].map do |entry|
            entry.split(",").map(&:strip)
          end.flatten
        else
          # Convert to array and remove the extra spaces
          entries = @name_args[1].split(",").map(&:strip)
        end

        # iterate over the list of things to remove,
        # warning if one of them was not found
        entries.each do |e|
          if node.run_list.find { |rli| e == rli.to_s }
            node.run_list.remove(e)
          else
            ui.warn "#{e} is not in the run list"
            unless /^(recipe|role)\[/.match?(e)
              ui.warn "(did you forget recipe[] or role[] around it?)"
            end
          end
        end

        node.save

        config[:run_list] = true

        output(format_for_display(node))
      end

    end
  end
end
