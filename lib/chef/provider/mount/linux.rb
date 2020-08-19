#
# Author:: Joshua Timberman (<joshua@chef.io>)
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

require_relative "../mount"

class Chef
  class Provider
    class Mount
      class Linux < Chef::Provider::Mount::Mount

        provides :mount, os: "linux"

        def mounted?
          mounted = false

          # "mount" outputs the mount points as real paths. Convert
          # the mount_point of the resource to a real path in case it
          # contains symlinks in its parents dirs.
          real_mount_point = if ::File.exists? @new_resource.mount_point
                               ::File.realpath(@new_resource.mount_point)
                             else
                               @new_resource.mount_point
                             end

          shell_out!("findmnt -rn").stdout.each_line do |line|
            case line
            when /\A#{Regexp.escape(real_mount_point)}\s+#{device_mount_regex}\s/
              mounted = true
              logger.trace("Special device #{device_logstring} mounted as #{real_mount_point}")
            when %r{\A#{Regexp.escape(real_mount_point)}\s+([/\w])+\s}
              mounted = false
              logger.trace("Special device #{$~[1]} mounted as #{real_mount_point}")
            when %r{\A#{Regexp.escape(real_mount_point)}\s+([/\w])+\[#{device_mount_regex}\]\s}
              mounted = true
              logger.trace("Bind device #{device_logstring} mounted as #{real_mount_point}")
            end
          end
          @current_resource.mounted(mounted)
        end
      end
    end
  end
end
