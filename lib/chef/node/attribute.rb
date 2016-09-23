#--
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: AJ Christensen (<aj@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software, Inc.
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

require "chef/node/mixin/immutablize_hash"
require "chef/node/mixin/path_tracking"
require "chef/node/immutable_collections"
require "chef/node/attribute_collections"
require "chef/decorator/unchain"
require "chef/mixin/deep_merge"
require "chef/log"

class Chef
  class Node

    # == Attribute
    # Attribute implements a nested key-value (Hash) and flat collection
    # (Array) data structure supporting multiple levels of precedence, such
    # that a given key may have multiple values internally, but will only
    # return the highest precedence value when reading.
    class Attribute < Mash

      include Immutablize

      include Enumerable

      # List of the component attribute hashes, in order of precedence, low to
      # high.
      COMPONENTS = [
        :@default,
        :@env_default,
        :@role_default,
        :@force_default,
        :@normal,
        :@override,
        :@role_override,
        :@env_override,
        :@force_override,
        :@automatic,
      ].freeze

      DEFAULT_COMPONENTS = [
        :@default,
        :@env_default,
        :@role_default,
        :@force_default,
      ]

      OVERRIDE_COMPONENTS = [
        :@override,
        :@role_override,
        :@env_override,
        :@force_override,
      ]

      [:all?,
       :any?,
       :assoc,
       :chunk,
       :collect,
       :collect_concat,
       :compare_by_identity,
       :compare_by_identity?,
       :count,
       :cycle,
       :detect,
       :drop,
       :drop_while,
       :each,
       :each_cons,
       :each_entry,
       :each_key,
       :each_pair,
       :each_slice,
       :each_value,
       :each_with_index,
       :each_with_object,
       :empty?,
       :entries,
       :except,
       :fetch,
       :find,
       :find_all,
       :find_index,
       :first,
       :flat_map,
       :flatten,
       :grep,
       :group_by,
       :has_value?,
       :include?,
       :index,
       :inject,
       :invert,
       :key,
       :keys,
       :length,
       :map,
       :max,
       :max_by,
       :merge,
       :min,
       :min_by,
       :minmax,
       :minmax_by,
       :none?,
       :one?,
       :partition,
       :rassoc,
       :reduce,
       :reject,
       :reverse_each,
       :select,
       :size,
       :slice_before,
       :sort,
       :sort_by,
       :store,
       :symbolize_keys,
       :take,
       :take_while,
       :to_a,
       :to_h,
       :to_hash,
       :to_set,
       :value?,
       :values,
       :values_at,
       :zip].each do |delegated_method|
         define_method(delegated_method) do |*args, &block|
           merged_attributes.send(delegated_method, *args, &block)
         end
       end

       # return the cookbook level default attribute component
      attr_reader :default

       # return the role level default attribute component
      attr_reader :role_default

       # return the environment level default attribute component
      attr_reader :env_default

       # return the force_default level attribute component
      attr_reader :force_default

       # return the "normal" level attribute component
      attr_reader :normal

       # return the cookbook level override attribute component
      attr_reader :override

       # return the role level override attribute component
      attr_reader :role_override

       # return the enviroment level override attribute component
      attr_reader :env_override

       # return the force override level attribute component
      attr_reader :force_override

       # return the automatic level attribute component
      attr_reader :automatic

       # This is used to track the top level key as we descend through method chaining into
       # a precedence level (e.g. node.default['foo']['bar']['baz']= results in 'foo' here).  We
       # need this so that when we hit the end of a method chain which results in a mutator method
       # that we can invalidate the whole top-level deep merge cache for the top-level key.  It is
       # the responsibility of the accessor on the Chef::Node object to reset this to nil, and then
       # the first VividMash#[] call can ||= and set this to the first key we encounter.
      attr_accessor :top_level_breadcrumb

       # Cache of deep merged values by top-level key.  This is a simple hash which has keys that are the
       # top-level keys of the node object, and we save the computed deep-merge for that key here.  There is
       # no cache of subtrees.
      attr_accessor :deep_merge_cache

      def initialize(normal, default, override, automatic)
        @default = VividMash.new(self, default)
        @env_default = VividMash.new(self, {})
        @role_default = VividMash.new(self, {})
        @force_default = VividMash.new(self, {})

        @normal = VividMash.new(self, normal)

        @override = VividMash.new(self, override)
        @role_override = VividMash.new(self, {})
        @env_override = VividMash.new(self, {})
        @force_override = VividMash.new(self, {})

        @automatic = VividMash.new(self, automatic)

        @merged_attributes = nil
        @combined_override = nil
        @combined_default = nil
        @top_level_breadcrumb = nil
        @deep_merge_cache = {}
      end

       # Debug what's going on with an attribute. +args+ is a path spec to the
       # attribute you're interested in. For example, to debug where the value
       # of `node[:network][:default_interface]` is coming from, use:
       #   debug_value(:network, :default_interface).
       # The return value is an Array of Arrays.  The Arrays
       # are pairs of `["precedence_level", value]`, where precedence level is
       # the component, such as role default, normal, etc. and value is the
       # attribute value set at that precedence level. If there is no value at
       # that precedence level, +value+ will be the symbol +:not_present+.
      def debug_value(*args)
        COMPONENTS.map do |component|
          ivar = instance_variable_get(component)
          value = args.inject(ivar) do |so_far, key|
            if so_far == :not_present
              :not_present
            elsif so_far.has_key?(key)
              so_far[key]
            else
              :not_present
            end
          end
          [component.to_s.sub(/^@/, ""), value]
        end
      end

       # Invalidate a key in the deep_merge_cache.  If called with nil, or no arg, this will invalidate
       # the entire deep_merge cache.  In the case of the user doing node.default['foo']['bar']['baz']=
       # that eventually results in a call to reset_cache('foo') here.  A node.default=hash_thing call
       # must invalidate the entire cache and re-deep-merge the entire node object.
      def reset_cache(path = nil)
        if path.nil?
          @deep_merge_cache = {}
        else
          deep_merge_cache.delete(path.to_s)
        end
      end

      alias :reset :reset_cache

       # Set the cookbook level default attribute component to +new_data+.
      def default=(new_data)
        reset
        @default = VividMash.new(self, new_data)
      end

       # Set the role level default attribute component to +new_data+
      def role_default=(new_data)
        reset
        @role_default = VividMash.new(self, new_data)
      end

       # Set the environment level default attribute component to +new_data+
      def env_default=(new_data)
        reset
        @env_default = VividMash.new(self, new_data)
      end

       # Set the force_default (+default!+) level attributes to +new_data+
      def force_default=(new_data)
        reset
        @force_default = VividMash.new(self, new_data)
      end

       # Set the normal level attribute component to +new_data+
      def normal=(new_data)
        reset
        @normal = VividMash.new(self, new_data)
      end

       # Set the cookbook level override attribute component to +new_data+
      def override=(new_data)
        reset
        @override = VividMash.new(self, new_data)
      end

       # Set the role level override attribute component to +new_data+
      def role_override=(new_data)
        reset
        @role_override = VividMash.new(self, new_data)
      end

       # Set the environment level override attribute component to +new_data+
      def env_override=(new_data)
        reset
        @env_override = VividMash.new(self, new_data)
      end

      def force_override=(new_data)
        reset
        @force_override = VividMash.new(self, new_data)
      end

      def automatic=(new_data)
        reset
        @automatic = VividMash.new(self, new_data)
      end

       #
       # Deleting attributes
       #

       # clears attributes from all precedence levels
      def rm(*args)
        with_deep_merged_return_value(self, *args) do
          rm_default(*args)
          rm_normal(*args)
          rm_override(*args)
        end
      end

       # clears attributes from all default precedence levels
       #
       # similar to: force_default!['foo']['bar'].delete('baz')
       # - does not autovivify
       # - does not trainwreck if interior keys do not exist
      def rm_default(*args)
        with_deep_merged_return_value(combined_default, *args) do
          default.unlink(*args)
          role_default.unlink(*args)
          env_default.unlink(*args)
          force_default.unlink(*args)
        end
      end

       # clears attributes from normal precedence
       #
       # equivalent to: normal!['foo']['bar'].delete('baz')
       # - does not autovivify
       # - does not trainwreck if interior keys do not exist
      def rm_normal(*args)
        normal.unlink(*args)
      end

       # clears attributes from all override precedence levels
       #
       # equivalent to: force_override!['foo']['bar'].delete('baz')
       # - does not autovivify
       # - does not trainwreck if interior keys do not exist
      def rm_override(*args)
        with_deep_merged_return_value(combined_override, *args) do
          override.unlink(*args)
          role_override.unlink(*args)
          env_override.unlink(*args)
          force_override.unlink(*args)
        end
      end

      def with_deep_merged_return_value(obj, *path, last)
        hash = obj.read(*path)
        return nil unless hash.is_a?(Hash)
        ret = hash[last]
        yield
        ret
      end

      private :with_deep_merged_return_value

       #
       # Replacing attributes without merging
       #

       # sets default attributes without merging
       #
       # - this API autovivifies (and cannot trainwreck)
      def default!(*args)
        return Decorator::Unchain.new(self, :default!) unless args.length > 0
        write(:default, *args)
      end

       # sets normal attributes without merging
       #
       # - this API autovivifies (and cannot trainwreck)
      def normal!(*args)
        return Decorator::Unchain.new(self, :normal!) unless args.length > 0
        write(:normal, *args)
      end

       # sets override attributes without merging
       #
       # - this API autovivifies (and cannot trainwreck)
      def override!(*args)
        return Decorator::Unchain.new(self, :override!) unless args.length > 0
        write(:override, *args)
      end

       # clears from all default precedence levels and then sets force_default
       #
       # - this API autovivifies (and cannot trainwreck)
      def force_default!(*args)
        return Decorator::Unchain.new(self, :force_default!) unless args.length > 0
        value = args.pop
        rm_default(*args)
        write(:force_default, *args, value)
      end

       # clears from all override precedence levels and then sets force_override
      def force_override!(*args)
        return Decorator::Unchain.new(self, :force_override!) unless args.length > 0
        value = args.pop
        rm_override(*args)
        write(:force_override, *args, value)
      end

      # method-style access to attributes

      def read(*path)
        merged_attributes.read(*path)
      end

      def read!(*path)
        merged_attributes.read!(*path)
      end

      def exist?(*path)
        merged_attributes.exist?(*path)
      end

      def write(level, *args, &block)
        self.send(level).write(*args, &block)
      end

      def write!(level, *args, &block)
        self.send(level).write!(*args, &block)
      end

      def unlink(level, *path)
        self.send(level).unlink(*path)
      end

      def unlink!(level, *path)
        self.send(level).unlink!(*path)
      end

       #
       # Accessing merged attributes.
       #
       # Note that merged_attributes('foo', 'bar', 'baz') can be called to compute only the
       # deep merge of node['foo']['bar']['baz'], but in practice we currently always compute
       # all of node['foo'] even if the user only requires node['foo']['bar']['baz'].
       #

      def merged_attributes(*path)
        immutablize(merge_all(path))
      end

      def combined_override(*path)
        immutablize(merge_overrides(path))
      end

      def combined_default(*path)
        immutablize(merge_defaults(path))
      end

      def normal_unless(*args)
        return Decorator::Unchain.new(self, :normal_unless) unless args.length > 0
        write(:normal, *args) if read(*args[0...-1]).nil?
      end

      def default_unless(*args)
        return Decorator::Unchain.new(self, :default_unless) unless args.length > 0
        write(:default, *args) if read(*args[0...-1]).nil?
      end

      def override_unless(*args)
        return Decorator::Unchain.new(self, :override_unless) unless args.length > 0
        write(:override, *args) if read(*args[0...-1]).nil?
      end

      def set_unless(*args)
        Chef.log_deprecation("node.set_unless is deprecated and will be removed in Chef 14, please use node.default_unless/node.override_unless (or node.normal_unless if you really need persistence)")
        return Decorator::Unchain.new(self, :default_unless) unless args.length > 0
        write(:normal, *args) if read(*args[0...-1]).nil?
      end

      def [](key)
        if deep_merge_cache.has_key?(key.to_s)
          # return the cache of the deep merged values by top-level key
          deep_merge_cache[key.to_s]
        else
          # save all the work of computing node[key]
          deep_merge_cache[key.to_s] = merged_attributes(key)
        end
      end

      def []=(key, value)
        raise Exceptions::ImmutableAttributeModification
      end

      def has_key?(key)
        COMPONENTS.any? do |component_ivar|
          instance_variable_get(component_ivar).has_key?(key)
        end
      end

      alias :attribute? :has_key?
      alias :member? :has_key?
      alias :include? :has_key?
      alias :key? :has_key?

      alias :each_attribute :each

      def method_missing(symbol, *args)
        if symbol == :to_ary
          merged_attributes.send(symbol, *args)
        elsif args.empty?
          Chef.log_deprecation %q{method access to node attributes (node.foo.bar) is deprecated and will be removed in Chef 13, please use bracket syntax (node["foo"]["bar"])}
          if key?(symbol)
            self[symbol]
          else
            raise NoMethodError, "Undefined method or attribute `#{symbol}' on `node'"
          end
        elsif symbol.to_s =~ /=$/
          Chef.log_deprecation %q{method setting of node attributes (node.foo="bar") is deprecated and will be removed in Chef 13, please use bracket syntax (node["foo"]="bar")}
          key_to_set = symbol.to_s[/^(.+)=$/, 1]
          self[key_to_set] = (args.length == 1 ? args[0] : args)
        else
          raise NoMethodError, "Undefined node attribute or method `#{symbol}' on `node'"
        end
      end

      def to_s
        merged_attributes.to_s
      end

      def inspect
        "#<#{self.class} " << (COMPONENTS + [:@merged_attributes, :@properties]).map do |iv|
          "#{iv}=#{instance_variable_get(iv).inspect}"
        end.join(", ") << ">"
      end

      private

       # Helper method for merge_all/merge_defaults/merge_overrides.
       #
       # apply_path(thing, [ "foo", "bar", "baz" ]) = thing["foo"]["bar"]["baz"]
       #
       # The path value can be nil in which case the whole component is returned.
       #
       # It returns nil (does not raise an exception) if it walks off the end of an Mash/Hash/Array, it does not
       # raise any TypeError if it attempts to apply a hash key to an Integer/String/TrueClass, and just returns
       # nil in that case.
       #
      def apply_path(component, path)
        path ||= []
        path.inject(component) do |val, path_arg|
          if val.respond_to?(:[])
            # Have an Array-like or Hash-like thing
            if !val.respond_to?(:has_key?)
              # Have an Array-like thing
              val[path_arg]
            elsif val.has_key?(path_arg)
              # Hash-like thing (must check has_key? first to protect against Autovivification)
              val[path_arg]
            else
              nil
            end
          else
            nil
          end
        end
      end

       # For elements like Fixnums, true, nil...
      def safe_dup(e)
        e.dup
      rescue TypeError
        e
      end

       # Deep merge all attribute levels using hash-only merging between different precidence
       # levels (so override arrays completely replace arrays set at any default level).
       #
       # The path allows for selectively deep-merging a subtree of the node object.
       #
       # @param path [Array] Array of args to method chain to descend into the node object
       # @return [attr] Deep Merged values (may be VividMash, Hash, Array, etc) from the node object
      def merge_all(path)
        components = [
          merge_defaults(path),
          apply_path(@normal, path),
          merge_overrides(path),
          apply_path(@automatic, path),
        ]

        components.map! do |component|
          safe_dup(component)
        end

        return nil if components.compact.empty?

        components.inject(ImmutableMash.new({})) do |merged, component|
          Chef::Mixin::DeepMerge.hash_only_merge!(merged, component)
        end
      end

       # Deep merge the default attribute levels with array merging.
       #
       # The path allows for selectively deep-merging a subtree of the node object.
       #
       # @param path [Array] Array of args to method chain to descend into the node object
       # @return [attr] Deep Merged values (may be VividMash, Hash, Array, etc) from the node object
      def merge_defaults(path)
        DEFAULT_COMPONENTS.inject(nil) do |merged, component_ivar|
          component_value = apply_path(instance_variable_get(component_ivar), path)
          Chef::Mixin::DeepMerge.deep_merge(component_value, merged)
        end
      end

       # Deep merge the override attribute levels with array merging.
       #
       # The path allows for selectively deep-merging a subtree of the node object.
       #
       # @param path [Array] Array of args to method chain to descend into the node object
       # @return [attr] Deep Merged values (may be VividMash, Hash, Array, etc) from the node object
      def merge_overrides(path)
        OVERRIDE_COMPONENTS.inject(nil) do |merged, component_ivar|
          component_value = apply_path(instance_variable_get(component_ivar), path)
          Chef::Mixin::DeepMerge.deep_merge(component_value, merged)
        end
      end
    end

    # needed for PathTracking
    def convert_key(key)
      key.kind_of?(Symbol) ? key.to_s : key
    end

    prepend Chef::Node::Mixin::PathTracking
    prepend Chef::Node::Mixin::ImmutablizeHash
  end
end
