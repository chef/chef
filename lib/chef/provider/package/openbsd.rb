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
require 'chef/exceptions'

class Chef
  class Provider
    class Package
      class Openbsd < Chef::Provider::Package

        provides :package, os: "openbsd"

        include Chef::Mixin::ShellOut
        include Chef::Mixin::GetSourceFromPackage

        def initialize(*args)
          super
          @current_resource = Chef::Resource::Package.new(new_resource.name)
        end

        def load_current_resource
          @current_resource.package_name(new_resource.package_name)
          @current_resource.version(installed_version)
          @current_resource
        end

        def define_resource_requirements
          super

          # Below are incomplete/missing features for this package provider
          requirements.assert(:all_actions) do |a|
            a.assertion { !new_resource.source }
            a.failure_message(Chef::Exceptions::Package, 'The openbsd package provider does not support the source attribute')
          end
          requirements.assert(:all_actions) do |a|
            a.assertion do
              if new_resource.package_name =~ /^(.+?)--(.+)/
                !new_resource.version
              else
                true
              end
            end
            a.failure_message(Chef::Exceptions::Package, 'The openbsd package provider does not support providing a version and flavor')
          end
        end

        def install_package(name, version)
          unless @current_resource.version
            if parts = name.match(/^(.+?)--(.+)/) # use double-dash for stems with flavors, see man page for pkg_add
              name = parts[1]
            end
            shell_out!("pkg_add -r #{name}#{version_string}", :env => {"PKG_PATH" => pkg_path}).status
            Chef::Log.debug("#{new_resource.package_name} installed")
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
          if parts = new_resource.package_name.match(/^(.+?)--(.+)/)
            name = parts[1]
          else
            name = new_resource.package_name
          end
          pkg_info = shell_out!("pkg_info -e \"#{name}->0\"", :env => nil, :returns => [0,1])
          result = pkg_info.stdout[/^inst:#{Regexp.escape(name)}-(.+?)\s/, 1]
          Chef::Log.debug("installed_version of '#{new_resource.package_name}' is '#{result}'")
          result
        end

        def candidate_version
          @candidate_version ||= begin
            results = []
            shell_out!("pkg_info -I \"#{new_resource.package_name}#{version_string}\"", :env => nil, :returns => [0,1]).stdout.each_line do |line|
              if parts = new_resource.package_name.match(/^(.+?)--(.+)/)
                results << line[/^#{Regexp.escape(parts[1])}-(.+?)\s/, 1]
              else
                results << line[/^#{Regexp.escape(new_resource.package_name)}-(.+?)\s/, 1]
              end
            end
            results = results.reject(&:nil?)
            Chef::Log.debug("candidate versions of '#{new_resource.package_name}' are '#{results}'")
            case results.length
            when 0
              []
            when 1
              results[0]
            else
              raise Chef::Exceptions::Package, "#{new_resource.name} has multiple matching candidates. Please use a more specific name" if results.length > 1
            end
          end
        end

        def version_string
          ver  = ''
          ver += "-#{new_resource.version}" if new_resource.version
        end

        def pkg_path
          ENV['PKG_PATH'] || "http://ftp.OpenBSD.org/pub/#{node.kernel.name}/#{node.kernel.release}/packages/#{node.kernel.machine}/"
        end

      end
    end
  end
end
