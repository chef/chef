#
# Authors:: Richard Manyanza (liseki@nyikacraftsmen.com)
# Copyright:: Copyright (c) 2013 Richard Manyanza
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
      class FreebsdNextGen < Chef::Provider::Package
        include Chef::Mixin::ShellOut

        include Chef::Mixin::GetSourceFromPackage

        def initialize(*args)
          super
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
        end

        def load_current_resource
          @current_resource.package_name(@new_resource.package_name)

          @current_resource.version(current_installed_version)
          Chef::Log.debug("#{@new_resource} current version is #{@current_resource.version}") if @current_resource.version

          @candidate_version = case @new_resource.source
                               when /^ports$/i
                                 ports_candidate_version
                               else
                                 package_candidate_version
                               end

          Chef::Log.debug("#{@new_resource} ports candidate version is #{@candidate_version}") if @candidate_version

          @current_resource
        end

        def install_package(name, version)
          unless @current_resource.version
            case @new_resource.source
            when /^ports$/i
              shell_out!("make -DBATCH install", :timeout => 1800, :env => nil, :cwd => port_path).status
            when /^(http|ftp|\/)/
              shell_out!("pkg add#{expand_options(@new_resource.options)} #{@new_resource.source}", :env => { 'LC_ALL' => nil }).status
              Chef::Log.debug("#{@new_resource} installed from: #{@new_resource.source}")
            else
              shell_out!("pkg install#{expand_options(@new_resource.options || '-y')} #{name}", :env => { 'LC_ALL' => nil }).status
            end
          end
        end

        def remove_package(name, version)
          shell_out!("pkg delete#{expand_options(@new_resource.options || '-y')} #{name}#{version ? '-' + version : ''}", :env => nil).status
        end




        private

        def current_installed_version
          pkg_info = shell_out!("pkg info \"#{@new_resource.package_name}\"", :env => nil, :returns => [0,70])
          pkg_info.stdout[/^#{Regexp.escape(@new_resource.package_name)}-(.+)/, 1]
        end

        def package_candidate_version
          if @new_resource.source
            @new_resource.source[/#{Regexp.escape(@new_resource.package_name)}-(.+)\.[[:alpha:]]{3}/, 1]
          else
            repo_candidate_version
          end
        end

        def repo_candidate_version
          if @new_resource.options && @new_resource.options.match(/(r .+)\b/)
            options = "-#{$1}"
          end

          pkg_query = shell_out!("pkg rquery#{expand_options(options)} '%v' #{@new_resource.package_name}", :env => nil, :returns => [0,69])
          pkg_query.stdout.strip.split(/\n/).first
        end

        def ports_candidate_version
          ports_makefile_variable_value("PORTVERSION")
        end

        def port_path
          case @new_resource.package_name
          # When the package name starts with a '/' treat it as the full path to the ports directory
          when /^\//
            @new_resource.package_name
          # Otherwise if the package name contains a '/' not at the start (like 'www/wordpress') treat as a relative
          # path from /usr/ports
          when /\//
            "/usr/ports/#{@new_resource.package_name}"
          # Otherwise look up the path to the ports directory using 'whereis'
          else
            whereis = shell_out!("whereis -s #{@new_resource.package_name}", :env => nil)
            unless path = whereis.stdout[/^#{Regexp.escape(@new_resource.package_name)}:\s+(.+)$/, 1]
              raise Chef::Exceptions::Package, "Could not find port with the name #{@new_resource.package_name}"
            end
            path
          end
        end

        def ports_makefile_variable_value(variable)
          make_v = shell_out!("make -V #{variable}", :cwd => port_path, :env => nil, :returns => [0,1])
          make_v.stdout.strip.split(/\n/).first
        end

      end
    end
  end
end
