#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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
require "chef/resource/apt_package"

class Chef
  class Provider
    class Package
      class Apt < Chef::Provider::Package
        use_multipackage_api

        provides :package, platform_family: "debian"
        provides :apt_package, os: "linux"

        def initialize(new_resource, run_context)
          super
        end

        def load_current_resource
          @current_resource = Chef::Resource::AptPackage.new(new_resource.name)
          current_resource.package_name(new_resource.package_name)
          current_resource.version(get_current_versions)
          current_resource
        end

        def define_resource_requirements
          super

          requirements.assert(:all_actions) do |a|
            a.assertion { !new_resource.source }
            a.failure_message(Chef::Exceptions::Package, "apt package provider cannot handle source attribute. Use dpkg provider instead")
          end
        end

        def package_data
          @package_data ||= Hash.new do |hash, key|
            hash[key] = package_data_for(key)
          end
        end

        def get_current_versions
          package_name_array.map do |package_name|
            package_data[package_name][:current_version]
          end
        end

        def get_candidate_versions
          package_name_array.map do |package_name|
            package_data[package_name][:candidate_version]
          end
        end

        def candidate_version
          @candidate_version ||= get_candidate_versions
        end

        def package_locked(name, version)
          islocked = false
          locked = shell_out_compact_timeout!("apt-mark", "showhold")
          locked.stdout.each_line do |line|
            line_package = line.strip
            if line_package == name
              islocked = true
            end
          end
          islocked
        end

        def install_package(name, version)
          package_name = name.zip(version).map do |n, v|
            package_data[n][:virtual] ? n : "#{n}=#{v}"
          end
          run_noninteractive("apt-get", "-q", "-y", default_release_options, options, "install", package_name)
        end

        def upgrade_package(name, version)
          install_package(name, version)
        end

        def remove_package(name, version)
          package_name = name.map do |n|
            package_data[n][:virtual] ? resolve_virtual_package_name(n) : n
          end
          run_noninteractive("apt-get", "-q", "-y", options, "remove", package_name)
        end

        def purge_package(name, version)
          package_name = name.map do |n|
            package_data[n][:virtual] ? resolve_virtual_package_name(n) : n
          end
          run_noninteractive("apt-get", "-q", "-y", options, "purge", package_name)
        end

        def preseed_package(preseed_file)
          Chef::Log.info("#{new_resource} pre-seeding package installation instructions")
          run_noninteractive("debconf-set-selections", preseed_file)
        end

        def reconfig_package(name, version)
          Chef::Log.info("#{new_resource} reconfiguring")
          run_noninteractive("dpkg-reconfigure", name)
        end

        def lock_package(name, version)
          run_noninteractive("apt-mark", options, "hold", name)
        end

        def unlock_package(name, version)
          run_noninteractive("apt-mark", options, "unhold", name)
        end

        private

        # Runs command via shell_out with magic environment to disable
        # interactive prompts. Command is run with default localization rather
        # than forcing locale to "C", so command output may not be stable.
        def run_noninteractive(*args)
          shell_out_compact_timeout!(*args, env: { "DEBIAN_FRONTEND" => "noninteractive" })
        end

        def default_release_options
          # Use apt::Default-Release option only if provider supports it
          if new_resource.respond_to?(:default_release) && new_resource.default_release
            [ "-o", "APT::Default-Release=#{new_resource.default_release}" ]
          end
        end

        def resolve_package_versions(pkg)
          current_version = nil
          candidate_version = nil
          run_noninteractive("apt-cache", default_release_options, "policy", pkg).stdout.each_line do |line|
            case line
            when /^\s{2}Installed: (.+)$/
              current_version = ( $1 != "(none)" ) ? $1 : nil
              Chef::Log.debug("#{new_resource} installed version for #{pkg} is #{$1}")
            when /^\s{2}Candidate: (.+)$/
              candidate_version = ( $1 != "(none)" ) ? $1 : nil
              Chef::Log.debug("#{new_resource} candidate version for #{pkg} is #{$1}")
            end
          end
          [ current_version, candidate_version ]
        end

        def resolve_virtual_package_name(pkg)
          showpkg = run_noninteractive("apt-cache", "showpkg", pkg).stdout
          partitions = showpkg.rpartition(/Reverse Provides: ?#{$/}/)
          return nil if partitions[0] == "" && partitions[1] == "" # not found in output
          set = partitions[2].lines.each_with_object(Set.new) do |line, acc|
            # there may be multiple reverse provides for a single package
            acc.add(line.split[0])
          end
          if set.size > 1
            raise Chef::Exceptions::Package, "#{new_resource.package_name} is a virtual package provided by multiple packages, you must explicitly select one"
          end
          set.to_a.first
        end

        def package_data_for(pkg)
          virtual           = false
          current_version   = nil
          candidate_version = nil

          current_version, candidate_version = resolve_package_versions(pkg)

          if candidate_version.nil?
            newpkg = resolve_virtual_package_name(pkg)

            if newpkg
              virtual = true
              Chef::Log.info("#{new_resource} is a virtual package, actually acting on package[#{newpkg}]")
              current_version, candidate_version = resolve_package_versions(newpkg)
            end
          end

          {
            current_version:    current_version,
            candidate_version:  candidate_version,
            virtual:            virtual,
          }
        end

      end
    end
  end
end
