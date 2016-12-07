# -*- coding: utf-8 -*-
#
# Authors:: Adam Jacob (<adam@chef.io>)
#           Ionuț Arțăriși (<iartarisi@suse.cz>)
# Copyright:: Copyright 2008-2016, Chef Software, Inc.
#             Copyright 2013-2016, SUSE Linux GmbH
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
require "chef/resource/zypper_package"

class Chef
  class Provider
    class Package
      class Zypper < Chef::Provider::Package
        use_multipackage_api

        provides :package, platform_family: "suse"
        provides :zypper_package, os: "linux"

        def get_versions(package_name)
          candidate_version = current_version = nil
          is_installed = false
          Chef::Log.debug("#{new_resource} checking zypper")
          status = shell_out_with_timeout!("zypper --non-interactive info #{package_name}")
          status.stdout.each_line do |line|
            case line
            when /^Version *: (.+) *$/
              candidate_version = $1.strip
              Chef::Log.debug("#{new_resource} version #{candidate_version}")
            when /^Installed *: Yes *$/
              is_installed = true
              Chef::Log.debug("#{new_resource} is installed")
            when /^Status *: out-of-date \(version (.+) installed\) *$/
              current_version = $1.strip
              Chef::Log.debug("#{new_resource} out of date version #{current_version}")
            end
          end
          current_version = candidate_version if is_installed
          { current_version: current_version, candidate_version: candidate_version }
        end

        def versions
          @versions ||=
            begin
              raw_versions = package_name_array.map do |package_name|
                get_versions(package_name)
              end
              Hash[*package_name_array.zip(raw_versions).flatten]
            end
        end

        def get_candidate_versions
          package_name_array.map do |package_name|
            versions[package_name][:candidate_version]
          end
        end

        def get_current_versions
          package_name_array.map do |package_name|
            versions[package_name][:current_version]
          end
        end

        def package_locked(name, version)
          islocked = false
          locked = shell_out_with_timeout!("zypper locks")
          locked.stdout.each_line do |line|
            line_package = line.split("|").shift(2).last.strip
            if line_package == name
              islocked = true
            end
          end
          return islocked
        end

        def load_current_resource
          @current_resource = Chef::Resource::ZypperPackage.new(new_resource.name)
          current_resource.package_name(new_resource.package_name)

          @candidate_version = get_candidate_versions
          current_resource.version(get_current_versions)

          current_resource
        end

        def zypper_version
          @zypper_version ||=
            `zypper -V 2>&1`.scan(/\d+/).join(".").to_f
        end

        def install_package(name, version)
          zypper_package("install --auto-agree-with-licenses", name, version)
        end

        def upgrade_package(name, version)
          # `zypper install` upgrades packages, we rely on the idempotency checks to get action :install behavior
          install_package(name, version)
        end

        def remove_package(name, version)
          zypper_package("remove", name, version)
        end

        def purge_package(name, version)
          zypper_package("remove --clean-deps", name, version)
        end

        def lock_package(name, version)
          zypper_package("addlock", name, version)
        end

        def unlock_package(name, version)
          zypper_package("removelock", name, version)
        end

        private

        def zip(names, versions)
          names.zip(versions).map do |n, v|
            (v.nil? || v.empty?) ? n : "#{n}=#{v}"
          end
        end

        def zypper_package(command, names, versions)
          zipped_names = zip(names, versions)
          if zypper_version < 1.0
            shell_out_with_timeout!(a_to_s("zypper", gpg_checks, command, "-y", names))
          else
            shell_out_with_timeout!(a_to_s("zypper --non-interactive", gpg_checks, command, zipped_names))
          end
        end

        def gpg_checks
          case Chef::Config[:zypper_check_gpg]
          when true
            ""
          when false
            "--no-gpg-checks"
          when nil
            Chef::Log.warn("Chef::Config[:zypper_check_gpg] was not set. " +
              "All packages will be installed without gpg signature checks. " +
              "This is a security hazard.")
            "--no-gpg-checks"
          end
        end
      end
    end
  end
end
