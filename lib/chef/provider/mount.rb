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

require 'chef/log'
require 'chef/mixin/command'
require 'chef/provider'

class Chef
  class Provider
    class Mount < Chef::Provider

      include Chef::Mixin::Command


      def whyrun_supported?
        true
      end

      def load_current_resource
        true
      end

      def action_mount
        unless @current_resource.mounted
          converge_by("mount #{@current_resource.device} to #{@current_resource.mount_point}") do 
            status = mount_fs()
            if status
              Chef::Log.info("#{@new_resource} mounted")
            end
          end
        else
          Chef::Log.debug("#{@new_resource} is already mounted")
        end
      end

      def action_umount
        if @current_resource.mounted
          converge_by("unmount #{@current_resource.device}") do 
            status = umount_fs()
            if status
              Chef::Log.info("#{@new_resource} unmounted")
            end
          end
        else
          Chef::Log.debug("#{@new_resource} is already unmounted")
        end
      end

      def action_remount
        unless @new_resource.supports[:remount]
          raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :remount"
        else
          if @current_resource.mounted
            converge_by("remount #{@current_resource.device}") do 
              status = remount_fs()
              if status
                Chef::Log.info("#{@new_resource} remounted")
              end
            end
          else
            Chef::Log.debug("#{@new_resource} not mounted, nothing to remount")
          end
        end
      end

      def action_enable
        unless @current_resource.enabled && mount_options_unchanged?
          converge_by("remount #{@current_resource.device}") do 
            status = enable_fs
            if status
              Chef::Log.info("#{@new_resource} enabled")
            else
              Chef::Log.debug("#{@new_resource} already enabled")
            end
          end
        end
      end

      def action_disable
        if @current_resource.enabled
          converge_by("remount #{@current_resource.device}") do 
            status = disable_fs
            if status
              Chef::Log.info("#{@new_resource} disabled")
            else
              Chef::Log.debug("#{@new_resource} already disabled")
            end
          end
        end
      end

      def mount_fs
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :mount"
      end

      def umount_fs
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :umount"
      end

      def remount_fs
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :remount"
      end
      
      def enable_fs
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :enable"        
      end
      
      def disable_fs
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :disable"        
      end      
    end
  end
end
