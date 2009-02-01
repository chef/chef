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
      class Freebsd < Chef::Provider::Package  
      
        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)
        
          status = popen4("pkg_info -E #{@new_resource.package_name}*") do |pid, stdin, stdout, stderr|
            stdout.each do |line|
              case line
              when /^#{@current_resource.package_name}-(.+)/
                @current_resource.version($1)
                Chef::Log.debug("Current version is #{@current_resource.version}")
              end
            end
          end
          @current_resource.version(nil) unless @current_resource.version

          unless status.exitstatus == 0 || status.exitstatus == 1
            raise Chef::Exception::Package, "pkg_info -E #{@new_resource.package_name} failed - #{status.inspect}!"
          end
      
          port_path = nil
          status = popen4("whereis -s #{@new_resource.package_name}") do |pid, stdin, stdout, stderr|
            stdout.each do |line|
              case line
              when /^#{@new_resource.package_name}:\s+(.+)$/
                @port_path = $1
              end
            end
          end

          makefile = ::File.open("#{@port_path}/Makefile")
          makefile.each do |line|
            case line
            when /^PORTVERSION=\s+(\S+)/
              @candidate_version = $1
              Chef::Log.debug("Ports candidate version is #{@candidate_version}")
            end
          end

          @current_resource
        end

        def install_package(name, version)
          unless @current_resource.version
            case @new_resource.source
            when /^ports$/
              run_command(
                :command => "make -DBATCH install",
                :cwd => "#{@port_path}"
              )
            when /^http/, /^ftp/
              run_command(
                :command => "pkg_add -r #{@new_resource.name}",
                :environment => { "PACKAGESITE" => @new_resource.source }
              )
              Chef::Log.info("Installed package #{@new_resource.name} from: #{@new_resource.source}")
            when /^\//
              run_command(
                :command => "pkg_add #{@new_resource.name}",
                :environment => { "PKG_PATH" => @new_resource.source }
              )
              Chef::Log.info("Installed package #{@new_resource.name} from: #{@new_resource.source}")
            else
              run_command(
                :command => "pkg_add -r #{@new_resource.name}"
              )
              Chef::Log.info("Installed package #{@new_resource.name}")
            end
          end
        end
      
        def remove_package(name, version)
          if @current_resource.version
            run_command(
              :command => "pkg_delete #{@current_resource.name}-#{@current_resource.version}"
            )
            Chef::Log.info("Removed package #{@current_resource.name}-#{@current_resource.version}")
          end
        end
      end
    end
  end
end
