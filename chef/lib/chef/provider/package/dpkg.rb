#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Copyright:: Copyright (c) 2009 Bryan McLellan
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
require 'chef/mixin/get_source_from_package'

class Chef
  class Provider
    class Package
      class Dpkg < Chef::Provider::Package::Apt

        DPKG_INFO = /([a-z\d\-\+\.]+)\t([\w\d.~-]+)/
        DPKG_INSTALLED = /^Status: install ok installed/
        DPKG_VERSION = /^Version: (.+)$/

        include Chef::Mixin::GetSourceFromPackage

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)

          assert_install_action_requires_source!

          _package_name, _version = package_name_and_version

          @new_resource.version          _version
          @current_resource.package_name _package_name
          @current_resource.version      installed_version

          @current_resource
        end

        def install_package(name, version)
          shell_out_with_systems_locale!(
            "dpkg -i#{expand_options(@new_resource.options)} #{@new_resource.source}",
            :environment => { "DEBIAN_FRONTEND" => "noninteractive" } )
        end

        def remove_package(name, version)
          shell_out_with_systems_locale!(
            "dpkg -r#{expand_options(@new_resource.options)} #{@new_resource.package_name}",
            :environment => { "DEBIAN_FRONTEND" => "noninteractive" } )
        end

        def purge_package(name, version)
          shell_out_with_systems_locale!(
            "dpkg -P#{expand_options(@new_resource.options)} #{@new_resource.package_name}",
            :environment => { "DEBIAN_FRONTEND" => "noninteractive" } )
        end

        def assert_install_action_requires_source!
          # if the source was not set, and we're installing, fail
          if Array(@new_resource.action).include?(:install) && @new_resource.source.nil?
            raise Chef::Exceptions::Package, "Source for package #{@new_resource.name} required for action install"
          end
        end

        def assert_dpkg_exists!
          raise Chef::Exceptions::Package, "Package #{@new_resource.name} not found: #{@new_resource.source}" unless ::File.exists?(@new_resource.source)
        end

        def package_name_and_version
          # We only -need- source for action install
          return [ nil, nil ] unless @new_resource.source
          assert_dpkg_exists!

          # Get information from the package if supplied
          Chef::Log.debug("#{@new_resource} checking dpkg status")
          status = shell_out!("dpkg-deb -W #{@new_resource.source}")
          status.stdout.each_line do |line|
            if pkginfo = DPKG_INFO.match(line)
              return [ pkginfo[1], pkginfo[2] ]
            end
          end

          return [ nil, nil ]
        end

        def installed_version
          # Check to see if it is installed
          package_installed = nil
          Chef::Log.debug("#{@new_resource} checking install state")

          status = shell_out!("dpkg -s #{@current_resource.package_name}") 

          unless status.exitstatus == 0 || status.exitstatus == 1
            raise Chef::Exceptions::Package, "dpkg failed - #{status.inspect}!"
          end

          status.stdout.each_line do |line|
            case line
            when DPKG_INSTALLED
              package_installed = true
            when DPKG_VERSION
              if package_installed
                Chef::Log.debug("#{@new_resource} current version is #{$1}")
                return $1
              end
            end
          end

          return nil
        end

      end
    end
  end
end
