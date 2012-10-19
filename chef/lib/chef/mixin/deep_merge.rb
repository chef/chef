#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Steve Midgley (http://www.misuse.org/science)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
# Copyright:: Copyright (c) 2008 Steve Midgley
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
    # == Chef::Mixin::DeepMerge
    # Implements a deep merging algorithm for nested data structures.
    # ==== Notice:
    #   This code was originally imported from deep_merge by Steve Midgley.
    #   deep_merge is available under the MIT license from
    #   http://trac.misuse.org/science/wiki/DeepMerge
    module DeepMerge

      class InvalidSubtractiveMerge < ArgumentError; end

      OLD_KNOCKOUT_PREFIX = "!merge:".freeze
      OLD_KNOCKOUT_MATCH = %r[!merge].freeze

      extend self

      def merge(first, second)
        first  = Mash.new(first)  unless first.kind_of?(Mash)
        second = Mash.new(second) unless second.kind_of?(Mash)

        DeepMerge.deep_merge(second, first)
      end

      # Inherited roles use the knockout_prefix array subtraction functionality
      # This is likely to go away in Chef >= 0.11
      def role_merge(first, second)
        first  = Mash.new(first)  unless first.kind_of?(Mash)
        second = Mash.new(second) unless second.kind_of?(Mash)

        DeepMerge.deep_merge(second, first)
      end

      class InvalidParameter < StandardError; end

      # Deep Merge core documentation.
      # deep_merge! method permits merging of arbitrary child elements. The two top level
      # elements must be hashes. These hashes can contain unlimited (to stack limit) levels
      # of child elements. These child elements to not have to be of the same types.
      # Where child elements are of the same type, deep_merge will attempt to merge them together.
      # Where child elements are not of the same type, deep_merge will skip or optionally overwrite
      # the destination element with the contents of the source element at that level.
      # So if you have two hashes like this:
      #   source = {:x => [1,2,3], :y => 2}
      #   dest =   {:x => [4,5,'6'], :y => [7,8,9]}
      #   dest.deep_merge!(source)
      #   Results: {:x => [1,2,3,4,5,'6'], :y => 2}
      # By default, "deep_merge!" will overwrite any unmergeables and merge everything else.
      # To avoid this, use "deep_merge" (no bang/exclamation mark)
      def deep_merge!(source, dest)
        # if dest doesn't exist, then simply copy source to it
        if dest.nil?
          dest = source; return dest
        end

        raise_if_knockout_used!(source)
        case source
        when nil
          dest
        when Hash
          source.each do |src_key, src_value|
            if dest.kind_of?(Hash)
              if dest[src_key]
                dest[src_key] = deep_merge!(src_value, dest[src_key])
              else # dest[src_key] doesn't exist so we take whatever source has
                raise_if_knockout_used!(src_value)
                dest[src_key] = src_value
              end
            else # dest isn't a hash, so we overwrite it completely
              dest = source
            end
          end
        when Array
          if dest.kind_of?(Array)
            dest = dest | source
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

      def raise_if_knockout_used!(obj)
        if uses_knockout?(obj)
          raise InvalidSubtractiveMerge, "subtractive merge with !merge is no longer supported"
        end
      end

      def uses_knockout?(obj)
        case obj
        when String
          obj =~ OLD_KNOCKOUT_MATCH
        when Array
          obj.any? {|element| element.respond_to?(:gsub) && element =~ OLD_KNOCKOUT_MATCH }
        else
          false
        end
      end

      def deep_merge(source, dest)
        deep_merge!(source.dup, dest.dup)
      end

    end
  end
end


