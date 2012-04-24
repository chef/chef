#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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
require 'chef/resource/package'
require 'singleton'

class Chef
  class Provider
    class Package
      class Zypper < Chef::Provider::Package

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)

          is_installed=false
          is_out_of_date=false
          version=''
          oud_version=''

          Chef::Log.debug("#{@new_resource} checking zypper")

          status = shell_out!("zypper info #{@new_resource.package_name}")
          raise Chef::Exceptions::Package, "zypper failed - #{status.inspect}!" unless status.exitstatus == 0

          status.stdout.each_line do |line|
            case line
            when /^Version: (.+)$/
              version = $1
              Chef::Log.debug("#{@new_resource} version #{$1}")
            when /^Installed: Yes$/
              is_installed = true
              Chef::Log.debug("#{@new_resource} is installed")
            when /^Installed: No$/
              is_installed = false
              Chef::Log.debug("#{@new_resource} is not installed")
            when /^Status: out-of-date \(version (.+) installed\)$/
              is_installed = true
              is_out_of_date = true
              oud_version = $1
              Chef::Log.debug("#{@new_resource} out of date version #{$1}")
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

          @current_resource
        end

        #Gets the zypper Version from command output (Returns Floating Point number)
        def zypper_version()
          status = shell_out!('zypper -V 2>&1')
          status.stdout.scan(/\d+/).join(".").to_f
        end

        def install_package(name, version)
          if zypper_version < 1.0
            shell_out! "zypper install -y #{name}"
          elsif version
            shell_out! "zypper -n --no-gpg-checks install -l  #{name}=#{version}"
          else
            shell_out! "zypper -n --no-gpg-checks install -l  #{name}"
          end
        end

        def upgrade_package(name, version)
          if zypper_version < 1.0
            shell_out! "zypper install -y #{name}"
          elsif version
            shell_out! "zypper -n --no-gpg-checks install -l #{name}=#{version}"
          else
            shell_out! "zypper -n --no-gpg-checks install -l #{name}"
          end
        end

        def remove_package(name, version)
          if zypper_version < 1.0
            shell_out! "zypper remove -y #{name}"
          elsif version
            shell_out! "zypper -n --no-gpg-checks remove  #{name}=#{version}"
          else
            shell_out! "zypper -n --no-gpg-checks remove  #{name}"
          end
        end

        def purge_package(name, version)
          remove_package(name, version)
        end

      end
    end
  end
end
