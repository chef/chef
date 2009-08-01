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
      attr_accessor :attribute, :default, :override, :state, :current_attribute, :current_default, :current_override, :auto_vivifiy_on_read

      def initialize(attribute, default, override, state=[])
        @attribute = attribute
        @current_attribute = attribute
        @default = default
        @current_default = default
        @override = override
        @current_override = override 
        @state = state 
        @auto_vivifiy_on_read = false
      end

      def [](key)

        @state << key 

        o_value = value_or_descend(current_override, key, auto_vivifiy_on_read)
        a_value = value_or_descend(current_attribute, key, auto_vivifiy_on_read)
        d_value = value_or_descend(current_default, key, auto_vivifiy_on_read)
       
        if o_value.respond_to?(:has_key?) && a_value.respond_to?(:has_key?) && d_value.respond_to?(:has_key?)
          value = Chef::Mixin::DeepMerge(d_value, a_value)
          value = Chef::Mixin::DeepMerge(value, o_value)
          value
        elsif o_value.respond_to?(:has_key?) && a_value.respond_to?(:has_key?)
          Chef::Mixin::DeepMerge(a_value, o_value)
        elsif o_value.respond_to?(:has_key?) && d_value.respond_to?(:has_key?)
          Chef::Mixin::DeepMerge(d_value, o_value)
        elsif a_value.respond_to?(:has_key?) && d_value.respond_to?(:has_key?)
          Chef::Mixin::DeepMerge(d_value, a_value)
        else
          if ! o_value.nil?
            o_value
          elsif ! a_value.nil?
            a_value
          elsif ! d_value.nil?
            d_value
          else 
            nil
          end
        end
      end

      def []=(key, value)
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
          cna.current_attribute = current_attribute[key]
          cna.current_default   = current_default[key]
          cna.current_override  = current_override[key]
          cna.auto_vivifiy_on_read = auto_vivifiy_on_read
          cna
        else
          data_hash[key]
        end
      end

    end
  end
end
