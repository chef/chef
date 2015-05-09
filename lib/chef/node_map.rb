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
    def set(key, value, platform: nil, platform_family: nil, os: nil, on_platform: nil, on_platforms: nil, &block)
      Chef::Log.deprecation "The on_platform option to node_map has been deprecated" if on_platform
      Chef::Log.deprecation "The on_platforms option to node_map has been deprecated" if on_platforms
      platform ||= on_platform || on_platforms
      filters = { platform: platform, platform_family: platform_family, os: os }
      new_matcher = { filters: filters, block: block, value: value }
      @map[key] ||= []
      # Decide where to insert the matcher; the new value is preferred over
      # anything more specific (see `priority_of`) and is preferred over older
      # values of the same specificity.  (So all other things being equal,
      # newest wins.)
      insert_at = 0
      @map[key].each_with_index do |matcher, index|
        if specificity(new_matcher) >= specificity(matcher)
          insert_at = index
          break
        end
      end
      @map[key].insert(insert_at, new_matcher)
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
      list(node, key).first
    end

    # List all matches for the given node and key from the NodeMap, from
    # most-recently added to oldest.
    #
    # @param node [Chef::Node] The Chef::Node object for the run
    # @param key [Object] Key to look up
    # @return [Object] Value
    #
    def list(node, key)
      # FIXME: real exception
      raise "first argument must be a Chef::Node" unless node.is_a?(Chef::Node)
      return [] unless @map.has_key?(key)
      @map[key].select do |matcher|
        filters_match?(node, matcher[:filters]) && block_matches?(node, matcher[:block])
      end.map { |matcher| matcher[:value] }
    end

    private

    #
    # Gives a value for "how specific" the matcher is.
    # Things which specify more specific filters get a higher number
    # (platform_version > platform > platform_family > os); things
    # with a block have higher specificity than similar things without
    # a block.
    #
    def specificity(matcher)
      if matcher[:filters][:platform_version]
        specificity = 8
      elsif matcher[:filters][:platform]
        specificity = 6
      elsif matcher[:filters][:platform_family]
        specificity = 4
      elsif matcher[:filters][:os]
        specificity = 2
      else
        specificity = 0
      end
      specificity += 1 if matcher[:block]
      specificity
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
