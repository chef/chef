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

require "chef/provider/package"
require "chef/resource/powershell_package"
require "chef/mixin/powershell_out"

class Chef
  class Provider
    class Package
      class Powershell < Chef::Provider::Package
        include Chef::Mixin::PowershellOut

        provides :powershell_package, os: "windows"

        def load_current_resource
          @current_resource = Chef::Resource::PowershellPackage.new(new_resource.name)
          current_resource.package_name(new_resource.package_name)
          current_resource.version(build_current_versions)
          current_resource
        end

        def define_resource_requirements
          super
          if powershell_out("$PSVersionTable.PSVersion.Major").stdout.strip().to_i < 5
            raise "Minimum installed Powershell Version required is 5"
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

        def install_package(names, versions)
          # Installs the package specified with the version passed else latest version will be installed
          names.each_with_index do |name, index|
            powershell_out("Install-Package #{name} -Force -ForceBootstrap -RequiredVersion #{versions[index]}", { :timeout => @new_resource.timeout })
          end
        end

        def remove_package(names, versions)
          # Removes the package, if no version is passed, all installed version  will be removed
          names.each_with_index do |name, index|
            if versions && versions[index] != nil
              powershell_out( "Uninstall-Package #{name} -Force -RequiredVersion #{versions[index]}", { :timeout => @new_resource.timeout })
            else
              stdout = "0"
              until stdout.empty?
                stdout = powershell_out( "Uninstall-Package #{name} -Force", { :timeout => @new_resource.timeout }).stdout
                if !stdout.empty?
                  Chef::Log.info("Removed package #{name} with version #{parse_version(stdout.downcase, name.downcase)}")
                end
              end
            end
          end
        end

        # return array of latest available packages online
        def build_candidate_versions
          versions = []
          new_resource.package_name.each_with_index do |name, index|
            if new_resource.version && new_resource.version[index] != nil
              stdout = powershell_out("Find-Package #{name} -RequiredVersion #{new_resource.version[index]}", { :timeout => @new_resource.timeout }).stdout
            else
              stdout = powershell_out("Find-Package #{name}", { :timeout => @new_resource.timeout }).stdout
            end
            versions.push(parse_version(stdout.downcase, name.downcase))
          end
          versions
        end

        #return array of currently installed version
        def build_current_versions
          version_list = []
          new_resource.package_name.each_with_index do |name, index|
            if new_resource.version && new_resource.version[index] != nil
              stdout = powershell_out("Get-Package -Name #{name} -RequiredVersion #{new_resource.version[index]}", { :timeout => @new_resource.timeout }).stdout
            else
              stdout = powershell_out("Get-Package -Name #{name}", { :timeout => @new_resource.timeout }).stdout
            end
            version_list.push(parse_version(stdout.downcase, name.downcase))
          end
          version_list
        end

        def parse_version(output, name)
          if output.empty?
            nil
            #raise Chef::Exceptions::Package, "Invalid Package name specified or proper version not passed"
          else
            #sample value of output variable
            #Name                           Version          Source           Summary
            #----                           -------          ------           -------
            #xCertificate                   2.1.0.0          PSGallery        This module includes DSC resources that simplify administration of certificates on a Windows Server
            output_list = output.split(" ")
            output_list[output_list.index(name) + 1]
          end
        end

      end
    end
  end
end
