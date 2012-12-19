#
# Author:: Jesse Campbell (<hikeit@gmail.com>)
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

require 'chef/resource/local_file'
require 'chef/provider/file'
require 'chef/file_access_control'
require 'tempfile'

class Chef

  class Provider
    class LocalFile < Chef::Provider::File

      include Chef::Mixin::EnforceOwnershipAndPermissions

      def whyrun_supported?
        true
      end

      def load_current_resource
        @current_resource = Chef::Resource::LocalFile.new(@new_resource.name)
        super
      end

      # Compare the content of a file.  Returns true if they are the same, false if they are not.
      def compare_content
        @current_resource.checksum == checksum(@new_resource.source)
      end

      def description
        descarray = []
        desc = "update content in file #{@new_resource.path}" if ::File.exists?(@new_resource.path)
        desc = "create file #{@new_resource.path}" unless ::File.exists?(@new_resource.path)

        desc << " with file #{@new_resource.source}"
        descarray << desc
        descarray << diff_current(file_cache_location)
        descarray
      end

      def action_create
        unless ::File.exists?(@new_resource.path) && compare_content && !@move
          converge_by(description) do
            Chef::Log.debug("#{@new_resource} has new contents")
            backup
            deploy_tempfile do |tempfile|
              Chef::Log.debug("#{@new_resource} staging to #{tempfile.path}")
              tempfile.close
              FileUtils.cp(file_cache_location, tempfile.path) unless @move
              FileUtils.mv(file_cache_location, tempfile.path) if @move
            end
            Chef::Log.info("#{@new_resource} created file #{@new_resource.path}")
          end
        end
        set_all_access_controls
      end

      def action_move
        if ::File.exists?(@new_resource.source)
          #move only makes sense for local files
          @move = true
          action_create
        end
      end

      def file_cache_location
        @file_cache_location ||= begin
          @new_resource.source
        end
      end

    end
  end
end
