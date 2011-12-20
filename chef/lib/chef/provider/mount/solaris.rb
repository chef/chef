#
# Author:: Hugo Fichter
# Original Author: Joshua Timberman (<joshua@opscode.com>)
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
      class Solaris < Chef::Provider::Mount
        include Chef::Mixin::ShellOut

        def initialize(new_resource, run_context)
          super
          @real_device = nil
        end
        attr_accessor :real_device

        def load_current_resource
          puts "name " + @new_resource.name
          puts "mount point " + @new_resource.mount_point
          puts "device" + @new_resource.device
          @current_resource = Chef::Resource::Mount.new(@new_resource.name)
          @current_resource.mount_point(@new_resource.mount_point)
          @current_resource.device(@new_resource.device)
          mounted?
          enabled?
        end
        
        def mountable?
          # only check for existence of non-remote devices
          if (device_should_exist? && !::File.exists?(device_real) )
            raise Chef::Exceptions::Mount, "Device #{@new_resource.device} does not exist"
          elsif( !::File.exists?(@new_resource.mount_point) )
            raise Chef::Exceptions::Mount, "Mount point #{@new_resource.mount_point} does not exist"
          end
          return true
        end
        
        def enabled?
          # Check to see if there is a entry in /etc/vfstab. Last entry for a volume wins.
          enabled = false
          ::File.foreach("/etc/vfstab") do |line|
            case line
            when /^[#\s]/
              next

            # vfstab format: 
            # device         device          mount           FS      fsck    mount   mount
            # to mount       to fsck         point           type    pass    at boot options
            when /^#{device_vfstab_regex}\s+[-\/\w]+\s+#{Regexp.escape(@new_resource.mount_point)}\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/
              enabled = true
              @current_resource.fstype($1)
              if $2 == "-" 
                pass = 0
              else
                pass = $2.to_i
              end
              @current_resource.pass(pass)
              no_auto_option = ($3 == "yes") 
              options = $4
              if no_auto_option
                if options.nil? || options.empty? 
                  options = "noauto"
                else
                  options += ",nouauto"
                end
              end
              @current_resource.options(options)
              Chef::Log.debug("Found mount #{device_fstab} to #{@new_resource.mount_point} in /etc/vfstab")
              next
            when /^[-\/\w]+[-\/\w]+\s+\s+#{Regexp.escape(@new_resource.mount_point)}\s+/
              enabled = false
              Chef::Log.debug("Found conflicting mount point #{@new_resource.mount_point} in /etc/vfstab")
            end
          end
          @current_resource.enabled(enabled)
        end
        
        def mounted?
          mounted = false
          shell_out!("mount").stdout.each_line do |line|
            case line
            when /^#{Regexp.escape(@new_resource.mount_point)}\s+on\s+#{device_mount_regex}/
              mounted = true
              Chef::Log.debug("Special device #{device_logstring} mounted as #{@new_resource.mount_point}")
            when /^#{Regexp.escape(@new_resource.mount_point)}\son\s([\/\w])+\s+/
              mounted = false
              Chef::Log.debug("Special device #{$~[1]} mounted as #{@new_resource.mount_point}")
            end
          end
          @current_resource.mounted(mounted)
          Chef::Log.debug("MOUNTED? #{mounted}")
        end

        def mount_fs
          unless @current_resource.mounted
            mountable?
            actual_options = unless @new_resource.options.nil?
              @new_resource.options(@new_resource.options.delete("noauto"))
            end
            command = "mount -F #{@new_resource.fstype}"
            command << " -o #{actual_options.join(',')}" unless actual_options.nil?  || actual_options.empty?
            command << " #{device_real}"
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
            Chef::Log.debug("#{@current_resource} is already enabled - nothing to do")
            return nil
          end
          
          if @current_resource.enabled
            # The current options don't match what we have, so
            # disable, then enable.
            disable_fs
          end
          ::File.open("/etc/vfstab", "a") do |fstab|
                auto = @new_resource.options.nil? || ! @new_resource.options.include?("noauto")
                actual_options = unless @new_resource.options.nil?  
                  @new_resource.options.delete("noauto")
                  @new_resource.options
                end 
		fstab.puts("#{device_fstab}\t-\t#{@new_resource.mount_point}\t#{@new_resource.fstype}\t#{@new_resource.pass == 0 ? "-" : @new_resource.pass}\t#{ auto ? :yes : :no }\t #{(actual_options.nil? || actual_options.empty?) ? "-" : actual_options.join(',')}")
            Chef::Log.debug("#{@new_resource} is enabled at #{@new_resource.mount_point}")
          end
        end

        def disable_fs
          if @current_resource.enabled
            contents = []
            
            found = false
            ::File.readlines("/etc/vfstab").reverse_each do |line|
              if !found && line =~ /^#{device_vfstab_regex}\s+[-\/\w]+\s+#{Regexp.escape(@new_resource.mount_point)}/
                found = true
                Chef::Log.debug("#{@new_resource} is removed from vfstab")
                next
              else
                contents << line
              end
            end
            
            ::File.open("/etc/vfstab", "w") do |fstab|
              contents.reverse_each { |line| fstab.puts line}
            end
          else
            Chef::Log.debug("#{@new_resource} is not enabled - nothing to do")
          end
        end

        def device_should_exist?
          @new_resource.device !~ /:/ && @new_resource.device !~ /\/\// && @new_resource.device != "tmpfs" && @new_resource.fstype != 'fuse'
        end

        private

        def device_fstab
          case @new_resource.device_type
          when :device
            @new_resource.device
          else
            Chef::Log.error("Mount resource can only be of of device_type ':device' on Solaris")
          end
        end



        def device_real
          if @real_device == nil 
            if @new_resource.device_type == :device
              @real_device = @new_resource.device
            else
              Chef::Log.error("Mount resource can only be of of device_type ':device' on Solaris")
            end
          end
          @real_device
        end

        def device_logstring
          case @new_resource.device_type
          when :device
            "#{device_real}"
          else
              Chef::Log.error("Mount resource can only be of of device_type ':device' on Solaris")
          end
        end

        def device_mount_regex
          ::File.symlink?(device_real) ? "(?:#{Regexp.escape(device_real)})|(?:#{Regexp.escape(::File.readlink(device_real))})" : Regexp.escape(device_real)
        end

        def device_vfstab_regex
          if @new_resource.device_type == :device
            device_mount_regex
          else
            Chef::Log.error("Mount resource can only be of of device_type ':device' on Solaris")
          end
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
