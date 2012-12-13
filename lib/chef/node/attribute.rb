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

         @merged_attributes = nil
         @combined_override = nil
         @combined_default = nil
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

       def merged_attributes
         @merged_attributes ||= begin
                                  resolved_attrs = COMPONENTS.inject(Mash.new) do |merged, component_ivar|
                                    component_value = instance_variable_get(component_ivar)
                                    Chef::Mixin::DeepMerge.merge(merged, component_value)
                                  end
                                  immutablize(resolved_attrs)
                                end
       end

       def combined_override
         @combined_override ||= begin
                                  resolved_attrs = OVERRIDE_COMPONENTS.inject(Mash.new) do |merged, component_ivar|
                                    component_value = instance_variable_get(component_ivar)
                                    Chef::Mixin::DeepMerge.merge(merged, component_value)
                                  end
                                  immutablize(resolved_attrs)
                                end
       end

       def combined_default
         @combined_default ||= begin
                                  resolved_attrs = DEFAULT_COMPONENTS.inject(Mash.new) do |merged, component_ivar|
                                    component_value = instance_variable_get(component_ivar)
                                    Chef::Mixin::DeepMerge.merge(merged, component_value)
                                  end
                                  immutablize(resolved_attrs)
                                end
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

    end

  end
end
