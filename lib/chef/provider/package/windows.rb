#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

require 'chef/resource/windows_package'
require 'chef/provider/package'
require 'chef/util/path_helper'
require 'uri'

class Chef
  class Provider
    class Package
      class Windows < Chef::Provider::Package

        provides :package, os: "windows"
        provides :windows_package, os: "windows"

        # Depending on the installer, we may need to examine installer_type or
        # source attributes, or search for text strings in the installer file
        # binary to determine the installer type for the user. Since the file
        # must be on disk to do so, we have to make this choice in the provider.
        require 'chef/provider/package/windows/msi.rb'

        # load_current_resource is run in Chef::Provider#run_action when not in whyrun_mode?
        def load_current_resource
          @current_resource = Chef::Resource::WindowsPackage.new(@new_resource.name)
          if should_download?
            Chef::Log.debug("We do not know the version of #{new_resource.source} because the file is not downloaded")
            current_resource.version(:unknown.to_s)
          else
            current_resource.version(package_provider.installed_version)
            new_resource.version(package_provider.package_version)
          end

          current_resource
        end

        def package_provider
          @package_provider ||= begin
            case installer_type
            when :msi
              Chef::Provider::Package::Windows::MSI.new(resource_for_provider)
            else
              raise "Unable to find a Chef::Provider::Package::Windows provider for installer_type '#{installer_type}'"
            end
          end
        end

        def installer_type
          @installer_type ||= begin
            if @new_resource.installer_type
              @new_resource.installer_type
            else
              file_extension = ::File.basename(@new_resource.source).split(".").last.downcase

              if file_extension == "msi"
                :msi
              else
                raise ArgumentError, "Installer type for Windows Package '#{@new_resource.name}' not specified and cannot be determined from file extension '#{file_extension}'"
              end
            end
          end
        end

        def action_install
          if should_download?
            download_source_file
            load_current_resource
          end
          super
        end

        # Chef::Provider::Package action_install + action_remove call install_package + remove_package
        # Pass those calls to the correct sub-provider
        def install_package(name, version)
          package_provider.install_package(name, version)
        end

        def remove_package(name, version)
          package_provider.remove_package(name, version)
        end

        # @return [Array] new_version(s) as an array
        def new_version_array
          # Because the one in the parent caches things
          [new_resource.version]
        end

        private

        def should_download?
          is_url?(new_resource.source) && !::File.exists?(source_location)
        end

        def resource_for_provider
          @resource_for_provider = Chef::Resource::WindowsPackage.new(new_resource.name).tap do |r|
            r.source(Chef::Util::PathHelper.validate_path(source_location))
            r.timeout(new_resource.timeout)
            r.returns(new_resource.returns)
            r.options(new_resource.options)
          end
        end

        def download_source_file
          source_resource.run_action(:create)
          Chef::Log.debug("#{@new_resource} fetched source file to #{source_resource.path}")
        end

        def source_resource
          @remote_file ||= Chef::Resource::RemoteFile.new(source_location, run_context).tap do |r|
            r.source(new_resource.source)
            r.backup(false)
          end
        end

        def source_location
          @source_location ||= begin
            if is_url?(new_resource.source)
              uri = ::URI.parse(new_resource.source)
              filename = ::File.basename(::URI.unescape(uri.path))
              file_cache_dir = Chef::FileCache.create_cache_path("package/")
              Chef::Util::PathHelper.cleanpath("#{file_cache_dir}/#{filename}")
            else
              Chef::Util::PathHelper.cleanpath(new_resource.source)
            end
          end
        end

        def is_url?(source)
          begin
            scheme = URI.split(source).first
            return false unless scheme
            %w(http https ftp file).include?(scheme.downcase)
          rescue URI::InvalidURIError
            return false
          end
        end

      end
    end
  end
end
