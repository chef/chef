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

    module TraceableCollection

      # Mash and AttrArray use #convert_value to mashify values on input.
      # We override it here to convert hash or array values to VividMash or
      # AttrArray for consistency and to ensure that the added parts of the
      # attribute tree will have the correct cache invalidation behavior.

      def convert_value(value)
        case value
        when VividMash
          value
        when AttrArray
          value
        when Hash
          VividMash.new(root, value, self, component)
        when Mash
          VividMash.new(root, value, self, component)
        when Array
          AttrArray.new(root, value, self, component)
        else
          value
        end
      end

      def find_path_to_entry_ascent

        # If my parent is a CNA, I'm the root.
        if parent.kind_of?(Chef::Node::Attribute) then return '/' end
        
        # Otherwise, I should be a child of my parent.
        parent_path = parent.find_path_to_entry_ascent
        my_key = parent.keys.find {|k| parent[k].equal?(self) }
        if parent_path && my_key
          parent_path + (parent_path == '/' ? '' : '/') + my_key.to_s
        else
          nil
        end
      end

      def find_path_to_entry_descent(needle)
        # Needle is a VividMash, AttrArray or some leaf type, that (we beleive) 
        # is a descendant of this collection.  Find it, and report the path to it.

        # I suppose it could be me.
        return '/' if self.equal? needle

        # Can't use self.each here - self may be an AttrArray.  We added a keys() to it, tho.
        self.keys.each do |key|
          child = self[key]
          # Depth first
          if child.equal? needle
            return '/' + key
          elsif child.respond_to?(:find_path_to_entry_descent)
            deeper = child.find_path_to_entry_descent(needle)
            if deeper
              return '/' + key + deeper
            end
          end          
        end
        return nil
      end

    end
      

    # == AttrArray
    # AttrArray is identical to Array, except that it keeps a reference to the
    # "root" (Chef::Node::Attribute) object, and will trigger a cache
    # invalidation on that object when mutated.
    # * To support attribute tracing, it tracks its parent and component (for use in path finding)
    # * To support attribute tracing, methods are added to find child elements.
    class AttrArray < Array
      include TraceableCollection

      MUTATOR_METHODS = [
        :<<,
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
        class_eval(<<-METHOD_DEFN, __FILE__, __LINE__)
          def #{mutator}(*args, &block)
            root.reset_cache
            super
          end
        METHOD_DEFN
      end

      attr_reader :root
      attr_reader :parent
      attr_reader :component

      def initialize(root, data, parent=nil, component=nil)
        @root = root
        @parent = parent
        @component = component
        super([])
        # Set each item individually so that each gets a chance to be converted and traced
        data.each_with_index do |value, idx|
          self[idx] = value
        end
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

      def [](idx)
        # Be cool with idx being a string int.
        super(idx.to_i)
      end

      # Implement << in terms of []= to get tracing
      def <<(value)
        self[self.length]= value
      end

      def []=(idx, value)        

        root.reset_cache
        super(idx.to_i, convert_value(value))

        # Don't use value here - it will have been converted and stored 
        root.trace_attribute_change(self, idx, self[idx]) 

        self[idx]
      end

      # this is mostly to play nicely with find_path_to_entry_descent
      def keys
        (0..self.length-1).to_a.map { |i| i.to_s }
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
    # * To support attribute tracing, it tracks its parent and component (for use in path finding)
    # * To support attribute tracing, methods are added to find child elements
    
    class VividMash < Mash
      include TraceableCollection

      attr_reader :root
      attr_reader :parent
      attr_reader :component

      # Methods that mutate a VividMash. Each of them is overridden so that it
      # also invalidates the cached merged_attributes on the root Attribute
      # object.
      MUTATOR_METHODS = [
        :clear,
        :delete,
        :delete_if,
        :keep_if,
        :reject!,
        :replace,
        :select!,
        :shift
      ]

      # For all of the mutating methods on Mash, override them so that they
      # also invalidate the cached `merged_attributes` on the root Attribute
      # object.
      MUTATOR_METHODS.each do |mutator|
        class_eval(<<-METHOD_DEFN, __FILE__, __LINE__)
          def #{mutator}(*args, &block)
            root.reset_cache
            super
          end
        METHOD_DEFN
      end


      # @param other_hash<Hash>
      #   A hash to update values in the VividMash with. The keys and the values will be
      #   converted to VividMash format.
      #
      # @return [VividMash] The updated VividMash.
      def update(other_hash)
        # Rely on []= to handle autovivification, conversion and tracing.
        other_hash.each_pair { |key, value| self[key] = value }
        self
      end

      alias_method :merge!, :update


      def initialize(root=nil, data={}, parent=nil, component=nil)
        @root = root
        @parent = parent
        @component = component
        super(data)
      end

      def [](key)
        value = super
        if !key?(key)
          value = self.class.new(root, {}, self, self.component)
          self[key] = value
        else
          value
        end
      end

      def []=(key, value)
        if set_unless? && key?(key)
          root.trace_attribute_ignored_unless(self, key, value)
          self[key]          
        else
          root.reset_cache
          super

          # Don't use value here - it may have been converted and then stored by super()
          root.trace_attribute_change(self, key, self[key]) 

          self[key]
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
        root.set_unless?
      end

      def convert_key(key)
        super
      end

      def dup
        Mash.new(self)
      end

    end
  end
end
