#
# Author:: Joshua Timberman (<joshua@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc
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

require 'chef/provider/mount'
require 'chef/log'
require 'chef/mixin/shell_out'

class Chef
  class Provider
    class Mount
      class Mount < Chef::Provider::Mount
        include Chef::Mixin::ShellOut

        def initialize(new_resource, run_context)
          super
          @real_device = nil
        end
        attr_accessor :real_device

        def load_current_resource
          @current_resource = Chef::Resource::Mount.new(@new_resource.name)

          @current_resource.mount_point @new_resource.mount_point
          @current_resource.device      @new_resource.device

          @current_resource.fstype  fstab_info[:fstype]
          @current_resource.options fstab_info[:options]
          @current_resource.dump    fstab_info[:dump]
          @current_resource.pass    fstab_info[:pass]

          @current_resource.mounted mounted?
          @current_resource.enabled enabled?

          @current_resource
        end

        def mountable?
          # only check for existence of non-remote devices
          assert_device_exists! if device_should_exist?
          assert_mount_point_exists!
          return true
        end

        def assert_device_exists!
          raise Chef::Exceptions::Mount, "Device #{@new_resource.device} does not exist" unless ::File.exists?(device_real)
        end

        def assert_mount_point_exists!
            raise Chef::Exceptions::Mount,
              "Mount point #{@new_resource.mount_point} does not exist" unless ::File.exists?(@new_resource.mount_point)
        end

        def fstab_info
          return @fstab_info if @fstab_info

          # Check to see if there is a entry in /etc/fstab. Last entry for a volume wins.
          @fstab_info = { :enabled? => false }

          ::File.readlines("/etc/fstab").each do |line|
            case line
            when /^[#\s]/
              next
            when /^#{device_fstab_regex}\s+#{Regexp.escape(@new_resource.mount_point)}\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/

              @fstab_info[:enabled?] = true
              @fstab_info[:fstype]   = $1
              @fstab_info[:options]  = $2
              @fstab_info[:dump]     = $3.to_i
              @fstab_info[:pass]     = $4.to_i

              Chef::Log.debug("Found mount #{device_fstab} to #{@new_resource.mount_point} in /etc/fstab")
              next
            when /^[\/\w]+\s+#{Regexp.escape(@new_resource.mount_point)}\s+/
              @fstab_info[:enabled?] = false
              Chef::Log.debug("Found conflicting mount point #{@new_resource.mount_point} in /etc/fstab")
            end
          end

          return @fstab_info
        end

        def enabled?
          fstab_info[:enabled?]
        end

        def mounted?
          _mounted = false
          shell_out!("mount").stdout.each_line do |line|
            case line
            when /^#{device_mount_regex}\s+on\s+#{Regexp.escape(@new_resource.mount_point)}/
              # Can we do a return here?
              _mounted = true
              Chef::Log.debug("Special device #{device_logstring} mounted as #{@new_resource.mount_point}")
            when /^([\/\w])+\son\s#{Regexp.escape(@new_resource.mount_point)}\s+/
              _mounted = false
              Chef::Log.debug("Special device #{$~[1]} mounted as #{@new_resource.mount_point}")
            end
          end
          return _mounted
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

        def remount_fs
          if @current_resource.mounted and @new_resource.supports[:remount]
            shell_out!("mount -o remount #{@new_resource.mount_point}")
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
          Chef::Log.debug("#{@new_resource} is not enabled - nothing to do") and return unless @current_resource.enabled

          # Look for the last occurance of the filesystem, and remove only that line.
          fstab_content = ::File.readlines("/etc/fstab")
          return unless fs_idx = fstab_content.rindex { |i| i =~ /^#{device_fstab_regex}\s+#{Regexp.escape(@new_resource.mount_point)}/ }
          fstab_content.delete_at(fs_idx)
          ::File.open("/etc/fstab", "w") { |f| f.puts fstab_content }
        end

        def network_device?
          @new_resource.device =~ /:/ || @new_resource.device =~ /\/\//
        end

        def device_should_exist?
          ( not network_device? ) and ( not %w[ tmpfs fuse ].include? @new_resource.fstype )
        end

        protected

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
          return @real_device if @real_device
          return @real_device = @new_resource.device if @new_resource.device_type == :device

          @real_device = ""
          status = popen4("/sbin/findfs #{device_fstab}") do |pid, stdin, stdout, stderr|
            device_line = stdout.first # stdout.first consumes
            @real_device = device_line.chomp unless device_line.nil?
          end

          return @real_device
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
            Regexp.escape(device_real)+"/?"
          elsif ::File.symlink?(device_real)
            "(?:#{Regexp.escape(device_real)})|(?:#{Regexp.escape(::File.readlink(device_real))})"
          else
            Regexp.escape(device_real)
          end
        end

        def device_fstab_regex
          @new_resource.device_type == :device ? device_mount_regex : device_fstab
        end

        def mount_options_unchanged?
          @current_resource.fstype == @new_resource.fstype and
          @current_resource.options == @new_resource.options and
          @current_resource.dump == @new_resource.dump and
          @current_resource.pass == @new_resource.pass
        end

      end
    end
  end
end
