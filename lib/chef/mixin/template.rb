#--
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

require 'tempfile'
require 'erubis'

class Chef
  module Mixin
    module Template

      # == ChefContext
      # ChefContext was previously used to mix behavior into Erubis::Context so
      # that it would be available to templates. This behavior has now moved to
      # TemplateContext, but this module is still mixed in to the
      # TemplateContext class so that any user code that modified ChefContext
      # will continue to work correctly.
      module ChefContext
      end

      # == TemplateContext
      # TemplateContext is the base context class for all templates in Chef. It
      # defines user-facing extensions to the base Erubis::Context to provide
      # enhanced features. Individual instances of TemplateContext can be
      # extended to add logic to a specific template.
      #
      class TemplateContext < Erubis::Context

        include ChefContext

        attr_reader :_extension_modules

        #
        # Helpers for adding context of which resource is rendering the template (CHEF-5012)
        #

        # name of the cookbook containing the template resource, e.g.:
        #   test
        #
        # @return [String] cookbook name
        attr_reader :cookbook_name

        # name of the recipe containing the template resource, e.g.:
        #   default
        #
        # @return [String] recipe name
        attr_reader :recipe_name

        # string representation of the line in the recipe containing the template resource, e.g.:
        #   /Users/lamont/solo/cookbooks/test/recipes/default.rb:2:in `from_file'
        #
        # @return [String] recipe line
        attr_reader :recipe_line_string

        # path to the recipe containing the template resource, e.g.:
        #   /Users/lamont/solo/cookbooks/test/recipes/default.rb
        #
        # @return [String] recipe path
        attr_reader :recipe_path

        # line in the recipe containing the template reosurce, e.g.:
        #   2
        #
        # @return [String] recipe line
        attr_reader :recipe_line

        # name of the template source itself, e.g.:
        #   foo.erb
        #
        # @return [String] template name
        attr_reader :template_name

        # path to the template source itself, e.g.:
        #   /Users/lamont/solo/cookbooks/test/templates/default/foo.erb
        #
        # @return [String] template path
        attr_reader :template_path

        def initialize(variables)
          super
          @_extension_modules = []
        end

        ###
        # USER FACING API
        ###

        # Returns the current node object, or raises an error if it's not set.
        # Provides API consistency, allowing users to reference the node object
        # by the bare `node` everywhere.
        def node
          return @node if @node
          raise "Could not find a value for node. If you are explicitly setting variables in a template, " +
                "include a node variable if you plan to use it."
        end


        #
        # Takes the name of the partial, plus a hash of options. Returns a
        # string that contains the result of the evaluation of the partial.
        #
        # All variables from the parent template will be propagated down to
        # the partial, unless you pass the +variables+ option (see below).
        #
        # Valid options are:
        #
        # :local:: If true then the partial name will be interpreted as the
        #          path to a file on the local filesystem; if false (the
        #          default) it will be looked up in the cookbook according to
        #          the normal rules for templates.
        # :source:: If specified then the partial will be looked up with this
        #           name or path (according to the +local+ option) instead of
        #           +partial_name+.
        # :cookbook:: Search for the partial in the provided cookbook instead
        #             of the cookbook that contains the top-level template.
        # :variables:: A Hash of variable_name => value that will be made
        #              available to the partial. If specified, none of the
        #              variables from the master template will be, so if you
        #              need them you will need to propagate them explicitly.
        #
        def render(partial_name, options = {})
          raise "You cannot render partials in this context" unless @template_finder

          partial_variables = options.delete(:variables) || _public_instance_variables
          partial_context = self.class.new(partial_variables)
          partial_context._extend_modules(@_extension_modules)

          template_location = @template_finder.find(partial_name, options)
          _render_template(IO.binread(template_location), partial_context)
        end

        def render_template(template_location)
          _render_template(IO.binread(template_location), self)
        end

        def render_template_from_string(template)
          _render_template(template, self)
        end

        ###
        # INTERNAL PUBLIC API
        ###

        def _render_template(template, context)
          begin
            eruby = Erubis::Eruby.new(template)
            output = eruby.evaluate(context)
          rescue Object => e
            raise TemplateError.new(e, template, context)
          end

          # CHEF-4399
          # Erubis always emits unix line endings during template
          # rendering. Chef used to convert line endings to the
          # original line endings in the template. However this
          # created problems in cases when cookbook developer is
          # coding the cookbook on windows but using it on non-windows
          # platforms.
          # The safest solution is to make sure that native to the
          # platform we are running on is used in order to minimize
          # potential issues for the applications that will consume
          # this template.

          if Chef::Platform.windows?
            output = output.gsub(/\r?\n/,"\r\n")
          end

          output
        end

        def _extend_modules(module_names)
          module_names.each do |mod|
            context_methods = [:node, :render, :render_template, :render_template_from_string]
            context_methods.each do |core_method|
              if mod.method_defined?(core_method) or mod.private_method_defined?(core_method)
                Chef::Log.warn("Core template method `#{core_method}' overridden by extension module #{mod}")
              end
            end
            extend(mod)
            @_extension_modules << mod
          end
        end

        # Collects instance variables set on the current object as a Hash
        # suitable for creating a new TemplateContext. Instance variables that
        # are only valid for this specific instance are omitted from the
        # collection.
        def _public_instance_variables
          all_ivars = instance_variables
          all_ivars.delete(:@_extension_modules)
          all_ivars.inject({}) do |ivar_map, ivar_symbol_name|
            value = instance_variable_get(ivar_symbol_name)
            name_without_at = ivar_symbol_name.to_s[1..-1].to_sym
            ivar_map[name_without_at] = value
            ivar_map
          end
        end
      end

      class TemplateError < RuntimeError
        attr_reader :original_exception, :context
        SOURCE_CONTEXT_WINDOW = 2

        def initialize(original_exception, template, context)
          @original_exception, @template, @context = original_exception, template, context
        end

        def message
          @original_exception.message
        end

        def line_number
          @line_number ||= $1.to_i if original_exception.backtrace.find {|line| line =~ /\(erubis\):(\d+)/ }
        end

        def source_location
          "on line ##{line_number}"
        end

        def source_listing
          @source_listing ||= begin
            lines = @template.split(/\n/)
            if line_number
              line_index = line_number - 1
              beginning_line = line_index <= SOURCE_CONTEXT_WINDOW ? 0 : line_index - SOURCE_CONTEXT_WINDOW
              source_size = SOURCE_CONTEXT_WINDOW * 2 + 1
            else
              beginning_line = 0
              source_size    = lines.length
            end
            contextual_lines = lines[beginning_line, source_size]
            output = []
            contextual_lines.each_with_index do |line, index|
              line_number = (index+beginning_line+1).to_s.rjust(3)
              output << "#{line_number}: #{line}"
            end
            output.join("\n")
          end
        end

        def to_s
          "\n\n#{self.class} (#{message}) #{source_location}:\n\n" +
            "#{source_listing}\n\n  #{original_exception.backtrace.join("\n  ")}\n\n"
        end
      end
    end
  end
end
