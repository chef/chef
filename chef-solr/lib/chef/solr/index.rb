#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require 'chef/log'
require 'chef/config'
require 'chef/solr'
require 'libxml'
require 'net/http'

class Chef
  class Solr
    class Index < Solr

      UNDERSCORE              = '_'
      X                       = 'X'

      X_CHEF_id_CHEF_X        = 'X_CHEF_id_CHEF_X'
      X_CHEF_database_CHEF_X  = 'X_CHEF_database_CHEF_X'
      X_CHEF_type_CHEF_X      = 'X_CHEF_type_CHEF_X'

      def add(id, database, type, item)
        unless item.respond_to?(:keys)
          raise ArgumentError, "#{self.class.name} can only index Hash-like objects. You gave #{item.inspect}"
        end

        to_index = flatten_and_expand(item)

        to_index[X_CHEF_id_CHEF_X]        = [id]
        to_index[X_CHEF_database_CHEF_X]  = [database]
        to_index[X_CHEF_type_CHEF_X]      = [type]

        solr_add(to_index)
        to_index
      end

      def delete(id)
        solr_delete_by_id(id)
      end

      def delete_by_query(query)
        solr_delete_by_query(query)
      end

      def flatten_and_expand(item)
        @flattened_item = Hash.new {|hash, key| hash[key] = []}

        item.each do |key, value|
          flatten_each([key.to_s], value)
        end

        @flattened_item.each_value { |values| values.uniq! }
        @flattened_item
      end

      def flatten_each(keys, values)
        case values
        when Hash
          values.each do |child_key, child_value|
            add_field_value(keys, child_key)
            flatten_each(keys + [child_key.to_s], child_value)
          end
        when Array
          values.each { |child_value| flatten_each(keys, child_value) }
        else
          add_field_value(keys, values)
        end
      end

      def add_field_value(keys, value)
        value = value.to_s
        each_expando_field(keys) { |expando_field| @flattened_item[expando_field] << value }
        @flattened_item[keys.join(UNDERSCORE)] << value
        @flattened_item[keys.last] << value
      end

      def each_expando_field(keys)
        return if keys.size == 1
        0.upto(keys.size - 1) do |index|
          original = keys[index]
          keys[index] = X
          yield keys.join(UNDERSCORE)
          keys[index] = original
        end
      end

    end
  end
end
