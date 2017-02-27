#
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Author:: Matt Wrock <matt@mattwrock.com>
# Copyright:: Copyright 2011-2016, Chef Software, Inc.
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

require "chef/mixin/shell_out"

class Chef
  class Provider
    class Package
      class Windows
        class Exe
          include Chef::Mixin::ShellOut

          def initialize(resource, installer_type, uninstall_entries)
            @new_resource = resource
            @installer_type = installer_type
            @uninstall_entries = uninstall_entries
          end

          attr_reader :new_resource
          attr_reader :installer_type
          attr_reader :uninstall_entries

          # From Chef::Provider::Package
          def expand_options(options)
            options ? " #{options}" : ""
          end

          # Returns a version if the package is installed or nil if it is not.
          def installed_version
            Chef::Log.debug("#{new_resource} checking package version")
            current_installed_version
          end

          def package_version
            new_resource.version
          end

          def install_package
            Chef::Log.debug("#{new_resource} installing #{new_resource.installer_type} package '#{new_resource.source}'")
            shell_out!(
              [
                "start",
                "\"\"",
                "/wait",
                "\"#{new_resource.source}\"",
                unattended_flags,
                expand_options(new_resource.options),
                "& exit %%%%ERRORLEVEL%%%%",
              ].join(" "), timeout: new_resource.timeout, returns: new_resource.returns
            )
          end

          def remove_package
            uninstall_version = new_resource.version || current_installed_version
            uninstall_entries.select { |entry| [uninstall_version].flatten.include?(entry.display_version) }
                             .map(&:uninstall_string).uniq.each do |uninstall_string|
              Chef::Log.debug("Registry provided uninstall string for #{new_resource} is '#{uninstall_string}'")
              shell_out!(uninstall_command(uninstall_string), timeout: new_resource.timeout, returns: new_resource.returns)
            end
          end

          private

          def uninstall_command(uninstall_string)
            uninstall_string = "\"#{uninstall_string}\"" if ::File.exist?(uninstall_string)
            uninstall_string = [
              uninstall_string,
              expand_options(new_resource.options),
              " ",
              unattended_flags,
            ].join
            %{start "" /wait #{uninstall_string} & exit %%%%ERRORLEVEL%%%%}
          end

          def current_installed_version
            @current_installed_version ||=
              if uninstall_entries.count != 0
                uninstall_entries.map(&:display_version).uniq
              end
          end

          # http://unattended.sourceforge.net/installers.php
          def unattended_flags
            case installer_type
            when :installshield
              "/s /sms"
            when :nsis
              "/S /NCRC"
            when :inno
              "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
            when :wise
              "/s"
            end
          end
        end
      end
    end
  end
end
