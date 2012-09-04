#
# Author:: Jason J. W. Williams (<williamsjj@digitar.com>)
# Author:: Stephen Nelson-Smith (<sns@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'open3'
require 'chef/provider/package'
require 'chef/mixin/command'
require 'chef/resource/package'
require 'chef/mixin/shell_out'

class Chef
  class Provider
    class Package
      class Ips < Chef::Provider::Package

        include Chef::Mixin::ShellOut
        attr_accessor :virtual

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
          installed = false
          depends = false
          
          shell_out!("pkg info -r #{package}").stdout.each_line do |line|
            case line
            when /^\s+State: Installed/
              installed = true
            when /^\s+Version: (.*)/
              @candidate_version = $1.split[0]
              if installed
                @current_resource.version($1)
              else
                @current_resource.version(nil)
              end
            end
          end

          return installed
        end

        def install_package(name, version)
          package_name = "#{name}@#{version}"
          normal_command = "pkg#{expand_options(@new_resource.options)} install -q #{package_name}"
          if @new_resource.respond_to?(:accept_license) and @new_resource.accept_license
            command = normal_command.gsub('-q', '-q --accept')
          else
            command = normal_command
          end
          begin
            run_command_with_systems_locale(:command => command)
          rescue
          end
        end

        def upgrade_package(name, version)
          install_package(name, version)
        end

        def remove_package(name, version)
          package_name = "#{name}@#{version}"
          run_command_with_systems_locale(
            :command => "pkg#{expand_options(@new_resource.options)} uninstall -q #{package_name}"
          )
        end
      end
    end
  end
end

