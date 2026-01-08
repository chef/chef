#
# Author:: Adam Jacob (<adam@chef.io>)
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

autoload :ChefUtils, "chef-utils"
require_relative "../mixin/chef_utils_wiring" unless defined?(Chef::Mixin::ChefUtilsWiring)

class Chef
  module DSL
    # == Chef::DSL::PlatformIntrospection
    # Provides the DSL for platform-dependent switch logic, such as
    # #value_for_platform.
    module PlatformIntrospection
      include ChefUtils
      include Chef::Mixin::ChefUtilsWiring

      # Implementation class for determining platform dependent values
      class PlatformDependentValue

        # Create a platform dependent value object.
        # === Arguments
        # platform_hash (Hash) a hash of the same structure as Chef::Platform,
        # like this:
        #   {
        #     :debian => {:default => 'the value for all debian'}
        #     [:centos, :redhat, :fedora] => {:default => "value for all EL variants"}
        #     :ubuntu => { :default => "default for ubuntu", '10.04' => "value for 10.04 only"},
        #     :default => "the default when nothing else matches"
        #   }
        # * platforms can be specified as Symbols or Strings
        # * multiple platforms can be grouped by using an Array as the key
        # * values for platforms need to be Hashes of the form:
        #   {platform_version => value_for_that_version}
        # * the exception to the above is the default value, which is given as
        #   :default => default_value
        def initialize(platform_hash)
          @values = {}
          platform_hash.each { |platforms, value| set(platforms, value) }
        end

        def value_for_node(node)
          platform, version = node[:platform].to_s, node[:platform_version].to_s
          # Check if we match a version constraint via Chef::VersionConstraint::Platform and Chef::Version::Platform
          matched_value = match_versions(node)
          if @values.key?(platform) && @values[platform].key?(version)
            @values[platform][version]
          elsif matched_value
            matched_value
          elsif @values.key?(platform) && @values[platform].key?("default")
            @values[platform]["default"]
          elsif @values.key?("default")
            @values["default"]
          else
            nil
          end
        end

        private

        def match_versions(node)
          platform, version = node[:platform].to_s, node[:platform_version].to_s
          return nil unless @values.key?(platform)

          node_version = Chef::Version::Platform.new(version)
          key_matches = []
          keys = @values[platform].keys
          keys.each do |k|

            if Chef::VersionConstraint::Platform.new(k).include?(node_version)
              key_matches << k
            end
          rescue Chef::Exceptions::InvalidVersionConstraint => e
            Chef::Log.trace "Caught InvalidVersionConstraint. This means that a key in value_for_platform cannot be interpreted as a Chef::VersionConstraint::Platform."
            Chef::Log.trace(e)

          end
          return @values[platform][version] if key_matches.include?(version)

          case key_matches.length
          when 0
            nil
          when 1
            @values[platform][key_matches.first]
          else
            raise "Multiple matches detected for #{platform} with values #{@values}. The matches are: #{key_matches}"
          end
        rescue Chef::Exceptions::InvalidCookbookVersion => e
          # Lets not break because someone passes a weird string like 'default' :)
          Chef::Log.trace(e)
          Chef::Log.trace "InvalidCookbookVersion exceptions are common and expected here: the generic constraint matcher attempted to match something which is not a constraint. Moving on to next version or constraint"
          nil
        rescue Chef::Exceptions::InvalidPlatformVersion => e
          Chef::Log.trace "Caught InvalidPlatformVersion, this means that Chef::Version::Platform does not know how to turn #{node_version} into an x.y.z format"
          Chef::Log.trace(e)
          nil
        end

        def set(platforms, value)
          if platforms.to_s == "default"
            @values["default"] = value
          else
            assert_valid_platform_values!(platforms, value)
            Array(platforms).each { |platform| @values[platform.to_s] = normalize_keys(value) }
            value
          end
        end

        def normalize_keys(hash)
          hash.inject({}) do |h, key_value|
            keys, value = *key_value
            Array(keys).each do |key|
              h[key.to_s] = value
            end
            h
          end
        end

        def assert_valid_platform_values!(platforms, value)
          unless value.is_a?(Hash)
            msg = "platform dependent values must be specified in the format :platform => {:version => value} "
            msg << "you gave a value #{value.inspect} for platform(s) #{platforms}"
            raise ArgumentError, msg
          end
        end
      end

      # Given a hash similar to the one we use for Platforms, select a value from the hash.  Supports
      # per platform defaults, along with a single base default. Arrays may be passed as hash keys and
      # will be expanded.
      #
      # === Parameters
      # platform_hash:: A platform-style hash.
      #
      # === Returns
      # value:: Whatever the most specific value of the hash is.
      def value_for_platform(platform_hash)
        PlatformDependentValue.new(platform_hash).value_for_node(node)
      end

      # Given a list of platforms, returns true if the current recipe is being run on a node with
      # that platform, false otherwise.
      #
      # === Parameters
      # args:: A list of platforms. Each platform can be in string or symbol format.
      #
      # === Returns
      # true:: If the current platform is in the list
      # false:: If the current platform is not in the list
      def platform?(*args)
        has_platform = false

        args.flatten.each do |platform|
          has_platform = true if platform.to_s == node[:platform]
        end

        has_platform
      end

      # Implementation class for determining platform family dependent values
      class PlatformFamilyDependentValue

        # Create a platform family dependent value object.
        # === Arguments
        # platform_family_hash (Hash) a map of platform families to values.
        # like this:
        #   {
        #     :rhel => "value for all EL variants"
        #     :fedora =>  "value for fedora variants fedora and amazon" ,
        #     [:fedora, :rhel] => "value for all known redhat variants"
        #     :debian =>  "value for debian variants including debian, ubuntu, mint" ,
        #     :default => "the default when nothing else matches"
        #   }
        # * platform families can be specified as Symbols or Strings
        # * multiple platform families can be grouped by using an Array as the key
        # * values for platform families can be any object, with no restrictions. Some examples:
        #   - [:stop, :start]
        #   - "mysql-devel"
        #   - { :key => "value" }
        def initialize(platform_family_hash)
          @values = {}
          @values["default"] = nil
          platform_family_hash.each { |platform_families, value| set(platform_families, value) }
        end

        def value_for_node(node)
          if node.key?(:platform_family)
            platform_family = node[:platform_family].to_s
            if @values.key?(platform_family)
              @values[platform_family]
            else
              @values["default"]
            end
          else
            @values["default"]
          end
        end

        private

        def set(platform_family, value)
          if platform_family.to_s == "default"
            @values["default"] = value
          else
            Array(platform_family).each { |family| @values[family.to_s] = value }
            value
          end
        end
      end

      # Given a hash mapping platform families to values, select a value from the hash. Supports a single
      # base default if platform family is not in the map. Arrays may be passed as hash keys and will be
      # expanded
      #
      # === Parameters
      # platform_family_hash:: A hash in the form { platform_family_name => value }
      #
      # === Returns
      # value:: Whatever the most specific value of the hash is.
      def value_for_platform_family(platform_family_hash)
        PlatformFamilyDependentValue.new(platform_family_hash).value_for_node(node)
      end

      # Given a list of platform families, returns true if the current recipe is being run on a
      # node within that platform family, false otherwise.
      #
      # === Parameters
      # args:: A list of platform families. Each platform family can be in string or symbol format.
      #
      # === Returns
      # true:: if the current node platform family is in the list.
      # false:: if the current node platform family is not in the list.
      def platform_family?(*args)
        args.flatten.any? do |platform_family|
          platform_family.to_s == node[:platform_family]
        end
      end

      # a simple helper to determine if we're on a windows release pre-2012 / 8
      #
      # @deprecated Windows releases before Windows 2012 and 8 are no longer supported
      # @return [Boolean] Is the system older than Windows 8 / 2012
      def older_than_win_2012_or_8?(node = run_context.nil? ? nil : run_context.node)
        false # we don't support platforms that would be true
      end

      # ^^^^^^ NOTE: PLEASE DO NOT CONTINUE TO ADD THESE KINDS OF PLATFORM_VERSION APIS WITHOUT ^^^^^^^
      # ^^^^^^ GOING THROUGH THE DESIGN REVIEW PROCESS AND ADDRESS THE EXISTING CHEF-SUGAR ONES ^^^^^^^
      # ^^^^^^ DO "THE HARD RIGHT THING" AND ADDRESS THE BROADER PROBLEM AND FIX IT ALL.        ^^^^^^^
    end
  end
end
