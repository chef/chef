#--
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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
        :unshift
      ]

      # For all of the methods that may mutate an Array, we override them to
      # also invalidate the cached merged_attributes on the root
      # Node::Attribute object.
      MUTATOR_METHODS.each do |mutator|
        define_method(mutator) do |*args, &block|
          root.reset_cache(root.top_level_breadcrumb)
          super(*args, &block)
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
        Array.new(map {|e| safe_dup(e)})
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
    # * It supports a set_unless flag (via the root Attribute object) which
    #   allows `||=` style behavior (`||=` does not work with
    #   auto-vivification). This is only implemented for #[]=; methods such as
    #   #store work as normal.
    # * attr_accessor style element set and get are supported via method_missing
    class VividMash < Mash
      attr_reader :root

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
        :shift
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

      def initialize(root, data={})
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
        if set_unless? && key?(key)
          self[key]
        else
          root.reset_cache(root.top_level_breadcrumb)
          super
        end
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
        elsif symbol.to_s =~ /=$/
          key_to_set = symbol.to_s[/^(.+)=$/, 1]
          self[key_to_set] = (args.length == 1 ? args[0] : args)
        else
          raise NoMethodError, "Undefined node attribute or method `#{symbol}' on `node'. To set an attribute, use `#{symbol}=value' instead."
        end
      end

      def set_unless?
        @root.set_unless?
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

    # == MultiMash
    # This is a Hash-like object that contains multiple VividMashes in it.  Its
    # purpose is so that the user can descend into the mash and delete a subtree
    # from all of the Mash objects (used to delete all values in a subtree from
    # default, force_default, role_default and env_default at the same time).  The
    # assignment operator strictly does assignment (does no merging) and works
    # by deleting the subtree and then assigning to the last mash which passed in
    # the initializer.
    #
    # A lot of the complexity of this class comes from the fact that at any key
    # value some or all of the mashes may walk off their ends and become nil or
    # true or something.  The schema may change so that one precidence leve may
    # be 'true' object and another may be a VividMash.  It is also possible that
    # one or many of them may transition from VividMashes to Hashes or Arrays.
    #
    # It also supports the case where you may be deleting a key using node.rm
    # in which case if intermediate keys all walk off into nil then you don't want
    # to be autovivifying keys as you go.  On the other hand you may be using
    # node.force_default! in which case you'll wind up with a []= operator at the
    # end and you want autovivification, so we conditionally have to support either
    # operation.
    #
    # @todo: can we have an autovivify class that decorates a class that doesn't
    # autovivify or something so that the code is less awful?
    #
    class MultiMash
      attr_reader :root
      attr_reader :mashes
      attr_reader :opts
      attr_reader :primary_mash

      # Initialize with an array of mashes.  For the delete return value to work
      # properly the mashes must come from the same attribute level (i.e. all
      # override or all default, but not a mix of both).
      def initialize(root, primary_mash, mashes, opts={})
        @root = root
        @primary_mash = primary_mash
        @mashes = mashes
        @opts = opts
        @opts[:autovivify] = true if @opts[:autovivify].nil?
      end

      def [](key)
        # handle the secondary mashes
        new_mashes = []
        mashes.each do |mash|
          new_mash = safe_evalute_key(mash, key)
          # secondary mashes never autovivify so once they fall into nil, we just stop tracking them
          new_mashes.push(new_mash) unless new_mash.nil?
        end

        new_primary_mash = safe_evalute_key(primary_mash, key)

        if new_primary_mash.nil? && @opts[:autovivify]
          primary_mash[key] = VividMash.new(root)
          new_primary_mash = primary_mash[key]
        end

        MultiMash.new(root, new_primary_mash, new_mashes, opts)
      end

      def []=(key, value)
        if primary_mash.nil?
          # This theoretically should never happen since node#force_default! setter methods will autovivify and
          # node#rm methods do not end in #[]= operators.
          raise TypeError, "No autovivification was specified initially on a method chain ending in assignment"
        end
        ret = delete(key)
        primary_mash[key] = value
        ret
      end

      # mash.element('foo', 'bar') is the same as mash['foo']['bar']
      def element(key = nil, *subkeys)
        return self if key.nil?
        submash = self[key]
        subkeys.empty? ? submash : submash.element(*subkeys)
      end

      def delete(key)
        # the return value is a deep merge which is correct semantics when
        # merging between attributes on the same level (this would be incorrect
        # if passed both override and default attributes which would need hash_only
        # merging).
        ret = mashes.inject(Mash.new) do |merged, mash|
          Chef::Mixin::DeepMerge.merge(merged, mash)
        end
        ret = Chef::Mixin::DeepMerge.merge(ret, primary_mash)
        mashes.each do |mash|
          mash.delete(key) if mash.respond_to?(:delete)
        end
        primary_mash.delete(key) if primary_mash.respond_to?(:delete)
        ret[key]
      end

      private

      def safe_evalute_key(mash, key)
        if mash.respond_to?(:[])
          if mash.respond_to?(:has_key?)
            if mash.has_key?(key)
              return mash[key] if mash[key].respond_to?(:[])
            end
          elsif !mash[key].nil?
            return mash[key] if mash[key].respond_to?(:[])
          end
        end
        return nil
      end

    end

  end
end
