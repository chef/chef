#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
begin
  # The explicit call to FFI::DynamicLibrary.open was added to address an issue specific to the Habitat packaging of Chef Infra Client on windows.
  # In the Habitat environment, the libarchive library (archive.dll) is installed in a non-standard location that is not included
  # in the default search paths used by the FFI gem to locate dynamic libraries. The default search paths for FFI are:
  #   - <system library path>
  #   - /usr/lib
  #   - /usr/local/lib
  #   - /opt/local/lib
  # These paths do not account for the Habitat package structure, where libraries are installed in isolated directories under
  # the Habitat package path (e.g., C:/hab/pkgs/core/libarchive/<version>/bin on Windows).
  #
  # Without explicitly loading archive.dll using FFI::DynamicLibrary.open, the ffi-libarchive gem fails to locate and load the library,
  # resulting in runtime errors when attempting to use the archive_file resource.
  #
  # This code dynamically determines the path to archive.dll using the Habitat CLI (`hab pkg path core/libarchive`) and explicitly
  # loads the library using FFI::DynamicLibrary.open. This ensures that the library is correctly loaded in the Habitat environment.
  #
  # Note: This logic is gated by a check for Habitat-specific environment variables (HAB_CACHE_SRC_PATH or HAB_PKG_PATH) to ensure
  # that it is only applied in Habitat runs. For other environments (e.g., Omnibus, plain gem installations, or git checkouts),
  # the default behavior of FFI is sufficient, as the libraries are installed in standard locations or embedded paths that are
  # included in the default search paths.
  if RUBY_PLATFORM.match?(/mswin|mingw|windows/) && (ENV["HAB_CACHE_SRC_PATH"] || ENV["HAB_PKG_PATH"])
    require "ffi" unless defined?(FFI)
    require "open3" unless defined?(Open3)
    # Dynamically determine the path to the core/libarchive package
    stdout, stderr, status = Open3.capture3("hab pkg path core/libarchive")
    unless status.success?
      Chef::Log.debug("Failed to determine Habitat libarchive path: #{stderr}")
      return
    end

    habitat_libarchive_path = File.join(stdout.strip.tr("\\", "/"), "bin")
    unless Dir.exist?(habitat_libarchive_path)
      Chef::Log.debug("Habitat libarchive path not found: #{habitat_libarchive_path}")
      return
    end

    archive_dll_path = File.join(habitat_libarchive_path, "archive.dll")
    unless File.exist?(archive_dll_path)
      Chef::Log.debug("archive.dll not found in Habitat path: #{habitat_libarchive_path}")
      return
    end

    FFI::DynamicLibrary.open(archive_dll_path, FFI::DynamicLibrary::RTLD_LAZY) # Explicitly load the DLL
    Chef::Log.debug("Explicitly loaded archive.dll from Habitat path: #{archive_dll_path}")
  end

  # ffi-libarchive must be eager loaded see: https://github.com/chef/chef/issues/12228
  require "ffi-libarchive" unless defined?(Archive::Reader)
rescue LoadError => e
  STDERR.puts "ffi-libarchive could not be loaded. libarchive is probably not installed on system, archive_file will not be available"
end

class Chef
  class Resource
    class ArchiveFile < Chef::Resource

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

      property :strip_components, Integer,
        description: "Remove the specified number of leading path elements. Pathnames with fewer elements will be silently skipped. This behaves similarly to tar's --strip-components command line argument.",
        introduced: "17.5",
        default: 0

      # backwards compatibility for the legacy cookbook names
      alias_method :extract_options, :options
      alias_method :extract_to, :destination

      action :extract, description: "Extract and archive file." do

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
            Archive::Reader.open_filename(new_resource.path, nil, strip_components: new_resource.strip_components) do |archive|
              archive.each_entry do |e|
                FileUtils.chown(new_resource.owner, new_resource.group, "#{new_resource.destination}/#{e.pathname}")
              end
            end
          end
        end
      end

      action_class do
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
          Archive::Reader.open_filename(src, nil, strip_components: new_resource.strip_components) do |archive|
            Chef::Log.trace("Beginning the comparison of file mtime between contents of #{src} and #{dest}")
            archive.each_entry do |e|
              pathname = ::File.expand_path(e.pathname, dest)
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
              Archive::Reader.open_filename(src, nil, strip_components: new_resource.strip_components) do |archive|
                archive.each_entry do |e|
                  archive.extract(e, flags.to_i)
                end
              end
            end
          end
        end
      end
    end
  end
end
