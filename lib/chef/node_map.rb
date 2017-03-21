#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2014-2017, Chef Software Inc.
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
  class NodeMap

    #
    # Set a key/value pair on the map with a filter.  The filter must be true
    # when applied to the node in order to retrieve the value.
    #
    # @param key [Object] Key to store
    # @param value [Object] Value associated with the key
    # @param filters [Hash] Node filter options to apply to key retrieval
    #
    # @yield [node] Arbitrary node filter as a block which takes a node argument
    #
    # @return [NodeMap] Returns self for possible chaining
    #
    def set(key, value, platform: nil, platform_version: nil, platform_family: nil, os: nil, canonical: nil, override: nil, &block)
      filters = {}
      filters[:platform] = platform if platform
      filters[:platform_version] = platform_version if platform_version
      filters[:platform_family] = platform_family if platform_family
      filters[:os] = os if os
      new_matcher = { value: value, filters: filters }
      new_matcher[:block] = block if block
      new_matcher[:canonical] = canonical if canonical
      new_matcher[:override] = override if override

      # The map is sorted in order of preference already; we just need to find
      # our place in it (just before the first value with the same preference level).
      insert_at = nil
      map[key] ||= []
      map[key].each_with_index do |matcher, index|
        cmp = compare_matchers(key, new_matcher, matcher)
        insert_at ||= index if cmp && cmp <= 0
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
    # @param canonical [Boolean] `true` or `false` to match canonical or
    #   non-canonical values only. `nil` to ignore canonicality.  Default: `nil`
    #
    # @return [Object] Value
    #
    def get(node, key, canonical: nil)
      raise ArgumentError, "first argument must be a Chef::Node" unless node.is_a?(Chef::Node) || node.nil?
      list(node, key, canonical: canonical).first
    end

    #
    # List all matches for the given node and key from the NodeMap, from
    # most-recently added to oldest.
    #
    # @param node [Chef::Node] The Chef::Node object for the run, or `nil` to
    #   ignore all filters.
    # @param key [Object] Key to look up
    # @param canonical [Boolean] `true` or `false` to match canonical or
    #   non-canonical values only. `nil` to ignore canonicality.  Default: `nil`
    #
    # @return [Object] Value
    #
    def list(node, key, canonical: nil)
      raise ArgumentError, "first argument must be a Chef::Node" unless node.is_a?(Chef::Node) || node.nil?
      return [] unless map.has_key?(key)
      map[key].select do |matcher|
        node_matches?(node, matcher) && canonical_matches?(canonical, matcher)
      end.map { |matcher| matcher[:value] }
    end

    # Seriously, don't use this, it's nearly certain to change on you
    # @return remaining
    # @api private
    def delete_canonical(key, value)
      remaining = map[key]
      if remaining
        remaining.delete_if { |matcher| matcher[:canonical] && Array(matcher[:value]) == Array(value) }
        if remaining.empty?
          map.delete(key)
          remaining = nil
        end
      end
      remaining
    end

    private

    #
    # Succeeds if:
    # - no negative matches (!value)
    # - at least one positive match (value or :all), or no positive filters
    #
    def matches_black_white_list?(node, filters, attribute)
      # It's super common for the filter to be nil.  Catch that so we don't
      # spend any time here.
      return true if !filters[attribute]
      filter_values = Array(filters[attribute])
      value = node[attribute]

      # Split the blacklist and whitelist
      blacklist, whitelist = filter_values.partition { |v| v.is_a?(String) && v.start_with?("!") }

      # If any blacklist value matches, we don't match
      return false if blacklist.any? { |v| v[1..-1] == value }

      # If the whitelist is empty, or anything matches, we match.
      whitelist.empty? || whitelist.any? { |v| v == :all || v == value }
    end

    def matches_version_list?(node, filters, attribute)
      # It's super common for the filter to be nil.  Catch that so we don't
      # spend any time here.
      return true if !filters[attribute]
      filter_values = Array(filters[attribute])
      value = node[attribute]

      filter_values.empty? ||
        Array(filter_values).any? do |v|
          Chef::VersionConstraint::Platform.new(v).include?(value)
        end
    end

    def filters_match?(node, filters)
      matches_black_white_list?(node, filters, :os) &&
        matches_black_white_list?(node, filters, :platform_family) &&
        matches_black_white_list?(node, filters, :platform) &&
        matches_version_list?(node, filters, :platform_version)
    end

    def block_matches?(node, block)
      return true if block.nil?
      block.call node
    end

    def node_matches?(node, matcher)
      return true if !node
      filters_match?(node, matcher[:filters]) && block_matches?(node, matcher[:block])
    end

    def canonical_matches?(canonical, matcher)
      return true if canonical.nil?
      !!canonical == !!matcher[:canonical]
    end

    # @api private
    def dispatch_compare_matchers(key, new_matcher, matcher)
      cmp = compare_matcher_properties(new_matcher, matcher) { |m| m[:block] }
      return cmp if cmp != 0
      cmp = compare_matcher_properties(new_matcher, matcher) { |m| m[:filters][:platform_version] }
      return cmp if cmp != 0
      cmp = compare_matcher_properties(new_matcher, matcher) { |m| m[:filters][:platform] }
      return cmp if cmp != 0
      cmp = compare_matcher_properties(new_matcher, matcher) { |m| m[:filters][:platform_family] }
      return cmp if cmp != 0
      cmp = compare_matcher_properties(new_matcher, matcher) { |m| m[:filters][:os] }
      return cmp if cmp != 0
      cmp = compare_matcher_properties(new_matcher, matcher) { |m| m[:override] }
      return cmp if cmp != 0
      # If all things are identical, return 0
      0
    end

    #
    # "provides" lines with identical filters sort by class name (ascending).
    #
    def compare_matchers(key, new_matcher, matcher)
      cmp = dispatch_compare_matchers(key, new_matcher, matcher)
      if cmp == 0
        # Sort by class name (ascending) as well, if all other properties
        # are exactly equal
        if new_matcher[:value].is_a?(Class) && !new_matcher[:override]
          cmp = compare_matcher_properties(new_matcher, matcher) { |m| m[:value].name }
        end
      end
      cmp
    end

    def compare_matcher_properties(new_matcher, matcher)
      a = yield(new_matcher)
      b = yield(matcher)

      # Check for blcacklists ('!windows'). Those always come *after* positive
      # whitelists.
      a_negated = Array(a).any? { |f| f.is_a?(String) && f.start_with?("!") }
      b_negated = Array(b).any? { |f| f.is_a?(String) && f.start_with?("!") }
      if a_negated != b_negated
        return 1 if a_negated
        return -1 if b_negated
      end

      # We treat false / true and nil / not-nil with the same comparison
      a = nil if a == false
      b = nil if b == false
      cmp = a <=> b
      # This is the case where one is non-nil, and one is nil. The one that is
      # nil is "greater" (i.e. it should come last).
      if cmp.nil?
        return 1 if a.nil?
        return -1 if b.nil?
      end
      cmp
    end

    def map
      @map ||= {}
    end
  end
end
