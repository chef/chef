#--
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2008, 2009 Opscode, Inc.
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

require 'chef/mixin/convert_to_class_name'
require 'chef/exceptions'
require 'chef/resource_builder'
require 'chef/mixin/shell_out'
require 'chef/dsl/resources'
require 'chef/dsl/definitions'

class Chef
  module DSL

    # == Chef::DSL::Recipe
    # Provides the primary recipe DSL functionality for defining Chef resource
    # objects via method calls.
    module Recipe

      include Chef::Mixin::ShellOut

      # method_missing must live for backcompat purposes until Chef 13.
      def method_missing(method_symbol, *args, &block)
        #
        # If there is already DSL for this, someone must have called
        # method_missing manually. Not a fan. Not. A. Fan.
        #
        if respond_to?(method_symbol)
          Chef::Log.deprecation("Calling method_missing(#{method_symbol.inspect}) directly is deprecated in Chef 12 and will be removed in Chef 13.")
          Chef::Log.deprecation("Use public_send() or send() instead.")
          return send(method_symbol, *args, &block)
        end

        #
        # If a definition exists, then Chef::DSL::Definitions.add_definition was
        # never called.  DEPRECATED.
        #
        if run_context.definitions.has_key?(method_symbol.to_sym)
          Chef::Log.deprecation("Definition #{method_symbol} (#{run_context.definitions[method_symbol.to_sym]}) was added to the run_context without calling Chef::DSL::Definitions.add_definition(#{method_symbol.to_sym.inspect}).  This will become required in Chef 13.")
          Chef::DSL::Definitions.add_definition(method_symbol)
          return send(method_symbol, *args, &block)
        end

        #
        # See if the resource exists anyway.  If the user had set
        # Chef::Resource::Blah = <resource>, a deprecation warning will be
        # emitted and the DSL method 'blah' will be added to the DSL.
        #
        resource_class = Chef::ResourceResolver.new(run_context ? run_context.node : nil, method_symbol).resolve
        if resource_class
          return send(method_symbol, *args, &block)
        end

        begin
          super
        rescue NoMethodError
          raise NoMethodError, "No resource or method named `#{method_symbol}' for #{describe_self_for_error}"
        rescue NameError
          raise NameError, "No resource, method, or local variable named `#{method_symbol}' for #{describe_self_for_error}"
        end
      end

      include Chef::DSL::Resources
      include Chef::DSL::Definitions

      #
      # Instantiates a resource (via #build_resource), then adds it to the
      # resource collection. Note that resource classes are looked up directly,
      # so this will create the resource you intended even if the method name
      # corresponding to that resource has been overridden.
      #
      # @param type [Symbol] The type of resource (e.g. `:file` or `:package`)
      # @param name [String] The name of the resource (e.g. '/x/y.txt' or 'apache2')
      # @param created_at [String] The caller of the resource.  Use `caller[0]`
      #   to get the caller of your function.  Defaults to the caller of this
      #   function.
      # @param resource_attrs_block A block that lets you set attributes of the
      #   resource (it is instance_eval'd on the resource instance).
      #
      # @return [Chef::Resource] The new resource.
      #
      # @example
      #   declare_resource(:file, '/x/y.txy', caller[0]) do
      #     action :delete
      #   end
      #   # Equivalent to
      #   file '/x/y.txt' do
      #     action :delete
      #   end
      #
      def declare_resource(type, name, created_at=nil, &resource_attrs_block)
        created_at ||= caller[0]

        resource = build_resource(type, name, created_at, &resource_attrs_block)

        run_context.resource_collection.insert(resource, resource_type: type, instance_name: name)
        resource
      end

      #
      # Instantiate a resource of the given +type+ with the given +name+ and
      # attributes as given in the +resource_attrs_block+.
      #
      # The resource is NOT added to the resource collection.
      #
      # @param type [Symbol] The type of resource (e.g. `:file` or `:package`)
      # @param name [String] The name of the resource (e.g. '/x/y.txt' or 'apache2')
      # @param created_at [String] The caller of the resource.  Use `caller[0]`
      #   to get the caller of your function.  Defaults to the caller of this
      #   function.
      # @param resource_attrs_block A block that lets you set attributes of the
      #   resource (it is instance_eval'd on the resource instance).
      #
      # @return [Chef::Resource] The new resource.
      #
      # @example
      #   build_resource(:file, '/x/y.txy', caller[0]) do
      #     action :delete
      #   end
      #
      def build_resource(type, name, created_at=nil, &resource_attrs_block)
        created_at ||= caller[0]

        Chef::ResourceBuilder.new(
          type:                type,
          name:                name,
          created_at:          created_at,
          params:              @params,
          run_context:         run_context,
          cookbook_name:       cookbook_name,
          recipe_name:         recipe_name,
          enclosing_provider:  self.is_a?(Chef::Provider) ? self :  nil
        ).build(&resource_attrs_block)
      end

      def resource_class_for(snake_case_name)
        Chef::Resource.resource_for_node(snake_case_name, run_context.node)
      end

      def have_resource_class_for?(snake_case_name)
        not resource_class_for(snake_case_name).nil?
      rescue NameError
        false
      end

      def describe_self_for_error
        if respond_to?(:name)
          %Q[`#{self.class.name} "#{name}"']
        elsif respond_to?(:recipe_name)
          %Q[`#{self.class.name} "#{recipe_name}"']
        else
          to_s
        end
      end

      def exec(args)
        raise Chef::Exceptions::ResourceNotFound, "exec was called, but you probably meant to use an execute resource.  If not, please call Kernel#exec explicitly.  The exec block called was \"#{args}\""
      end

    end
  end
end

# We require this at the BOTTOM of this file to avoid circular requires (it is used
# at runtime but not load time)
require 'chef/resource'

# **DEPRECATED**
# This used to be part of chef/mixin/recipe_definition_dsl_core. Load the file to activate the deprecation code.
require 'chef/mixin/recipe_definition_dsl_core'
