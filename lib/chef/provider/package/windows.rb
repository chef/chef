#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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

require "chef/mixin/uris"
require "chef/resource/windows_package"
require "chef/provider/package"
require "chef/util/path_helper"
require "chef/mixin/checksum"

class Chef
  class Provider
    class Package
      class Windows < Chef::Provider::Package
        include Chef::Mixin::Uris
        include Chef::Mixin::Checksum

        provides :package, os: "windows"
        provides :windows_package, os: "windows"

        require "chef/provider/package/windows/registry_uninstall_entry.rb"

        def define_resource_requirements
          requirements.assert(:install) do |a|
            a.assertion { new_resource.source || msi? }
            a.failure_message Chef::Exceptions::NoWindowsPackageSource, "Source for package #{new_resource.name} must be specified in the resource's source property for package to be installed because the package_name property is used to test for the package installation state for this package type."
          end
        end

        # load_current_resource is run in Chef::Provider#run_action when not in whyrun_mode?
        def load_current_resource
          @current_resource = Chef::Resource::WindowsPackage.new(new_resource.name)
          if downloadable_file_missing?
            Chef::Log.debug("We do not know the version of #{new_resource.source} because the file is not downloaded")
            current_resource.version(:unknown.to_s)
          else
            current_resource.version(package_provider.installed_version)
            new_resource.version(package_provider.package_version) if package_provider.package_version
          end

          current_resource
        end

        def package_provider
          @package_provider ||= begin
            case installer_type
            when :msi
              Chef::Log.debug("#{new_resource} is MSI")
              require "chef/provider/package/windows/msi"
              Chef::Provider::Package::Windows::MSI.new(resource_for_provider, uninstall_registry_entries)
            else
              Chef::Log.debug("#{new_resource} is EXE with type '#{installer_type}'")
              require "chef/provider/package/windows/exe"
              Chef::Provider::Package::Windows::Exe.new(resource_for_provider, installer_type, uninstall_registry_entries)
            end
          end
        end

        def installer_type
          # Depending on the installer, we may need to examine installer_type or
          # source attributes, or search for text strings in the installer file
          # binary to determine the installer type for the user. Since the file
          # must be on disk to do so, we have to make this choice in the provider.
          @installer_type ||= begin
            return :msi if msi?

            if new_resource.installer_type
              new_resource.installer_type
            elsif source_location.nil?
              inferred_registry_type
            else
              basename = ::File.basename(source_location)
              file_extension = basename.split(".").last.downcase

              # search the binary file for installer type
              ::Kernel.open(::File.expand_path(source_location), "rb") do |io|
                filesize = io.size
                bufsize = 4096 # read 4K buffers
                overlap = 16 # bytes to overlap between buffer reads

                until io.eof
                  contents = io.read(bufsize)

                  case contents
                  when /inno/i # Inno Setup
                    return :inno
                  when /wise/i # Wise InstallMaster
                    return :wise
                  when /nullsoft/i # Nullsoft Scriptable Install System
                    return :nsis
                  end

                  if io.tell < filesize
                    io.seek(io.tell - overlap)
                  end
                end

                # if file is named 'setup.exe' assume installshield
                if basename == "setup.exe"
                  :installshield
                else
                  raise Chef::Exceptions::CannotDetermineWindowsInstallerType, "Installer type for Windows Package '#{new_resource.name}' not specified and cannot be determined from file extension '#{file_extension}'"
                end
              end
            end
          end
        end

        def action_install
          if uri_scheme?(new_resource.source)
            download_source_file
            load_current_resource
          else
            validate_content!
          end

          super
        end

        # Chef::Provider::Package action_install + action_remove call install_package + remove_package
        # Pass those calls to the correct sub-provider
        def install_package(name, version)
          package_provider.install_package
        end

        def remove_package(name, version)
          package_provider.remove_package
        end

        # @return [Array] new_version(s) as an array
        def new_version_array
          # Because the one in the parent caches things
          [new_resource.version]
        end

        # @return [String] candidate_version
        def candidate_version
          @candidate_version ||= (new_resource.version || "latest")
        end

        # @return [Array] current_version(s) as an array
        # this package provider does not support package arrays
        # However, There may be multiple versions for a single
        # package so the first element may be a nested array
        def current_version_array
          [ current_resource.version ]
        end

        # @param current_version<String> one or more versions currently installed
        # @param new_version<String> version of the new resource
        #
        # @return [Boolean] true if new_version is equal to or included in current_version
        def target_version_already_installed?(current_version, new_version)
          Chef::Log.debug("Checking if #{new_resource} version '#{new_version}' is already installed. #{current_version} is currently installed")
          if current_version.is_a?(Array)
            current_version.include?(new_version)
          else
            new_version == current_version
          end
        end

        def have_any_matching_version?
          target_version_already_installed?(current_resource.version, new_resource.version)
        end

        private

        def uninstall_registry_entries
          @uninstall_registry_entries ||= Chef::Provider::Package::Windows::RegistryUninstallEntry.find_entries(new_resource.package_name)
        end

        def inferred_registry_type
          @inferred_registry_type ||= begin
            uninstall_registry_entries.each do |entry|
              return :inno if entry.key.end_with?("_is1")
              return :msi if entry.uninstall_string.downcase.start_with?("msiexec.exe ")
              return :nsis if entry.uninstall_string.downcase.end_with?("uninst.exe\"")
            end
            nil
          end
        end

        def downloadable_file_missing?
          !new_resource.source.nil? && uri_scheme?(new_resource.source) && !::File.exist?(source_location)
        end

        def resource_for_provider
          @resource_for_provider = Chef::Resource::WindowsPackage.new(new_resource.name).tap do |r|
            r.source(Chef::Util::PathHelper.validate_path(source_location)) unless source_location.nil?
            r.cookbook_name = new_resource.cookbook_name
            r.version(new_resource.version)
            r.timeout(new_resource.timeout)
            r.returns(new_resource.returns)
            r.options(new_resource.options)
          end
        end

        def download_source_file
          source_resource.run_action(:create)
          Chef::Log.debug("#{new_resource} fetched source file to #{source_resource.path}")
        end

        def source_resource
          @source_resource ||= Chef::Resource::RemoteFile.new(default_download_cache_path, run_context).tap do |r|
            r.source(new_resource.source)
            r.cookbook_name = new_resource.cookbook_name
            r.checksum(new_resource.checksum)
            r.backup(false)

            if new_resource.remote_file_attributes
              new_resource.remote_file_attributes.each do |(k, v)|
                r.send(k.to_sym, v)
              end
            end
          end
        end

        def default_download_cache_path
          uri = ::URI.parse(new_resource.source)
          filename = ::File.basename(::URI.unescape(uri.path))
          file_cache_dir = Chef::FileCache.create_cache_path("package/")
          Chef::Util::PathHelper.cleanpath("#{file_cache_dir}/#{filename}")
        end

        def source_location
          if new_resource.source.nil?
            nil
          elsif uri_scheme?(new_resource.source)
            source_resource.path
          else
            new_source = Chef::Util::PathHelper.cleanpath(new_resource.source)
            ::File.exist?(new_source) ? new_source : nil
          end
        end

        def validate_content!
          if new_resource.checksum
            source_checksum = checksum(source_location)
            if new_resource.checksum.downcase != source_checksum
              raise Chef::Exceptions::ChecksumMismatch.new(short_cksum(new_resource.checksum), short_cksum(source_checksum))
            end
          end
        end

        def msi?
          return true if new_resource.installer_type == :msi

          if source_location.nil?
            inferred_registry_type == :msi
          else
            ::File.extname(source_location).casecmp(".msi") == 0
          end
        end
      end
    end
  end
end
