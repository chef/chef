#
# Author:: Jan Zimmek (<jan.zimmek@web.de>)
# Copyright:: Copyright 2010-2016, Jan Zimmek
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

require_relative "../package"
require_relative "../../resource/package"

class Chef
  class Provider
    class Package
      class Pacman < Chef::Provider::Package

        provides :package, platform: "arch", target_mode: true
        provides :pacman_package, target_mode: true

        use_multipackage_api
        allow_nils

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(new_resource.name)
          current_resource.package_name(new_resource.package_name)
          current_resource.version = []

          repos = %w{extra core community}

          if ::TargetIO::File.exist?("/etc/pacman.conf")
            pacman = ::TargetIO::File.read("/etc/pacman.conf")
            repos = pacman.scan(/\[(.+)\]/).flatten
          end

          repos = Regexp.union(repos)
          status = shell_out("pacman", "-Sl")

          unless status.exitstatus == 0 || status.exitstatus == 1
            raise Chef::Exceptions::Package, "pacman failed - #{status.inspect}!"
          end

          pkg_db_data = status.stdout
          @candidate_version = []
          package_name_array.each do |pkg|
            pkg_data = pkg_db_data.match(/(#{repos}) #{pkg} (?<candidate>.*?-[0-9]+)(?<installed> \[.*?( (?<current>.*?-[0-9]+))?\])?\n/m)
            unless pkg_data
              raise Chef::Exceptions::Package, "pacman does not have a version of package #{pkg}"
            end

            @candidate_version << pkg_data[:candidate]
            if pkg_data[:installed]
              current_resource.version << (pkg_data[:current] || pkg_data[:candidate])
            else
              current_resource.version << nil
            end
          end

          current_resource
        end

        def candidate_version
          @candidate_version
        end

        def install_package(name, version)
          shell_out!("pacman", "--sync", "--noconfirm", "--noprogressbar", options, *name)
        end

        def upgrade_package(name, version)
          install_package(name, version)
        end

        def remove_package(name, version)
          shell_out!("pacman", "--remove", "--noconfirm", "--noprogressbar", options, *name)
        end

        def purge_package(name, version)
          remove_package(name, version)
        end

      end
    end
  end
end
