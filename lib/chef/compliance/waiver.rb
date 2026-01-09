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
    # Chef object that represents a single waiver file in the compliance
    # segment of a cookbook
    #
    class Waiver
      # @return [Boolean] if the waiver has been enabled
      attr_reader :enabled

      # @return [String] The name of the cookbook that the waiver is in
      attr_reader :cookbook_name

      # @return [String] The full path on the host to the waiver yml file
      attr_reader :path

      # @return [String] the pathname in the cookbook
      attr_reader :pathname

      # @api private
      attr_reader :data

      # Event dispatcher for this run.
      #
      # @return [Chef::EventDispatch::Dispatcher]
      #
      attr_accessor :events

      def initialize(events, data, path, cookbook_name)
        @events = events
        @data = data
        @cookbook_name = cookbook_name
        @path = path
        @pathname = File.basename(path, File.extname(path)) unless path.nil?
        disable!
      end

      # @return [Boolean] if the waiver has been enabled
      #
      def enabled?
        !!@enabled
      end

      # Set the waiver to being enabled
      #
      def enable!
        events.compliance_waiver_enabled(self)
        @enabled = true
      end

      # Set the waiver as being disabled
      #
      def disable!
        @enabled = false
      end

      # Render the waiver in a way that it can be consumed by inspec
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

      # Helper to construct a waiver object from a hash.  Since the path and
      # cookbook_name are required this is probably not externally useful.
      #
      def self.from_hash(events, hash, path = nil, cookbook_name = nil)
        new(events, hash, path, cookbook_name)
      end

      # Helper to construct a waiver object from a yaml string.  Since the path
      # and cookbook_name are required this is probably not externally useful.
      #
      def self.from_yaml(events, string, path = nil, cookbook_name = nil)
        from_hash(events, YAML.safe_load(string, permitted_classes: [Date]), path, cookbook_name)
      end

      # @param filename [String] full path to the yml file in the cookbook
      # @param cookbook_name [String] cookbook that the waiver is in
      #
      def self.from_file(events, filename, cookbook_name = nil)
        from_yaml(events, IO.read(filename), filename, cookbook_name)
      end
    end
  end
end
