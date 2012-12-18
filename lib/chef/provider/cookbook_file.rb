#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

require 'chef/file_access_control'
require 'chef/provider/file'
require 'tempfile'

class Chef
  class Provider
    class CookbookFile < Chef::Provider::File

      include Chef::Mixin::EnforceOwnershipAndPermissions

      def whyrun_supported?
        true
      end

      def load_current_resource
        @current_resource = Chef::Resource::CookbookFile.new(@new_resource.name)
        super
      end

      def action_create
        if file_cache_location && content_stale? 
          description = []
          description << "create a new cookbook_file #{@new_resource.path}"
          description << diff_current(file_cache_location)
          converge_by(description) do
            Chef::Log.debug("#{@new_resource} has new contents")
            backup_new_resource
            deploy_tempfile do |tempfile|
              Chef::Log.debug("#{@new_resource} staging #{file_cache_location} to #{tempfile.path}")
              tempfile.close
              FileUtils.cp(file_cache_location, tempfile.path)
            end
            Chef::Log.info("#{@new_resource} created file #{@new_resource.path}")
          end
        else
          set_all_access_controls
        end
      end

      def file_cache_location
        @file_cache_location ||= begin
          cookbook = run_context.cookbook_collection[resource_cookbook]
          cookbook.preferred_filename_on_disk_location(node, :files, @new_resource.source, @new_resource.path)
        end
      end

      # Determine the cookbook to get the file from. If new resource sets an
      # explicit cookbook, use it, otherwise fall back to the implicit cookbook
      # i.e., the cookbook the resource was declared in.
      def resource_cookbook
        @new_resource.cookbook || @new_resource.cookbook_name
      end

      def backup_new_resource
        if ::File.exists?(@new_resource.path)
          backup @new_resource.path
        end
      end

      def content_stale?
        ( ! ::File.exist?(@new_resource.path)) || ( ! compare_content)
      end

    end
  end
end
