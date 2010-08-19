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
          installed?
          @current_resource
        end

        def installed?(package=@new_resource.package_name)
          Chef::Log.debug("Checking package status for #{package}")
          installed = false
         
          status = shell_out!("aptitude show #{package}")
          status.stdout.each do |line|
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
              when /Provided by: (.+)$/
                Chef::Log.debug("Virtual package provided by #{$1}")
                @virtual = true
                installed = installed?($1)
                @candidate_version = $1
            end
          end

          unless status.exitstatus == 0
            raise Chef::Exceptions::Package, "aptitude show failed - #{status.inspect}!"
          end

          if @candidate_version == nil
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
            Chef::Log.info("Pre-seeding #{@new_resource} with package installation instructions.")
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
