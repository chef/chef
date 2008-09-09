#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
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

require File.join(File.dirname(__FILE__), "package")
require File.join(File.dirname(__FILE__), "..", "mixin", "command")

class Chef
  class Provider
    class Apt < Chef::Provider::Package  
      
      def load_current_resource
        @current_resource = Chef::Resource::Package.new(@new_resource.name)
        @current_resource.package_name(@new_resource.package_name)
        
        status = popen4("apt-cache policy #{@new_resource.package_name}") do |pid, stdin, stdout, stderr|
          stdin.close
          stdout.each do |line|
            case line
            when /^\s{2}Installed: (.+)$/
              installed_version = $1
              if installed_version == '(none)'
                @current_resource.version(nil)
              else
                @current_resource.version(installed_version)
              end
            when /^\s{2}Candidate: (.+)$/
              @candidate_version = $1
            end
          end
        end

        unless status.exitstatus == 0
          raise Chef::Exception::Package, "apt-cache failed - #{status.inspect}!"
        end
        
        @current_resource
      end
      
      def install_package(name, version)
        run_command(
          :command => "apt-get -q -y install #{name}=#{version}",
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
          :command => "apt-get -q -y remove #{@new_resource.package_name}",
          :environment => {
            "DEBIAN_FRONTEND" => "noninteractive"
          }
        )
      end
      
      def purge_package(name, version)
        run_command(
          :command => "apt-get -q -y purge #{@new_resource.package_name}",
          :environment => {
            "DEBIAN_FRONTEND" => "noninteractive"
          }
        )
      end
      
    end
  end
end
