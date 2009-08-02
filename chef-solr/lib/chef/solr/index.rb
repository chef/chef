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

      def add(id, database, type, item)
        raise ArgumentError, "Object must respond to keys!" unless item.respond_to?(:keys)
        to_index = flatten_and_expand(item)
        to_index["X_CHEF_id_CHEF_X"] = id
        to_index["X_CHEF_database_CHEF_X"] = database
        to_index["X_CHEF_type_CHEF_X"] = type
        solr_add(to_index)
        to_index
      end

      def delete(id)
        solr_delete_by_id(id)
      end

      def delete_by_query(query)
        solr_delete_by_query(query)
      end

      def flatten_and_expand(item, fields=Hash.new, parent=nil)
        item.keys.each do |key|
          # If we have a parent, we want to add the current key as a value 
          if parent
            # foo_bar = bar
            set_field_value(fields, parent, key) 
            # foo_X = bar, etc.
            make_expando_fields(parent).each do |ex_key|
              set_field_value(fields, ex_key, key)
            end
          end
          case item[key]
          when Hash
            parent_key = parent ? "#{parent}_#{key}" : key
            flatten_and_expand(item[key], fields, parent_key)
          else
            parent_key = parent ? "#{parent}_#{key}" : key
            set_field_value(fields, key, item[key])
            set_field_value(fields, parent_key, item[key]) if parent
            make_expando_fields(parent_key).each do |ex_key|
              set_field_value(fields, ex_key, item[key])
            end
          end
        end
        fields
      end

      def make_expando_fields(key)
        key = key.to_s
        fields = Array.new 
        parts = key.split("_")
        length = parts.length
        parts.each_index do |i|
          beginning = nil
          remainder = nil
          if i == 0
            beginning = "X"
          else
            beginning = parts[0..i-1].join("_")
          end

          if i == length-1
            remainder = "X"
          else
            remainder = parts[i+1..-1].join("_")
          end

          if beginning == "X" || remainder == "X"
            unless beginning == "X" && remainder == "X"
              fields << "#{beginning}_#{remainder}" 
            end
          else
            fields << "#{beginning}_X_#{remainder}"
          end
        end
        fields
      end

      def set_field_value(fields, key, value)
        key = key.to_s
        if fields.has_key?(key)
          convert_field_to_array(fields, key, value) unless fields[key].kind_of?(Array)
          add_value_to_field_array(fields, key, value)
        else
          check_value(value)
          if value.kind_of?(Array)
            fields[key] = Array.new
            value.each do |v|
              fields[key] << v.to_s
            end
          else
            fields[key] = value.to_s
          end
        end
        fields
      end

      def add_value_to_field_array(fields, key, value)
        check_value(value)
        if value.kind_of?(Array)
          value.each do |v|
            check_value(v)
            fields[key] << v.to_s unless fields[key].include?(v.to_s)
          end
        else
          fields[key] << value.to_s unless fields[key].include?(value.to_s)
        end
        fields
      end

      def convert_field_to_array(fields, key, value)
        if fields[key] != value
          safe = fields[key]
          fields[key] = [ safe ]
        end
        fields
      end

      def check_value(value)
        raise ArgumentError, "Value must not be a type of hash!" if value.kind_of?(Hash)
        value
      end

    end
  end
end

