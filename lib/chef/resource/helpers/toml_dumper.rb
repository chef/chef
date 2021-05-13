#
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
# limitations

class Chef
  module ResourceHelpers
    module TomlDumper
      attr_reader :toml_str

      def initialize(hash)
        @toml_str = ""

        visit(hash, [])
      end

      def visit(hash, prefix, extra_brackets = false)
        simple_pairs, nested_pairs, table_array_pairs = sort_pairs hash

        if prefix.any? && (simple_pairs.any? || hash.empty?)
          print_prefix prefix, extra_brackets
        end

        dump_pairs simple_pairs, nested_pairs, table_array_pairs, prefix
      end

      def sort_pairs(hash)
        nested_pairs = []
        simple_pairs = []
        table_array_pairs = []

        hash.keys.sort.each do |key|
          val = hash[key]
          element = [key, val]

          if val.is_a? Hash
            nested_pairs << element
          elsif val.is_a?(Array) && val.first.is_a?(Hash)
            table_array_pairs << element
          else
            simple_pairs << element
          end
        end

        [simple_pairs, nested_pairs, table_array_pairs]
      end

      def dump_pairs(simple, nested, table_array, prefix = [])
        # First add simple pairs, under the prefix
        dump_simple_pairs simple
        dump_nested_pairs nested, prefix
        dump_table_array_pairs table_array, prefix
      end

      def dump_simple_pairs(simple_pairs)
        simple_pairs.each do |key, val|
          key = quote_key(key) unless bare_key? key
          @toml_str << "#{key} = #{to_toml(val)}\n"
        end
      end

      def dump_nested_pairs(nested_pairs, prefix)
        nested_pairs.each do |key, val|
          key = quote_key(key) unless bare_key? key

          visit val, prefix + [key], false
        end
      end

      def dump_table_array_pairs(table_array_pairs, prefix)
        table_array_pairs.each do |key, val|
          key = quote_key(key) unless bare_key? key
          aux_prefix = prefix + [key]

          val.each do |child|
            print_prefix aux_prefix, true
            args = sort_pairs(child) << aux_prefix

            dump_pairs(*args)
          end
        end
      end

      def print_prefix(prefix, array = false)
        new_prefix = prefix.join(".")
        new_prefix = "[#{new_prefix}]" if array

        @toml_str += "[#{new_prefix}]\n"
      end

      def to_toml(obj)
        if obj.is_a?(Time) || obj.is_a?(DateTime)
          obj.strftime("%Y-%m-%dT%H:%M:%SZ")
        elsif obj.is_a?(Date)
          obj.strftime("%Y-%m-%d")
        elsif obj.is_a? Regexp
          obj.inspect.inspect
        elsif obj.is_a? String
          obj.inspect.gsub(/\\(#[$@{])/, '\1')
        else
          obj.inspect
        end
      end

      def bare_key?(key)
        !!key.to_s.match(/^[a-zA-Z0-9_-]*$/)
      end

      def quote_key(key)
        '"' + key.gsub('"', '\\"') + '"'
      end
    end

    def toml_dump(hash)
      Dumper.new(hash).toml_str
    end

    extend self
  end
end
