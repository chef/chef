#
# Authors:: Richard Manyanza (liseki@nyikacraftsmen.com)
# Copyright:: Copyright (c) 2014 Richard Manyanza
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

require 'chef/provider/package/freebsd/base'

class Chef
  class Provider
    class Package
      module Freebsd
        class Port < Base
          include PortsHelper

          def install_package(name, version)
            shell_out!("make -DBATCH install clean", :timeout => 1800, :env => nil, :cwd => port_dir).status
          end

          def remove_package(name, version)
            shell_out!("make deinstall", :timeout => 300, :env => nil, :cwd => port_dir).status
          end

          def current_installed_version
            pkg_info = if supports_pkgng?
                         shell_out!("pkg info \"#{@new_resource.package_name}\"", :env => nil, :returns => [0,70])
                       else
                         shell_out!("pkg_info -E \"#{@new_resource.package_name}*\"", :env => nil, :returns => [0,1])
                       end
            pkg_info.stdout[/^#{Regexp.escape(@new_resource.package_name)}-(.+)/, 1]
          end

          def candidate_version
            if supports_ports?
              makefile_variable_value("PORTVERSION", port_dir)
            else
              raise Chef::Exceptions::Package, "Ports collection could not be found"
            end
          end

          def port_dir
            super(@new_resource.package_name)
          end



          private

          def supports_pkgng?
            with_pkgng = makefile_variable_value('WITH_PKGNG')
            with_pkgng && with_pkgng =~ /yes/i
          end

        end
      end
    end
  end
end
