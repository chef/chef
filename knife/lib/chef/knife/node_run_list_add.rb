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
    class NodeRunListAdd < Knife

      deps do
        require "chef/node" unless defined?(Chef::Node)
        require "chef/json_compat" unless defined?(Chef::JSONCompat)
      end

      banner "knife node run_list add [NODE] [ENTRY [ENTRY]] (options)"

      option :after,
        short: "-a ITEM",
        long: "--after ITEM",
        description: "Place the ENTRY in the run list after ITEM."

      option :before,
        short: "-b ITEM",
        long: "--before ITEM",
        description: "Place the ENTRY in the run list before ITEM."

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

        if config[:after] && config[:before]
          ui.fatal("You cannot specify both --before and --after!")
          exit 1
        end

        if config[:after]
          add_to_run_list_after(node, entries, config[:after])
        elsif config[:before]
          add_to_run_list_before(node, entries, config[:before])
        else
          add_to_run_list_after(node, entries)
        end

        node.save

        config[:run_list] = true

        output(format_for_display(node))
      end

      private

      def add_to_run_list_after(node, entries, after = nil)
        if after
          nlist = []
          node.run_list.each do |entry|
            nlist << entry
            if entry == after
              entries.each { |e| nlist << e }
            end
          end
          node.run_list.reset!(nlist)
        else
          entries.each { |e| node.run_list << e }
        end
      end

      def add_to_run_list_before(node, entries, before)
        nlist = []
        node.run_list.each do |entry|
          if entry == before
            entries.each { |e| nlist << e }
          end
          nlist << entry
        end
        node.run_list.reset!(nlist)
      end

    end
  end
end
