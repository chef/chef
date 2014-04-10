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
require 'chef/node/attribute_tracing'
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

       # default! is the "advertised" method for force_default, but is
       # implemented as an alias because instance variables can't (easily) have
       # +!+ characters.
       alias :default! :force_default

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

       # +override!+ is the "advertised" method for +force_override+ but is
       # implemented as an alias because instance variables can't easily have
       # +!+ characters.
       alias :override! :force_override

       # return the automatic level attribute component
       attr_reader :automatic

       # Hash (by slashpath) of arrays of attribute changes, CHEF-2913
       attr_reader :trace_log

       def initialize(normal, default, override, automatic)
         @set_unless_present = false

         @default = VividMash.new(self, default, self, :default)
         @env_default = VividMash.new(self, {}, self, :env_default)
         @role_default = VividMash.new(self, {}, self, :role_default)
         @force_default = VividMash.new(self, {}, self, :force_default)

         @normal = VividMash.new(self, normal, self, :normal)

         @override = VividMash.new(self, override, self, :override)
         @role_override = VividMash.new(self, {}, self, :role_override)
         @env_override = VividMash.new(self, {}, self, :env_override)
         @force_override = VividMash.new(self, {}, self, :force_override)

         @automatic = VividMash.new(self, automatic, self, :automatic)

         @merged_attributes = nil
         @combined_override = nil
         @combined_default = nil

         @trace_queue = []
         @trace_log = {}
       end

       class << self
         # This is really gross (effectively a global variable), but aside from
         # doing some major surgery in the Mash, DeepMerge, and RunListExpansion
         # classes, this is a practical way of passing along things like the name
         # of the role being merged in.
         #  Just prior to doing a merge against a component, set this to a hash 
         # with hints about the provenance of the merge.  Keys should match that 
         # of a TraceLogEntry - :mechanism, :explanation, any other details 
         # specific to the merge.
         #  You should clear this after a merge.
         attr_accessor :tracer_hint
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

       # Clears merged_attributes, which will cause it to be recomputed on the
       # next access.
       def reset_cache
         @merged_attributes = nil
         @combined_default  = nil
         @combined_override = nil
         @set_unless_present = false
       end

       alias :reset :reset_cache

       # Deeply merges a Hash, Mash, or VididMash into the given precedence level.
       # Intended to make it easier to trace merges as role attributes are expanded.
       def merge_into_component(component_ivar, new_data)
         existing = instance_variable_get(component_ivar)
         Chef::Mixin::DeepMerge.deep_merge!(new_data, existing)
       end

       # Set the cookbook level default attribute component to +new_data+.
       def default=(new_data)
         reset
         trace_attribute_clear(:default)
         @default = VividMash.new(self, new_data, self, :default)
       end

       # Set the role level default attribute component to +new_data+
       def role_default=(new_data)
         reset
         # Do not trace a clear here - this is only used by 
         # node.apply_expansion_attributes, which appends the expansion's
         # trace log.
         @role_default = VividMash.new(self, new_data, self, :role_default)
       end

       # Set the environment level default attribute component to +new_data+
       def env_default=(new_data)
         reset
         trace_attribute_clear(:env_default)
         @env_default = VividMash.new(self, new_data, self, :env_default)
       end

       # Set the force_default (+default!+) level attributes to +new_data+
       def force_default=(new_data)
         reset
         trace_attribute_clear(:force_default)
         @force_default = VividMash.new(self, new_data, self, :force_default)
       end

       # Set the normal level attribute component to +new_data+
       def normal=(new_data)
         reset
         trace_attribute_clear(:normal)
         @normal = VividMash.new(self, new_data, self, :normal)
         @normal
       end

       # Set the cookbook level override attribute component to +new_data+
       def override=(new_data)
         reset
         trace_attribute_clear(:override)
         @override = VividMash.new(self, new_data, self, :override)
       end

       # Set the role level override attribute component to +new_data+
       def role_override=(new_data)
         reset
         # Do not trace a clear here - this is only used by 
         # node.apply_expansion_attributes, which appends the expansion's
         # trace log.
         @role_override = VividMash.new(self, new_data, self, :role_override)
       end

       # Set the environment level override attribute component to +new_data+
       def env_override=(new_data)
         reset
         trace_attribute_clear(:env_override)
         @env_override = VividMash.new(self, new_data, self, :env_override)
       end

       def force_override=(new_data)
         reset
         trace_attribute_clear(:force_override)
         @force_override = VividMash.new(self, new_data, self, :force_override)
       end

       def automatic=(new_data)
         reset
         trace_attribute_clear(:automatic)
         # TODO - use two-stage create throughout if needed
         @automatic = VividMash.new(self, {}, self, :automatic)
         @automatic.update(new_data)
         @automatic
       end

       def merged_attributes
         @merged_attributes ||= begin
                                  components = [merge_defaults, @normal, merge_overrides, @automatic]
                                  resolved_attrs = components.inject(Mash.new) do |merged, component|
                                    Chef::Mixin::DeepMerge.hash_only_merge(merged, component)
                                  end
                                  immutablize(resolved_attrs)
                                end
       end

       def combined_override
         @combined_override ||= immutablize(merge_overrides)
       end

       def combined_default
         @combined_default ||= immutablize(merge_defaults)
       end

       def [](key)
         merged_attributes[key]
       end

       def []=(key, value)
         merged_attributes[key] = value
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

       def merge_defaults
         DEFAULT_COMPONENTS.inject(Mash.new) do |merged, component_ivar|
           component_value = instance_variable_get(component_ivar)
           Chef::Mixin::DeepMerge.merge(merged, component_value)
         end
       end

       def merge_overrides
         OVERRIDE_COMPONENTS.inject(Mash.new) do |merged, component_ivar|
           component_value = instance_variable_get(component_ivar)
           Chef::Mixin::DeepMerge.merge(merged, component_value)
         end
       end


    end

  end
end
