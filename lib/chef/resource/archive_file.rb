#
# Copyright:: Copyright 2017-2018, Chef Software Inc.
# Author:: Jamie Winsor (<jamie@vialstudios.com>)
# Author:: Tim Smith (<tsmith@chef.io>)
#
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

require "chef/resource"

class Chef
  class Resource
    class ArchiveFile < Chef::Resource

      resource_name :archive_file
      provides :archive_file
      provides :libarchive_file # legacy cookbook name

      introduced "15.0"

      property :path, String,
               name_property: true,
               coerce: proc { |f| ::File.expand_path(f) },
               description: ""

      property :owner, String,
               description: ""

      property :group, String,
               description: ""

      property :mode, [String, Integer],
               description: "",
               default: "755"

      property :destination, String,
               description: "",
               required: true

      property :options, [Array, Symbol],
               description: "",
               default: lazy { [] }

      # backwards compatibility for the legacy cookbook names
      alias_method :extract_options, :options
      alias_method :extract_to, :destination

      action :extract do
        require "fileutils"

        unless ::File.exist?(new_resource.path)
          raise Errno::ENOENT, "No archive found at #{new_resource.path}!"
        end

        unless Dir.exist?(new_resource.destination)
          converge_by("create directory #{new_resource.destination}") do
            FileUtils.mkdir_p(new_resource.destination, mode: new_resource.mode.to_i)
          end
        end

        converge_by("extract #{new_resource.path} to #{new_resource.destination}") do
          extract(new_resource.path, new_resource.destination,
            Array(new_resource.options))
        end

        if new_resource.owner || new_resource.group
          converge_by("set owner of #{new_resource.destination} to #{new_resource.owner}:#{new_resource.group}") do
            FileUtils.chown_R(new_resource.owner, new_resource.group, new_resource.destination)
          end
        end
      end

      action_class do
        # This can't be a constant since we might not have required 'ffi-libarchive' yet.
        def extract_option_map
          {
            owner: Archive::EXTRACT_OWNER,
            permissions: Archive::EXTRACT_PERM,
            time: Archive::EXTRACT_TIME,
            no_overwrite: Archive::EXTRACT_NO_OVERWRITE,
            acl: Archive::EXTRACT_ACL,
            fflags: Archive::EXTRACT_FFLAGS,
            extended_information: Archive::EXTRACT_XATTR,
            xattr: Archive::EXTRACT_XATTR,
            no_overwrite_newer: Archive::EXTRACT_NO_OVERWRITE_NEWER,
          }
        end

        # @param [String] src
        # @param [String] dest
        # @param [Array] options
        #
        # @return [Boolean] was the file extraction performed or not
        def extract(src, dest, options = [])
          require "ffi-libarchive"

          flags = [options].flatten.map { |option| extract_option_map[option] }.compact.reduce(:|)
          modified = false

          Dir.chdir(dest) do
            archive = Archive::Reader.open_filename(src)

            archive.each_entry do |e|
              pathname = ::File.expand_path(e.pathname)
              if ::File.exist?(pathname)
                modified = true unless ::File.mtime(pathname) == e.mtime
              else
                modified = true
              end

              archive.extract(e, flags.to_i)
            end
            archive.close
          end
          modified
        end
      end
    end
  end
end
