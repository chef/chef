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

require "chef/resource/package"
require "chef/provider/package"
require "chef/mixin/get_source_from_package"

class Chef
  class Provider
    class Package
      module Freebsd

        module PortsHelper
          def supports_ports?
            ::File.exist?("/usr/ports/Makefile")
          end

          def port_dir(port)
            case port

            # When the package name starts with a '/' treat it as the full path to the ports directory.
            when /^\//
              port

            # Otherwise if the package name contains a '/' not at the start (like 'www/wordpress') treat
            # as a relative path from /usr/ports.
            when /\//
              "/usr/ports/#{port}"

            # Otherwise look up the path to the ports directory using 'whereis'
            else
              whereis = shell_out_compact_timeout!("whereis", "-s", port, env: nil)
              unless path = whereis.stdout[/^#{Regexp.escape(port)}:\s+(.+)$/, 1]
                raise Chef::Exceptions::Package, "Could not find port with the name #{port}"
              end
              path
            end
          end

          def makefile_variable_value(variable, dir = nil)
            options = dir ? { cwd: dir } : {}
            make_v = shell_out_compact_timeout!("make", "-V", variable, options.merge!(env: nil, returns: [0, 1]))
            make_v.exitstatus == 0 ? make_v.stdout.strip.split($OUTPUT_RECORD_SEPARATOR).first : nil # $\ is the line separator, i.e. newline.
          end
        end

        class Base < Chef::Provider::Package
          include Chef::Mixin::GetSourceFromPackage

          def initialize(*args)
            super
            @current_resource = Chef::Resource::Package.new(new_resource.name)
          end

          def load_current_resource
            current_resource.package_name(new_resource.package_name)

            current_resource.version(current_installed_version)
            Chef::Log.debug("#{new_resource} current version is #{current_resource.version}") if current_resource.version

            @candidate_version = candidate_version
            Chef::Log.debug("#{new_resource} candidate version is #{@candidate_version}") if @candidate_version

            current_resource
          end
        end

      end
    end
  end
end
