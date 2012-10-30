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
require 'chef/mixin/get_source_from_package'

class Chef
  class Provider
    class Package
      class Dpkg < Chef::Provider::Package::Apt
        DPKG_INFO = /([a-z\d\-\+\.]+)\t([\w\d.~-]+)/
        DPKG_INSTALLED = /^Status: install ok installed/
        DPKG_VERSION = /^Version: (.+)$/

        include Chef::Mixin::GetSourceFromPackage
        def define_resource_requirements
          super
          requirements.assert(:install) do |a| 
            a.assertion{ not @new_resource.source.nil? }
            a.failure_message Chef::Exceptions::Package, "Source for package #{@new_resource.name} required for action install"
          end

          # TODO this was originally written for any action in which .source is provided
          # but would it make more sense to only look at source if the action is :install?
          requirements.assert(:all_actions) do |a| 
            a.assertion { @source_exists }
            a.failure_message Chef::Exceptions::Package, "Package #{@new_resource.name} not found: #{@new_resource.source}"
            a.whyrun "Assuming it would have been previously downloaded."
          end
        end

        def load_current_resource
          @source_exists = true
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)
          @new_resource.version(nil)

          if @new_resource.source
            @source_exists = ::File.exists?(@new_resource.source) 
            if @source_exists
              # Get information from the package if supplied
              Chef::Log.debug("#{@new_resource} checking dpkg status")
              status = popen4("dpkg-deb -W #{@new_resource.source}") do |pid, stdin, stdout, stderr|
                stdout.each_line do |line|
                  if pkginfo = DPKG_INFO.match(line)
                    @current_resource.package_name(pkginfo[1])
                    @new_resource.version(pkginfo[2])
                  end
                end
              end
            else
              # Source provided but not valid means we can't safely do further processing
              return
            end

          end
          
          # Check to see if it is installed
          package_installed = nil
          Chef::Log.debug("#{@new_resource} checking install state")
          status = popen4("dpkg -s #{@current_resource.package_name}") do |pid, stdin, stdout, stderr|
            stdout.each_line do |line|
              case line
              when DPKG_INSTALLED
                package_installed = true
              when DPKG_VERSION
                if package_installed
                  Chef::Log.debug("#{@new_resource} current version is #{$1}")
                  @current_resource.version($1)
                end
              end
            end
          end

          unless status.exitstatus == 0 || status.exitstatus == 1
            raise Chef::Exceptions::Package, "dpkg failed - #{status.inspect}!"
          end
          
          @current_resource
        end
     
        def install_package(name, version)
          run_command_with_systems_locale(
            :command => "dpkg -i#{expand_options(@new_resource.options)} #{@new_resource.source}",
            :environment => {
              "DEBIAN_FRONTEND" => "noninteractive"
            }
          )
        end

        def remove_package(name, version)
          run_command_with_systems_locale(
            :command => "dpkg -r#{expand_options(@new_resource.options)} #{@new_resource.package_name}",
            :environment => {
              "DEBIAN_FRONTEND" => "noninteractive"
            }
          )
        end
      
        def purge_package(name, version)
          run_command_with_systems_locale(
            :command => "dpkg -P#{expand_options(@new_resource.options)} #{@new_resource.package_name}",
            :environment => {
              "DEBIAN_FRONTEND" => "noninteractive"
            }
          )
        end
      end
    end
  end
end
