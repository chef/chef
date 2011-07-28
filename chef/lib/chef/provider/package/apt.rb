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
require 'chef/mixin/command'
require 'chef/resource/package'

class Chef
  class Provider
    class Package
      class Apt < Chef::Provider::Package

        include Chef::Mixin::ShellOut
        attr_accessor :virtual

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)
          check_package_state(@new_resource.package_name)
          @current_resource
        end

        def check_package_state(package)
          Chef::Log.debug("Checking package status for #{package}")
          installed = false
          depends = false

          shell_out!("aptitude show #{package}").stdout.each_line do |line|
            case line
            when /^State: installed/
              installed = true
            when /^Version: (.*)/
              @candidate_version = $1
              if installed
                @current_resource.version($1)
              else
                @current_resource.version(nil)
              end
            # Grab the first package in the dependency list to resolve case where a virtual package is provided by more than one package
            when /Depends: ([\w\d\-\.]*)/
              depends = $1
            # Check to see if this is a virtual package
            when /Provided by: ([\w\d\-\.]*)/
              next if installed
              virtual_provider = $1
              virtual_provider = depends if depends
              Chef::Log.debug("Virtual package provided by #{virtual_provider}")
              @virtual = true
              installed = check_package_state(virtual_provider)
              @candidate_version = virtual_provider
            end
          end

          if @candidate_version.nil?
            raise Chef::Exceptions::Package, "apt does not have a version of package #{@new_resource.package_name}"
          end

          return installed
        end

        def install_package(name, version)
          package_name = "#{name}=#{version}"
          package_name = "#{name} #{@candidate_version}" if @virtual
          run_command_with_systems_locale(
            :command => "apt-get -q -y#{expand_options(@new_resource.options)} install #{package_name}",
            :environment => {
              "DEBIAN_FRONTEND" => "noninteractive"
            }
          )
        end

        def upgrade_package(name, version)
          install_package(name, version)
        end

        def remove_package(name, version)
          package_name = "#{name}"
          package_name = "#{name} #{@candidate_version}" if @virtual
          run_command_with_systems_locale(
            :command => "apt-get -q -y#{expand_options(@new_resource.options)} remove #{package_name}",
            :environment => {
              "DEBIAN_FRONTEND" => "noninteractive"
            }
          )
        end

        def purge_package(name, version)
          run_command_with_systems_locale(
            :command => "apt-get -q -y#{expand_options(@new_resource.options)} purge #{@new_resource.package_name}",
            :environment => {
              "DEBIAN_FRONTEND" => "noninteractive"
            }
          )
        end

        def preseed_package(name, version)
          preseed_file = get_preseed_file(name, version)
          if preseed_file
            Chef::Log.info("#{@new_resource} pre-seeding package installation instructions")
            run_command_with_systems_locale(
              :command => "debconf-set-selections #{preseed_file}",
              :environment => {
                "DEBIAN_FRONTEND" => "noninteractive"
              }
            )
          end
        end

      end
    end
  end
end
