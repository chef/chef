# Authors:: Trevor O (trevoro@joyent.com)
#           Bryan McLellan (btm@loftninjas.org)
#           Matthew Landauer (matthew@openaustralia.org)
#           Sean OMeara (<someara@opscode.com>)
# Copyright:: Copyright (c) 2009 Bryan McLellan, Matthew Landauer
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


require 'chef/provider/package'
require 'chef/mixin/command'
require 'chef/resource/package'
require 'chef/mixin/shell_out'

class Chef
  class Provider
    class Package
      class Pkgin < Chef::Provider::Package
        
        include Chef::Mixin::ShellOut
        attr_accessor :is_virtual_package        
        
        def define_resource_requirements
          super
        
          requirements.assert(:all_actions) do |a|
            a.assertion { ! @candidate_version.nil? }
            a.failure_message Chef::Exceptions::Package, "Package #{@new_resource.package_name} not found"
            a.whyrun "Assuming package #{@new_resource.package_name} would have been made available."
          end
        end
        
        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.name)
          check_package_state(@new_resource.package_name)
          @current_resource
        end
        
        def check_package_state(package)
          Chef::Log.debug("Checking package status for #{package}")

          # see what is installed
          package_version = nil
          info = shell_out!("pkg_info -E #{package}", :env => nil, :returns => [0,1])

          unless info.nil? || info.stdout.empty?
            package_info = info.stdout.split(/(-[0-9])/)
            package_name = package_info[0]
            package_version = (package_info[1]+package_info[2]).chop.reverse.chop.reverse
          end

          if !package_version
            @current_resource.version(nil)
          else
            @current_resource.version(package_version)
          end

          # see whats available - set candidate_version
          available_info = shell_out!("pkgin avail | grep ^#{package}-[0-9] | awk '{ print $1 }'", :env => nil, :returns => [0,1])
          
          unless available_info.nil? || available_info.stdout.empty?
            candidate_info = available_info.stdout.split(/(-[0-9])/)
            candidate_name = candidate_info[0]
            candidate_version = (candidate_info[1]+candidate_info[2]).chop.reverse.chop.reverse
          end
          if !candidate_version
            @candidate_version = nil
          else
            @candidate_version = candidate_version
          end
        end
           
        def install_package(name, version)
          full_package_name = "#{name}-#{version}"
          shell_out!("pkgin -y install #{full_package_name}", :env => nil)
        end

        def upgrade_package(name, version)
          install_package(name, version)
        end
          
        def remove_package(name, version)
          full_package_name = "#{name}-#{version}"
          shell_out!("pkgin -y remove #{full_package_name}",  :env => nil)
        end
        
      end
    end
  end
end
