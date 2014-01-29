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

require 'digest/md5'
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
            check_package_state
            @current_resource # modified by check_package_state
        end

        def check_package_state()
            Chef::Log.debug("#{@new_resource} checking package #{@new_resource.package_name}")

            installed = false
            @current_resource.version(nil)

            out = shell_out!("rpm -q #{@new_resource.package_name}", :env => nil, :returns => [0,1])
            if out.stdout
                Chef::Log.debug("rpm STDOUT: #{out.stdout}");
                version = version_from_nvra(out.stdout)
                if version
                    @current_resource.version(version)
                    installed = true
                end
            end

            return installed
        end

        def candidate_version
            Chef::Log.debug("poldek check candidate version for #{@new_resource.package_name}");
            return @candidate_version if @candidate_version

            update_indexes
            cmd = "poldek -q --uniq --skip-installed #{expand_options(@new_resource.options)} --cmd 'ls #{@new_resource.package_name}'"
            out = shell_out!(cmd, :env => nil, :returns => [0,1,255])
            if out.stdout
                Chef::Log.debug("poldek STDOUT: #{out.stdout}");
                version = version_from_nvra(out.stdout)
                if version
                    @candidate_version = version
                end
            end
            unless @candidate_version
                raise Chef::Exceptions::Package, "poldek does not have a version of package #{@new_resource.package_name}"
            end
            @candidate_version
        end

        def install_package(name, version)
            Chef::Log.debug("#{@new_resource} installing package #{name}-#{version}")
            package = "#{name}-#{version}"
            update_indexes
            out = shell_out!("poldek --noask #{expand_options(@new_resource.options)} -u #{package}", :env => nil)
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

        private
        @@updated = Hash.new

        def version_from_nvra(stdout)
            stdout[/^#{Regexp.escape(@new_resource.package_name)}-(.+)/, 1]
        end

        def update_indexes()
            Chef::Log.debug("#{@new_resource} call update indexes #{expand_options(@new_resource.options)}")
            checksum = Digest::MD5.hexdigest(@new_resource.options || '').to_s

            if @@updated[checksum]
                return
            end
            Chef::Log.debug("#{@new_resource} updating package indexes: #{expand_options(@new_resource.options)}")
            shell_out!("poldek --up #{expand_options(@new_resource.options)}", :env => nil)
            @@updated[checksum] = true
        end
      end
    end
  end
end
