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
        attr_accessor :is_virtual_package

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)
          check_package_state(@new_resource.package_name)
          @current_resource
        end

        def check_package_state(package)
          Chef::Log.debug("#{@new_resource} checking package status for #{package}")
          installed = false

          shell_out!("aptitude show #{package}").stdout.each_line do |line|
            case line
            when /^State: installed/
              installed = true
            when /^State: not a real package/
              @is_virtual_package = true
            when /^Version: (.*)/
              @candidate_version = $1
              if installed
                @current_resource.version($1)
              else
                @current_resource.version(nil)
              end
            # If we are a virtual package with one provider package, install it
            when /^Provided by: ([\w\d\-\.]*)$/
              next unless @is_virtual_package
              virtual_provider = $1
              Chef::Log.info("#{@new_resource} is a virtual package, actually acting on package[#{virtual_provider}]")
              installed = check_package_state(virtual_provider)
            # If there is a comma, it is a list of packages. In this case fail to force the user to choose.
            when /^Provided by: .*,/
              next unless @is_virtual_package
              raise Chef::Exceptions::Package, "#{@new_resource.package_name} is a virtual package provided by multiple packages, you must explicitly select one to install"
            end
          end

          if @candidate_version.nil?
            raise Chef::Exceptions::Package, "apt does not have a version of package #{@new_resource.package_name}"
          end

          return installed
        end

        def install_package(name, version)
          package_name = "#{name}=#{version}"
          package_name = name if @is_virtual_package
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
