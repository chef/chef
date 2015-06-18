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
require 'chef/node/attribute_trait/decorator'

class Chef
  class Node
    class Attribute
      include AttributeTrait::Decorator
      include AttributeConstants

      def initialize(*args)
        if args.length == 4
          # Chef 11.x - 12.4.x backcompat initializer
          # FIXME: deprecate
          super(
            wrapped_object: AttributeCell.new(
              default: args[1],
              env_default: {},
              role_default: {},
              force_default: {},
              normal: args[0],
              override: args[2],
              role_override: {},
              env_override: {},
              force_override: {},
              automatic: args[3],
            )
          )
        else
          super
        end
      end

      def self.new_top_level_node_object
        new(
            wrapped_object: AttributeCell.new(
              default: {},
              env_default: {},
              role_default: {},
              force_default: {},
              normal: {},
              override: {},
              role_override: {},
              env_override: {},
              force_override: {},
              automatic: {},
            )
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
        SetUnless.new_decorator(wrapped_object: wrapped_object.normal)
      end

      def default_unless
        SetUnless.new_decorator(wrapped_object: wrapped_object.default)
      end

      def override_unless
        SetUnless.new_decorator(wrapped_object: wrapped_object.override)
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
      alias_method :include?, :has_key?

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

      def kind_of?(klass)
        wrapped_object.kind_of?(klass) || super(klass)
      end

      def is_a?(klass)
        wrapped_object.is_a?(klass) || super(klass)
      end

      def kind_of?(klass)
        wrapped_object.kind_of?(klass) || super(klass)
      end

      def inspect
        wrapped_object.inspect
      end

      def rm(*args)
        raise "unimplemented"
      end

      def rm_default(*args)
        raise "unimplemented"
      end

      def rm_normal(*args)
        raise "unimplemented"
      end

      def rm_override(*args)
        raise "unimplemented"
      end

      def default!(*args)
        raise "unimplemented"
      end

      def normal!(*args)
        raise "unimplemented"
      end

      def override!(*args)
        raise "unimplemented"
      end

      def force_default!(*args)
        raise "unimplemented"
      end

      def force_override!(*args)
        raise "unimplemented"
      end
    end
  end
end
