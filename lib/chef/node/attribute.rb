#--
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: AJ Christensen (<aj@opscode.com>)
# Copyright:: Copyright (c) 2008-2015 Chef Software, Inc.
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

require 'chef/node/attribute_constants'
require 'chef/node/attribute_cell'
require 'chef/node/set_unless'
require 'chef/node/un_method_chain'
require 'chef/node/attribute_traits'

class Chef
  class Node
    class Attribute
      include AttributeTrait::Decorator
      include AttributeTrait::SymbolConvert
      include AttributeTrait::MethodMissing
      include AttributeTrait::Immutable
      #include AttributeTrait::DeepMergeCache
      include AttributeConstants

      #deep_merge_cache_populator

      def initialize(normal: nil, default: nil, override: nil, automatic: nil, **args)
        super(**args)
        @wrapped_object ||= AttributeCell.new(
            default: default || {},
            env_default: {},
            role_default: {},
            force_default: {},
            normal: normal || {},
            override: override || {},
            role_override: {},
            env_override: {},
            force_override: {},
            automatic: automatic || {},
        )
      end

      COMPONENTS_AS_SYMBOLS.each do |component|
        attr_writer component

        define_method component do
          wrapped_object.public_send(component)
        end

        define_method :"#{component}=" do |value|
          wrapped_object.public_send(:"#{component}=", value)
        end
      end

      def combined_default
        wrapped_object.combined_default
      end

      def combined_override
        wrapped_object.combined_override
      end

      def normal_unless
        SetUnless.new(wrapped_object: wrapped_object.normal, convert_value: false)
      end

      def default_unless
        SetUnless.new(wrapped_object: wrapped_object.default, convert_value: false)
      end

      def override_unless
        SetUnless.new(wrapped_object: wrapped_object.override, convert_value: false)
      end

      # should deprecate all of these, epecially #set
      alias_method :set, :normal
      alias_method :set_unless, :normal_unless
      alias_method :default_attrs, :default
      alias_method :default_attrs=, :default=
      alias_method :normal_attrs, :normal
      alias_method :normal_attrs=, :normal=
      alias_method :override_attrs, :override
      alias_method :override_attrs=, :override=
      alias_method :automatic_attrs, :automatic
      alias_method :automatic_attrs=, :automatic=

      def has_key?(key)
        self.public_send(:key?, key)
      end

      alias_method :attribute?, :has_key?
      alias_method :member?, :has_key?

      def include?(val)
        wrapped_object.public_send(:include?, val)
      end

      def each_attribute(&block)
        self.public_send(:each, &block)
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
        COMPONENTS_AS_SYMBOLS.map do |component|
          ivar = wrapped_object.send(component)
          value = args.inject(ivar) do |so_far, key|
            if so_far == :not_present
              :not_present
            elsif so_far.has_key?(key)
              so_far[key]
            else
              :not_present
            end
          end
          [component.to_s, value]
        end
      end

      def to_s
        wrapped_object.to_s
      end

      def eql?(other)
        wrapped_object.eql?(other)
      end

      def ===(other)
        wrapped_object === other
      end

      def ==(other)
        wrapped_object == other
      end

      def is_a?(klass)
        wrapped_object.is_a?(klass) || super(klass)
      end

      def kind_of?(klass)
        wrapped_object.kind_of?(klass) || super(klass)
      end

      # clears attributes from all precedence levels
      #
      # - does not autovivify
      # - does not trainwreck if interior keys do not exist
      def rm(*args)
        cell = args_to_cell(*args)
        return nil unless cell.is_a?(Hash)
        ret = cell[args.last]
        rm_default(*args)
        rm_normal(*args)
        rm_override(*args)
        ret
      end

      # clears attributes from all default precedence levels
      #
      # - similar to: force_default!['foo']['bar'].delete('baz')
      # - does not autovivify
      # - does not trainwreck if interior keys do not exist
      def rm_default(*args)
        cell = args_to_cell(*args)
        return nil unless cell.is_a?(Hash)
        ret = if cell.combined_default.is_a?(Hash)
                cell.combined_default[args.last]
              end
        cell.default.delete(args.last) if cell.default.is_a?(Hash)
        cell.role_default.delete(args.last) if cell.role_default.is_a?(Hash)
        cell.env_default.delete(args.last) if cell.env_default.is_a?(Hash)
        cell.force_default.delete(args.last) if cell.force_default.is_a?(Hash)
        ret
      end

      # clears attributes from normal precedence
      #
      # - similar to: normal!['foo']['bar'].delete('baz')
      # - does not autovivify
      # - does not trainwreck if interior keys do not exist
      def rm_normal(*args)
        cell = args_to_cell(*args)
        return nil unless cell.is_a?(Hash)
        cell.normal.delete(args.last) if cell.normal.is_a?(Hash)
      end

      # clears attributes from all override precedence levels
      #
      # - similar to: force_override!['foo']['bar'].delete('baz')
      # - does not autovivify
      # - does not trainwreck if interior keys do not exist
      def rm_override(*args)
        cell = args_to_cell(*args)
        return nil unless cell.is_a?(Hash)
        ret = if cell.combined_override.is_a?(Hash)
                cell.combined_override[args.last]
              end
        cell.override.delete(args.last) if cell.override.is_a?(Hash)
        cell.role_override.delete(args.last) if cell.role_override.is_a?(Hash)
        cell.env_override.delete(args.last) if cell.env_override.is_a?(Hash)
        cell.force_override.delete(args.last) if cell.force_override.is_a?(Hash)
        ret
      end

      def args_to_cell(*args)
        begin
          last = args.pop
          cell = args.inject(self) do |memo, arg|
            memo[arg]
          end
          cell
        rescue NoMethodError
          nil
        end
      end

      private :args_to_cell

      # FIXME: should probably be another decorator behavior that changes :[] and :[]= to wipe
      # out intermediate non-hash things and replace them with hashes in addition to autovivifying
      # and/or add #hashifying_accessor and #hashifying_writer methods directly to VividMash.
      def write_value(level, *args)
        value = args.pop
        last = args.pop
        previous_memo = previous_arg = nil
        my_level = self.send(level)
        chain = args.inject(self.send(level)) do |memo, arg|
          unless memo.respond_to?(:[])
            # The public API will never get previous_memo set to nil, so we do not care.
            previous_memo[previous_arg] = {}
            memo = previous_memo[previous_arg]
          end
          previous_memo = memo
          previous_arg = arg
          memo[arg]
        end
        unless chain.respond_to?(:[]=)
          # The public API will never get previous_memo set to nil, so we do not care.
          previous_memo[previous_arg] = {}
          chain = previous_memo[previous_arg]
        end
        chain[last] = value
      end

      private :write_value

      # sets default attributes without merging.
      #
      # - this API autovivifies (and cannot tranwreck)
      def default!(*args)
        return UnMethodChain.new(wrapped_object: self, method_to_call: :default!) unless args.length > 0
        write_value(:default, *args)
      end

      # set normal attributes without merging.
      #
      # - this API autovivifies (and cannot tranwreck)
      def normal!(*args)
        return UnMethodChain.new(wrapped_object: self, method_to_call: :normal!) unless args.length > 0
        write_value(:normal, *args)
      end

      # set override attributes without merging.
      #
      # - this API autovivifies (and cannot tranwreck)
      def override!(*args)
        return UnMethodChain.new(wrapped_object: self, method_to_call: :override!) unless args.length > 0
        write_value(:override, *args)
      end

      # set force_default attributes without merging.
      #
      # - this also clears all of the other default levels as well.
      # - this API autovivifies (and cannot tranwreck)
      def force_default!(*args)
        return UnMethodChain.new(wrapped_object: self, method_to_call: :force_default!) unless args.length > 0
        value = args.pop
        rm_default(*args)
        write_value(:force_default, *args, value)
      end

      # set force_override attributes without merging.
      #
      # - this also clears all of the other override levels as well.
      # - this API autovivifies (and cannot tranwreck)
      def force_override!(*args)
        return UnMethodChain.new(wrapped_object: self, method_to_call: :force_override!) unless args.length > 0
        value = args.pop
        rm_override(*args)
        write_value(:force_override, *args, value)
      end
    end
  end
end
