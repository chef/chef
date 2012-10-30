#
# Authors:: Bryan McLellan (btm@loftninjas.org)
#           Matthew Landauer (matthew@openaustralia.org)
# Copyright:: Copyright (c) 2009 Bryan McLellan, Matthew Landauer
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
      class Freebsd < Chef::Provider::Package
        include Chef::Mixin::ShellOut

        include Chef::Mixin::GetSourceFromPackage

        def initialize(*args)
          super
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
        end

        def current_installed_version
          pkg_info = shell_out!("pkg_info -E \"#{package_name}*\"", :env => nil, :returns => [0,1])
          pkg_info.stdout[/^#{package_name}-(.+)/, 1]
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
            unless path = whereis.stdout[/^#{@new_resource.package_name}:\s+(.+)$/, 1]
              raise Chef::Exceptions::Package, "Could not find port with the name #{@new_resource.package_name}"
            end
            path
          end
        end

        def ports_makefile_variable_value(variable)
          make_v = shell_out!("make -V #{variable}", :cwd => port_path, :env => nil, :returns => [0,1])
          make_v.stdout.strip.split($\).first # $\ is the line separator, i.e., newline
        end

        def ports_candidate_version
          ports_makefile_variable_value("PORTVERSION")
        end

        def file_candidate_version_path
          Dir["#{@new_resource.source}/#{@current_resource.package_name}*"][-1].to_s
        end

        def file_candidate_version
          file_candidate_version_path.split(/-/).last.split(/.tbz/).first
        end

        def load_current_resource
          @current_resource.package_name(@new_resource.package_name)

          @current_resource.version(current_installed_version)
          Chef::Log.debug("#{@new_resource} current version is #{@current_resource.version}") if @current_resource.version

          case @new_resource.source
          when /^http/, /^ftp/
            @candidate_version = "0.0.0"
          when /^\//
            @candidate_version = file_candidate_version
          else
            @candidate_version = ports_candidate_version
          end

          Chef::Log.debug("#{@new_resource} ports candidate version is #{@candidate_version}") if @candidate_version

          @current_resource
        end

        def latest_link_name
          ports_makefile_variable_value("LATEST_LINK")
        end

        # The name of the package (without the version number) as understood by pkg_add and pkg_info
        def package_name
          if ::File.exist?("/usr/ports/Makefile")
            if ports_makefile_variable_value("PKGNAME") =~ /^(.+)-[^-]+$/
              $1
            else
              raise Chef::Exceptions::Package, "Unexpected form for PKGNAME variable in #{port_path}/Makefile"
            end
          else
            @new_resource.package_name
          end
        end

        def install_package(name, version)
          unless @current_resource.version
            case @new_resource.source
            when /^ports$/
              shell_out!("make -DBATCH install", :timeout => 1200, :env => nil, :cwd => port_path).status
            when /^http/, /^ftp/
              if @new_resource.source =~ /\/$/
                shell_out!("pkg_add -r #{package_name}", :env => { "PACKAGESITE" => @new_resource.source, 'LC_ALL' => nil }).status
              else
                shell_out!("pkg_add -r #{package_name}", :env => { "PACKAGEROOT" => @new_resource.source, 'LC_ALL' => nil }).status
              end
              Chef::Log.debug("#{@new_resource} installed from: #{@new_resource.source}")
            when /^\//
              shell_out!("pkg_add #{file_candidate_version_path}", :env => { "PKG_PATH" => @new_resource.source , 'LC_ALL'=>nil}).status
              Chef::Log.debug("#{@new_resource} installed from: #{@new_resource.source}")
            else
              shell_out!("pkg_add -r #{latest_link_name}", :env => nil).status
            end
          end
        end

        def remove_package(name, version)
          # a version is mandatory
          if version
            shell_out!("pkg_delete #{package_name}-#{version}", :env => nil).status
          else
            shell_out!("pkg_delete #{package_name}-#{@current_resource.version}", :env => nil).status
          end
        end

      end
    end
  end
end
