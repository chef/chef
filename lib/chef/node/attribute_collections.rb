#--
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software, Inc.
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

require "chef/node/common_api"

class Chef
  class Node
    # == AttrArray
    # AttrArray is identical to Array, except that it keeps a reference to the
    # "root" (Chef::Node::Attribute) object, and will trigger a cache
    # invalidation on that object when mutated.
    class AttrArray < Array
      MUTATOR_METHODS = [
        :<<,
        :[]=,
        :clear,
        :collect!,
        :compact!,
        :default=,
        :default_proc=,
        :delete,
        :delete_at,
        :delete_if,
        :fill,
        :flatten!,
        :insert,
        :keep_if,
        :map!,
        :merge!,
        :pop,
        :push,
        :update,
        :reject!,
        :reverse!,
        :replace,
        :select!,
        :shift,
        :slice!,
        :sort!,
        :sort_by!,
        :uniq!,
        :unshift,
      ]

      # For all of the methods that may mutate an Array, we override them to
      # also invalidate the cached merged_attributes on the root
      # Node::Attribute object.
      MUTATOR_METHODS.each do |mutator|
        define_method(mutator) do |*args, &block|
          ret = super(*args, &block)
          root.reset_cache(root.top_level_breadcrumb)
          ret
        end
      end

      attr_reader :root

      def initialize(root, data)
        @root = root
        super(data)
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
      attr_reader :root

      include CommonAPI

      # Methods that mutate a VividMash. Each of them is overridden so that it
      # also invalidates the cached merged_attributes on the root Attribute
      # object.
      MUTATOR_METHODS = [
        :clear,
        :delete,
        :delete_if,
        :keep_if,
        :merge!,
        :update,
        :reject!,
        :replace,
        :select!,
        :shift,
      ]

      # For all of the mutating methods on Mash, override them so that they
      # also invalidate the cached `merged_attributes` on the root Attribute
      # object.
      MUTATOR_METHODS.each do |mutator|
        define_method(mutator) do |*args, &block|
          root.reset_cache(root.top_level_breadcrumb)
          super(*args, &block)
        end
      end

      def initialize(root, data = {})
        @root = root
        super(data)
      end

      def [](key)
        root.top_level_breadcrumb ||= key
        value = super
        if !key?(key)
          value = self.class.new(root)
          self[key] = value
        else
          value
        end
      end

      def []=(key, value)
        root.top_level_breadcrumb ||= key
        ret = super
        root.reset_cache(root.top_level_breadcrumb)
        ret
      end

      alias :attribute? :has_key?

      def method_missing(symbol, *args)
        # Calling `puts arg` implicitly calls #to_ary on `arg`. If `arg` does
        # not implement #to_ary, ruby recognizes it as a single argument, and
        # if it returns an Array, then ruby prints each element. If we don't
        # account for that here, we'll auto-vivify a VividMash for the key
        # :to_ary which creates an unwanted key and raises a TypeError.
        if symbol == :to_ary
          super
        elsif args.empty?
          self[symbol]
        elsif symbol.to_s =~ /^\w.*=$/
          key_to_set = symbol.to_s[/^(.+)=$/, 1]
          self[key_to_set] = (args.length == 1 ? args[0] : args)
        else
          if symbol.to_s =~ /\w/
            raise NoMethodError, "Undefined node attribute or method `#{symbol}' on `node'. To set an attribute, use `#{symbol}=value' instead."
          else
            raise NoMethodError, "Undefined node attribute or method `#{symbol}' on `node'."
          end
        end
      end

      def convert_key(key)
        super
      end

      # Mash uses #convert_value to mashify values on input.
      # We override it here to convert hash or array values to VividMash or
      # AttrArray for consistency and to ensure that the added parts of the
      # attribute tree will have the correct cache invalidation behavior.
      def convert_value(value)
        case value
        when VividMash
          value
        when Hash
          VividMash.new(root, value)
        when Array
          AttrArray.new(root, value)
        else
          value
        end
      end

      def dup
        Mash.new(self)
      end

    end
  end
end
