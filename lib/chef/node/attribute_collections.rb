#--
# Author:: Daniel DeLeo (<dan@chef.io>)
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

require_relative "common_api"
require_relative "mixin/state_tracking"
require_relative "mixin/state_tracking_array"
require_relative "mixin/immutablize_array"
require_relative "mixin/immutablize_hash"
require_relative "mixin/mashy_array"

class Chef
  class Node
    # == AttrArray
    # AttrArray is identical to Array, except that it keeps a reference to the
    # "root" (Chef::Node::Attribute) object, and will trigger a cache
    # invalidation on that object when mutated.
    class AttrArray < Array
      include Chef::Node::Mixin::MashyArray

      MUTATOR_METHODS = Chef::Node::Mixin::ImmutablizeArray::DISALLOWED_MUTATOR_METHODS

      # For all of the methods that may mutate an Array, we override them to
      # also invalidate the cached merged_attributes on the root
      # Node::Attribute object.
      MUTATOR_METHODS.each do |mutator|
        define_method(mutator) do |*args, &block|
          ret = super(*args, &block)
          # TODO: use `send_reset_cache(__path__)` for all mutator methods?
          send_reset_cache
          ret
        end
      end

      def <<(obj)
        ret = super(obj)
        # NOTE: Expecting __path__ to be top-level attribute only
        send_reset_cache(__path__)
        ret
      end

      def delete(key, &block)
        send_reset_cache(__path__, key)
        super
      end

      def initialize(data = [])
        super(data)
        map! { |e| convert_value(e) }
      end

      # For elements like Fixnums, true, nil...
      def safe_dup(e)
        e.dup
      rescue TypeError
        e
      end

      def dup
        Array.new(map { |e| safe_dup(e) })
      end

      def to_yaml(*opts)
        to_a.to_yaml(*opts)
      end

      private

      def convert_value(value)
        case value
        when VividMash, AttrArray
          value
        when Hash
          VividMash.new(value, __root__, __node__, __precedence__)
        when Array
          AttrArray.new(value, __root__, __node__, __precedence__)
        else
          value
        end
      end

      # needed for __path__
      def convert_key(key)
        key
      end

      prepend Chef::Node::Mixin::StateTrackingArray
    end

    # == VividMash
    # VividMash is identical to a Mash, with a few exceptions:
    # * It has a reference to the root Chef::Node::Attribute to which it
    #   belongs, and will trigger cache invalidation on that object when
    #   mutated.
    # * It auto-vivifies, that is a reference to a missing element will result
    #   in the creation of a new VividMash for that key. (This only works when
    #   using the element reference method, `[]` -- other methods, such as
    #   #fetch, work as normal).
    # * attr_accessor style element set and get are supported via method_missing
    class VividMash < Mash
      include CommonAPI

      # Methods that mutate a VividMash. Each of them is overridden so that it
      # also invalidates the cached merged_attributes on the root Attribute
      # object.
      MUTATOR_METHODS = Chef::Node::Mixin::ImmutablizeHash::DISALLOWED_MUTATOR_METHODS - %i{write write! unlink unlink!}

      # For all of the mutating methods on Mash, override them so that they
      # also invalidate the cached `merged_attributes` on the root Attribute
      # object.
      MUTATOR_METHODS.each do |mutator|
        define_method(mutator) do |*args, &block|
          send_reset_cache
          super(*args, &block)
        end
      end

      def delete(key, &block)
        send_reset_cache(__path__, key)
        super
      end

      def initialize(data = {})
        super(data)
      end

      def [](key)
        value = super
        if !key?(key)
          value = self.class.new({}, __root__)
          self[key] = value
        else
          value
        end
      end

      def []=(key, value)
        ret = super
        send_reset_cache(__path__, key)
        ret # rubocop:disable Lint/Void
      end

      alias :attribute? :has_key?

      def convert_key(key)
        super
      end

      # Mash uses #convert_value to mashify values on input.
      # We override it here to convert hash or array values to VividMash or
      # AttrArray for consistency and to ensure that the added parts of the
      # attribute tree will have the correct cache invalidation behavior.
      def convert_value(value)
        case value
        when VividMash, AttrArray
          value
        when Hash
          VividMash.new(value, __root__, __node__, __precedence__)
        when Array
          AttrArray.new(value, __root__, __node__, __precedence__)
        else
          value
        end
      end

      def dup
        Mash.new(self)
      end

      def to_yaml(*opts)
        to_h.to_yaml(*opts)
      end

      prepend Chef::Node::Mixin::StateTracking
    end
  end
end
