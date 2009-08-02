#
# Author:: Adam Jacob (<adam@opscode.com>)
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

require 'chef/mixin/deep_merge'
require 'chef/log'

class Chef
  class Node
    class Attribute
      attr_accessor :attribute, :default, :override, :state, :current_attribute, :current_default, :current_override, :auto_vivifiy_on_read, :set_unless_value_present

      def initialize(attribute, default, override, state=[])
        @attribute = attribute
        @current_attribute = attribute
        @default = default
        @current_default = default
        @override = override
        @current_override = override 
        @state = state 
        @auto_vivifiy_on_read = false
        @set_unless_value_present = false
      end

      # Reset our internal state to the top of every tree 
      def reset
        @current_attribute = @attribute
        @current_default = @default
        @current_override = @override
        @state = []
      end

      def [](key)

        @state << key 

        o_value = value_or_descend(current_override, key, auto_vivifiy_on_read)
        a_value = value_or_descend(current_attribute, key, auto_vivifiy_on_read)
        d_value = value_or_descend(current_default, key, auto_vivifiy_on_read)
     
        determine_value(o_value, a_value, d_value)
      end

      def attribute?(key)
        return true if get_value(override, key)
        return true if get_value(attribute, key)
        return true if get_value(default, key)
        false
      end

      def has_key?(key)
        attribute?(key)
      end

      def each_attribute(&block)
        get_keys.each do |key|
          value = determine_value(
            get_value(override, key),
            get_value(attribute, key),
            get_value(default, key)
          )
          block.call(key, value)
        end
      end

      def get_keys
        keys = current_override.keys
        current_attribute.keys.each do |key|
          keys << key unless keys.include?(key)
        end
        current_default.keys.each do |key|
          keys << key unless keys.include?(key)
        end
        keys
      end

      def each(&block)
        get_keys.each do |k|
          block.call(k)
        end
      end

      def get_value(data_hash, key)
        last = nil

        if state.length == 0
          if data_hash.has_key?(key) && ! data_hash[key].nil?
            return data_hash[key]
          else
            return nil
          end
        end

        0.upto(state.length) do |i|
          if i == 0
            last = auto_vivifiy(data_hash, state[i]) 
          elsif i == state.length
            fk = last[state[i - 1]]
            if fk.has_key?(key) && ! fk[key].nil?
              return fk[key]
            else
              return nil
            end
          else
            last = auto_vivifiy(last[state[i - 1]], state[i]) 
          end
        end
      end

      def hash_and_not_cna?(to_check)
        (! to_check.kind_of?(Chef::Node::Attribute)) && to_check.respond_to?(:has_key?)
      end

      def determine_value(o_value, a_value, d_value)
        # If all three have hash values, merge them
        if hash_and_not_cna?(o_value) && hash_and_not_cna?(a_value) && hash_and_not_cna?(d_value)
          value = Chef::Mixin::DeepMerge.merge(d_value, a_value)
          value = Chef::Mixin::DeepMerge.merge(value, o_value)
          value
        # If only the override and attributes have values, merge them 
        elsif hash_and_not_cna?(o_value) && hash_and_not_cna?(a_value)
          Chef::Mixin::DeepMerge.merge(a_value, o_value)
        # If only the override and default attributes have values, merge them
        elsif hash_and_not_cna?(o_value) && hash_and_not_cna?(d_value)
          Chef::Mixin::DeepMerge.merge(d_value, o_value)
        # If only the override attribute has a value (any value) use it
        elsif ! o_value.nil?
          o_value
        # If the attributes is a hash, and the default is a hash, merge them
        elsif hash_and_not_cna?(a_value) && hash_and_not_cna?(d_value)
          Chef::Mixin::DeepMerge.merge(d_value, a_value)
        # If we have an attribute value, use it
        elsif ! a_value.nil?
          a_value
        # If we have a default value, use it
        elsif ! d_value.nil?
          d_value
        else 
          nil
        end
      end

      def []=(key, value)
        if set_unless_value_present
          if get_value(@default, key) != nil
            Chef::Log.debug("Not setting #{state.join("/")}/#{key} to #{value.inspect} because it has a default value already")
            return false
          end
          if get_value(@attribute, key) != nil
            Chef::Log.debug("Not setting #{state.join("/")}/#{key} to #{value.inspect} because it has a node attribute value already")
            return false
          end
          if get_value(@override, key) != nil
            Chef::Log.debug("Not setting #{state.join("/")}/#{key} to #{value.inspect} because it has an override value already")
            return false
          end
        end

        set_value(@attribute, key, value) 
        set_value(@override, key, value) 
        value
      end

      def set_value(data_hash, key, value)
        last = nil

        # If there is no state, just set the value
        if state.length == 0
          data_hash[key] = value
          return data_hash
        end

        # Walk all the previous places we have been
        0.upto(state.length) do |i|
          # If we are the first, we are top level, and should vivifiy the data_hash
          if i == 0
            last = auto_vivifiy(data_hash, state[i]) 
          # If we are one past the last state, we are adding a key to that hash with a value 
          elsif i == state.length
            last[state[i - 1]][key] = value
          # Otherwise, we're auto-vivifiy-ing an interim mash
          else
            last = auto_vivifiy(last[state[i - 1]], state[i]) 
          end
        end
        data_hash
      end

      def auto_vivifiy(data_hash, key)
        if data_hash.has_key?(key)
          unless data_hash[key].respond_to?(:has_key?)
            raise ArgumentError, "You tried to set a nested key, where the parent is not a hash-like object." unless auto_vivifiy_on_read
          end
        else
          data_hash[key] = Mash.new
        end
        data_hash
      end

      def value_or_descend(data_hash, key, auto_vivifiy=false)

        if auto_vivifiy
          data_hash = auto_vivifiy(data_hash, key)
          unless current_attribute.has_key?(key)
            current_attribute[key] = data_hash[key]
          end
          unless current_default.has_key?(key)
            current_default[key] = data_hash[key]
          end
          unless current_override.has_key?(key)
            current_override[key] = data_hash[key]
          end
        else
          return nil if data_hash == nil
          return nil unless data_hash.has_key?(key)
        end

        if data_hash[key].respond_to?(:has_key?)
          cna = Chef::Node::Attribute.new(@attribute, @default, @override, @state)
          cna.current_attribute = current_attribute.nil? ? Mash.new : current_attribute[key]
          cna.current_default   = current_default.nil? ? Mash.new : current_default[key]
          cna.current_override  = current_override.nil? ? Mash.new : current_override[key]
          cna.auto_vivifiy_on_read = auto_vivifiy_on_read
          cna.set_unless_value_present = set_unless_value_present 
          cna
        else
          data_hash[key]
        end
      end

      def method_missing(symbol, *args)
        by = symbol
        if self.attribute?(symbol)
          by = symbol
        elsif self.attribute?(symbol.to_s) 
          by = symbol.to_s 
        else
          if args.length != 0
            by = symbol
          else
            raise ArgumentError, "Attribute #{symbol.to_s} is not defined!"
          end
        end

        if args.length != 0
          self[by] = args.length == 1 ? args[0] : args
        else
          self[by]
        end
      end


    end
  end
end
