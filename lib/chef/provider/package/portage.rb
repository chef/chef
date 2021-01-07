#
# Author:: Ezra Zygmuntowicz (<ezra@engineyard.com>)
# Copyright:: Copyright (c) Chef Software Inc.
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
require_relative "../../resource/portage_package"
require_relative "../../util/path_helper"

class Chef
  class Provider
    class Package
      class Portage < Chef::Provider::Package

        provides :package, platform: "gentoo"
        provides :portage_package

        PACKAGE_NAME_PATTERN = %r{^(?:([^/]+)/)?([^/]+)$}.freeze

        def load_current_resource
          @current_resource = Chef::Resource::PortagePackage.new(new_resource.name)
          current_resource.package_name(new_resource.package_name)

          category, pkg = PACKAGE_NAME_PATTERN.match(new_resource.package_name)[1, 2]

          globsafe_category = category ? Chef::Util::PathHelper.escape_glob_dir(category) : nil
          globsafe_pkg = Chef::Util::PathHelper.escape_glob_dir(pkg)
          possibilities = Dir["/var/db/pkg/#{globsafe_category || "*"}/#{globsafe_pkg}-*"].map { |d| d.sub(%r{/var/db/pkg/}, "") }
          versions = possibilities.map do |entry|
            if entry =~ %r{[^/]+/#{Regexp.escape(pkg)}\-(\d[\.\d]*[a-z]?((_(alpha|beta|pre|rc|p)\d*)*)?(-r\d+)?)}
              [$&, $1]
            end
          end.compact

          if versions.size > 1
            atoms = versions.map(&:first).sort
            categories = atoms.map { |v| v.split("/")[0] }.uniq
            if !category && categories.size > 1
              raise Chef::Exceptions::Package, "Multiple packages found for #{new_resource.package_name}: #{atoms.join(" ")}. Specify a category."
            end
          elsif versions.size == 1
            current_resource.version(versions.first.last)
            logger.trace("#{new_resource} current version #{$1}")
          end

          current_resource
        end

        def raise_error_for_query(msg)
          raise Chef::Exceptions::Package, "Query for '#{new_resource.package_name}' #{msg}"
        end

        def candidate_version
          return @candidate_version if @candidate_version

          pkginfo = shell_out("portageq", "best_visible", "/", new_resource.package_name)

          if pkginfo.exitstatus != 0
            pkginfo.stderr.each_line do |line|
              # cspell:disable-next-line
              if /[Uu]nqualified atom .*match.* multiple/.match?(line)
                raise_error_for_query("matched multiple packages (please specify a category):\n#{pkginfo.inspect}")
              end
            end

            if pkginfo.stdout.strip.empty?
              raise_error_for_query("did not find a matching package:\n#{pkginfo.inspect}")
            end

            raise_error_for_query("resulted in an unknown error:\n#{pkginfo.inspect}")
          end

          if pkginfo.stdout.lines.count > 1
            raise_error_for_query("produced unexpected output (multiple lines):\n#{pkginfo.inspect}")
          end

          pkginfo.stdout.chomp!
          if /-r\d+$/.match?(pkginfo.stdout)
            # Latest/Best version of the package is a revision (-rX).
            @candidate_version = pkginfo.stdout.split(/(?<=-)/).last(2).join
          else
            # Latest/Best version of the package is NOT a revision (-rX).
            @candidate_version = pkginfo.stdout.split("-").last
          end

          @candidate_version
        end

        def install_package(name, version)
          pkg = "=#{name}-#{version}"

          if version =~ /^\~(.+)/
            # If we start with a tilde
            pkg = "~#{name}-#{$1}"
          end

          shell_out!( "emerge", "-g", "--color", "n", "--nospinner", "--quiet", options, pkg )
        end

        def upgrade_package(name, version)
          install_package(name, version)
        end

        def remove_package(name, version)
          pkg = if version
                  "=#{new_resource.package_name}-#{version}"
                else
                  new_resource.package_name.to_s
                end

          shell_out!( "emerge", "--unmerge", "--color", "n", "--nospinner", "--quiet", options, pkg )
        end

        def purge_package(name, version)
          remove_package(name, version)
        end

      end
    end
  end
end
