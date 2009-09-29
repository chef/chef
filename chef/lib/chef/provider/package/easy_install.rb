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

        def install_check(name, version)
          command = "python -c \"import sys; print sys.path\""
          check = false
          if version
            package = "#{name}-#{version}"
          else
            package = "#{name}"
          end
          status = popen4(command) do |pid, stdin, stdout, stderr|
            stdout.each do |line|
              if line.include? package
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

          if install_check(@new_resource.package_name, @new_resource.version)
            Chef::Log.debug("#{@new_resource.package_name} at version #{@new_resource.version}")
            @current_resource.version(@new_resource.version)
          end

          @current_resource
        end

        def candidate_version
          no_version = ""
          no_version
        end

        def install_package(name, version)
          if version == ""
            run_command(:command => "#{easy_install_binary_path} #{name}")
          else
            run_command(:command => "#{easy_install_binary_path} \"#{name}==#{version}\"")
          end
        end

        def upgrade_package(name, version)
          install_package(name)
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
