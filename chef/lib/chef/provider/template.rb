#--
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2008, 2010 Opscode, Inc.
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

require 'chef/provider/file'
require 'chef/mixin/template'
require 'chef/mixin/checksum'
require 'chef/file_access_control'

class Chef
  class Provider

    class Template < Chef::Provider::File

      include Chef::Mixin::Checksum
      include Chef::Mixin::Template

      def load_current_resource
        super
        @current_resource.checksum(checksum(@current_resource.path)) if ::File.exist?(@current_resource.path)
      end
      
      def define_resource_requirements
        super

        requirements.assert(:create, :create_if_missing) do |a| 
          a.assertion { ::File::exist?(template_location) } 
          a.failure_message "Template source #{template_location} could not be found."
          a.whyrun "Template source #{template_location} does not exist. Assuming it would have been created."
          a.block_action!
        end
      end

      def action_create
        render_with_context(template_location) do |rendered_template|
          rendered(rendered_template)
          update = ::File.exist?(@new_resource.path)
          if update && content_matches?
            Chef::Log.debug("#{@new_resource} content has not changed.")
          else
            description = [] 
            action_message = update ? "Would update #{@current_resource} from #{short_cksum(@current_resource.checksum)} to #{short_cksum(@new_resource.checksum)}" :
              "Would create #{@new_resource}"
            description << action_message
            description << diff_current(rendered_template.path)
            converge_by(description) do
              backup
              FileUtils.mv(rendered_template.path, @new_resource.path)
              Chef::Log.info("#{@new_resource} updated content")
            end
          end
          set_all_access_controls
        end  
      end


      def template_location
        @template_file_cache_location ||= begin
          if @new_resource.local
            @new_resource.source
          else
            cookbook = run_context.cookbook_collection[resource_cookbook]
            cookbook.preferred_filename_on_disk_location(node, :templates, @new_resource.source)
          end
        end
      end

      def resource_cookbook
        @new_resource.cookbook || @new_resource.cookbook_name
      end

      def rendered(rendered_template)
        @new_resource.checksum(checksum(rendered_template.path))
        Chef::Log.debug("Current content's checksum:  #{@current_resource.checksum}")
        Chef::Log.debug("Rendered content's checksum: #{@new_resource.checksum}")
      end

      def content_matches?
        @current_resource.checksum == @new_resource.checksum
      end

      private

      def render_with_context(template_location, &block)
        context = {}
        context.merge!(@new_resource.variables)
        context[:node] = node
        render_template(IO.read(template_location), context, &block)
      end

    end
  end
end
