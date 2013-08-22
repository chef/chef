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
require 'chef/mixin/shell_out'
require 'singleton'

class Chef
  class Provider
    class Package
      class Zypper < Chef::Provider::Package

        include Chef::Mixin::ShellOut

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)

          is_installed=false
          is_out_of_date=false
          version=''
          oud_version=''
          Chef::Log.debug("#{@new_resource} checking zypper")
          status = popen4("zypper --non-interactive info #{@new_resource.package_name}") do |pid, stdin, stdout, stderr|
            stdout.each do |line|
              case line
              when /^Version: (.+)$/
                version = $1
                Chef::Log.debug("#{@new_resource} version #{$1}")
              when /^Installed: Yes$/
                is_installed=true
                Chef::Log.debug("#{@new_resource} is installed")

              when /^Installed: No$/
                is_installed=false
                Chef::Log.debug("#{@new_resource} is not installed")
              when /^Status: out-of-date \(version (.+) installed\)$/
                is_out_of_date=true
                oud_version=$1
                Chef::Log.debug("#{@new_resource} out of date version #{$1}")
              end
            end
          end

          if is_installed==false
            @candidate_version=version
            @current_resource.version(nil)
          end

          if is_installed==true
            if is_out_of_date==true
              @current_resource.version(oud_version)
              @candidate_version=version
            else
              @current_resource.version(version)
              @candidate_version=version
            end
          end

          unless status.exitstatus == 0
            raise Chef::Exceptions::Package, "zypper failed - #{status.inspect}!"
          end

          @current_resource
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
        def zypper_package(command, pkgname, version)
          version = "=#{version}" unless version.empty?
          if zypper_version < 1.0
            shell_out!("zypper#{gpg_checks} #{command} -y #{pkgname}")
          else
            shell_out!("zypper --non-interactive#{gpg_checks} "+
                      "#{command} #{pkgname}#{version}")
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
