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
require 'chef/mixin/command'
require 'chef/resource/package'

class Chef
  class Provider
    class Package
      class Dpkg < Chef::Provider::Package  
      
        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @new_resource.version(nil)

          # Get information from the package supplied
          Chef::Log.debug("Checking dpkg status for #{@new_resource.package_name}")
          status = popen4("dpkg-deb -W #{@new_resource.source}") do |pid, stdin, stdout, stderr|
            stdout.each do |line|
              case line
              when /([\w\d]+)\t([\w\d.-]+)/
                @current_resource.package_name($1)
                @new_resource.version($2)
              end
            end
          end
          
          # Check to see if it is installed
          package_installed = nil
          Chef::Log.debug("Checking install state for #{@current_resource.package_name}")
          status = popen4("dpkg -s #{@current_resource.package_name}") do |pid, stdin, stdout, stderr|
            stdout.each do |line|
              case line
              when /^Status: install ok installed/
                package_installed = true
              when /^Version: (.+)$/
                if package_installed
                  Chef::Log.debug("Current version is #{$1}")                
                  @current_resource.version($1)
                end
              end
            end
          end

          unless status.exitstatus == 0 || status.exitstatus == 1
            raise Chef::Exception::Package, "dpkg failed - #{status.inspect}!"
          end
          
          @current_resource
        end
     
        def install_package(name, version)
          run_command(
            :command => "dpkg -i #{@new_resource.source}",
            :environment => {
              "DEBIAN_FRONTEND" => "noninteractive"
            }
          )
        end

        def upgrade_package(name, version)
          install_package(name, version)
        end
      
        def remove_package(name, version)
          run_command(
            :command => "dpkg -r #{@new_resource.package_name}",
            :environment => {
              "DEBIAN_FRONTEND" => "noninteractive"
            }
          )
        end
      
        def purge_package(name, version)
          run_command(
            :command => "dpkg -P #{@new_resource.package_name}",
            :environment => {
              "DEBIAN_FRONTEND" => "noninteractive"
            }
          )
        end
        
        def preseed_package(name, version)
          preseed_file = get_preseed_file(name, version)
          if preseed_file
            Chef::Log.info("Pre-seeding #{@new_resource} with package installation instructions.")
            run_command(
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
