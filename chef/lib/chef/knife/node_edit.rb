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
require 'chef/json_compat'

class Chef
  class Knife

    module NodeEditController
      def edit_node
        abort "You specified the --no-editor option, nothing to edit" if config[:no_editor]
        assert_editor_set!

        updated_node_data = edit_data(view)
        apply_updates(updated_node_data)
        @updated_node
      end

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
        Chef::JSONCompat.to_json_pretty(result)
      end

      def edit_data(text)
        edited_data = tempfile_for(text) {|filename| system("#{config[:editor]} #{filename}")}
        Chef::JSONCompat.from_json(edited_data)
      end

      def apply_updates(updated_data)
        # TODO: should warn/error/ask for confirmation when changing the
        # name, since this results in a new node, not an edited node.
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

      def updated?
        pristine_copy = Chef::JSONCompat.from_json(Chef::JSONCompat.to_json(node), :create_additions => false)
        updated_copy  = Chef::JSONCompat.from_json(Chef::JSONCompat.to_json(@updated_node), :create_additions => false)
        unless pristine_copy == updated_copy
          updated_properties = %w{name normal chef_environment run_list default override automatic}.reject do |key|
             pristine_copy[key] == updated_copy[key]
          end
        end
        ( pristine_copy != updated_copy ) && updated_properties
      end

      private

      def abort(message)
        STDERR.puts("ERROR: #{message}")
        exit 1
      end

      def assert_editor_set!
        unless config[:editor]
          abort "You must set your EDITOR environment variable or configure your editor via knife.rb"
        end
      end

      def tempfile_for(data)
        # TODO: include useful info like the node name in the temp file
        # name
        basename = "knife-edit-" << rand(1_000_000_000_000_000).to_s.rjust(15, '0') << '.js'
        filename = File.join(Dir.tmpdir, basename)
        File.open(filename, "w+") do |f|
          f.sync = true
          f.puts data
        end

        yield filename

        IO.read(filename)
      ensure
        File.unlink(filename)
      end
    end

    class NodeEdit < Knife
      include NodeEditController

      attr_reader :node_name
      attr_reader :node

      banner "knife node edit NODE (options)"

      option :all_attributes,
        :short => "-a",
        :long => "--all",
        :boolean => true,
        :description => "Display all attributes when editing"

      def run
        node_name = @name_args[0]

        if node_name.nil?
          show_usage
          Chef::Log.fatal("You must specify a node name")
          exit 1
        end

        load_node(node_name)
        updated_node = edit_node
        if updated_values = updated?
          Log.info "Saving updated #{updated_values.join(', ')} on node #{node.name}"
          updated_node.save
        else
          Log.info "Node not updated, skipping node save"
        end
      end

      def load_node(node_name)
        @node = Chef::Node.load(node_name)
        # TODO: rescue errors with a helpful message
      end
    end
  end
end


