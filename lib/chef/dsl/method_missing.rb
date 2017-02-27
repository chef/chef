#--
# Copyright:: Copyright 2008-2016 Chef Software, Inc.
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

class Chef
  module DSL
    # @deprecated scheduled to die in a Chef 13 fire
    module MethodMissing
      def describe_self_for_error
        if respond_to?(:name)
          %Q{`#{self.class} "#{name}"'}
        elsif respond_to?(:recipe_name)
          %Q{`#{self.class} "#{recipe_name}"'}
        else
          to_s
        end
      end

      # DEPRECATED:
      # method_missing must live for backcompat purposes until Chef 13.
      def method_missing(method_symbol, *args, &block)
        #
        # If there is already DSL for this, someone must have called
        # method_missing manually. Not a fan. Not. A. Fan.
        #
        if respond_to?(method_symbol)
          Chef.deprecated(:internal_api, "Calling method_missing(#{method_symbol.inspect}) directly is deprecated in Chef 12 and will be removed in Chef 13. Use public_send() or send() instead.")
          return send(method_symbol, *args, &block)
        end

        #
        # If a definition exists, then Chef::DSL::Definitions.add_definition was
        # never called.  DEPRECATED.
        #
        if run_context.definitions.has_key?(method_symbol.to_sym)
          Chef.deprecated(:internal_api, "Definition #{method_symbol} (#{run_context.definitions[method_symbol.to_sym]}) was added to the run_context without calling Chef::DSL::Definitions.add_definition(#{method_symbol.to_sym.inspect}).  This will become required in Chef 13.")
          Chef::DSL::Definitions.add_definition(method_symbol)
          return send(method_symbol, *args, &block)
        end

        #
        # See if the resource exists anyway.  If the user had set
        # Chef::Resource::Blah = <resource>, a deprecation warning will be
        # emitted and the DSL method 'blah' will be added to the DSL.
        #
        resource_class = Chef::ResourceResolver.resolve(method_symbol, node: run_context ? run_context.node : nil)
        if resource_class
          Chef::DSL::Resources.add_resource_dsl(method_symbol)
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
    end
  end
end
