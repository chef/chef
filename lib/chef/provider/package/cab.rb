#
# Author:: Vasundhara Jagdale (<vasundhara.jagdale@msystechnologies.com>)
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
require "chef/resource/cab_package"
require "chef/mixin/shell_out"

class Chef
  class Provider
    class Package
      class Cab < Chef::Provider::Package
        include Chef::Mixin::ShellOut

        provides :cab_package, os: "windows"

        def load_current_resource
          @current_resource = Chef::Resource::CabPackage.new(new_resource.name)
          current_resource.source(new_resource.source)
          new_resource.version(package_version)
          current_resource.version(installed_version)
          current_resource
        end

        def install_package(name, version)
          dism_command("/Add-Package /PackagePath:\"#{@new_resource.source}\"")
        end

        def remove_package(name, version)
          dism_command("/Remove-Package /PackagePath:\"#{@new_resource.source}\"")
        end

        def dism_command(command)
          shellout = Mixlib::ShellOut.new("dism.exe /Online #{command} /NoRestart", { :timeout => @new_resource.timeout })
          with_os_architecture(nil) do
            shellout.run_command
          end
        end

        def installed_version
          stdout = dism_command("/Get-PackageInfo /PackagePath:\"#{@new_resource.source}\"").stdout
          package_info = parse_dism_get_package_info(stdout)
          # e.g. Package_for_KB2975719~31bf3856ad364e35~amd64~~6.3.1.8
          package = split_package_identity(package_info["package_information"]["package_identity"])
          # Search for just the package name to catch a different version being installed
          Chef::Log.debug("#{@new_resource} searching for installed package #{package['name']}")
          found_packages = installed_packages.select { |p| p["package_identity"] =~ /^#{package['name']}~/ }
          if found_packages.length == 0
            nil
          elsif found_packages.length == 1
            stdout = dism_command("/Get-PackageInfo /PackageName:\"#{found_packages.first["package_identity"]}\"").stdout
            find_version(stdout)
          else
            # Presuming this won't happen, otherwise we need to handle it
            raise Chef::Exceptions::Package, "Found multiple packages installed matching name #{package['name']}, found: #{found_packages.length} matches"
          end
        end

        def package_version
          Chef::Log.debug("#{@new_resource} getting product version for package at #{@new_resource.source}")
          stdout = dism_command("/Get-PackageInfo /PackagePath:\"#{@new_resource.source}\"").stdout
          find_version(stdout)
        end

        def find_version(stdout)
          package_info = parse_dism_get_package_info(stdout)
          package = split_package_identity(package_info["package_information"]["package_identity"])
          package["version"]
        end

        # returns a hash of package state information given the output of dism /get-packages
        # expected keys: package_identity
        def parse_dism_get_packages(text)
          packages = Array.new
          text.each_line do |line|
            key, value = line.split(":") if line.start_with?("Package Identity")
            unless key.nil? || value.nil?
              package = Hash.new
              package[key.downcase.strip.tr(" ", "_")] = value.strip.chomp
              packages << package
            end
          end
          packages
        end

        # returns a hash of package information given the output of dism /get-packageinfo
        def parse_dism_get_package_info(text)
          package_data = Hash.new
          errors = Array.new
          in_section = false
          section_headers = [ "Package information", "Custom Properties", "Features" ]
          text.each_line do |line|
            if line =~ /Error: (.*)/
              errors << $1.strip
            elsif section_headers.any? { |header| line =~ /^(#{header})/ }
              in_section = $1.downcase.tr(" ", "_")
            elsif line =~ /(.*) ?: (.*)/
              v = $2 # has to be first or the gsub below replaces this variable
              k = $1.downcase.strip.tr(" ", "_")
              if in_section
                package_data[in_section] = Hash.new unless package_data[in_section]
                package_data[in_section][k] = v
              else
                package_data[k] = v
              end
            end
          end
          unless errors.empty?
            if errors.include?("0x80070003") || errors.include?("0x80070002")
              raise Chef::Exceptions::Package, "DISM: The system cannot find the path or file specified."
            elsif errors.include?("740")
              raise Chef::Exceptions::Package, "DISM: Error 740: Elevated permissions are required to run DISM."
            else
              raise Chef::Exceptions::Package, "Unknown errors encountered parsing DISM output: #{errors}"
            end
          end
          package_data
        end

        def split_package_identity(identity)
          data = Hash.new
          data["name"], data["publisher"], data["arch"], data["resource_id"], data["version"] = identity.split("~")
          data
        end

        def installed_packages
          @packages ||= begin
            output = dism_command("/Get-Packages").stdout
            packages = parse_dism_get_packages(output)
            packages
          end
        end
      end
    end
  end
end
