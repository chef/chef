#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require "yaml"

class Chef
  module Compliance
    #
    # Chef object that represents a single input file in the compliance segment
    # of a cookbook.
    #
    class Input
      # @return [Boolean] if the input has been enabled
      attr_reader :enabled

      # @return [String] The name of the cookbook that the input is in
      attr_reader :cookbook_name

      # @return [String] The full path on the host to the input yml file
      attr_reader :path

      # @return [String] the pathname in the cookbook
      attr_reader :pathname

      # Event dispatcher for this run.
      #
      # @return [Chef::EventDispatch::Dispatcher]
      #
      attr_reader :events

      # @api private
      attr_reader :data

      def initialize(events, data, path, cookbook_name)
        @events = events
        @data = data
        @cookbook_name = cookbook_name
        @path = path
        @pathname = File.basename(path, File.extname(path)) unless path.nil?
        disable!
      end

      # @return [Boolean] if the input has been enabled
      #
      def enabled?
        !!@enabled
      end

      # Set the input to being enabled
      #
      def enable!
        events.compliance_input_enabled(self)
        @enabled = true
      end

      # Set the input as being disabled
      #
      def disable!
        @enabled = false
      end

      # Render the input in a way that it can be consumed by inspec
      #
      def inspec_data
        data
      end

      HIDDEN_IVARS = [ :@events ].freeze

      # Omit the event object from error output
      #
      def inspect
        ivar_string = (instance_variables.map(&:to_sym) - HIDDEN_IVARS).map do |ivar|
          "#{ivar}=#{instance_variable_get(ivar).inspect}"
        end.join(", ")
        "#<#{self.class}:#{object_id} #{ivar_string}>"
      end

      # Helper to construct a input object from a hash.  Since the path and
      # cookbook_name are required this is probably not externally useful.
      #
      def self.from_hash(events, hash, path = nil, cookbook_name = nil)
        new(events, hash, path, cookbook_name)
      end

      # Helper to construct a input object from a yaml string.  Since the path
      # and cookbook_name are required this is probably not externally useful.
      #
      def self.from_yaml(events, string, path = nil, cookbook_name = nil)
        from_hash(events, YAML.safe_load(string, permitted_classes: [Date]), path, cookbook_name)
      end

      # @param filename [String] full path to the yml file in the cookbook
      # @param cookbook_name [String] cookbook that the input is in
      #
      def self.from_file(events, filename, cookbook_name = nil)
        from_yaml(events, IO.read(filename), filename, cookbook_name)
      end
    end
  end
end
