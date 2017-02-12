#
# Authors:: Bryan McLellan (btm@loftninjas.org)
#           Matthew Landauer (matthew@openaustralia.org)
#           Richard Manyanza (liseki@nyikacraftsmen.com)
# Copyright:: Copyright 2009-2016, Bryan McLellan, Matthew Landauer
# Copyright:: Copyright 2014-2016, Richard Manyanza
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

require "chef/provider/package/freebsd/base"
require "chef/util/path_helper"

class Chef
  class Provider
    class Package
      module Freebsd
        class Pkg < Base
          include PortsHelper

          def install_package(name, version)
            unless current_resource.version
              case new_resource.source
              when /^http/, /^ftp/
                if new_resource.source =~ /\/$/
                  shell_out_compact_timeout!("pkg_add", "-r", package_name, env: { "PACKAGESITE" => new_resource.source, "LC_ALL" => nil }).status
                else
                  shell_out_compact_timeout!("pkg_add", "-r", package_name, env: { "PACKAGEROOT" => new_resource.source, "LC_ALL" => nil }).status
                end
                Chef::Log.debug("#{new_resource} installed from: #{new_resource.source}")

              when /^\//
                shell_out_compact_timeout!("pkg_add", file_candidate_version_path, env: { "PKG_PATH" => new_resource.source, "LC_ALL" => nil }).status
                Chef::Log.debug("#{new_resource} installed from: #{new_resource.source}")

              else
                shell_out_compact_timeout!("pkg_add", "-r", latest_link_name, env: nil).status
              end
            end
          end

          def remove_package(name, version)
            shell_out_compact_timeout!("pkg_delete", "#{package_name}-#{version || current_resource.version}", env: nil).status
          end

          # The name of the package (without the version number) as understood by pkg_add and pkg_info.
          def package_name
            if supports_ports?
              if makefile_variable_value("PKGNAME", port_path) =~ /^(.+)-[^-]+$/
                $1
              else
                raise Chef::Exceptions::Package, "Unexpected form for PKGNAME variable in #{port_path}/Makefile"
              end
            else
              new_resource.package_name
            end
          end

          def latest_link_name
            makefile_variable_value("LATEST_LINK", port_path)
          end

          def current_installed_version
            pkg_info = shell_out_compact_timeout!("pkg_info", "-E", "#{package_name}*", env: nil, returns: [0, 1])
            pkg_info.stdout[/^#{Regexp.escape(package_name)}-(.+)/, 1]
          end

          def candidate_version
            case new_resource.source
            when /^http/, /^ftp/
              repo_candidate_version
            when /^\//
              file_candidate_version
            else
              ports_candidate_version
            end
          end

          def file_candidate_version_path
            Dir[Chef::Util::PathHelper.escape_glob_dir("#{new_resource.source}/#{current_resource.package_name}") + "*"][-1].to_s
          end

          def file_candidate_version
            file_candidate_version_path.split(/-/).last.split(/.tbz/).first
          end

          def repo_candidate_version
            "0.0.0"
          end

          def ports_candidate_version
            makefile_variable_value("PORTVERSION", port_path)
          end

          def port_path
            port_dir new_resource.package_name
          end

        end
      end
    end
  end
end
