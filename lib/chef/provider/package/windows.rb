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

class Chef
  class Provider
    class Package
      class Windows < Chef::Provider::Package

        # Depending on the installer, we may need to examine installer_type or 
        # source attributes, or search for text strings in the installer file 
        # binary to determine the installer type for the user. Since the file
        # must be on disk to do so, we have to make this choice in the provider.
        require 'chef/provider/package/windows/msi.rb'

        # load_current_resource is run in Chef::Provider#run_action when not in whyrun_mode?
        def load_current_resource
          @new_resource.source(Chef::Util::PathHelper.validate_path(@new_resource.source))

          @current_resource = Chef::Resource::WindowsPackage.new(@new_resource.name)
          @current_resource.version(package_provider.installed_version)
          @new_resource.version(package_provider.package_version)
          @current_resource
        end

        def package_provider
          @package_provider ||= begin
            case installer_type
            when :msi
              Chef::Provider::Package::Windows::MSI.new(@new_resource)
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

        # Chef::Provider::Package action_install + action_remove call install_package + remove_package
        # Pass those calls to the correct sub-provider
        def install_package(name, version)
          package_provider.install_package(name, version)
        end

        def remove_package(name, version)
          package_provider.remove_package(name, version)
        end
      end
    end
  end
end
