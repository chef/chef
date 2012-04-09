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

      def action_create
        render_with_context(template_location) do |rendered_template|
          rendered(rendered_template)
          if ::File.exist?(@new_resource.path) && content_matches?
            Chef::Log.debug("#{@new_resource} content has not changed.")
            set_all_access_controls
          else
            action_message = content_matches? ? "Would create #{@new_resource}" :
              "Would update #{@current_resource}"
            converge_by(action_message) do
              backup
              set_all_access_controls
              FileUtils.mv(rendered_template.path, @new_resource.path)
              Chef::Log.info("#{@new_resource} updated content")
              @new_resource.updated_by_last_action(true)
            end
          end
        end
      end

      def action_create_if_missing
        if ::File.exists?(@new_resource.path)
          Chef::Log.debug("#{@new_resource} exists - taking no action")
        else
          action_create
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

      def set_all_access_controls
        if access_controls.requires_changes?
          converge_by(access_controls.describe_change_reasons, access_controls.describe_changes) do 
            access_controls.set_all
          end
        end
        @new_resource.updated_by_last_action(access_controls.modified?)
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
