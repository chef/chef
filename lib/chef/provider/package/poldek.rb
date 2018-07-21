#
# Author:: Elan Ruusamäe (glen@pld-linux.org)
# Copyright:: Copyright (c) 2013,2018 Elan Ruusamäe
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

require 'digest/md5'
require 'chef/provider/package'
require 'chef/mixin/shell_out'
require 'chef/resource/package'

class Chef
  class Provider
    class Package
      class Poldek < Chef::Provider::Package
        include Chef::Mixin::ShellOut

        allow_nils
        use_multipackage_api

        provides :package, platform_family: "pld"

        def load_current_resource
          logger.debug("#{new_resource} loading current resource")
          @current_resource = Chef::Resource::Package.new(new_resource.name)
          current_resource.package_name(new_resource.package_name)
          current_resource.version(get_current_versions)
          current_resource
        end

        def candidate_version
          @candidate_version ||= get_candidate_versions
        end

        def get_current_versions
          names = package_name_array
          logger.debug("#{new_resource} checking current version: #{names}")

          # rpm works as expected: output is returned in order as input given, even duplicates
          cmd = rpm("-q", "--qf", "%{NAME} %{VERSION}\n", names)
          versions_from_name_list(cmd.stdout, names)
        end

        def get_candidate_versions
          names = package_name_array
          logger.debug("#{new_resource} check candidate version");

          update_indexes

          # poldek works unexpectedly: packages that don't exist are printed as errors first, and names are de-duplicated
          cmd = poldek(%w{--uniq --skip-installed} + options.to_a + ["--cmd", "ls --qf '%{NAME} %{VERSION}\n'", names])
          versions_from_name_list(cmd.stdout, names)
        end

        def install_package(names, versions)
          logger.trace("#{new_resource} installing package #{names} version #{versions}")
          update_indexes
          poldek("-u", names)
        end

        def upgrade_package(names, versions)
          logger.trace("#{new_resource} upgrading package #{names} version #{versions}")
          install_package(names, versions)
        end

        def remove_package(names, versions)
          logger.trace("#{new_resource} removing package #{names} version #{versions}")
          poldek("-e", names)
        end

        private
        @@updated = Hash.new

        def update_indexes()
          checksum = Digest::MD5.hexdigest(opts).to_s

          if @@updated[checksum]
              return
          end

          logger.debug("#{new_resource} updating package indexes")
          poldek("--up")
          @@updated[checksum] = true
        end

        def opts
          expand_options(options)
        end

        def versions_from_name_list(input, names)
          packages = extract_packages(input)
          versions = match_versions(names, packages)
          versions
        end

        def extract_packages(output)
          packages = {}
          output.each_line do |line|
            case line.rstrip
            when /^package (.+) is not installed$/
            when /(.+): no such package or directory$/
            when /^(.+?) (.+)$/
              packages[$1] = $2
            end
          end
          packages
        end

        def match_versions(names, packages)
          names.map do |name|
            packages[name]
          end
        end

        def rpm(*args)
          shell_out_compact_timeout!("rpm", *args, env: nil, returns: [0, 1])
        end

        def poldek(*args)
          shell_out_compact_timeout!(%w{poldek -q --noask}, options, *args, env: nil, returns: [0, 1, 255])
        end
      end
    end
  end
end
