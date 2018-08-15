# -*- coding: utf-8 -*-
#
# Authors:: Adam Jacob (<adam@chef.io>)
#           Ionuț Arțăriși (<iartarisi@suse.cz>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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
        provides :zypper_package

        def get_versions(package_name)
          candidate_version = current_version = nil
          is_installed = false
          logger.trace("#{new_resource} checking zypper")
          status = shell_out!("zypper", "--non-interactive", "info", package_name)
          status.stdout.each_line do |line|
            case line
            when /^Version *: (.+) *$/
              candidate_version = $1.strip
              logger.trace("#{new_resource} version #{candidate_version}")
            when /^Installed *: Yes.*$/ # http://rubular.com/r/9StcAMjOn6
              is_installed = true
              logger.trace("#{new_resource} is installed")
            when /^Status *: out-of-date \(version (.+) installed\) *$/
              current_version = $1.strip
              logger.trace("#{new_resource} out of date version #{current_version}")
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

        def packages_all_locked?(names, versions)
          names.all? { |n| locked_packages.include? n }
        end

        def packages_all_unlocked?(names, versions)
          names.all? { |n| !locked_packages.include? n }
        end

        def locked_packages
          @locked_packages ||=
            begin
              locked = shell_out!("zypper", "locks")
              locked.stdout.each_line.map do |line|
                line.split("|").shift(2).last.strip
              end
            end
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
          zypper_package("install", *options, "--auto-agree-with-licenses", allow_downgrade, name, version)
        end

        def upgrade_package(name, version)
          # `zypper install` upgrades packages, we rely on the idempotency checks to get action :install behavior
          install_package(name, version)
        end

        def remove_package(name, version)
          zypper_package("remove", *options, name, version)
        end

        def purge_package(name, version)
          zypper_package("remove", *options, "--clean-deps", name, version)
        end

        def lock_package(name, version)
          zypper_package("addlock", *options, name, version)
        end

        def unlock_package(name, version)
          zypper_package("removelock", *options, name, version)
        end

        private

        def zip(names, versions)
          names.zip(versions).map do |n, v|
            (v.nil? || v.empty?) ? n : "#{n}=#{v}"
          end
        end

        def zypper_package(command, *options, names, versions)
          zipped_names = zip(names, versions)
          if zypper_version < 1.0
            shell_out!("zypper", gpg_checks, command, *options, "-y", names)
          else
            shell_out!("zypper", "--non-interactive", gpg_checks, command, *options, zipped_names)
          end
        end

        def gpg_checks
          "--no-gpg-checks" unless new_resource.gpg_check
        end

        def allow_downgrade
          "--oldpackage" if new_resource.allow_downgrade
        end
      end
    end
  end
end
