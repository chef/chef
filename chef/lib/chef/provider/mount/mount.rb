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
            
        def initialize(node, new_resource)
          super(node, new_resource)
        end
            
        def load_current_resource
          @current_resource = Chef::Resource::Mount.new(@new_resource.name)
          @current_resource.mount_point(@new_resource.mount_point)
          Chef::Log.debug("Checking for mount point #{@current_resource.mount_point}")
          popen4("mount") do |pid, stdin, stdout, stderr|
            stdout.each do |line|
              case line
              when /^#{@new_resource.device}\s+on\s+#{@new_resource.mount_point}/
                @current_resource.mounted(true)
                Chef::Log.debug("Special device #{@new_resource.device} mounted as #{@new_resource.mount_point}")
              end
            end
          end
          # revisit for enable/disable
          # File.read("/etc/fstab").each do |line|
          #   case line
          #   when /^[#\s]/
          #     next
          #   when /^[\/\w]+#{@new_resource.mount_point}/
          #     @mount_exists = true
          #     Chef::Log.debug("Found mount point #{@new_resource.mount_point} in /etc/fstab")
          #   end
          # end
          @current_resource
        end
      
        def mount_fs
          unless @current_resource.mounted
            if @new_resource.options
              command = "mount -t #{@new_resource.fstype} -o #{@new_resource.options} "
            else
              command = "mount -t #{@new_resource.fstype} "
            end
            command << "#{@new_resource.device} "
            command << "#{@new_resource.mount_point} "
            run_command(:command => command)
            Chef::Log.info("Mounted #{@new_resource.mount_point}")
          end
        end
      
        def umount_fs
          if @current_resource.mounted
            command = "umount #{@new_resource.mount_point}"
            run_command(:command => command)
            Chef::Log.info("Unmounted #{@new_resource.mount_point}")
          end
        end
            
        def remount_fs
          if @current_resource.mounted and @new_resource.supports[:remount]
            command = "mount -o remount #{@new_resource.mount_point}"
            run_command(:command => command)
            Chef::Log.info("Remounted #{@new_resource.mount_point}")
          # elsif @mounted 
          #   umount_fs
          #   mount_fs
          # else
          #   Chef::Log.info("#{@new_resource.mount_point} is not mounted.")
          end
        end
      
        # def action_enable, action_disable, future feature/improvement.
      end
    end
  end
end
