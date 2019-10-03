# Author:: Dheeraj Dubey(dheeraj.dubey@msystechnologies.com)
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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

require_relative "../package"
require_relative "../../resource/powershell_package"
require_relative "../../mixin/powershell_out"

class Chef
  class Provider
    class Package
      class Powershell < Chef::Provider::Package
        include Chef::Mixin::PowershellOut

        provides :powershell_package

        def load_current_resource
          @current_resource = Chef::Resource::PowershellPackage.new(new_resource.name)
          current_resource.package_name(new_resource.package_name)
          current_resource.version(build_current_versions)
          current_resource
        end

        def define_resource_requirements
          super
          if powershell_out("$PSVersionTable.PSVersion.Major").stdout.strip.to_i < 5
            raise "Minimum installed PowerShell Version required is 5"
          end

          requirements.assert(:install) do |a|
            a.assertion { candidates_exist_for_all_uninstalled? }
            a.failure_message(Chef::Exceptions::Package, "No candidate version available for #{packages_missing_candidates.join(", ")}")
            a.whyrun("Assuming a repository that offers #{packages_missing_candidates.join(", ")} would have been configured")
          end
        end

        def candidate_version
          @candidate_version ||= build_candidate_versions
        end

        # Installs the package specified with the version passed else latest version will be installed
        def install_package(names, versions)
          names.each_with_index do |name, index|
            cmd = powershell_out(build_powershell_package_command("Install-Package '#{name}'", versions[index]), timeout: new_resource.timeout)
            next if cmd.nil?
            raise Chef::Exceptions::PowershellCmdletException, "Failed to install package due to catalog signing error, use skip_publisher_check to force install" if cmd.stderr =~ /SkipPublisherCheck/
          end
        end

        # Removes the package for the version passed and if no version is passed, then all installed versions of the package are removed
        def remove_package(names, versions)
          names.each_with_index do |name, index|
            if versions && !versions[index].nil?
              powershell_out(build_powershell_package_command("Uninstall-Package '#{name}'", versions[index]), timeout: new_resource.timeout)
            else
              version = "0"
              until version.empty?
                version = powershell_out(build_powershell_package_command("Uninstall-Package '#{name}'"), timeout: new_resource.timeout).stdout.strip
                unless version.empty?
                  logger.info("Removed package '#{name}' with version #{version}")
                end
              end
            end
          end
        end

        # Returns array of available available online
        def build_candidate_versions
          versions = []
          new_resource.package_name.each_with_index do |name, index|
            version = if new_resource.version && !new_resource.version[index].nil?
                        powershell_out(build_powershell_package_command("Find-Package '#{name}'", new_resource.version[index]), timeout: new_resource.timeout).stdout.strip
                      else
                        powershell_out(build_powershell_package_command("Find-Package '#{name}'"), timeout: new_resource.timeout).stdout.strip
                      end
            if version.empty?
              version = nil
            end
            versions.push(version)
          end
          versions
        end

        # Returns version array of installed version on the system
        def build_current_versions
          version_list = []
          new_resource.package_name.each_with_index do |name, index|
            version = if new_resource.version && !new_resource.version[index].nil?
                        powershell_out(build_powershell_package_command("Get-Package '#{name}'", new_resource.version[index]), timeout: new_resource.timeout).stdout.strip
                      else
                        powershell_out(build_powershell_package_command("Get-Package '#{name}'"), timeout: new_resource.timeout).stdout.strip
                      end
            if version.empty?
              version = nil
            end
            version_list.push(version)
          end
          version_list
        end

        def build_powershell_package_command(command, version = nil)
          command = [command] unless command.is_a?(Array)
          cmdlet_name = command.first
          command.unshift("(")
          %w{-Force -ForceBootstrap}.each do |arg|
            command.push(arg)
          end
          command.push("-RequiredVersion #{version}") if version
          command.push("-Source #{new_resource.source}") if new_resource.source && cmdlet_name =~ Regexp.union(/Install-Package/, /Find-Package/)
          command.push("-SkipPublisherCheck") if new_resource.skip_publisher_check && cmdlet_name !~ /Find-Package/
          command.push(").Version")
          command.join(" ")
        end

        def check_resource_semantics!
          # This validation method from Chef::Provider::Package does not apply here, so no-op it.
        end
      end
    end
  end
end
