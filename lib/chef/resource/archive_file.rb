#
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../resource"
require "fileutils" unless defined?(FileUtils)

class Chef
  class Resource
    class ArchiveFile < Chef::Resource
      unified_mode true

      provides :archive_file
      provides :libarchive_file # legacy cookbook name

      introduced "15.0"
      description "Use the **archive_file** resource to extract archive files to disk. This resource uses the libarchive library to extract multiple archive formats including tar, gzip, bzip, and zip formats."
      examples <<~DOC
        **Extract a zip file to a specified directory**:

        ```ruby
        archive_file 'Precompiled.zip' do
          path '/tmp/Precompiled.zip'
          destination '/srv/files'
        end
        ```

        **Set specific permissions on the extracted files**:

        ```ruby
        archive_file 'Precompiled.zip' do
          owner 'tsmith'
          group 'staff'
          mode '700'
          path '/tmp/Precompiled.zip'
          destination '/srv/files'
        end
        ```
      DOC

      property :path, String,
        name_property: true,
        coerce: proc { |f| ::File.expand_path(f) },
        description: "An optional property to set the file path to the archive to extract if it differs from the resource block's name."

      property :owner, String,
        description: "The owner of the extracted files."

      property :group, String,
        description: "The group of the extracted files."

      property :mode, [String, Integer],
        description: "The mode of the extracted files. Integer values are deprecated as octal values (ex. 0755) would not be interpreted correctly.",
        default: "755", default_description: "'755'"

      property :destination, String,
        description: "The file path to extract the archive file to.",
        required: true

      property :options, [Array, Symbol],
        description: "An array of symbols representing extraction flags. Example: `:no_overwrite` to prevent overwriting files on disk. By default, this properly sets `:time` which preserves the modification timestamps of files in the archive when writing them to disk.",
        default: lazy { [:time] }

      property :overwrite, [TrueClass, FalseClass, :auto],
        description: "Should the resource overwrite the destination file contents if they already exist? If set to `:auto` the date stamp of files within the archive will be compared to those on disk and disk contents will be overwritten if they differ. This may cause unintended consequences if disk date stamps are changed between runs, which will result in the files being overwritten during each client run. Make sure to properly test any change to this property.",
        default: false

      # backwards compatibility for the legacy cookbook names
      alias_method :extract_options, :options
      alias_method :extract_to, :destination

      action :extract, description: "Extract and archive file." do

        require_libarchive

        unless ::File.exist?(new_resource.path)
          raise Errno::ENOENT, "No archive found at #{new_resource.path}! Cannot continue."
        end

        if !::File.exist?(new_resource.destination)
          Chef::Log.trace("File or directory does not exist at destination path: #{new_resource.destination}")

          converge_by("create directory #{new_resource.destination}") do
            # @todo when we remove the ability for mode to be an int we can remove the .to_s below
            FileUtils.mkdir_p(new_resource.destination, mode: new_resource.mode.to_s.to_i(8))
          end

          extract(new_resource.path, new_resource.destination, Array(new_resource.options))
        else
          Chef::Log.trace("File or directory exists at destination path: #{new_resource.destination}.")

          if new_resource.overwrite == true ||
              (new_resource.overwrite == :auto && archive_differs_from_disk?(new_resource.path, new_resource.destination))
            Chef::Log.debug("Overwriting existing content at #{new_resource.destination} due to resource's overwrite property settings.")

            extract(new_resource.path, new_resource.destination, Array(new_resource.options))
          else
            Chef::Log.debug("Not extracting archive as #{new_resource.destination} exists and resource not set to overwrite.")
          end
        end

        if new_resource.owner || new_resource.group
          converge_by("set owner of files extracted in #{new_resource.destination} to #{new_resource.owner}:#{new_resource.group}") do
            archive = Archive::Reader.open_filename(new_resource.path)
            archive.each_entry do |e|
              FileUtils.chown(new_resource.owner, new_resource.group, "#{new_resource.destination}/#{e.pathname}")
            end
          end
        end
      end

      action_class do
        def require_libarchive
          require "ffi-libarchive"
        end

        def define_resource_requirements
          if new_resource.mode.is_a?(Integer)
            Chef.deprecated(:archive_file_integer_file_mode, "The mode property should be passed to archive_file resources as a String and not an Integer to ensure the value is properly interpreted.")
          end
        end

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

        # try to determine if the resource has updated or not by checking for files that are in the
        # archive, but not on disk or files with a non-matching mtime
        #
        # @param [String] src
        # @param [String] dest
        #
        # @return [Boolean]
        def archive_differs_from_disk?(src, dest)
          modified = false
          Dir.chdir(dest) do
            archive = Archive::Reader.open_filename(src)
            Chef::Log.trace("Beginning the comparison of file mtime between contents of #{src} and #{dest}")
            archive.each_entry do |e|
              pathname = ::File.expand_path(e.pathname)
              if ::File.exist?(pathname)
                Chef::Log.trace("#{pathname} mtime is #{::File.mtime(pathname)} and archive is #{e.mtime}")
                modified = true unless ::File.mtime(pathname) == e.mtime
              else
                Chef::Log.trace("#{pathname} doesn't exist on disk, but exists in the archive")
                modified = true
              end
            end
          end
          modified
        end

        # extract the archive
        #
        # @param [String] src
        # @param [String] dest
        # @param [Array] options
        #
        # @return [void]
        def extract(src, dest, options = [])
          converge_by("extract #{src} to #{dest}") do
            flags = [options].flatten.map { |option| extract_option_map[option] }.compact.reduce(:|)

            Dir.chdir(dest) do
              archive = Archive::Reader.open_filename(src)

              archive.each_entry do |e|
                archive.extract(e, flags.to_i)
              end
              archive.close
            end
          end
        end
      end
    end
  end
end
