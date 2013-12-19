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

class Chef
  class Knife
    class NodeRunListAdd < Knife

      deps do
        require 'chef/node'
        require 'chef/json_compat'
      end

      banner "knife node run_list add [NODE] [ENTRY[,ENTRY]] (options)"

      option :after,
        :short => "-a ITEM",
        :long  => "--after ITEM",
        :description => "Place the ENTRY in the run list after ITEM"

      option :before,
             :short => "-b ITEM",
             :long  => "--before ITEM",
             :description => "Place the ENTRY in the run list before ITEM"

      def run
        node = Chef::Node.load(@name_args[0])
        if @name_args.size > 2
          # Check for nested lists and create a single plain one
          entries = @name_args[1..-1].map do |entry|
            entry.split(',').map { |e| e.strip }
          end.flatten
        else
          # Convert to array and remove the extra spaces
          entries = @name_args[1].split(',').map { |e| e.strip }
        end

        if config[:after] && config[:before]
          raise ArgumentError, "You cannot specify both --before and --after"
        end

        if config[:after]
          add_to_run_list(node, entries, :after, config[:after])
        elsif config[:before]
          add_to_run_list(node, entries, :before, config[:before])
        else
          add_to_run_list(node, entries)
        end

        node.save

        config[:run_list] = true

        output(format_for_display(node))
      end

      def add_to_run_list(node, entries, after_or_before=nil, item=nil)
        if after_or_before
          nlist = []
          node.run_list.each do |entry|
            if after_or_before == :after && entry == item
              nlist << entry
              entries.each { |e| nlist << e }
            elsif after_or_before == :before && entry == item
              entries.each { |e| nlist << e }
              nlist << entry
            else
              nlist << entry
            end
          end
          node.run_list.reset!(nlist)
        else
          entries.each { |e| node.run_list << e }
        end
      end

    end
  end
end
