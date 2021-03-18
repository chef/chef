#--
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: AJ Christensen (<aj@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "mixin/deep_merge_cache"
require_relative "mixin/immutablize_hash"
require_relative "mixin/state_tracking"
require_relative "immutable_collections"
require_relative "attribute_collections"
require_relative "../decorator/unchain"
require_relative "../mixin/deep_merge"
require_relative "../log"

class Chef
  class Node

    # == Attribute
    # Attribute implements a nested key-value (Hash) and flat collection
    # (Array) data structure supporting multiple levels of precedence, such
    # that a given key may have multiple values internally, but will only
    # return the highest precedence value when reading.
    class Attribute < Mash

      include Immutablize
      # FIXME:  what is include Enumerable doing up here, when down below we delegate
      # most of the Enumerable/Hash things to the underlying merged ImmutableHash.  That
      # is, in fact, the correct, thing to do, while including Enumerable to try to create
      # a hash-like API gets lots of things wrong because of the difference between the
      # Hash `each do |key, value|` vs the Array-like `each do |value|` API that Enumerable
      # expects.  This include should probably be deleted?
      include Enumerable

      include Chef::Node::Mixin::DeepMergeCache
      include Chef::Node::Mixin::StateTracking
      include Chef::Node::Mixin::ImmutablizeHash

      # List of the component attribute hashes, in order of precedence, low to
      # high.
      COMPONENTS = %i{
        @default
        @env_default
        @role_default
        @force_default
        @normal
        @override
        @role_override
        @env_override
        @force_override
        @automatic
      }.freeze

      DEFAULT_COMPONENTS = %i{
        @default
        @env_default
        @role_default
        @force_default
      }.freeze

      OVERRIDE_COMPONENTS = %i{
        @override
        @role_override
        @env_override
        @force_override
      }.freeze

      ENUM_METHODS = %i{
        all?
        any?
        assoc
        chunk
        collect
        collect_concat
        compare_by_identity
        compare_by_identity?
        count
        cycle
        detect
        drop
        drop_while
        each
        each_cons
        each_entry
        each_key
        each_pair
        each_slice
        each_value
        each_with_index
        each_with_object
        empty?
        entries
        except
        fetch
        find
        find_all
        find_index
        first
        flat_map
        flatten
        grep
        group_by
        has_value?
        include?
        index
        inject
        invert
        key
        keys
        length
        map
        max
        max_by
        merge
        min
        min_by
        minmax
        minmax_by
        none?
        one?
        partition
        rassoc
        reduce
        reject
        reverse_each
        select
        size
        slice_before
        sort
        sort_by
        store
        symbolize_keys
        take
        take_while
        to_a
        to_h
        to_hash
        to_json
        to_set
        to_yaml
        value?
        values
        values_at
        zip
      }.freeze

      ENUM_METHODS.each do |delegated_method|
        if Hash.public_method_defined?(delegated_method)
          define_method(delegated_method) do |*args, &block|
            merged_attributes.send(delegated_method, *args, &block)
          end
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

      # return the environment level override attribute component
      attr_reader :env_override

      # return the force override level attribute component
      attr_reader :force_override

      # return the automatic level attribute component
      attr_reader :automatic

      def initialize(normal, default, override, automatic, node = nil)
        @default        = VividMash.new(default, self, node, :default)
        @env_default    = VividMash.new({}, self, node, :env_default)
        @role_default   = VividMash.new({}, self, node, :role_default)
        @force_default  = VividMash.new({}, self, node, :force_default)

        @normal = VividMash.new(normal, self, node, :normal)

        @override       = VividMash.new(override, self, node, :override)
        @role_override  = VividMash.new({}, self, node, :role_override)
        @env_override   = VividMash.new({}, self, node, :env_override)
        @force_override = VividMash.new({}, self, node, :force_override)

        @automatic = VividMash.new(automatic, self, node, :automatic)

        super(nil, self, node, :merged)
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
          value =
            begin
              instance_variable_get(component).read!(*args)
            rescue
              :not_present
            end
          [component.to_s.sub(/^@/, ""), value]
        end
      end

      # Set the cookbook level default attribute component to +new_data+.
      def default=(new_data)
        reset
        @default = VividMash.new(new_data, self, __node__, :default)
      end

      # Set the role level default attribute component to +new_data+
      def role_default=(new_data)
        reset
        @role_default = VividMash.new(new_data, self, __node__, :role_default)
      end

      # Set the environment level default attribute component to +new_data+
      def env_default=(new_data)
        reset
        @env_default = VividMash.new(new_data, self, __node__, :env_default)
      end

      # Set the force_default (+default!+) level attributes to +new_data+
      def force_default=(new_data)
        reset
        @force_default = VividMash.new(new_data, self, __node__, :force_default)
      end

      # Set the normal level attribute component to +new_data+
      def normal=(new_data)
        reset
        @normal = VividMash.new(new_data, self, __node__, :normal)
      end

      # Set the cookbook level override attribute component to +new_data+
      def override=(new_data)
        reset
        @override = VividMash.new(new_data, self, __node__, :override)
      end

      # Set the role level override attribute component to +new_data+
      def role_override=(new_data)
        reset
        @role_override = VividMash.new(new_data, self, __node__, :role_override)
      end

      # Set the environment level override attribute component to +new_data+
      def env_override=(new_data)
        reset
        @env_override = VividMash.new(new_data, self, __node__, :env_override)
      end

      def force_override=(new_data)
        reset
        @force_override = VividMash.new(new_data, self, __node__, :force_override)
      end

      def automatic=(new_data)
        reset
        @automatic = VividMash.new(new_data, self, __node__, :automatic)
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

      #
      # Accessing merged attributes.
      #
      # Note that merged_attributes('foo', 'bar', 'baz') can be called to compute only the
      # deep merge of node['foo']['bar']['baz'], but in practice we currently always compute
      # all of node['foo'] even if the user only requires node['foo']['bar']['baz'].
      #
      def merged_attributes(*path)
        merge_all(path)
      end

      def combined_override(*path)
        ret = merge_overrides(path)
        ret == NIL ? nil : ret
      end

      def combined_default(*path)
        ret = merge_defaults(path)
        ret == NIL ? nil : ret
      end

      def normal_unless(*args)
        return Decorator::Unchain.new(self, :normal_unless) unless args.length > 0

        write(:normal, *args) if normal.read(*args[0...-1]).nil?
      end

      def default_unless(*args)
        return Decorator::Unchain.new(self, :default_unless) unless args.length > 0

        write(:default, *args) if default.read(*args[0...-1]).nil?
      end

      def override_unless(*args)
        return Decorator::Unchain.new(self, :override_unless) unless args.length > 0

        write(:override, *args) if override.read(*args[0...-1]).nil?
      end

      def has_key?(key)
        COMPONENTS.any? do |component_ivar|
          instance_variable_get(component_ivar).key?(key)
        end
      end

      # method-style access to attributes (has to come after the prepended ImmutablizeHash)

      def read(*path)
        merged_attributes.read(*path)
      end

      alias :dig :read

      def read!(*path)
        merged_attributes.read!(*path)
      end

      def exist?(*path)
        merged_attributes.exist?(*path)
      end

      def write(level, *args, &block)
        send(level).write(*args, &block)
      end

      def write!(level, *args, &block)
        send(level).write!(*args, &block)
      end

      def unlink(level, *path)
        send(level).unlink(*path)
      end

      def unlink!(level, *path)
        send(level).unlink!(*path)
      end

      alias :attribute? :has_key?
      alias :member? :has_key?
      alias :include? :has_key?
      alias :key? :has_key?

      alias :each_attribute :each

      def to_s
        merged_attributes.to_s
      end

      def inspect
        "#<#{self.class} " << (COMPONENTS + %i{@merged_attributes @properties}).map do |iv|
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
            elsif val.key?(path_arg)
              # Hash-like thing (must check has_key? first to protect against Autovivification)
              val[path_arg]
            else
              NIL
            end
          else
            NIL
          end
        end
      end

      # For elements like Fixnums, true, nil...
      def safe_dup(e)
        e.dup
      rescue TypeError
        e
      end

      # Deep merge all attribute levels using hash-only merging between different precedence
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

        ret = components.inject(NIL) do |merged, component|
          hash_only_merge!(merged, component)
        end
        ret == NIL ? nil : ret
      end

      # Deep merge the default attribute levels with array merging.
      #
      # The path allows for selectively deep-merging a subtree of the node object.
      #
      # @param path [Array] Array of args to method chain to descend into the node object
      # @return [attr] Deep Merged values (may be VividMash, Hash, Array, etc) from the node object
      def merge_defaults(path)
        DEFAULT_COMPONENTS.inject(NIL) do |merged, component_ivar|
          component_value = apply_path(instance_variable_get(component_ivar), path)
          deep_merge!(merged, component_value)
        end
      end

      # Deep merge the override attribute levels with array merging.
      #
      # The path allows for selectively deep-merging a subtree of the node object.
      #
      # @param path [Array] Array of args to method chain to descend into the node object
      # @return [attr] Deep Merged values (may be VividMash, Hash, Array, etc) from the node object
      def merge_overrides(path)
        OVERRIDE_COMPONENTS.inject(NIL) do |merged, component_ivar|
          component_value = apply_path(instance_variable_get(component_ivar), path)
          deep_merge!(merged, component_value)
        end
      end

      # needed for __path__
      def convert_key(key)
        key.is_a?(Symbol) ? key.to_s : key
      end

      NIL = Object.new

      # @api private
      def deep_merge!(merge_onto, merge_with)
        # If there are two Hashes, recursively merge.
        if merge_onto.is_a?(Hash) && merge_with.is_a?(Hash)
          merge_with.each do |key, merge_with_value|
            value =
              if merge_onto.key?(key)
                deep_merge!(safe_dup(merge_onto.internal_get(key)), merge_with_value)
              else
                merge_with_value
              end

            # internal_set bypasses converting keys, does convert values and allows writing to immutable mashes
            merge_onto.internal_set(key, value)
          end
          merge_onto

        elsif merge_onto.is_a?(Array) && merge_with.is_a?(Array)
          merge_onto |= merge_with

        # If merge_with is NIL, don't replace merge_onto
        elsif merge_with == NIL
          merge_onto

        # In all other cases, replace merge_onto with merge_with
        else
          if merge_with.is_a?(Hash)
            Chef::Node::ImmutableMash.new(merge_with)
          elsif merge_with.is_a?(Array)
            Chef::Node::ImmutableArray.new(merge_with)
          else
            merge_with
          end
        end
      end

      # @api private
      def hash_only_merge!(merge_onto, merge_with)
        # If there are two Hashes, recursively merge.
        if merge_onto.is_a?(Hash) && merge_with.is_a?(Hash)
          merge_with.each do |key, merge_with_value|
            value =
              if merge_onto.key?(key)
                hash_only_merge!(safe_dup(merge_onto.internal_get(key)), merge_with_value)
              else
                merge_with_value
              end

            # internal_set bypasses converting keys, does convert values and allows writing to immutable mashes
            merge_onto.internal_set(key, value)
          end
          merge_onto

        # If merge_with is NIL, don't replace merge_onto
        elsif merge_with == NIL
          merge_onto

        # In all other cases, replace merge_onto with merge_with
        else
          if merge_with.is_a?(Hash)
            Chef::Node::ImmutableMash.new(merge_with)
          elsif merge_with.is_a?(Array)
            Chef::Node::ImmutableArray.new(merge_with)
          else
            merge_with
          end
        end
      end
    end
  end
end
