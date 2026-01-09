#
# Author:: T.Heinen (<thomas.heinen@gmail.com>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "snap"

class Chef
  class Provider
    class Package
      class SnapTM < Chef::Provider::Package::Snap
        provides :snap_package, target_mode: true, agent_mode: false

        def install_package(names, versions)
          if new_resource.source
            install_snap_from_source(names, new_resource.source)
          else
            Array(names).each do |snap|
              snap_options = new_resource.options

              snapctl([
                "install",
                "--channel=#{new_resource.channel}",
                snap_options&.map { |opt| "--#{opt}" },
                snap,
              ].flatten.compact)
            end
          end
        end

        def remove_package(names, versions)
          Array(names).each do |snap|
            snapctl([
              "remove",
              snap,
            ])
          end
        end

        def snapctl(*args)
          # Deferred execution can result in exit code 10
          shell_out!("snap", *args, returns: [0, 10])
        end

        def get_latest_package_version(name, channel)
          cmd = shell_out("snap info #{name}")
          latest = cmd.stdout.lines.detect { |l| l.start_with? "  #{new_resource.channel}:" }
          return unless latest

          latest.split.at(1)
        end

        def get_installed_package_by_name(name)
          cmd = shell_out("snap info #{name}")
          installed = cmd.stdout.lines.detect { |l| l.start_with? "installed:" }
          return {} unless installed

          {
            "name" => name,
            "version" => installed.split.at(1),
          }
        end
      end
    end
  end
end
