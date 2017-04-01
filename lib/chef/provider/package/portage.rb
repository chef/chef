#
# Author:: Ezra Zygmuntowicz (<ezra@engineyard.com>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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
require "chef/util/path_helper"

class Chef
  class Provider
    class Package
      class Portage < Chef::Provider::Package

        provides :package, platform: "gentoo"
        provides :portage_package

        PACKAGE_NAME_PATTERN = %r{(?:([^/]+)/)?([^/]+)}

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(new_resource.name)
          current_resource.package_name(new_resource.package_name)

          category, pkg = /^#{PACKAGE_NAME_PATTERN}$/.match(new_resource.package_name)[1, 2]

          globsafe_category = category ? Chef::Util::PathHelper.escape_glob_dir(category) : nil
          globsafe_pkg = Chef::Util::PathHelper.escape_glob_dir(pkg)
          possibilities = Dir["/var/db/pkg/#{globsafe_category || '*'}/#{globsafe_pkg}-*"].map { |d| d.sub(%r{/var/db/pkg/}, "") }
          versions = possibilities.map do |entry|
            if entry =~ %r{[^/]+/#{Regexp.escape(pkg)}\-(\d[\.\d]*[a-z]?((_(alpha|beta|pre|rc|p)\d*)*)?(-r\d+)?)}
              [$&, $1]
            end
          end.compact

          if versions.size > 1
            atoms = versions.map(&:first).sort
            categories = atoms.map { |v| v.split("/")[0] }.uniq
            if !category && categories.size > 1
              raise Chef::Exceptions::Package, "Multiple packages found for #{new_resource.package_name}: #{atoms.join(' ')}. Specify a category."
            end
          elsif versions.size == 1
            current_resource.version(versions.first.last)
            Chef::Log.debug("#{new_resource} current version #{$1}")
          end

          current_resource
        end

        def parse_emerge(package, txt)
          availables = {}
          found_package_name = nil

          txt.each_line do |line|
            if line =~ /\*\s+#{PACKAGE_NAME_PATTERN}/
              found_package_name = $&.delete("*").strip
              if package =~ /\// # the category is specified
                if found_package_name == package
                  availables[found_package_name] = nil
                end
              else # the category is not specified
                if found_package_name.split("/").last == package
                  availables[found_package_name] = nil
                end
              end
            end

            if line =~ /Latest version available: (.*)/ && availables.key?(found_package_name)
              availables[found_package_name] = $1.strip
            end
          end

          if availables.size > 1
            # shouldn't happen if a category is specified so just use `package`
            raise Chef::Exceptions::Package, "Multiple emerge results found for #{package}: #{availables.keys.join(' ')}. Specify a category."
          end

          availables.values.first
        end

        def candidate_version
          return @candidate_version if @candidate_version

          status = shell_out_compact("emerge", "--color", "n", "--nospinner", "--search", new_resource.package_name.split("/").last)
          available, installed = parse_emerge(new_resource.package_name, status.stdout)
          @candidate_version = available

          unless status.exitstatus == 0
            raise Chef::Exceptions::Package, "emerge --search failed - #{status.inspect}!"
          end

          @candidate_version
        end

        def install_package(name, version)
          pkg = "=#{name}-#{version}"

          if version =~ /^\~(.+)/
            # If we start with a tilde
            pkg = "~#{name}-#{$1}"
          end

          shell_out_compact!( "emerge", "-g", "--color", "n", "--nospinner", "--quiet", options, pkg )
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

          shell_out_compact!( "emerge", "--unmerge", "--color", "n", "--nospinner", "--quiet", options, pkg )
        end

        def purge_package(name, version)
          remove_package(name, version)
        end

      end
    end
  end
end
