# -*- coding: utf-8 -*-
#
# Authors:: Adam Jacob (<adam@opscode.com>)
#           Ionuț Arțăriși (<iartarisi@suse.cz>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
#             Copyright (c) 2013 SUSE Linux GmbH
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

require 'chef/provider/package'
require 'chef/mixin/command'
require 'chef/resource/package'
require 'singleton'

class Chef
  class Provider
    class Package
      class Zypper < Chef::Provider::Package

        provides :package, platform_family: "suse"
        provides :zypper_package, os: "linux"

        def load_current_resource
          @current_resource = Chef::Resource::ZypperPackage.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)
          check_all_packages_state(@new_resource.package_name)
          @current_resource
        end

        def check_all_packages_state(package)
          installed_version = {}
          candidate_version = {}
          installed = {}

          [package].flatten.each do |pkg|
            ret = check_package_state(pkg)
            installed[pkg]          = ret[:installed]
            installed_version[pkg]  = ret[:installed_version]
            candidate_version[pkg]  = ret[:candidate_version]
          end

          if package.is_a?(Array)
            @candidate_version = []
            final_installed_version = []
            [package].flatten.each do |pkg|
              @candidate_version << candidate_version[pkg]
              final_installed_version << installed_version[pkg]
            end
            @current_resource.version(final_installed_version)
          else
            @candidate_version = candidate_version[package]
            @current_resource.version(installed_version[package])
          end
        end


        def check_package_state(pkg)
          is_installed=false
          is_out_of_date=false
          version=''
          oud_version=''

          installed_version=nil
          candidate_version=nil


          Chef::Log.debug("#{new_resource} checking zypper")
          status = shell_out_with_timeout("zypper --non-interactive info #{pkg}")
          status.stdout.each_line do |line|
            case line
              when /^Version: (.+)$/
                version = $1
                Chef::Log.debug("#{new_resource} version #{$1}")
              when /^Installed: Yes$/
                is_installed=true
                Chef::Log.debug("#{new_resource} is installed")

              when /^Installed: No$/
                is_installed=false
                Chef::Log.debug("#{new_resource} is not installed")
              when /^Status: out-of-date \(version (.+) installed\)$/
                is_out_of_date=true
                oud_version=$1
                Chef::Log.debug("#{new_resource} out of date version #{$1}")
            end
          end

          if !is_installed
            candidate_version=version
            installed_version=nil
          else
            if is_out_of_date
              installed_version=oud_version
              candidate_version=version
            else
              installed_version=version
              candidate_version=version
            end
          end

          unless status.exitstatus == 0
            raise Chef::Exceptions::Package, "zypper failed - #{status.inspect}!"
          end

          return {
            installed_version:   installed_version,
            installed:           is_installed,
            candidate_version:   candidate_version,
          }
        end

        def zypper_version()
          `zypper -V 2>&1`.scan(/\d+/).join(".").to_f
        end

        def install_package(name, version)
          zypper_package("install --auto-agree-with-licenses", name, version)
        end

        def upgrade_package(name, version)
          install_package(name, version)
        end

        def remove_package(name, version)
          zypper_package("remove", name, version)
        end

        def purge_package(name, version)
          zypper_package("remove --clean-deps", name, version)
        end

        private
        def zypper_package(command, name, version)
          name_array = [ name ].flatten
          version_array = [ version ].flatten
          package_name = name_array.zip(version_array).map do |n, v|
            (v.nil? || v.empty?) ? n : "#{n}=#{v}"
          end.join(' ')

          if zypper_version < 1.0
            shell_out_with_timeout!("zypper#{gpg_checks} #{command} -y #{name_array.join(' ')}")
          else
            shell_out_with_timeout!("zypper --non-interactive#{gpg_checks} "+
                      "#{command} #{package_name}")
          end
        end

        def gpg_checks()
          case Chef::Config[:zypper_check_gpg]
          when true
            ""
          when false
            " --no-gpg-checks"
          when nil
            Chef::Log.warn("Chef::Config[:zypper_check_gpg] was not set. " +
              "All packages will be installed without gpg signature checks. " +
              "This is a security hazard.")
            " --no-gpg-checks"
          end
        end
      end
    end
  end
end
