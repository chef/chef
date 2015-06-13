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

class Chef
  class Provider
    class Package
      class Ips < Chef::Provider::Package

        provides :ips_package, os: "solaris2"

        attr_accessor :virtual

        def define_resource_requirements
          super

          requirements.assert(:all_actions) do |a|
            a.assertion { ! @candidate_version.nil? }
            a.failure_message Chef::Exceptions::Package, "Package #{@new_resource.package_name} not found"
            a.whyrun "Assuming package #{@new_resource.package_name} would have been made available."
          end
        end

        def get_current_version
          shell_out_with_timeout("pkg info #{@new_resource.package_name}").stdout.each_line do |line|
            return $1.split[0] if line =~ /^\s+Version: (.*)/
          end
          return nil
        end

        def get_candidate_version
          shell_out_with_timeout!("pkg info -r #{new_resource.package_name}").stdout.each_line do |line|
            return $1.split[0] if line =~ /Version: (.*)/
          end
          return nil
        end

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)
          Chef::Log.debug("Checking package status for #{@new_resource.name}")
          @current_resource.version(get_current_version)
          @candidate_version = get_candidate_version
          @current_resource
        end

        def install_package(name, version)
          package_name = "#{name}@#{version}"
          normal_command = "pkg#{expand_options(@new_resource.options)} install -q #{package_name}"
          command =
            if @new_resource.respond_to?(:accept_license) and @new_resource.accept_license
              normal_command.gsub('-q', '-q --accept')
            else
              normal_command
            end
          shell_out_with_timeout(command)
        end

        def upgrade_package(name, version)
          install_package(name, version)
        end

        def remove_package(name, version)
          package_name = "#{name}@#{version}"
          shell_out_with_timeout!( "pkg#{expand_options(@new_resource.options)} uninstall -q #{package_name}" )
        end
      end
    end
  end
end
