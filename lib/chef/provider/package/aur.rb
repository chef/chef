#
# Author:: Ryan Chipman (<rchipman@mit.edu>)
# Copyright:: Copyright (c) 2015 Ryan Chipman
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
require 'chef/mixin/command'
require 'chef/resource/package'

require 'net/http'
require 'uri'
require 'json'

class Chef
  class Provider
    class Package
      class AUR < Chef::Provider::Package

        provides :aur_package, os: "linux"

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)

          @current_resource.version(nil)

          Chef::Log.debug("#{@new_resource} checking pacman for #{@new_resource.package_name}")
          status = popen4("pacman -Qi #{@new_resource.package_name}") do |pid, stdin, stdout, stderr|
            stdout.each do |line|
              case line
              when /^Version(\s?)*: (.+)$/
                Chef::Log.debug("#{@new_resource} current version is #{$2}")
                @current_resource.version($2)
              end
            end
          end

          unless status.exitstatus == 0 || status.exitstatus == 1
            raise Chef::Exceptions::Package, "pacman failed - #{status.inspect}!"
          end

          @current_resource
        end

        def candidate_version
          return @candidate_version if @candidate_version

          info_url = "https://aur.archlinux.org/rpc.php?type=info&arg=#{@new_resource.package_name}"
          uri = URI.parse(info_url)
          response = Net::HTTP.get_response(uri)
          json = JSON.parse(response.body)

#          raise json.to_s

          results = json["results"]
          unless results.length == 0
            version = results["Version"]
          end

          @candidate_version = version

          unless @candidate_version
            raise Chef::Exceptions::Package, "pacman does not have a version of package #{@new_resource.package_name}"
          end

          @candidate_version

        end

        def install_package(name, version)
          abbreviation = name[0,2]
          tarball_name = "#{name}.tar.gz"
          aur_url = "http://aur.archlinux.org/packages/#{abbreviation}/#{name}/#{tarball_name}"
          shell_out!( "rm -rf /tmp/aur_pkgbuilds/* && mkdir -p /tmp/aur_pkgbuilds && cd /tmp/aur_pkgbuilds && wget #{aur_url} && tar xvf #{tarball_name} && cd #{name} && makepkg#{expand_options(@new_resource.options)} --syncdeps --install --noconfirm --noprogressbar PKGBUILD && cd && rm -rf tmp/aur_pkgbuilds" )
        end

        def upgrade_package(name, version)
          install_package(name, version)
        end

        # TODO: recursive removal?
        def remove_package(name, version)
          shell_out!( "pacman --remove --noconfirm --noprogressbar#{expand_options(@new_resource.options)} #{name}" )
        end

        def purge_package(name, version)
          remove_package(name, version)
        end

      end
    end
  end
end
