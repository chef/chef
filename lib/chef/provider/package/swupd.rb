#
# Author:: Alberto Murillo (<alberto.murillo.silva@intel.com>)
# Copyright:: Copyright 2017, Intel Corporation.
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

# require "chef/provider/package"
# require "chef/resource/swupd_package"

class Chef
  class Provider
    class Package
      class Swupd < Chef::Provider::Package
        provides :package, platform_family: "clearlinux"
        provides :swupd_package, platform_family: "clearlinux"

        def load_current_resource
          @current_resource = Chef::Resource::SwupdPackage.new(new_resource.name)
          current_resource.package_name(new_resource.package_name)
          @current_os_version, @latest_os_version = get_os_versions
          current_resource.version(get_current_versions)
          current_resource
        end

        def install_package(name, version)
          shell_out_compact_timeout!("sudo", "swupd", "bundle-add", name, options)
        end

        def upgrade_package(name, version)
          # swupd doesnt manage "bundle" versions, just one version for the whole OS
          upgrade_os
          install_package(name, version)
        end

        def remove_package(name, version)
          shell_out_compact_timeout!("sudo", "swupd", "bundle-remove", name, options)
        end

        def upgrade_os
          if os_needs_upgrade?
            shell_out_compact_timeout!("sudo", "swupd", "update", options)
          end
        end

        def is_installed?(package_name)
          ::File.exists?("/usr/share/clear/bundles/#{package_name}")
        end

        def os_needs_upgrade?
          @current_os_version != @latest_os_version
        end

        def get_versions(package_name)
          current_version = @current_os_version
          current_version = nil unless is_installed?(package_name)
          candidate_version = @latest_os_version
          { current_version: current_version, candidate_version: candidate_version }
        end

        def get_os_versions
          current_os_version = latest_os_version = nil
          output = shell_out_compact_timeout("sudo", "swupd", "check-update", options)
          output.stderr.each_line do |line|
            case line
            when /^Current OS version: (.*)$/
              current_os_version = $1.strip
            when /^There is a new OS version available: (.*)$/
              latest_os_version = $1.strip
            end
          end
          latest_os_version ||= current_os_version
          [ current_os_version, latest_os_version ]
        end

        def versions
          @versions ||= Hash.new do |hash, key|
            hash[key] = get_versions(key)
          end
        end

        def get_current_versions
          package_name_array.map do |package_name|
            versions[package_name][:current_version]
          end
        end

        def get_candidate_versions
          package_name_array.map do |package_name|
            versions[package_name][:candidate_version]
          end
        end

        def candidate_version
          @candidate_version ||= get_candidate_versions
        end

      end
    end
  end
end
