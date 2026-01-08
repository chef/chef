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

class Chef
  module Compliance
    class Profile
      # @return [Boolean] if the profile has been enabled
      attr_accessor :enabled

      # @return [String] The full path on the host to the profile inspec.yml
      attr_reader :path

      # @return [String] The name of the cookbook that the profile is in
      attr_reader :cookbook_name

      # @return [String] the pathname in the cookbook
      attr_accessor :pathname

      # @return [Chef::EventDispatch::Dispatcher] Event dispatcher for this run.
      attr_reader :events

      # @api private
      attr_reader :data

      def initialize(events, data, path, cookbook_name)
        @events = events
        @data = data
        @path = path
        @cookbook_name = cookbook_name
        @pathname = File.basename(File.dirname(path))
        disable!
        validate!
      end

      # @return [String] name of the inspec profile from parsing the inspec.yml
      def name
        @data["name"]
      end

      # @return [String] version of the inspec profile from parsing the inspec.yml
      def version
        @data["version"]
      end

      # Raises if the inspec profile is not valid.
      #
      def validate!
        raise "Inspec profile at #{path} has no name" unless name
      end

      # @return [Boolean] if the profile has been enabled
      def enabled?
        !!@enabled
      end

      # Set the profile to being enabled
      #
      def enable!
        events.compliance_profile_enabled(self)
        @enabled = true
      end

      # Set the profile as being disabled
      #
      def disable!
        @enabled = false
      end

      # Render the profile in a way that it can be consumed by inspec
      #
      def inspec_data
        { name: name, path: File.dirname(path) }
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

      # Helper to construct a profile object from a hash.  Since the path and
      # cookbook_name are required this is probably not externally useful.
      #
      def self.from_hash(events, hash, path, cookbook_name)
        new(events, hash, path, cookbook_name)
      end

      # Helper to construct a profile object from a yaml string.  Since the path
      # and cookbook_name are required this is probably not externally useful.
      #
      def self.from_yaml(events, string, path, cookbook_name)
        from_hash(events, YAML.safe_load(string, permitted_classes: [Date]), path, cookbook_name)
      end

      # @param filename [String] full path to the inspec.yml file in the cookbook
      # @param cookbook_name [String] cookbook that the profile is in
      #
      def self.from_file(events, filename, cookbook_name)
        from_yaml(events, IO.read(filename), filename, cookbook_name)
      end
    end
  end
end
