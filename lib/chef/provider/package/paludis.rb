#
# Author:: Vasiliy Tolstov (<v.tolstov@selfip.ru>)
# Copyright:: Copyright 2014-2016, Chef Software Inc.
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
      class Paludis < Chef::Provider::Package

        provides :package, platform: "exherbo"
        provides :paludis_package, os: "linux"

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(new_resource.package_name)
          current_resource.package_name(new_resource.package_name)

          Chef::Log.debug("Checking package status for #{new_resource.package_name}")
          installed = false
          re = Regexp.new("(.*)[[:blank:]](.*)[[:blank:]](.*)$")

          shell_out_compact!("cave", "-L", "warning", "print-ids", "-M", "none", "-m", new_resource.package_name, "-f", "%c/%p %v %r\n").stdout.each_line do |line|
            res = re.match(line)
            next if res.nil?
            case res[3]
            when "accounts", "installed-accounts"
              next
            when "installed"
              installed = true
              current_resource.version(res[2])
            else
              @candidate_version = res[2]
            end
          end

          current_resource
        end

        def install_package(name, version)
          pkg = if version
                  "=#{name}-#{version}"
                else
                  new_resource.package_name.to_s
                end
          shell_out_compact_timeout!("cave", "-L", "warning", "resolve", "-x", options, pkg)
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

          shell_out_compact!("cave", "-L", "warning", "uninstall", "-x", options, pkg)
        end

        def purge_package(name, version)
          remove_package(name, version)
        end

      end
    end
  end
end
