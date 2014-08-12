#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'chef/json_compat'
require 'chef/node'
require 'tempfile'

class Chef
  class Knife
    class NodeEditor

      attr_reader :node
      attr_reader :ui
      attr_reader :config

      def initialize(node, ui, config)
        @node, @ui, @config = node, ui, config
      end

      def edit_node
        abort "You specified the --disable_editing option, nothing to edit" if config[:disable_editing]
        assert_editor_set!

        updated_node_data = @ui.edit_data(view)
        apply_updates(updated_node_data)
        @updated_node
      end

      def updated?
        pristine_copy = Chef::JSONCompat.parse(Chef::JSONCompat.to_json(node))
        updated_copy  = Chef::JSONCompat.parse(Chef::JSONCompat.to_json(@updated_node))
        unless pristine_copy == updated_copy
          updated_properties = %w{name normal chef_environment run_list default override automatic}.reject do |key|
             pristine_copy[key] == updated_copy[key]
          end
        end
        ( pristine_copy != updated_copy ) && updated_properties
      end

      private

      def view
        result = {}
        result["name"] = node.name
        result["chef_environment"] = node.chef_environment
        result["normal"] = node.normal_attrs
        result["run_list"] = node.run_list

        if config[:all_attributes]
          result["default"]   = node.default_attrs
          result["override"]  = node.override_attrs
          result["automatic"] = node.automatic_attrs
        end
        result
      end

      def apply_updates(updated_data)
        if node.name and node.name != updated_data["name"]
          ui.warn "Changing the name of a node results in a new node being created, #{node.name} will not be modified or removed."
          confirm = ui.confirm "Proceed with creation of new node"
        end

        @updated_node = Node.new.tap do |n|
          n.name( updated_data["name"] )
          n.chef_environment( updated_data["chef_environment"] )
          n.run_list( updated_data["run_list"])
          n.normal_attrs = updated_data["normal"]

          if config[:all_attributes]
            n.default_attrs   = updated_data["default"]
            n.override_attrs  = updated_data["override"]
            n.automatic_attrs = updated_data["automatic"]
          else
            n.default_attrs   = node.default_attrs
            n.override_attrs  = node.override_attrs
            n.automatic_attrs = node.automatic_attrs
          end
        end
      end

      def abort(message)
        ui.error(message)
        exit 1
      end

      def assert_editor_set!
        unless config[:editor]
          abort "You must set your EDITOR environment variable or configure your editor via knife.rb"
        end
      end

    end
  end
end
