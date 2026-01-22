#
# Author:: Lamont Granquist (<lamont@chef.io>)
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

#
# example of a NodeMap entry for the user resource (as typed on the DSL):
#
#  :user=>
#  [{:klass=>Chef::Resource::User::AixUser, :os=>"aix"},
#   {:klass=>Chef::Resource::User::DsclUser, :os=>"darwin"},
#   {:klass=>Chef::Resource::User::PwUser, :os=>"freebsd"},
#   {:klass=>Chef::Resource::User::LinuxUser, :os=>"linux"},
#   {:klass=>Chef::Resource::User::SolarisUser,
#    :os=>["omnios", "solaris2"]},
#   {:klass=>Chef::Resource::User::WindowsUser, :os=>"windows"}],
#
# the entries in the array are pre-sorted into priority order (blocks/platform_version/platform/platform_family/os/none) so that
# the first entry's :klass that matches the filter is returned when doing a get.
#
# note that as this examples show filter values may be a scalar string or an array of scalar strings.
#
# XXX: confusingly, in the *_priority_map the :klass may be an array of Strings of class names
#

require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class NodeMap
    COLLISION_WARNING = <<~EOH.gsub(/\s+/, " ").strip
      %{type_caps} %{key} built into %{client_name} is being overridden by the %{type} from a cookbook. Please upgrade your cookbook
        or remove the cookbook from your run_list.
    EOH

    #
    # Set a key/value pair on the map with a filter.  The filter must be true
    # when applied to the node in order to retrieve the value.
    #
    # @param key [Object] Key to store
    # @param value [Object] Value associated with the key
    # @param filters [Hash] Node filter options to apply to key retrieval
    # @param chef_version [String] version constraint to match against the running Chef::VERSION
    #
    # @yield [node] Arbitrary node filter as a block which takes a node argument
    #
    # @return [NodeMap] Returns self for possible chaining
    #
    def set(key, klass, platform: nil, platform_version: nil, platform_family: nil, os: nil, override: nil, chef_version: nil, target_mode: nil, agent_mode: true, &block)
      new_matcher = { klass: klass }
      new_matcher[:platform] = platform if platform
      new_matcher[:platform_version] = platform_version if platform_version
      new_matcher[:platform_family] = platform_family if platform_family
      new_matcher[:os] = os if os
      new_matcher[:block] = block if block
      new_matcher[:override] = override if override
      new_matcher[:target_mode] = target_mode
      new_matcher[:agent_mode] = agent_mode

      if chef_version && Chef::VERSION !~ chef_version
        return map
      end

      # Check if the key is already present and locked, unless the override is allowed.
      # The checks to see if we should reject, in order:
      # 1. Core override mode is not set.
      # 2. The key exists.
      # 3. At least one previous `provides` is now locked.
      if map[key] && map[key].any? { |matcher| matcher[:locked] } && !map[key].any? { |matcher| matcher[:cookbook_override].is_a?(String) ? Chef::VERSION =~ matcher[:cookbook_override] : matcher[:cookbook_override] }
        # If we ever use locked mode on things other than the resource and provider handler maps, this probably needs a tweak.
        type_of_thing = if klass < Chef::Resource
                          "resource"
                        elsif klass < Chef::Provider
                          "provider"
                        else
                          klass.superclass.to_s
                        end
        Chef::Log.warn( COLLISION_WARNING % { type: type_of_thing, key: key, type_caps: type_of_thing.capitalize, client_name: ChefUtils::Dist::Infra::PRODUCT } )
      end

      # The map is sorted in order of preference already; we just need to find
      # our place in it (just before the first value with the same preference level).
      insert_at = nil
      map[key] ||= []
      map[key].each_with_index do |matcher, index|
        cmp = compare_matchers(key, new_matcher, matcher)
        if cmp && cmp <= 0
          insert_at = index
          break
        end
      end
      if insert_at
        map[key].insert(insert_at, new_matcher)
      else
        map[key] << new_matcher
      end
      map
    end

    #
    # Get a value from the NodeMap via applying the node to the filters that
    # were set on the key.
    #
    # @param node [Chef::Node] The Chef::Node object for the run, or `nil` to
    #   ignore all filters.
    # @param key [Object] Key to look up
    #
    # @return [Object] Class
    #
    def get(node, key)
      return nil unless map.key?(key)

      map[key].map do |matcher|
        return matcher[:klass] if node_matches?(node, matcher)
      end
      nil
    end

    #
    # List all matches for the given node and key from the NodeMap, from
    # most-recently added to oldest.
    #
    # @param node [Chef::Node] The Chef::Node object for the run, or `nil` to
    #   ignore all filters.
    # @param key [Object] Key to look up
    #
    # @return [Object] Class
    #
    def list(node, key)
      return [] unless map.key?(key)

      map[key].select do |matcher|
        node_matches?(node, matcher)
      end.map { |matcher| matcher[:klass] }
    end

    # Remove a class from all its matchers in the node_map, will remove mappings completely if its the last matcher left
    #
    # Note that this leaks the internal structure out a bit, but the main consumer of this (poise/halite) cares only about
    # the keys in the returned Hash.
    #
    # @param klass [Class] the class to seek and destroy
    #
    # @return [Hash] deleted entries in the same format as the @map
    def delete_class(klass)
      raise "please use a Class type for the klass argument" unless klass.is_a?(Class)

      deleted = {}
      map.each do |key, matchers|
        deleted_matchers = []
        matchers.delete_if do |matcher|
          # because matcher[:klass] may be a string (which needs to die), coerce both to strings to compare somewhat canonically
          if matcher[:klass].to_s == klass.to_s
            deleted_matchers << matcher
            true
          end
        end
        deleted[key] = deleted_matchers unless deleted_matchers.empty?
        map.delete(key) if matchers.empty?
      end
      deleted
    end

    # Check if this map has been locked.
    #
    # @api internal
    # @since 14.2
    # @return [Boolean]
    def locked?
      if defined?(@locked)
        @locked
      else
        false
      end
    end

    # Set this map to locked mode. This is used to prevent future overwriting
    # of existing names.
    #
    # @api internal
    # @since 14.2
    # @return [void]
    def lock!
      map.each do |key, matchers|
        matchers.each do |matcher|
          matcher[:locked] = true
        end
      end
      @locked = true
    end

    private

    def platform_family_query_helper?(node, m)
      method = "#{m}?".to_sym
      ChefUtils::DSL::PlatformFamily.respond_to?(method) && ChefUtils::DSL::PlatformFamily.send(method, node)
    end

    #
    # Succeeds if:
    # - no negative matches (!value)
    # - at least one positive match (value or :all), or no positive filters
    #
    def matches_block_allow_list?(node, filters, attribute)
      # It's super common for the filter to be nil.  Catch that so we don't
      # spend any time here.
      return true unless filters[attribute]

      filter_values = Array(filters[attribute])
      value = node[attribute]

      # Split the blocklist and allowlist
      blocklist, allowlist = filter_values.partition { |v| v.is_a?(String) && v.start_with?("!") }

      if attribute == :platform_family
        # If any blocklist value matches, we don't match
        return false if blocklist.any? { |v| v[1..] == value || platform_family_query_helper?(node, v[1..]) }

        # If the allowlist is empty, or anything matches, we match.
        allowlist.empty? || allowlist.any? { |v| v == :all || v == value || platform_family_query_helper?(node, v) }
      else
        # If any blocklist value matches, we don't match
        return false if blocklist.any? { |v| v[1..] == value }

        # If the allowlist is empty, or anything matches, we match.
        allowlist.empty? || allowlist.any? { |v| v == :all || v == value }
      end
    end

    def matches_version_list?(node, filters, attribute)
      # It's super common for the filter to be nil.  Catch that so we don't
      # spend any time here.
      return true unless filters[attribute]

      filter_values = Array(filters[attribute])
      value = node[attribute]

      filter_values.empty? ||
        Array(filter_values).any? do |v|
          Gem::Requirement.new(v).satisfied_by?(Gem::Version.new(value))
        end
    end

    # Succeeds if:
    # - we are in target mode, and the target_mode filter is true
    # - we are not in target mode
    #
    def matches_target_mode?(filters)
      return true unless Chef::Config.target_mode?

      !!filters[:target_mode]
    end

    # Succeeds if:
    # - we are in agent mode, and the agent_mode filter is true
    # - we are not in agent mode
    #
    def matches_agent_mode?(filters)
      return true if Chef::Config.target_mode?

      !!filters[:agent_mode]
    end

    def filters_match?(node, filters)
      matches_block_allow_list?(node, filters, :os) &&
        matches_block_allow_list?(node, filters, :platform_family) &&
        matches_block_allow_list?(node, filters, :platform) &&
        matches_version_list?(node, filters, :platform_version) &&
        matches_target_mode?(filters) &&
        matches_agent_mode?(filters)
    end

    def block_matches?(node, block)
      return true if block.nil?

      block.call node
    end

    def node_matches?(node, matcher)
      return true unless node

      filters_match?(node, matcher) && block_matches?(node, matcher[:block])
    end

    #
    # "provides" lines with identical filters sort by class name (ascending).
    #
    def compare_matchers(key, new_matcher, matcher)
      cmp = compare_matcher_properties(new_matcher[:block], matcher[:block])
      return cmp if cmp != 0

      cmp = compare_matcher_properties(new_matcher[:platform_version], matcher[:platform_version])
      return cmp if cmp != 0

      cmp = compare_matcher_properties(new_matcher[:platform], matcher[:platform])
      return cmp if cmp != 0

      cmp = compare_matcher_properties(new_matcher[:platform_family], matcher[:platform_family])
      return cmp if cmp != 0

      cmp = compare_matcher_properties(new_matcher[:os], matcher[:os])
      return cmp if cmp != 0

      cmp = compare_matcher_properties(new_matcher[:override], matcher[:override])
      return cmp if cmp != 0

      # If all things are identical, return 0
      0
    end

    def compare_matcher_properties(a, b)
      # falsity comparisons here handle both "nil" and "false"
      return 1 if !a && b
      return -1 if !b && a
      return 0 if !a && !b

      # Check for blocklists ('!windows'). Those always come *after* positive
      # allowlists.
      a_negated = Array(a).any? { |f| f.is_a?(String) && f.start_with?("!") }
      b_negated = Array(b).any? { |f| f.is_a?(String) && f.start_with?("!") }
      return 1 if a_negated && !b_negated
      return -1 if b_negated && !a_negated

      a <=> b
    end

    def map
      @map ||= {}
    end
  end
end
