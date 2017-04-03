#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright 2014-2017, Chef Software Inc.
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

# TODO: Allow new_resource.source to be a Product Code as a GUID for uninstall / network install

require "chef/win32/api/installer" if (RUBY_PLATFORM =~ /mswin|mingw32|windows/) && Chef::Platform.supports_msi?
require "chef/mixin/shell_out"

class Chef
  class Provider
    class Package
      class Windows
        class MSI
          include Chef::ReservedNames::Win32::API::Installer if (RUBY_PLATFORM =~ /mswin|mingw32|windows/) && Chef::Platform.supports_msi?
          include Chef::Mixin::ShellOut

          def initialize(resource, uninstall_entries)
            @new_resource = resource
            @uninstall_entries = uninstall_entries
          end

          attr_reader :new_resource
          attr_reader :uninstall_entries

          # From Chef::Provider::Package
          def expand_options(options)
            options ? " #{options}" : ""
          end

          # Returns a version if the package is installed or nil if it is not.
          def installed_version
            if !new_resource.source.nil? && ::File.exist?(new_resource.source)
              Chef::Log.debug("#{new_resource} getting product code for package at #{new_resource.source}")
              product_code = get_product_property(new_resource.source, "ProductCode")
              Chef::Log.debug("#{new_resource} checking package status and version for #{product_code}")
              get_installed_version(product_code)
            else
              if uninstall_entries.count != 0
                uninstall_entries.map(&:display_version).uniq
              end
            end
          end

          def package_version
            return new_resource.version if new_resource.version
            if !new_resource.source.nil? && ::File.exist?(new_resource.source)
              Chef::Log.debug("#{new_resource} getting product version for package at #{new_resource.source}")
              get_product_property(new_resource.source, "ProductVersion")
            end
          end

          def install_package
            # We could use MsiConfigureProduct here, but we'll start off with msiexec
            Chef::Log.debug("#{new_resource} installing MSI package '#{new_resource.source}'")
            shell_out!("msiexec /qn /i \"#{new_resource.source}\" #{expand_options(new_resource.options)}", timeout: new_resource.timeout, returns: new_resource.returns)
          end

          def remove_package
            # We could use MsiConfigureProduct here, but we'll start off with msiexec
            if !new_resource.source.nil? && ::File.exist?(new_resource.source)
              Chef::Log.debug("#{new_resource} removing MSI package '#{new_resource.source}'")
              shell_out!("msiexec /qn /x \"#{new_resource.source}\" #{expand_options(new_resource.options)}", timeout: new_resource.timeout, returns: new_resource.returns)
            else
              uninstall_version = new_resource.version || installed_version
              uninstall_entries.select { |entry| [uninstall_version].flatten.include?(entry.display_version) }
                               .map(&:uninstall_string).uniq.each do |uninstall_string|
                uninstall_string = "msiexec /x #{uninstall_string.match(/{.*}/)}"
                uninstall_string += expand_options(new_resource.options)
                uninstall_string += " /q" unless uninstall_string.downcase =~ / \/q/
                Chef::Log.debug("#{new_resource} removing MSI package version using '#{uninstall_string}'")
                shell_out!(uninstall_string, timeout: new_resource.timeout, returns: new_resource.returns)
              end
            end
          end
        end
      end
    end
  end
end
