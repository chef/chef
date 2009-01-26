#
# Author:: Ezra Zygmuntowicz (<ezra@engineyard.com>)
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
      class Portage < Chef::Provider::Package  
      
        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)
        
          status = popen4("emerge --color n --nospinner --search #{@new_resource.package_name}") do |pid, stdin, stdout, stderr|
            stdin.close
            
            available, installed = parse_emerge(@new_resource.package_name, stdout.read)
            
            if installed == "[ Not Installed ]"
              @current_resource.version(nil)
            else
              @current_resource.version(installed)
            end  
            @candidate_version = available
          end

          unless status.exitstatus == 0
            raise Chef::Exception::Package, "emerge --search failed - #{status.inspect}!"
          end
        
          @current_resource
        end
      
      
        def parse_emerge(package, txt)
          available, installed, pkg = nil
          txt.each do |line|
            if line =~ /\*(.*)/
              pkg = $1.strip
            end
            if pkg == package or pkg.split('/').last == package
              if line =~ /Latest version available: (.*)/
                available = $1
              elsif line =~ /Latest version installed: (.*)/
                installed = $1
              end  
            end
          end  
          available = installed unless available
          [available, installed]
        end
        
        
        def install_package(name, version)
          run_command(
            :command => "emerge -g --color n --nospinner --quiet =#{name}-#{version}"
          )
        end
      
        def upgrade_package(name, version)
          install_package(name, version)
        end
      
        def remove_package(name, version)
          run_command(
            :command => "emerge --unmerge --color n --nospinner --quiet #{@new_resource.package_name}"
          )
        end
      
        def purge_package(name, version)
          remove_package(name, version)
        end
      
      end
    end
  end
end