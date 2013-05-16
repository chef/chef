#
# Author:: Serdar Sutay (<serdar@opscode.com>)
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


class Chef
  module Deprecation
    module Provider

      # == Deprecation::Provider::CookbookFile
      # This module contains the deprecated functions of
      # Chef::Provider::CookbookFile. These functions are refactored to
      # different components. They are frozen and will be removed in Chef 12.
      #
      module CookbookFile

        def file_cache_location
          @file_cache_location ||= begin
            cookbook = run_context.cookbook_collection[resource_cookbook]
            cookbook.preferred_filename_on_disk_location(node, :files, @new_resource.source, @new_resource.path)
          end
        end

        def resource_cookbook
          @new_resource.cookbook || @new_resource.cookbook_name
        end

        def content_stale?
          ( ! ::File.exist?(@new_resource.path)) || ( ! compare_content)
        end

        def backup_new_resource
          if ::File.exists?(@new_resource.path)
            backup @new_resource.path
          end
        end

      end
    end
  end
end
