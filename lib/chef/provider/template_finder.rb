#--
# Author:: Andrea Campi (<andrea.campi@zephirworks.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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
  class Provider

    class TemplateFinder

      def initialize(run_context, cookbook_name, node)
        @run_context = run_context
        @cookbook_name = cookbook_name
        @node = node
      end

      def find(template_name, options = {})
        template_name = template_source_name(template_name, options)

        if options[:local]
          return template_name
        end

        cookbook_name = find_cookbook_name(options)
        cookbook = @run_context.cookbook_collection[cookbook_name]

        cookbook.preferred_filename_on_disk_location(@node, :templates, template_name)
      end

    protected
      def template_source_name(name, options)
        if options[:source]
          options[:source]
        else
          name
        end
      end

      def find_cookbook_name(options)
        if options[:cookbook]
          options[:cookbook]
        else
          @cookbook_name
        end
      end
    end
  end
end
