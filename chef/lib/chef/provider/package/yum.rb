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
      class Yum < Chef::Provider::Package  
      
        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)
        
          Chef::Log.debug("Checking yum info for #{@new_resource.package_name}")
          status = popen4("yum info -q -y #{@new_resource.package_name}") do |pid, stdin, stdout, stderr|
            package_type = nil
            installed_version = nil
            candidate_version = nil
            stdout.each do |line|
              case line
              when /^Installed Packages$/
                package_type = :installed
              when /^Available Packages$/
                package_type = :available
              when /^Version: (.+)$/
                if package_type == :installed
                  installed_version = $1
                elsif package_type == :available
                  candidate_version = $1
                end
              when /^Release: (.+)$/
                if package_type == :installed
                  installed_version += "-#{$1}"
                  Chef::Log.debug("Installed release is #{installed_version}")
                elsif package_type == :available
                  candidate_version += "-#{$1}"
                  Chef::Log.debug("Candidate version is #{candidate_version}")
                end
              end
            end
            
            @current_resource.version(installed_version)
            if candidate_version
              @candidate_version = candidate_version
            else
              @candidate_version = installed_version
            end
          end

          unless status.exitstatus == 0
            raise Chef::Exceptions::Package, "yum failed - #{status.inspect}!"
          end
        
          @current_resource
        end
      
        def install_package(name, version)
          run_command(
            :command => "yum -q -y install #{name}-#{version}"
          )
        end
      
        def upgrade_package(name, version)
          # If we have a version, we can upgrade - otherwise, install
          if @current_resource.version
            run_command(
              :command => "yum -q -y update #{name}-#{version}"
            )   
          else
            install_package(name, version)
          end
        end

        def remove_package(name, version)
          run_command(
            :command => "yum -q -y remove #{name}-#{version}"
          )
        end
      
        def purge_package(name, version)
          remove_package(name, version)
        end
      
      end
    end
  end
end
