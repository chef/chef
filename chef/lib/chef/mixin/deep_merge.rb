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
    #   This code is imported from deep_merge by Steve Midgley. deep_merge is
    #   available under the MIT license from
    #   http://trac.misuse.org/science/wiki/DeepMerge
    module DeepMerge
      def self.merge(first, second)
        first  = Mash.new(first)  unless first.kind_of?(Mash)
        second = Mash.new(second) unless second.kind_of?(Mash)

        DeepMerge.deep_merge!(second, first)
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
      #
      # NOTE: Original deep_merge, and the one in the release version of Chef
      # have many sophisticated features that allow you to remove elements via
      # merge (among other things). Those features are removed from this version.
      def self.deep_merge!(source, dest)

        # do nothing if source is nil
        return dest if source.nil?

        # if dest doesn't exist, then simply copy source to it
        return source if dest.nil?

        if source.kind_of?(Hash) && dest.kind_of?(Hash)
          source.each do |src_key, src_value|
            if dest[src_key]
              dest[src_key] = deep_merge!(src_value, dest[src_key])
            else # dest[src_key] doesn't exist so we want to create and overwrite
              dest[src_key] = src_value
            end
          end
          dest
        elsif source.kind_of?(Array) && dest.kind_of?(Array)
          dest | source
        else # src_hash is not an array or hash, so we'll have to overwrite dest
          source
        end
      end # deep_merge!

    end

  end
end


