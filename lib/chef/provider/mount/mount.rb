#
# Author:: Joshua Timberman (<joshua@chef.io>)
# Copyright:: Copyright 2009-2016, Chef Software Inc.
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

require "chef/provider/mount"
require "chef/log"

class Chef
  class Provider
    class Mount
      class Mount < Chef::Provider::Mount

        provides :mount

        def initialize(new_resource, run_context)
          super
          @real_device = nil
        end
        attr_accessor :real_device

        def load_current_resource
          @current_resource = Chef::Resource::Mount.new(@new_resource.name)
          @current_resource.mount_point(@new_resource.mount_point)
          @current_resource.device(@new_resource.device)
          mounted?
          enabled?
        end

        def mountable?
          # only check for existence of non-remote devices
          if device_should_exist? && !::File.exists?(device_real)
            raise Chef::Exceptions::Mount, "Device #{@new_resource.device} does not exist"
          elsif @new_resource.mount_point != "none" && !::File.exists?(@new_resource.mount_point)
            raise Chef::Exceptions::Mount, "Mount point #{@new_resource.mount_point} does not exist"
          end
          true
        end

        def enabled?
          # Check to see if there is a entry in /etc/fstab. Last entry for a volume wins.
          enabled = false
          ::File.foreach("/etc/fstab") do |line|
            case line
            when /^[#\s]/
              next
            when /^#{device_fstab_regex}\s+#{Regexp.escape(@new_resource.mount_point)}\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/
              enabled = true
              @current_resource.fstype($1)
              @current_resource.options($2)
              @current_resource.dump($3.to_i)
              @current_resource.pass($4.to_i)
              Chef::Log.debug("Found mount #{device_fstab} to #{@new_resource.mount_point} in /etc/fstab")
              next
            when /^[\/\w]+\s+#{Regexp.escape(@new_resource.mount_point)}\s+/
              enabled = false
              Chef::Log.debug("Found conflicting mount point #{@new_resource.mount_point} in /etc/fstab")
            end
          end
          @current_resource.enabled(enabled)
        end

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

          shell_out!("mount").stdout.each_line do |line|
            case line
            when /^#{device_mount_regex}\s+on\s+#{Regexp.escape(real_mount_point)}\s/
              mounted = true
              Chef::Log.debug("Special device #{device_logstring} mounted as #{real_mount_point}")
            when /^([\/\w])+\son\s#{Regexp.escape(real_mount_point)}\s+/
              mounted = false
              Chef::Log.debug("Special device #{$~[1]} mounted as #{real_mount_point}")
            end
          end
          @current_resource.mounted(mounted)
        end

        def mount_fs
          unless @current_resource.mounted
            mountable?
            command = "mount -t #{@new_resource.fstype}"
            command << " -o #{@new_resource.options.join(',')}" unless @new_resource.options.nil? || @new_resource.options.empty?
            command << case @new_resource.device_type
                       when :device
                         " #{device_real}"
                       when :label
                         " -L #{@new_resource.device}"
                       when :uuid
                         " -U #{@new_resource.device}"
                       end
            command << " #{@new_resource.mount_point}"
            shell_out!(command)
            Chef::Log.debug("#{@new_resource} is mounted at #{@new_resource.mount_point}")
          else
            Chef::Log.debug("#{@new_resource} is already mounted at #{@new_resource.mount_point}")
          end
        end

        def umount_fs
          if @current_resource.mounted
            shell_out!("umount #{@new_resource.mount_point}")
            Chef::Log.debug("#{@new_resource} is no longer mounted at #{@new_resource.mount_point}")
          else
            Chef::Log.debug("#{@new_resource} is not mounted at #{@new_resource.mount_point}")
          end
        end

        def remount_command
          "mount -o remount,#{@new_resource.options.join(',')} #{@new_resource.mount_point}"
        end

        def remount_fs
          if @current_resource.mounted && @new_resource.supports[:remount]
            shell_out!(remount_command)
            @new_resource.updated_by_last_action(true)
            Chef::Log.debug("#{@new_resource} is remounted at #{@new_resource.mount_point}")
          elsif @current_resource.mounted
            umount_fs
            sleep 1
            mount_fs
          else
            Chef::Log.debug("#{@new_resource} is not mounted at #{@new_resource.mount_point} - nothing to do")
          end
        end

        def enable_fs
          if @current_resource.enabled && mount_options_unchanged?
            Chef::Log.debug("#{@new_resource} is already enabled - nothing to do")
            return nil
          end

          if @current_resource.enabled
            # The current options don't match what we have, so
            # disable, then enable.
            disable_fs
          end
          ::File.open("/etc/fstab", "a") do |fstab|
            fstab.puts("#{device_fstab} #{@new_resource.mount_point} #{@new_resource.fstype} #{@new_resource.options.nil? ? "defaults" : @new_resource.options.join(",")} #{@new_resource.dump} #{@new_resource.pass}")
            Chef::Log.debug("#{@new_resource} is enabled at #{@new_resource.mount_point}")
          end
        end

        def disable_fs
          if @current_resource.enabled
            contents = []

            found = false
            ::File.readlines("/etc/fstab").reverse_each do |line|
              if !found && line =~ /^#{device_fstab_regex}\s+#{Regexp.escape(@new_resource.mount_point)}\s/
                found = true
                Chef::Log.debug("#{@new_resource} is removed from fstab")
                next
              else
                contents << line
              end
            end

            ::File.open("/etc/fstab", "w") do |fstab|
              contents.reverse_each { |line| fstab.puts line }
            end
          else
            Chef::Log.debug("#{@new_resource} is not enabled - nothing to do")
          end
        end

        def network_device?
          @new_resource.device =~ /:/ || @new_resource.device =~ /\/\//
        end

        def device_should_exist?
          ( @new_resource.device != "none" ) &&
            ( not network_device? ) &&
            ( not %w{ cgroup tmpfs fuse vboxsf zfs }.include? @new_resource.fstype )
        end

        private

        def device_fstab
          case @new_resource.device_type
          when :device
            @new_resource.device
          when :label
            "LABEL=#{@new_resource.device}"
          when :uuid
            "UUID=#{@new_resource.device}"
          end
        end

        def device_real
          if @real_device.nil?
            if @new_resource.device_type == :device
              @real_device = @new_resource.device
            else
              @real_device = ""
              ret = shell_out("/sbin/findfs #{device_fstab}")
              device_line = ret.stdout.lines.first # stdout.first consumes
              @real_device = device_line.chomp unless device_line.nil?
            end
          end
          @real_device
        end

        def device_logstring
          case @new_resource.device_type
          when :device
            "#{device_real}"
          when :label
            "#{device_real} with label #{@new_resource.device}"
          when :uuid
            "#{device_real} with uuid #{@new_resource.device}"
          end
        end

        def device_mount_regex
          if network_device?
            # ignore trailing slash
            Regexp.escape(device_real) + "/?"
          elsif ::File.symlink?(device_real)
            # This regular expression tries to match device_real. If that does not match it will try to match the target of device_real.
            # So given a symlink like this:
            # /dev/mapper/vgroot-tmp.vol -> /dev/dm-9
            # First it will try to match "/dev/mapper/vgroot-tmp.vol". If there is no match it will try matching for "/dev/dm-9".
            "(?:#{Regexp.escape(device_real)}|#{Regexp.escape(::File.expand_path(::File.readlink(device_real), ::File.dirname(device_real)))})"
          else
            Regexp.escape(device_real)
          end
        end

        def device_fstab_regex
          if @new_resource.device_type == :device
            device_mount_regex
          else
            device_fstab
          end
        end

        def mount_options_unchanged?
          @current_resource.fstype == @new_resource.fstype &&
            @current_resource.options == @new_resource.options &&
            @current_resource.dump == @new_resource.dump &&
            @current_resource.pass == @new_resource.pass
        end

      end
    end
  end
end
