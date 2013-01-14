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
require 'chef/provider/local_file'
require 'tempfile'

class Chef
  class Provider
    class CookbookFile < Chef::Provider::LocalFile

      include Chef::Mixin::EnforceOwnershipAndPermissions

      def whyrun_supported?
        true
      end

      def load_current_resource
        @current_resource = Chef::Resource::CookbookFile.new(@new_resource.name)
        super
      end

      def description
        desc_array = []
        desc_array << "create a new cookbook_file #{@new_resource.path}"
        desc_array << diff_current(file_cache_location)
        desc_array
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

    end
  end
end
