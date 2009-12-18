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
require 'chef/mixin/command'

class Chef
  class Provider
    class Mount
      class Mount < Chef::Provider::Mount

        include Chef::Mixin::Command

        def initialize(node, new_resource, collection=nil, definitions=nil, cookbook_loader=nil)
          super(node, new_resource, collection, definitions, cookbook_loader)
          @real_device = nil
        end
        attr_accessor :real_device

        def load_current_resource
          @current_resource = Chef::Resource::Mount.new(@new_resource.name)
          @current_resource.mount_point(@new_resource.mount_point)
          @current_resource.device(@new_resource.device)
          Chef::Log.debug("Checking for mount point #{@current_resource.mount_point}")

          # only check for existence of non-remote devices
          if(@new_resource.device !~ /:/ && @new_resource.device !~ /\/\// && !::File.exists?(@new_resource.device) )
            raise Chef::Exceptions::Mount, "Device #{@new_resource.device} does not exist"
          elsif( !::File.exists?(@new_resource.mount_point) )
            raise Chef::Exceptions::Mount, "Mount point #{@new_resource.mount_point} does not exist"
          end

          # Check to see if the volume is mounted. Last volume entry wins.
          mounted = false
          popen4("mount") do |pid, stdin, stdout, stderr|
            stdout.each do |line|
              case line
              when /^#{device_mount_regex}\s+on\s+#{@new_resource.mount_point}/
                mounted = true
                Chef::Log.debug("Special device #{device_logstring} mounted as #{@new_resource.mount_point}")
              when /^([\/\w])+\son\s#{@new_resource.mount_point}\s+/
                mounted = false
                Chef::Log.debug("Special device #{$~[1]} mounted as #{@new_resource.mount_point}")
              end
            end
          end
          @current_resource.mounted(mounted)

          # Check to see if there is a entry in /etc/fstab. Last entry for a volume wins.
          enabled = false
          ::File.read("/etc/fstab").each do |line|
            case line
            when /^[#\s]/
              next
            when /^#{device_fstab_regex}\s+#{@new_resource.mount_point}/
              enabled = true
              Chef::Log.debug("Found mount #{device_fstab} to #{@new_resource.mount_point} in /etc/fstab")
            when /^[\/\w]+\s+#{@new_resource.mount_point}/
              enabled = false
              Chef::Log.debug("Found conflicting mount point #{@new_resource.mount_point} in /etc/fstab")
            end
          end
          @current_resource.enabled(enabled)
        end

        def mount_fs
          unless @current_resource.mounted
            command = "mount -t #{@new_resource.fstype}"
            command << " -o #{@new_resource.options.join(',')}" unless @new_resource.options.nil? || @new_resource.options.empty?
            command << " #{device_real}"
            command << " #{@new_resource.mount_point}"
            run_command(:command => command)
            Chef::Log.info("Mounted #{@new_resource.mount_point}")
          else
            Chef::Log.debug("#{@new_resource.mount_point} is already mounted.")
          end
        end

        def umount_fs
          if @current_resource.mounted
            command = "umount #{@new_resource.mount_point}"
            run_command(:command => command)
            Chef::Log.info("Unmounted #{@new_resource.mount_point}")
          else
            Chef::Log.debug("#{@new_resource.mount_point} is not mounted.")
          end
        end

        def remount_fs
          if @current_resource.mounted and @new_resource.supports[:remount]
            command = "mount -o remount #{@new_resource.mount_point}"
            run_command(:command => command)

            @new_resource.updated = true
            Chef::Log.info("Remounted #{@new_resource.mount_point}")
          elsif @current_resource.mounted
            umount_fs
            sleep 1
            mount_fs
          else
            Chef::Log.debug("#{@new_resource.mount_point} is not mounted.")
          end
        end

        def enable_fs
          unless @current_resource.enabled
            ::File.open("/etc/fstab", "a") do |fstab|
              fstab.puts("#{device_fstab} #{@new_resource.mount_point} #{@new_resource.fstype} #{@new_resource.options.nil? ? "defaults" : @new_resource.options.join(",")} #{@new_resource.dump} #{@new_resource.pass}")
              Chef::Log.info("Enabled #{@new_resource.mount_point}")
            end
          else
            Chef::Log.debug("#{@new_resource.mount_point} is already enabled.")
          end
        end

        def disable_fs
          if @current_resource.enabled
            contents = []
            
            found = false
            ::File.readlines("/etc/fstab").reverse_each do |line|
              if !found && line =~ /^#{device_fstab_regex}\s+#{@new_resource.mount_point}/
                found = true
                Chef::Log.debug("Removing #{@new_resource.mount_point} from fstab")
                next
              else
                contents << line
              end
            end
            
            ::File.open("/etc/fstab", "w") do |fstab|
              contents.reverse_each { |line| fstab.puts line}
            end
          else
            Chef::Log.debug("#{@new_resource.mount_point} is not enabled")
          end
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
          if @real_device == nil 
            if @new_resource.device_type == :device
              @real_device = @new_resource.device
            else
              status = popen4("/sbin/findfs #{device_fstab}") do |pid, stdin, stdout, stderr|
                @real_device = stdout.first.chomp
              end
              unless status.exitstatus == 0
                @real_device = "/dev/null"
              end
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
          ::File.symlink?(device_real) ? "(?:#{device_real})|(?:#{::File.readlink(device_real)})" : device_real
        end

        def device_fstab_regex
          if @new_resource.device_type == :device
            device_mount_regex
          else
            device_fstab
          end
        end
      end
    end
  end
end
