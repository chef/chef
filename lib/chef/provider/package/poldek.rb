#
# Author:: Elan Ruusamäe (glen@pld-linux.org)
# Copyright:: Copyright (c) 2013 Elan Ruusamäe
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
require 'chef/mixin/shell_out'
require 'chef/resource/package'
require 'chef/mixin/get_source_from_package'

class Chef
  class Provider
    class Package
      class Poldek < Chef::Provider::Package
        include Chef::Mixin::ShellOut
        attr_accessor :is_virtual_package

        def load_current_resource
            Chef::Log.debug("#{@new_resource} loading current resource")
            @current_resource = Chef::Resource::Package.new(@new_resource.name)
            @current_resource.package_name(@new_resource.package_name)
            @current_resource.version(nil)
            check_package_state(@new_resource.package_name)
            @current_resource # modified by check_package_state
        end

        def check_package_state(name)
            Chef::Log.debug("#{@new_resource} checking package #{name}")
            installed = false
            @current_resource.version(nil)

            out = shell_out!("rpm -q #{name}", :env => nil, :returns => [0,1])
            if out.stdout
                Chef::Log.debug("rpm STDOUT: #{out.stdout}");
                version = out.stdout[/^#{@new_resource.package_name}-(.+)/, 1]
                if version
                    @current_resource.version(version)
                    installed = true
                end
            end

            if !installed
                out = shell_out!("poldek -q --uniq --skip-installed #{expand_options(@new_resource.options)} --cmd 'ls #{name}'", :env => nil, :returns => [0,1])
                if out.stdout
                    Chef::Log.debug("poldek STDOUT: #{out.stdout}");
                    version = out.stdout[/^#{@new_resource.package_name}-(.+)/, 1]
                    if version
                        @candidate_version = version
                    end
                end
            end

            return installed
        end

        def install_package(name, version)
            Chef::Log.debug("#{@new_resource} installing package #{name}-#{version}")
            package = "#{name}-#{version}"
            out = shell_out!("poldek --noask --up #{expand_options(@new_resource.options)} -u #{package}", :env => nil)
        end

        def upgrade_package(name, version)
            Chef::Log.debug("#{@new_resource} upgrading package #{name}-#{version}")
            install_package(name, version)
        end

        def remove_package(name, version)
            Chef::Log.debug("#{@new_resource} removing package #{name}-#{version}")
            package = "#{name}-#{version}"
            out = shell_out!("poldek --noask #{expand_options(@new_resource.options)} -e #{package}", :env => nil)
        end

        def purge_package(name, version)
            remove_package(name, version)
        end
      end
    end
  end
end
