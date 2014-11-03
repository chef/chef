#
# Authors:: Bryan McLellan (btm@loftninjas.org)
#           Matthew Landauer (matthew@openaustralia.org)
#           Richard Manyanza (liseki@nyikacraftsmen.com)
#           Scott Bonds (scott@ggr.com)
# Copyright:: Copyright (c) 2009 Bryan McLellan, Matthew Landauer
# Copyright:: Copyright (c) 2014 Richard Manyanza, Scott Bonds
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

require 'chef/resource/package'
require 'chef/provider/package'
require 'chef/mixin/shell_out'
require 'chef/mixin/get_source_from_package'

class Chef
  class Provider
    class Package
      class Openbsd < Chef::Provider::Package

        provides :package, os: "openbsd"

        include Chef::Mixin::ShellOut
        include Chef::Mixin::GetSourceFromPackage

        def initialize(*args)
          super
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @new_resource.source(pkg_path) if !@new_resource.source
        end

        def load_current_resource
          @current_resource.package_name(@new_resource.package_name)
          @current_resource.version(installed_version)
          @current_resource
        end

        def install_package(name, version)
          unless @current_resource.version
            version_string  = ''
            version_string += "-#{version}" if version
            if parts = name.match(/^(.+?)--(.+)/)
              name = parts[1]
            end
            shell_out!("pkg_add -r #{name}#{version_string}", :env => {"PKG_PATH" => @new_resource.source}).status
            Chef::Log.debug("#{@new_resource} installed from: #{@new_resource.source}")
          end
        end

        def remove_package(name, version)
          version_string  = ''
          version_string += "-#{version}" if version
          if parts = name.match(/^(.+?)--(.+)/)
            name = parts[1]
          end
          shell_out!("pkg_delete #{name}#{version_string}", :env => nil).status
        end

        private

        def installed_version
          if parts = @new_resource.package_name.match(/^(.+?)--(.+)/)
            name = parts[1]
          else
            name = @new_resource.package_name
          end
          pkg_info = shell_out!("pkg_info -e \"#{name}->0\"", :env => nil, :returns => [0,1])
          result = pkg_info.stdout[/^inst:#{Regexp.escape(name)}-(.+?)\s/, 1]
          Chef::Log.debug("installed_version of '#{@new_resource.package_name}' is '#{result}'")
          result
        end

        def candidate_version
          @candidate_version ||= begin
            version_string  = ''
            version_string += "-#{version}" if @new_resource.version
            pkg_info = shell_out!("pkg_info -I \"#{@new_resource.package_name}#{version_string}\"", :env => nil, :returns => [0,1])
            if parts = @new_resource.package_name.match(/^(.+?)--(.+)/)
              result = pkg_info.stdout[/^#{Regexp.escape(parts[1])}-(.+?)\s/, 1]
            else
              result = pkg_info.stdout[/^#{Regexp.escape(@new_resource.package_name)}-(.+?)\s/, 1]
            end
            Chef::Log.debug("candidate_version of '#{@new_resource.package_name}' is '#{result}'")
            result
          end
        end

        def pkg_path
          ENV['PKG_PATH'] || "http://ftp.OpenBSD.org/pub/#{node.kernel.name}/#{node.kernel.release}/packages/#{node.kernel.machine}/"
        end

      end
    end
  end
end
