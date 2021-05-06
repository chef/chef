#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Author:: Jordan Running (<jr@chef.io>)
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

require "chef/json_compat" unless defined?(Chef::JSONCompat)
require "chef/node" unless defined?(Chef::Node)

class Chef
  class Knife
    class NodeEditor
      attr_reader :node, :ui, :config
      private :node, :ui, :config

      # @param node [Chef::Node]
      # @param ui [Chef::Knife::UI]
      # @param config [Hash]
      def initialize(node, ui, config)
        @node, @ui, @config = node, ui, config
      end

      # Opens the node data (as JSON) in the user's editor and returns a new
      # {Chef::Node} reflecting the user's changes.
      #
      # @return [Chef::Node]
      def edit_node
        abort "You specified the --disable_editing option, nothing to edit" if config[:disable_editing]
        assert_editor_set!

        updated_node_data = ui.edit_hash(view)
        apply_updates(updated_node_data)
        @updated_node
      end

      # Returns an array of the names of properties that have been changed or
      # +false+ if none were changed.
      #
      # @return [Array<String>] if any properties have been changed.
      # @return [false] if no properties have been changed.
      def updated?
        return false if @updated_node.nil?

        pristine_copy = Chef::JSONCompat.parse(Chef::JSONCompat.to_json(node))
        updated_copy  = Chef::JSONCompat.parse(Chef::JSONCompat.to_json(@updated_node))

        updated_properties = %w{
          name
          chef_environment
          automatic
          default
          normal
          override
          policy_name
          policy_group
          run_list
        }.reject do |key|
          pristine_copy[key] == updated_copy[key]
        end

        updated_properties.any? && updated_properties
      end

      # @api private
      def view
        result = {
          "name" => node.name,
          "chef_environment" => node.chef_environment,
          "normal" => node.normal_attrs,
          "policy_name" => node.policy_name,
          "policy_group" => node.policy_group,
          "run_list" => node.run_list,
        }

        if config[:all_attributes]
          result["default"]   = node.default_attrs
          result["override"]  = node.override_attrs
          result["automatic"] = node.automatic_attrs
        end

        result
      end

      # @api private
      def apply_updates(updated_data)
        if node.name && node.name != updated_data["name"]
          ui.warn "Changing the name of a node results in a new node being created, #{node.name} will not be modified or removed."
          ui.confirm "Proceed with creation of new node"
        end

        data = updated_data.dup

        unless config[:all_attributes]
          data["automatic"] = node.automatic_attrs
          data["default"] = node.default_attrs
          data["override"] = node.override_attrs
        end

        @updated_node = Node.from_hash(data)
      end

      private

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
