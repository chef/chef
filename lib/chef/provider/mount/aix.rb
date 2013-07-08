#
# Author:: 
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
      class Aix < Chef::Provider::Mount::Mount

        def initialize(new_resource, run_context)
          super
          @real_device = nil
          @fstype = nil
        end
        attr_accessor :real_device

        def load_current_resource
          @current_resource = Chef::Resource::Mount.new(@new_resource.name)
          @current_resource.mount_point(@new_resource.mount_point)
          @current_resource.device(@new_resource.device)
          mounted?
          enabled?
        end



          
        def enabled?
      # Check to see if there is an entry in /etc/filesystems. Last entry for a volume wins. Using command "lsfs" to fetch entries.
          enabled = false
          cmd ="lsfs -c"	
          lsfs = Mixlib::ShellOut.new(cmd)
          lsfs.run_command
          fsentries = lsfs.stdout.split("\n")
          fsentries.each do | line |
                case line
          when /^#\s/
          next
          when /^#{Regexp.escape(@new_resource.mount_point)}+:+#{device_fstab_regex}/
            enabled = true
            fields = line.split(":")
            @current_resource.fstype(fields[3])
            @current_resource.options(fields[5])
            Chef::Log.debug("Found mount #{device_fstab} to #{@new_resource.mount_point} in /etc/filesystems")
         next
         when /^{Regexp.escape(@new_resource.mount_point)}/
           enabled=false
           Chef::Log.debug("Found conflicting mount point #{@new_resource.mount_point} in /etc/filesystems")
         end
         end
          @current_resource.enabled(enabled)
        end

        def mounted?
          mounted = false
          shell_out!("mount").stdout.each_line do |line|
            case line
             when /#{device_mount_regex}\s+#{Regexp.escape(@new_resource.mount_point)}/
               mounted = true
               Chef::Log.debug("Special device #{device_logstring} mounted as #{@new_resource.mount_point}")
               puts #{mounted}
               when /^[\/\w]+\s+#{Regexp.escape(@new_resource.mount_point)}\s+/
                 enabled = false
                 Chef::Log.debug("Found conflicting mount point #{@new_resource.mount_point} in /etc/fstab")
               end
          end
          @current_resource.mounted(mounted)
        end

        def mount_fs
          unless @current_resource.mounted
            mountable?
            command = "mount -v #{@new_resource.fstype}"
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

       def enable_fs
          if @current_resource.enabled && mount_options_unchanged?
            Chef::Log.debug("#{@new_resource} is already enabled - nothing to do
")
            return nil
          end

          if @current_resource.enabled
            # The current options don't match what we have, so
            # disable, then enable.
            disable_fs
          end
          ::File.open("/etc/filesystems", "a") do |fstab|
            fstab.puts("#{@new_resource.mount_point}: ")
            if network_device?
               device_details = device_fstab.split(":")
               fstab.puts(" nodename = #{device_details[0]} ")
               fstab.puts(" dev = #{device_details[1]} ")
            else
               fstab.puts(" dev = #{device_fstab} ")
            end 
            fstab.puts(" vfs = #{@new_resource.fstype} ")
            fstab.puts(" mount = true ")
            fstab.puts " options = #{@new_resource.options.join(',')}" unless @new_resource.options.nil? || @new_resource.options.empty?
            Chef::Log.debug("#{@new_resource} is enabled at #{@new_resource.mount_point}")
          end
        end

        def disable_fs
          if @current_resource.enabled
            command = "imfs -x -l #{device_fstab}"
            shell_out!(command)
          else
            Chef::Log.debug("#{@new_resource} is not enabled - nothing to do")
          end

        end

    end
   end
  end
end
