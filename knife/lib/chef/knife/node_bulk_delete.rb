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
    class NodeBulkDelete < Knife

      deps do
        require "chef/node" unless defined?(Chef::Node)
        require "chef/json_compat" unless defined?(Chef::JSONCompat)
      end

      banner "knife node bulk delete REGEX (options)"

      def run
        if name_args.length < 1
          ui.fatal("You must supply a regular expression to match the results against")
          exit 42
        end

        nodes_to_delete = {}
        matcher = /#{name_args[0]}/

        all_nodes.each do |name, node|
          next unless name&.match?(matcher)

          nodes_to_delete[name] = node
        end

        if nodes_to_delete.empty?
          ui.msg "No nodes match the expression /#{name_args[0]}/"
          exit 0
        end

        ui.msg("The following nodes will be deleted:")
        ui.msg("")
        ui.msg(ui.list(nodes_to_delete.keys.sort, :columns_down))
        ui.msg("")
        ui.confirm("Are you sure you want to delete these nodes")

        nodes_to_delete.sort.each do |name, node|
          node.destroy
          ui.msg("Deleted node #{name}")
        end
      end

      def all_nodes
        node_uris_by_name = Chef::Node.list

        node_uris_by_name.keys.inject({}) do |nodes_by_name, name|
          nodes_by_name[name] = Chef::Node.new.tap { |n| n.name(name) }
          nodes_by_name
        end
      end

    end
  end
end
