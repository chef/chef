#
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
      class Aix < Chef::Provider::Mount::Mount
        provides :mount, platform: "aix"

        # Override for aix specific handling
        def initialize(new_resource, run_context)
          super
          # options and fstype are set to "defaults" and "auto" respectively in the Mount Resource class. These options are not valid for AIX, override them.
          if @new_resource.options[0] == "defaults"
            @new_resource.options([])
          end
          if @new_resource.fstype == "auto"
            @new_resource.send(:clear_fstype)
          end
        end

        def enabled?
          # Check to see if there is an entry in /etc/filesystems. Last entry for a volume wins. Using command "lsfs" to fetch entries.
          enabled = false

          regex_arr = device_fstab_regex.split(":")
          if regex_arr.size == 2
            nodename = regex_arr[0]
            devicename = regex_arr[1]
          else
            devicename = regex_arr[0]
          end
          # lsfs o/p = #MountPoint:Device:Vfs:Nodename:Type:Size:Options:AutoMount:Acct
          # search only for current mount point
          shell_out("lsfs", "-c", @new_resource.mount_point).stdout.each_line do |line|
            case line
            when /^#\s/
              next
            when /^#{Regexp.escape(@new_resource.mount_point)}:#{devicename}:(\S+):#{nodename}:(\S+)?:(\S+):(\S+):(\S+):(\S+)/
              # mount point entry with ipv6 address for nodename (ipv6 address use ':')
              enabled = true
              @current_resource.fstype($1)
              @current_resource.options($4)
              logger.trace("Found mount point #{@new_resource.mount_point} :: device_type #{@current_resource.device_type} in /etc/filesystems")
              next
            when /^#{Regexp.escape(@new_resource.mount_point)}:#{nodename}:(\S+)::(\S+)?:(\S+):(\S+):(\S+):(\S+)/
              # mount point entry with hostname or ipv4 address
              enabled = true
              @current_resource.fstype($1)
              @current_resource.options($4)
              @current_resource.device("")
              logger.trace("Found mount point #{@new_resource.mount_point} :: device_type #{@current_resource.device_type} in /etc/filesystems")
              next
            when /^#{Regexp.escape(@new_resource.mount_point)}:(\S+)?:(\S+):#{devicename}:(\S+)?:(\S+):(\S+):(\S+):(\S+)/
              # mount point entry with hostname or ipv4 address
              enabled = true
              @current_resource.fstype($2)
              @current_resource.options($5)
              @current_resource.device(devicename + "/")
              logger.trace("Found mount point #{@new_resource.mount_point} :: device_type #{@current_resource.device_type} in /etc/filesystems")
              next
            when /^#{Regexp.escape(@new_resource.mount_point)}:(.*?):(.*?):(.*?):(.*?):(.*?):(.*?):(.*?):(.*?)/
              if $3.split("=")[0] == "LABEL" || $1.split("=")[0] == "LABEL"
                @current_resource.device_type("label")
              elsif $3.split("=")[0] == "UUID" || $1.split("=")[0] == "UUID"
                @current_resource.device_type("uuid")
              else
                @current_resource.device_type("device")
              end

              if @current_resource.device_type != @new_resource.device_type
                enabled = true
                logger.trace("Found mount point #{@new_resource.mount_point} :: device_type #{@current_resource.device_type} in /etc/filesystems")
              else
                enabled = false
                logger.trace("Found conflicting mount point #{@new_resource.mount_point} in /etc/filesystems")
              end
            end

          end
          @current_resource.enabled(enabled)
        end

        def mounted?
          mounted = false
          shell_out!("mount").stdout.each_line do |line|
            if network_device?
              device_details = device_fstab.split(":")
              search_device = device_details[1]
            else
              search_device = device_fstab_regex
            end
            case line
            when /#{search_device}\s+#{Regexp.escape(@new_resource.mount_point)}/
              mounted = true
              logger.trace("Special device #{device_logstring} mounted as #{@new_resource.mount_point}")
            when %r{^[/\w]+\s+#{Regexp.escape(@new_resource.mount_point)}\s+}
              mounted = false
              logger.trace("Found conflicting mount point #{@new_resource.mount_point} in /etc/fstab")
            end
          end
          @current_resource.mounted(mounted)
        end

        def mount_fs
          unless @current_resource.mounted
            mountable?
            command = [ "mount", "-v", @new_resource.fstype ]

            unless @new_resource.options.nil? || @new_resource.options.empty?
              command << "-o"
              command << @new_resource.options.join(",")
            end

            command << case @new_resource.device_type
                       when :device
                         device_real
                       when :label
                         [ "-L", @new_resource.device ]
                       when :uuid
                         [ "-U", @new_resource.device ]
                       end
            command << @new_resource.mount_point
            shell_out!(command)
            logger.trace("#{@new_resource} is mounted at #{@new_resource.mount_point}")
          else
            logger.debug("#{@new_resource} is already mounted at #{@new_resource.mount_point}")
          end
        end

        def remount_command
          if !(@new_resource.options.nil? || @new_resource.options.empty?)
            [ "mount", "-o", "remount,#{@new_resource.options.join(",")}", @new_resource.device, @new_resource.mount_point ]
          else
            [ "mount", "-o", "remount", @new_resource.device, @new_resource.mount_point ]
          end
        end

        def enable_fs
          if @current_resource.enabled && mount_options_unchanged?
            logger.debug("#{@new_resource} is already enabled - nothing to do")
            return nil
          end

          if @current_resource.enabled
            # The current options don't match what we have, so
            # disable, then enable.
            disable_fs
          end
          ::File.open("/etc/filesystems", "a") do |fstab|
            fstab.puts("\n\n#{@new_resource.mount_point}:")
            if network_device?
              device_details = device_fstab.split(":")
              fstab.puts("\tdev\t\t= #{device_details[1]}")
              fstab.puts("\tnodename\t\t= #{device_details[0]}")
            else
              fstab.puts("\tdev\t\t= #{device_fstab}")
            end
            fstab.puts("\tvfs\t\t= #{@new_resource.fstype}")
            fstab.puts("\tmount\t\t= false")
            fstab.puts "\toptions\t\t= #{@new_resource.options.join(",")}" unless @new_resource.options.nil? || @new_resource.options.empty?
            logger.trace("#{@new_resource} is enabled at #{@new_resource.mount_point}")
          end
        end

        def mount_options_unchanged?
          current_resource_options = @current_resource.options.delete_if { |x| x == "rw" }

          @current_resource.device == @new_resource.device &&
            @current_resource.fsck_device == @new_resource.fsck_device &&
            @current_resource.fstype == @new_resource.fstype &&
            current_resource_options == @new_resource.options &&
            @current_resource.dump == @new_resource.dump &&
            @current_resource.pass == @new_resource.pass
        end

        def disable_fs
          contents = []
          if @current_resource.enabled
            found_device = false
            ::File.open("/etc/filesystems", "r").each_line do |line|
              case line
              when %r{^/.+:\s*$}
                if /#{Regexp.escape(@new_resource.mount_point)}+:/.match?(line)
                  found_device = true
                else
                  found_device = false
                end
              end
              unless found_device
                contents << line
              end
            end
            ::File.open("/etc/filesystems", "w") do |fstab|
              contents.each { |line| fstab.puts line }
            end
          else
            logger.debug("#{@new_resource} is not enabled - nothing to do")
          end
        end

      end
    end
  end
end
