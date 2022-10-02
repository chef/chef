# rubocop: disable Performance/InefficientHashSearch
#
# Author:: Lamont Granquist (<lamont@chef.io>)
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
# limitations under the License.
#

require_relative "../../mixin/template"
require_relative "../../file_content_management/content_base"

class Chef
  class Provider
    class Template

      class Content < Chef::FileContentManagement::ContentBase

        include Chef::Mixin::Template

        def template_location
          @template_file_cache_location ||= template_finder.find(new_resource.source, local: new_resource.local, cookbook: new_resource.cookbook)
        end

        private

        def file_for_provider
          # Deal with any DelayedEvaluator values in the template variables.
          visitor = lambda do |obj|
            case obj
            when Hash
              # If this is an Attribute object, we need to change class otherwise
              # we get the immutable behavior. This could probably be fixed by
              # using Hash#transform_values once we only support Ruby 2.4.
              obj_class = obj.is_a?(Chef::Node::ImmutableMash) ? Mash : obj.class
              # Avoid mutating hashes in the resource in case we're changing anything.
              obj.each_with_object(obj_class.new) do |(key, value), memo|
                memo[key] = visitor.call(value)
              end
            when Array
              # Avoid mutating arrays in the resource in case we're changing anything.
              obj.map { |value| visitor.call(value) }
            when DelayedEvaluator
              new_resource.instance_eval(&obj)
            else
              obj
            end
          end
          variables = visitor.call(new_resource.variables)

          context = TemplateContext.new(variables)
          context[:node] = run_context.node
          context[:template_finder] = template_finder

          # helper variables
          context[:cookbook_name] = new_resource.cookbook_name unless context.keys.include?(:cookbook_name)
          context[:recipe_name] = new_resource.recipe_name unless context.keys.include?(:recipe_name)
          context[:recipe_line_string] = new_resource.source_line unless context.keys.include?(:recipe_line_string)
          context[:recipe_path] = new_resource.source_line_file unless context.keys.include?(:recipe_path)
          context[:recipe_line] = new_resource.source_line_number unless context.keys.include?(:recipe_line)
          context[:template_name] = new_resource.source unless context.keys.include?(:template_name)
          context[:template_path] = template_location unless context.keys.include?(:template_path)

          context._extend_modules(new_resource.helper_modules)
          output = context.render_template(template_location)

          tempfile = Chef::FileContentManagement::Tempfile.new(new_resource).tempfile
          tempfile.binmode
          tempfile.write(output)
          tempfile.close
          tempfile
        end

        def template_finder
          @template_finder ||= TemplateFinder.new(run_context, new_resource.cookbook_name, run_context.node)
        end
      end
    end
  end
end
