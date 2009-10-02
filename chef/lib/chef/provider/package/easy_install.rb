#
# Author:: Joe Williams (<joe@joetify.com>)
# Copyright:: Copyright (c) 2009 Joe Williams
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
      class EasyInstall < Chef::Provider::Package

        def install_check(name)
          command = "python -c \"import sys; print sys.path\""
          check = false
          status = popen4(command) do |pid, stdin, stdout, stderr|
            stdout.each do |line|
              if line.include? "#{name}"
                check = true
              end
            end
          end
          check
        end

        def easy_install_binary_path
          path = @new_resource.easy_install_binary
          path ? path : 'easy_install'
        end

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)
          @current_resource.version(nil)

          # get the currently installed version if installed
          if install_check(@new_resource.package_name)
            command = "python -c \"import #{@new_resource.package_name}; print #{@new_resource.package_name}.__path__\""
            pid, stdin, stdout, stderr = popen4(command)
            install_location = stdout.readline
            install_location[/\S\S(.*)\/(.*)-(.*)-py(.*).egg\S/]
            package_version = $3
          else
            package_version = nil
          end

          if package_version == @new_resource.version
            Chef::Log.debug("#{@new_resource.package_name} at version #{@new_resource.version}")
            @current_resource.version(@new_resource.version)
          else
            Chef::Log.debug("#{@new_resource.package_name} at version #{package_version}")
            @current_resource.version(package_version)
          end

          @current_resource
        end

        def candidate_version
           return @candidate_version if @candidate_version

           # do a dry run to get the latest version
           command = "#{easy_install_binary_path} -n #{@new_resource.package_name}"
           pid, stdin, stdout, stderr = popen4(command)
           dry_run_output = ""
           stdout.each do |line|
             dry_run_output << line
           end
           dry_run_output[/(.*)Best match: (.*) (.*)\n/]
           @candidate_version = $3
           @candidate_version
        end

        def install_package(name, version)
          run_command(:command => "#{easy_install_binary_path} \"#{name}==#{version}\"")
        end

        def upgrade_package(name, version)
          install_package(name, version)
        end

        def remove_package(name, version)
          run_command(:command => "#{easy_install_binary_path} -m #{name}")
        end

        def purge_package(name, version)
          remove_package(name, version)
        end

      end
    end
  end
end
