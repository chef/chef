#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

    VALID_OPTS = [
      :on_platform,
      :on_platforms,
      :platform,
      :os,
      :platform_family,
    ]

    DEPRECATED_OPTS = [
      :on_platform,
      :on_platforms,
    ]

    # Create a new NodeMap
    #
    def initialize
      @map = {}
    end

    # Set a key/value pair on the map with a filter.  The filter must be true
    # when applied to the node in order to retrieve the value.
    #
    # @param key [Object] Key to store
    # @param value [Object] Value associated with the key
    # @param filters [Hash] Node filter options to apply to key retrieval
    # @yield [node] Arbitrary node filter as a block which takes a node argument
    # @return [NodeMap] Returns self for possible chaining
    #
    def set(key, value, filters = {}, &block)
      validate_filter!(filters)
      deprecate_filter!(filters)
      @map[key] ||= []
      # we match on the first value we find, so we want to unshift so that the
      # last setter wins
      # FIXME: need a test for this behavior
      @map[key].unshift({ filters: filters, block: block, value: value })
      self
    end

    # Get a value from the NodeMap via applying the node to the filters that
    # were set on the key.
    #
    # @param node [Chef::Node] The Chef::Node object for the run
    # @param key [Object] Key to look up
    # @return [Object] Value
    #
    def get(node, key)
      # FIXME: real exception
      raise "first argument must be a Chef::Node" unless node.is_a?(Chef::Node)
      return nil unless @map.has_key?(key)
      @map[key].each do |matcher|
        if filters_match?(node, matcher[:filters]) &&
          block_matches?(node, matcher[:block])
          return matcher[:value]
        end
      end
      nil
    end

    def delete(key)
      @map.delete(key)
    end

    private

    # only allow valid filter options
    def validate_filter!(filters)
      filters.each_key do |key|
        # FIXME: real exception
        raise "Bad key #{key} in Chef::NodeMap filter expression" unless VALID_OPTS.include?(key)
      end
    end

    # warn on deprecated filter options
    def deprecate_filter!(filters)
      filters.each_key do |key|
        Chef::Log.warn "The #{key} option to node_map has been deprecated" if DEPRECATED_OPTS.include?(key)
      end
    end

    # @todo: this works fine, but is probably hard to understand
    def negative_match(filter, param)
      # We support strings prefaced by '!' to mean 'not'.  In particular, this is most useful
      # for os matching on '!windows'.
      negative_matches = filter.select { |f| f[0] == '!' }
      return true if !negative_matches.empty? && negative_matches.include?('!' + param)

      # We support the symbol :all to match everything, for backcompat, but this can and should
      # simply be ommitted.
      positive_matches = filter.reject { |f| f[0] == '!' || f == :all }
      return true if !positive_matches.empty? && !positive_matches.include?(param)

      # sorry double-negative: this means we pass this filter.
      false
    end

    def filters_match?(node, filters)
      return true if filters.empty?

      # each filter is applied in turn.  if any fail, then it shortcuts and returns false.
      # if it passes or does not exist it succeeds and continues on.  so multiple filters are
      # effectively joined by 'and'.  all filters can be single strings, or arrays which are
      # effectively joined by 'or'.

      os_filter = [ filters[:os] ].flatten.compact
      unless os_filter.empty?
        return false if negative_match(os_filter, node[:os])
      end

      platform_family_filter = [ filters[:platform_family] ].flatten.compact
      unless platform_family_filter.empty?
        return false if negative_match(platform_family_filter, node[:platform_family])
      end

      # :on_platform and :on_platforms here are synonyms which are deprecated
      platform_filter = [ filters[:platform] || filters[:on_platform] || filters[:on_platforms] ].flatten.compact
      unless platform_filter.empty?
        return false if negative_match(platform_filter, node[:platform])
      end

      return true
    end

    def block_matches?(node, block)
      return true if block.nil?
      block.call node
    end
  end
end
