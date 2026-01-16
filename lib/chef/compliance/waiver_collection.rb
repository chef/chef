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

require_relative "waiver"

class Chef
  module Compliance
    class WaiverCollection < Array

      # Event dispatcher for this run.
      #
      # @return [Chef::EventDispatch::Dispatcher]
      #
      attr_reader :events

      def initialize(events)
        @events = events
      end

      # Add a waiver to the waiver collection.  The cookbook_name needs to be determined by the
      # caller and is used in the `include_waiver` API to match on.  The path should be the complete
      # path on the host of the yml file, including the filename.
      #
      # @param path [String]
      # @param cookbook_name [String]
      #
      def from_file(filename, cookbook_name)
        new_waiver = Waiver.from_file(events, filename, cookbook_name)
        self << new_waiver
        events&.compliance_waiver_loaded(new_waiver)
      end

      # Add a waiver from a raw hash.  This waiver will be enabled by default.
      #
      # @param path [String]
      # @param cookbook_name [String]
      #
      def from_hash(hash)
        new_waiver = Waiver.from_hash(events, hash)
        new_waiver.enable!
        self << new_waiver
      end

      # @return [Array<Waiver>] inspec waivers which are enabled in a form suitable to pass to inspec
      #
      def inspec_data
        select(&:enabled?).each_with_object({}) { |waiver, hash| hash.merge!(waiver.inspec_data) }
      end

      # DSL method to enable waiver files.  This matches on the filename of the waiver file.
      # If the specific waiver is omitted then it uses the default waiver. The string
      # supports regular expression matching.
      #
      # @example Specific waiver file in a cookbook
      #
      # include_waiver "acme_cookbook::ssh-001"
      #
      # @example The compliance/waiver/default.rb waiver file in a cookbook
      #
      # include_waiver "acme_cookbook"
      #
      # @example Every waiver file in a cookbook
      #
      # include_waiver "acme_cookbook::.*"
      #
      # @example Matching waivers by regexp in a cookbook
      #
      # include_waiver "acme_cookbook::ssh.*"
      #
      # @example Matching waivers by regexp in any cookbook in the cookbook collection
      #
      # include_waiver ".*::ssh.*"
      #
      # @example Adding an arbitrary hash of data (not from any file in a cookbook)
      #
      # include_waiver({ "ssh-01" => {
      #   "expiration_date" => "2033-07-31",
      #   "run" => false,
      #   "justification" => "the reason it is waived",
      # } })
      #
      def include_waiver(arg)
        raise "include_waiver was given a nil value" if arg.nil?

        # if we're given a hash argument just shove it in the collection
        if arg.is_a?(Hash)
          from_hash(arg)
          return
        end

        matching_waivers!(arg).each(&:enable!)
      end

      def valid?(arg)
        !matching_waivers(arg).empty?
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

      private

      def matching_waivers(arg, should_raise: false)
        (cookbook_name, waiver_name) = arg.split("::")

        waiver_name = "default" if waiver_name.nil?

        waivers = select { |waiver| /^#{cookbook_name}$/.match?(waiver.cookbook_name) && /^#{waiver_name}$/.match?(waiver.pathname) }

        if waivers.empty? && should_raise
          raise "No inspec waivers matching '#{waiver_name}' found in cookbooks matching '#{cookbook_name}'"
        end

        waivers
      end

      def matching_waivers!(arg)
        matching_waivers(arg, should_raise: true)
      end
    end
  end
end
