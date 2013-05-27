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

      # TODO: extract to file
      # TODO: docs
      class TemplateContext < Erubis::Context

        include ChefContext

        attr_reader :_extension_modules

        def initialize(variables)
          super
          @_extension_modules = []
        end

        ###
        # USER FACING API
        ###

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
          eruby = Erubis::Eruby.new(IO.read(template_location))
          eruby.evaluate(partial_context)
        end

        ###
        # INTERNAL PUBLIC API
        ###

        def _define_helpers(helper_methods)
          # TODO (ruby 1.8 hack)
          # This is most elegantly done with Object#define_singleton_method,
          # however ruby 1.8.7 does not support that, so we create a module and
          # include it. This should be revised when 1.8 support is not needed.
          helper_mod = Module.new do
            helper_methods.each do |method_name, method_body|
              define_method(method_name, &method_body)
            end
          end
          @_extension_modules << helper_mod
          extend(helper_mod)
        end

        def _define_helpers_from_blocks(blocks)
          blocks.each do |module_body|
            helper_mod = Module.new(&module_body)
            extend(helper_mod)
            @_extension_modules << helper_mod
          end
        end

        def _extend_modules(module_names)
          module_names.each do |mod|
            extend(mod)
            @_extension_modules << mod
          end
        end

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


      # Render a template with Erubis.  Takes a template as a string, and a
      # context hash.
      def render_template(template, context)
        begin
          eruby = Erubis::Eruby.new(template)
          output = eruby.evaluate(context)
        rescue Object => e
          raise TemplateError.new(e, template, context)
        end
        Tempfile.open("chef-rendered-template") do |tempfile|
          tempfile.print(output)
          tempfile.close
          yield tempfile
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
