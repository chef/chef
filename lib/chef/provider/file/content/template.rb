#
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'chef/mixin/template'
require 'chef/provider/file/content'

class Chef
  class Provider
    class File
      class Content
        class Template < Chef::Provider::File::Content

          include Chef::Mixin::Template

          def template_location
            @template_file_cache_location ||= begin
              template_finder.find(@new_resource.source, :local => @new_resource.local, :cookbook => @new_resource.cookbook)
            end
          end

          private

          def file_for_provider
            context = {}
            context.merge!(@new_resource.variables)
            context[:node] = @run_context.node
            context[:template_finder] = template_finder
            file = nil
            render_template(IO.read(template_location), context) { |t| file = t }
            file
          end

          def template_finder
            @template_finder ||= begin
              TemplateFinder.new(run_context, @new_resource.cookbook_name, @run_context.node)
            end
          end
        end
      end
    end
  end
end

