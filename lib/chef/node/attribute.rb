#--
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: AJ Christensen (<aj@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'chef/node/immutable_collections'
require 'chef/node/attribute_collections'
require 'chef/mixin/deep_merge'
require 'chef/log'

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
        :@automatic
      ].freeze

      DEFAULT_COMPONENTS = [
        :@default,
        :@env_default,
        :@role_default,
        :@force_default
      ]

      OVERRIDE_COMPONENTS = [
        :@override,
        :@role_override,
        :@env_override,
        :@force_override
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
       :to_hash,
       :to_set,
       :value?,
       :values,
       :values_at,
       :zip].each do |delegated_method|
         class_eval(<<-METHOD_DEFN)
            def #{delegated_method}(*args, &block)
              merged_attributes.send(:#{delegated_method}, *args, &block)
            end
         METHOD_DEFN
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

       # cache of deep merged values by top-level key
       attr_reader :deep_merge_cache

       def initialize(normal, default, override, automatic)
         @set_unless_present = false

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

         @deep_merge_cache = {}
       end

       # Debug what's going on with an attribute. +args+ is a path spec to the
       # attribute you're interested in. For example, to debug where the value
       # of `node[:network][:default_interface]` is coming from, use:
       #   debug_value(:network, :default_interface).
       # The return value is an Array of Arrays. The first element is
       # `["set_unless_enabled?", Boolean]`, which describes whether the
       # attribute collection is in "set_unless" mode. The rest of the Arrays
       # are pairs of `["precedence_level", value]`, where precedence level is
       # the component, such as role default, normal, etc. and value is the
       # attribute value set at that precedence level. If there is no value at
       # that precedence level, +value+ will be the symbol +:not_present+.
       def debug_value(*args)
         components = COMPONENTS.map do |component|
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
           [component.to_s.sub(/^@/,""), value]
         end
         [["set_unless_enabled?", @set_unless_present]] + components
       end

       # Enables or disables `||=`-like attribute setting. See, e.g., Node#set_unless
       def set_unless_value_present=(setting)
         @set_unless_present = setting
       end

       def reset_cache(path = nil)
         if path.nil? || path.empty?
           @deep_merge_cache = {}
         else
           @deep_merge_cache.delete[path.first]
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
         reset(args)
         # just easier to compute our retval, rather than collect+merge sub-retvals
         ret = args.inject(merged_attributes) do |attr, arg|
           if attr.nil? || !attr.respond_to?(:[])
             nil
           else
             begin
               attr[arg]
             rescue TypeError
               raise TypeError, "Wrong type in index of attribute (did you use a Hash index on an Array?)"
             end
           end
         end
         rm_default(*args)
         rm_normal(*args)
         rm_override(*args)
         ret
       end

       # does <level>['foo']['bar'].delete('baz')
       def remove_from_precedence_level(level, *args, key)
         multimash = level.element(*args)
         multimash.nil? ? nil : multimash.delete(key)
       end

       private :remove_from_precedence_level

       # clears attributes from all default precedence levels
       #
       # equivalent to: force_default!['foo']['bar'].delete('baz')
       def rm_default(*args)
         reset(args)
         remove_from_precedence_level(force_default!(autovivify: false), *args)
       end

       # clears attributes from normal precedence
       #
       # equivalent to: normal!['foo']['bar'].delete('baz')
       def rm_normal(*args)
         reset(args)
         remove_from_precedence_level(normal!(autovivify: false), *args)
       end

       # clears attributes from all override precedence levels
       #
       # equivalent to: force_override!['foo']['bar'].delete('baz')
       def rm_override(*args)
         reset(args)
         remove_from_precedence_level(force_override!(autovivify: false), *args)
       end

       #
       # Replacing attributes without merging
       #

       # sets default attributes without merging
       def default!(opts={})
         # FIXME: do not flush whole cache
         reset
         MultiMash.new(self, @default, [], opts)
       end

       # sets normal attributes without merging
       def normal!(opts={})
         # FIXME: do not flush whole cache
         reset
         MultiMash.new(self, @normal, [], opts)
       end

       # sets override attributes without merging
       def override!(opts={})
         # FIXME: do not flush whole cache
         reset
         MultiMash.new(self, @override, [], opts)
       end

       # clears from all default precedence levels and then sets force_default
       def force_default!(opts={})
         # FIXME: do not flush whole cache
         reset
         MultiMash.new(self, @force_default, [@default, @env_default, @role_default], opts)
       end

       # clears from all override precedence levels and then sets force_override
       def force_override!(opts={})
         # FIXME: do not flush whole cache
         reset
         MultiMash.new(self, @force_override, [@override, @env_override, @role_override], opts)
       end

       #
       # Accessing merged attributes
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

       def [](key)
         if deep_merge_cache.has_key?(key)
           deep_merge_cache[key]
         else
           deep_merge_cache[key] = merged_attributes(key)
         end
       end

       def []=(key, value)
         raise "this should just raise an immutable attribute exception"
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
         if args.empty?
           if key?(symbol)
             self[symbol]
           else
             raise NoMethodError, "Undefined method or attribute `#{symbol}' on `node'"
           end
         elsif symbol.to_s =~ /=$/
           key_to_set = symbol.to_s[/^(.+)=$/, 1]
           self[key_to_set] = (args.length == 1 ? args[0] : args)
         else
           raise NoMethodError, "Undefined node attribute or method `#{symbol}' on `node'"
         end
       end

       def inspect
         "#<#{self.class} " << (COMPONENTS + [:@merged_attributes, :@properties]).map{|iv|
           "#{iv}=#{instance_variable_get(iv).inspect}"
         }.join(', ') << ">"
       end

       def set_unless?
         @set_unless_present
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
           apply_path(@automatic, path)
         ]
         components.inject(nil) do |merged, component|
           Chef::Mixin::DeepMerge.hash_only_merge(merged, component)
         end
       end

       # Deep merge the default attribute levels with array merging.
       #
       # The path allows for selectively deep-merging a subtree of the node object.
       #
       # @param path [Array] Array of args to method chain to descend into the node object
       # @return [attr] Deep Merged values (may be VividMash, Hash, Array, etc) from the node object
       def merge_defaults(path)
         ret = DEFAULT_COMPONENTS.inject(nil) do |merged, component_ivar|
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
         ret = OVERRIDE_COMPONENTS.inject(nil) do |merged, component_ivar|
           component_value = apply_path(instance_variable_get(component_ivar), path)
           Chef::Mixin::DeepMerge.deep_merge(component_value, merged)
         end
       end

    end

  end
end
