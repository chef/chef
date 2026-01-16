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

require_relative "profile"

class Chef
  module Compliance
    class ProfileCollection < Array

      # Event dispatcher for this run.
      #
      # @return [Chef::EventDispatch::Dispatcher]
      #
      attr_reader :events

      def initialize(events)
        @events = events
      end

      # Add a profile to the profile collection.  The cookbook_name needs to be determined by the
      # caller and is used in the `include_profile` API to match on.  The path should be the complete
      # path on the host of the inspec.yml file, including the filename.
      #
      # @param path [String]
      # @param cookbook_name [String]
      #
      def from_file(path, cookbook_name)
        new_profile = Profile.from_file(events, path, cookbook_name)
        self << new_profile
        events&.compliance_profile_loaded(new_profile)
      end

      # @return [Boolean] if any of the profiles are enabled
      def using_profiles?
        any?(&:enabled?)
      end

      # @return [Array<Profile>] inspec profiles which are enabled in a form suitable to pass to inspec
      #
      def inspec_data
        select(&:enabled?).each_with_object([]) { |profile, arry| arry << profile.inspec_data }
      end

      # DSL method to enable profile files.  This matches on the name of the profile being included it
      # does not match on the filename of the input file.  If the specific profile is omitted then
      # it uses the default profile. The string supports regular expression matching.
      #
      # @example Specific profile in a cookbook
      #
      # include_profile "acme_cookbook::ssh-001"
      #
      # @example The profile named "default" in a cookbook
      #
      # include_profile "acme_cookbook"
      #
      # @example Every profile in a cookbook
      #
      # include_profile "acme_cookbook::.*"
      #
      # @example Matching profiles by regexp in a cookbook
      #
      # include_profile "acme_cookbook::ssh.*"
      #
      # @example Matching profiles by regexp in any cookbook in the cookbook collection
      #
      # include_profile ".*::ssh.*"
      #
      def include_profile(arg)
        (cookbook_name, profile_name) = arg.split("::")

        profile_name = "default" if profile_name.nil?

        profiles = select { |profile| /^#{cookbook_name}$/.match?(profile.cookbook_name) && /^#{profile_name}$/.match?(profile.pathname) }

        if profiles.empty?
          raise "No inspec profiles matching '#{profile_name}' found in cookbooks matching '#{cookbook_name}'"
        end

        profiles.each(&:enable!)
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
    end
  end
end
