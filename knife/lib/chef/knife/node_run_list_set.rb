#
# Author:: Mike Fiedler (<miketheman@gmail.com>)
# Copyright:: Copyright 2013-2016, Mike Fiedler
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
    class NodeRunListSet < Knife

      deps do
        require "chef/node" unless defined?(Chef::Node)
        require "chef/json_compat" unless defined?(Chef::JSONCompat)
      end

      banner "knife node run_list set NODE ENTRIES (options)"

      def run
        if @name_args.size < 2
          ui.fatal "You must supply both a node name and a run list."
          show_usage
          exit 1
        elsif @name_args.size > 2
          # Check for nested lists and create a single plain one
          entries = @name_args[1..].map do |entry|
            entry.split(",").map(&:strip)
          end.flatten
        else
          # Convert to array and remove the extra spaces
          entries = @name_args[1].split(",").map(&:strip)
        end
        node = Chef::Node.load(@name_args[0])

        set_run_list(node, entries)

        node.save

        config[:run_list] = true

        output(format_for_display(node))
      end

      # Clears out any existing run_list_items and sets them to the
      # specified entries
      def set_run_list(node, entries)
        node.run_list.run_list_items.clear
        entries.each { |e| node.run_list << e }
      end

    end
  end
end
