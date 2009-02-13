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

            Chef::Log.debug("SOURCE: #{@new_resource.source}")
          if @new_resource.source
            Chef::Log.debug("FOUND SOURCE!!!!")
            unless ::File.exists?(@new_resource.source)
              raise Chef::Exception::Package, "Package #{@new_resource.name} not found: #{@new_resource.package_name}"
            end

            # Get information from the package if supplied
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
          else
            # if the source was not set, and we're installing, fail
            if @new_resource.actions.has_key?(:install)
              raise Chef::Exception::Package, "Source for package #{@new_resource.name} required for action install"
            end
            @current_resource.package_name(@new_resource.package_name)
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
      end
    end
  end
end
