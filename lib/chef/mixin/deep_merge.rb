#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Steve Midgley (http://www.misuse.org/science)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# Copyright:: Copyright 2008-2016, Steve Midgley
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

class Chef
  module Mixin
    # Implements a deep merging algorithm for nested data structures.
    #
    # This code was originally imported from deep_merge by Steve Midgley.
    # deep_merge is available under the MIT license from
    # http://trac.misuse.org/science/wiki/DeepMerge
    #
    # Note that this is not considered a public interface.  It is technically
    # public and has been used and we cannot break the API, but continued
    # external use is discouraged.  We are unlikely to change the shape of
    # the API and break anyone, but this code does not serve the purposes of
    # cookbook authors and customers.  It is intended only for the purposes
    # of the internal use in the chef-client codebase.  We do not accept
    # pull requests to extend the functionality of this algorithm.  Users
    # who find this does nearly what they want, should copy and paste the
    # algorithm and tune to their needs.  We will not maintain any additional
    # use cases.
    #
    # "It is what it is, and if it isn't what you want, you need to build
    # that yourself"
    #
    # @api private
    #
    module DeepMerge

      extend self

      # @api private
      def merge(first, second)
        first  = Mash.new(first)  unless first.is_a?(Mash)
        second = Mash.new(second) unless second.is_a?(Mash)

        DeepMerge.deep_merge(second, first)
      end

      class InvalidParameter < StandardError; end

      # deep_merge! method permits merging of arbitrary child elements. The two top level
      # elements must be hashes. These hashes can contain unlimited (to stack limit) levels
      # of child elements. These child elements to not have to be of the same types.
      # Where child elements are of the same type, deep_merge will attempt to merge them together.
      # Where child elements are not of the same type, deep_merge will skip or optionally overwrite
      # the destination element with the contents of the source element at that level.
      #
      # So if you have two hashes like this:
      #
      #   source = {:x => [1,2,3], :y => 2}
      #   dest =   {:x => [4,5,'6'], :y => [7,8,9]}
      #   dest.deep_merge!(source)
      #   Results: {:x => [1,2,3,4,5,'6'], :y => 2}
      #
      # By default, "deep_merge!" will overwrite any unmergeables and merge everything else.
      # To avoid this, use "deep_merge" (no bang/exclamation mark)
      #
      # @api private
      #
      def deep_merge!(source, dest)
        case source
        when Hash
          if dest.is_a?(Hash)
            source.each do |src_key, src_value|
              if dest.key?(src_key)
                dest[src_key] = deep_merge!(src_value, dest[src_key])
              else # dest[src_key] doesn't exist so we take whatever source has
                dest[src_key] = src_value
              end
            end
          else # dest isn't a hash, so we overwrite it completely
            dest = source
          end
        when Array
          if dest.is_a?(Array)
            dest |= source
          else
            dest = source
          end
        when String
          dest = source
        else # src_hash is not an array or hash, so we'll have to overwrite dest
          dest = source
        end
        dest
      end # deep_merge!

      # @api private
      def hash_only_merge(merge_onto, merge_with)
        hash_only_merge!(safe_dup(merge_onto), safe_dup(merge_with))
      end

      # @api private
      def safe_dup(thing)
        thing.dup
      rescue TypeError
        thing
      end

      # Deep merge without Array merge.
      # `merge_onto` is the object that will "lose" in case of conflict.
      # `merge_with` is the object whose values will replace `merge_onto`s
      # values when there is a conflict.
      #
      # @api private
      #
      def hash_only_merge!(merge_onto, merge_with)
        # If there are two Hashes, recursively merge.
        if merge_onto.is_a?(Hash) && merge_with.is_a?(Hash)
          merge_with.each do |key, merge_with_value|
            value =
              if merge_onto.key?(key)
                hash_only_merge(merge_onto[key], merge_with_value)
              else
                merge_with_value
              end

            if merge_onto.respond_to?(:public_method_that_only_deep_merge_should_use)
              # we can't call ImmutableMash#[]= because its immutable, but we need to mutate it to build it in-place
              merge_onto.public_method_that_only_deep_merge_should_use(key, value)
            else
              merge_onto[key] = value
            end
          end
          merge_onto
        # In all other cases, replace merge_onto with merge_with
        else
          merge_with
        end
      end

      # @api private
      #
      def deep_merge(source, dest)
        deep_merge!(safe_dup(source), safe_dup(dest))
      end

    end
  end
end
