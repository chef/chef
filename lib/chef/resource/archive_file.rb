#
# Author:: Jamie Winsor <jamie@vialstudios.com>
# Author:: Tim Smith <tsmith@chef.io>
# Author:: John Bellone <jbellone@bloomberg.net>
# Author:: Jennifer Davis <sigje@chef.io>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
#     You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "chef/resource"
require "fileutils"
require "chef/mixin/archive_file_helper"

class Chef
  class Resource
    class ArchiveFile < Chef::Resource
      preview_resource true
      resource_name :archive_file

      description "Extract archives in multiple formats."
      introduced "14.6"

      property :path, String,
               name_property: true,
               description: "Path of the archive to extract"
      property :owner, String,
               description: "Set the owner of the extracted files"
      property :group, String,
               description: "Set the group of the extracted files"
      property :mode, [String, Integer],
               default: 0755,
               description: "Set the mode of the extracted files"
      property :extract_to, String,
               required: true,
               description: "Filepath to extract the contents of the archive to"
      property :extract_options, [Array, Symbol],
               default: lazy { [] },
               description: "An array of symbols representing extraction flags."

      action :extract do
        description "Extracts an archive to a specified folder"
        unless ::File.exist?(new_resource.path)
          raise Errno::ENOENT, "No archive found at #{new_resource.path}!"
        end

        unless Dir.exist?(new_resource.extract_to)
          converge_by("create directory #{new_resource.extract_to}") do
            FileUtils.mkdir_p(new_resource.extract_to, mode: new_resource.mode.to_i)
          end
        end

        converge_by("extract #{new_resource.path} to #{new_resource.extract_to}") do
          Chef::Mixin::ArchiveFileHelper.extract(new_resource.path, new_resource.extract_to, Array(new_resource.extract_options))
        end

        if new_resource.owner || new_resource.group
          converge_by("set owner of #{new_resource.extract_to} to #{new_resource.owner}:#{new_resource.group}") do
            FileUtils.chown_R(new_resource.owner, new_resource.group, new_resource.extract_to)
          end
        end
      end
    end
  end
end
