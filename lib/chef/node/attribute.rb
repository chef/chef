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
require 'chef/node/un_method_chain'
require 'chef/node/attribute_traits'

class Chef
  class Node
    class Attribute
      include AttributeTrait::Decorator
      include AttributeTrait::SymbolConvert
      include AttributeTrait::MethodMissing
      include AttributeTrait::Immutable
      include AttributeTrait::DeepMergeCache
      include AttributeTrait::PathTracking
      include AttributeConstants

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
          deep_merge_cache: __deep_merge_cache,
          node: __node
        )
      end

      COMPONENTS_AS_SYMBOLS.each do |component|
        attr_writer component

        define_method component do
          wrapped_object.public_send(component)
        end

        define_method :"#{component}=" do |value|
          __deep_merge_cache.clear
          wrapped_object.public_send(:"#{component}=", value)
        end
      end

      def wrap_automatic_attrs(value)
        __deep_merge_cache.clear
        wrapped_object.wrap_automatic_attrs(value)
      end

      def combined_default
        self.class.new(wrapped_object: wrapped_object.combined_default)
      end

      def combined_override
        self.class.new(wrapped_object: wrapped_object.combined_override)
      end

      def normal_unless(*args)
        return UnMethodChain.new(wrapped_object: self, method_to_call: :normal_unless) unless args.length > 0
        write_value(:normal, *args) if safe_reader(*args[0...-1]).nil?
      end

      def default_unless(*args)
        return UnMethodChain.new(wrapped_object: self, method_to_call: :default_unless) unless args.length > 0
        write_value(:default, *args) if safe_reader(*args[0...-1]).nil?
      end

      def override_unless(*args)
        return UnMethodChain.new(wrapped_object: self, method_to_call: :override_unless) unless args.length > 0
        write_value(:override, *args) if safe_reader(*args[0...-1]).nil?
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

      alias_method :attribute?, :include?
      alias_method :member?, :include?

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

      # FIXME: doesn't decorator handle all this delgated crap now?
      # vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
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
        with_deep_merged_return_value(self, *args) do
          rm_default(*args)
          rm_normal(*args)
          rm_override(*args)
        end
      end

      def with_deep_merged_return_value(obj, *args)
        hash = obj.safe_reader(*args[0...-1])
        return nil unless hash.is_a?(Hash)
        ret = hash[args.last]
        yield
        ret
      end

      private :with_deep_merged_return_value

      # clears attributes from all default precedence levels
      #
      # - similar to: force_default!['foo']['bar'].delete('baz')
      # - does not autovivify
      # - does not trainwreck if interior keys do not exist
      def rm_default(*args)
        with_deep_merged_return_value(combined_default, *args) do
          default.safe_delete(*args)
          role_default.safe_delete(*args)
          env_default.safe_delete(*args)
          force_default.safe_delete(*args)
        end
      end

      # clears attributes from normal precedence
      #
      # - similar to: normal!['foo']['bar'].delete('baz')
      # - does not autovivify
      # - does not trainwreck if interior keys do not exist
      def rm_normal(*args)
        normal.safe_delete(*args)
      end

      # clears attributes from all override precedence levels
      #
      # - similar to: force_override!['foo']['bar'].delete('baz')
      # - does not autovivify
      # - does not trainwreck if interior keys do not exist
      def rm_override(*args)
        with_deep_merged_return_value(combined_override, *args) do
          override.safe_delete(*args)
          role_override.safe_delete(*args)
          env_override.safe_delete(*args)
          force_override.safe_delete(*args)
        end
      end

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
