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

# TODO: Allow @new_resource.source to be a Product Code as a GUID for uninstall / network install

require 'chef/win32/api/installer' if (RUBY_PLATFORM =~ /mswin|mingw32|windows/) && Chef::Platform.supports_msi?
require 'chef/mixin/shell_out'

class Chef
  class Provider
    class Package
      class Windows
        class MSI
          include Chef::ReservedNames::Win32::API::Installer if (RUBY_PLATFORM =~ /mswin|mingw32|windows/) && Chef::Platform.supports_msi?
          include Chef::Mixin::ShellOut

          def initialize(resource)
            @new_resource = resource
          end

          # From Chef::Provider::Package
          def expand_options(options)
            options ? " #{options}" : ""
          end

          # Returns a version if the package is installed or nil if it is not.
          def installed_version
            Chef::Log.debug("#{@new_resource} getting product code for package at #{@new_resource.source}")
            product_code = get_product_property(@new_resource.source, "ProductCode")
            Chef::Log.debug("#{@new_resource} checking package status and version for #{product_code}")
            get_installed_version(product_code)
          end

          def package_version
            Chef::Log.debug("#{@new_resource} getting product version for package at #{@new_resource.source}")
            get_product_property(@new_resource.source, "ProductVersion")
          end

          def install_package(name, version)
            # We could use MsiConfigureProduct here, but we'll start off with msiexec
            Chef::Log.debug("#{@new_resource} installing MSI package '#{@new_resource.source}'")
            shell_out!("msiexec /qn /i \"#{@new_resource.source}\" #{expand_options(@new_resource.options)}", {:timeout => @new_resource.timeout, :returns => @new_resource.returns})
          end

          def remove_package(name, version)
            # We could use MsiConfigureProduct here, but we'll start off with msiexec
            Chef::Log.debug("#{@new_resource} removing MSI package '#{@new_resource.source}'")
            shell_out!("msiexec /qn /x \"#{@new_resource.source}\" #{expand_options(@new_resource.options)}", {:timeout => @new_resource.timeout, :returns => @new_resource.returns})
          end
        end
      end
    end
  end
end
