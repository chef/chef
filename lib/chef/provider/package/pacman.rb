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

require "chef/provider/package"
require "chef/resource/package"

class Chef
  class Provider
    class Package
      class Pacman < Chef::Provider::Package

        provides :package, platform: "arch"
        provides :pacman_package, os: "linux"

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(new_resource.name)
          current_resource.package_name(new_resource.package_name)

          Chef::Log.debug("#{new_resource} checking pacman for #{new_resource.package_name}")
          status = shell_out_compact_timeout("pacman", "-Qi", new_resource.package_name)
          status.stdout.each_line do |line|
            case line
            when /^Version(\s?)*: (.+)$/
              Chef::Log.debug("#{new_resource} current version is #{$2}")
              current_resource.version($2)
            end
          end

          unless status.exitstatus == 0 || status.exitstatus == 1
            raise Chef::Exceptions::Package, "pacman failed - #{status.inspect}!"
          end

          current_resource
        end

        def candidate_version
          return @candidate_version if @candidate_version

          repos = %w{extra core community}

          if ::File.exist?("/etc/pacman.conf")
            pacman = ::File.read("/etc/pacman.conf")
            repos = pacman.scan(/\[(.+)\]/).flatten
          end

          package_repos = repos.map { |r| Regexp.escape(r) }.join("|")

          status = shell_out_compact_timeout("pacman", "-Sl")
          status.stdout.each_line do |line|
            case line
            when /^(#{package_repos}) #{Regexp.escape(new_resource.package_name)} (.+)$/
              # $2 contains a string like "4.4.0-1" or "3.10-4 [installed]"
              # simply split by space and use first token
              @candidate_version = $2.split(" ").first
            end
          end

          unless status.exitstatus == 0 || status.exitstatus == 1
            raise Chef::Exceptions::Package, "pacman failed - #{status.inspect}!"
          end

          unless @candidate_version
            raise Chef::Exceptions::Package, "pacman does not have a version of package #{new_resource.package_name}"
          end

          @candidate_version
        end

        def install_package(name, version)
          shell_out_compact_timeout!( "pacman", "--sync", "--noconfirm", "--noprogressbar", options, name)
        end

        def upgrade_package(name, version)
          install_package(name, version)
        end

        def remove_package(name, version)
          shell_out_compact_timeout!( "pacman", "--remove", "--noconfirm", "--noprogressbar", options, name )
        end

        def purge_package(name, version)
          remove_package(name, version)
        end

      end
    end
  end
end
