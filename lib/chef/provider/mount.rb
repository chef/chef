#
# Author:: Joshua Timberman (<joshua@chef.io>)
# Author:: Lamont Granquist (<lamont@chef.io>)
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

require_relative "../log"
require_relative "../provider"

class Chef
  class Provider
    class Mount < Chef::Provider

      attr_accessor :unmount_retries

      def load_current_resource
        true
      end

      def initialize(new_resource, run_context)
        super
        self.unmount_retries = 20
      end

      action :mount do
        unless current_resource.mounted
          converge_by("mount #{current_resource.device} to #{current_resource.mount_point}") do
            mount_fs
            logger.info("#{new_resource} mounted")
          end
        else
          logger.debug("#{new_resource} is already mounted")
        end
      end

      action :umount do
        if current_resource.mounted
          converge_by("unmount #{current_resource.device}") do
            umount_fs
            logger.info("#{new_resource} unmounted")
          end
        else
          logger.debug("#{new_resource} is already unmounted")
        end
      end

      action :remount do
        if current_resource.mounted
          if new_resource.supports[:remount]
            converge_by("remount #{current_resource.device}") do
              remount_fs
              logger.info("#{new_resource} remounted")
            end
          else
            converge_by("unmount #{current_resource.device}") do
              umount_fs
              logger.info("#{new_resource} unmounted")
            end
            wait_until_unmounted(unmount_retries)
            converge_by("mount #{current_resource.device}") do
              mount_fs
              logger.info("#{new_resource} mounted")
            end
          end
        else
          logger.debug("#{new_resource} not mounted, nothing to remount")
        end
      end

      action :enable do
        unless current_resource.enabled && mount_options_unchanged? && device_unchanged?
          converge_by("enable #{current_resource.device}") do
            enable_fs
            logger.info("#{new_resource} enabled")
          end
        else
          logger.debug("#{new_resource} already enabled")
        end
      end

      action :disable do
        if current_resource.enabled
          converge_by("disable #{current_resource.device}") do
            disable_fs
            logger.info("#{new_resource} disabled")
          end
        else
          logger.debug("#{new_resource} already disabled")
        end
      end

      alias :action_unmount :action_umount

      #
      # Abstract Methods to be implemented by subclasses
      #

      # should actually check if the filesystem is mounted (not just return current_resource) and return true/false
      def mounted?
        raise Chef::Exceptions::UnsupportedAction, "#{self} does not implement #mounted?"
      end

      # should check new_resource against current_resource to see if mount options need updating, returns true/false
      def mount_options_unchanged?
        raise Chef::Exceptions::UnsupportedAction, "#{self} does not implement #mount_options_unchanged?"
      end

      # It's entirely plausible that a site might prefer UUIDs or labels, so
      # we need to be able to update fstab to conform with their wishes
      # without necessarily needing to remount the device.
      # See #6851 for more.
      # We have to compare current resource device with device_fstab value
      # because entry in /etc/fstab will be as per device_type.
      # For Ex: 'LABEL=/tmp/ /mnt ext3 defaults 0 2', where 'device_type' is :label.
      def device_unchanged?
        @current_resource.device == device_fstab
      end

      #
      # NOTE: for the following methods, this superclass will already have checked if the filesystem is
      # enabled and/or mounted and they will be called in converge_by blocks, so most defensive checking
      # does not need to be done in the subclass implementation -- just do the thing.
      #

      # should implement mounting of the filesystem, raises if action does not succeed
      def mount_fs
        raise Chef::Exceptions::UnsupportedAction, "#{self} does not support :mount"
      end

      # should implement unmounting of the filesystem, raises if action does not succeed
      def umount_fs
        raise Chef::Exceptions::UnsupportedAction, "#{self} does not support :umount"
      end

      # should implement remounting of the filesystem (via a -o remount or some other atomic-ish action that isn't
      # simply a umount/mount style remount), raises if action does not succeed
      def remount_fs
        raise Chef::Exceptions::UnsupportedAction, "#{self} does not support :remount"
      end

      # should implement enabling of the filesystem (e.g. in /etc/fstab), raises if action does not succeed
      def enable_fs
        raise Chef::Exceptions::UnsupportedAction, "#{self} does not support :enable"
      end

      # should implement disabling of the filesystem (e.g. in /etc/fstab), raises if action does not succeed
      def disable_fs
        raise Chef::Exceptions::UnsupportedAction, "#{self} does not support :disable"
      end

      private

      def wait_until_unmounted(tries)
        while mounted?
          if (tries -= 1) < 0
            raise Chef::Exceptions::Mount, "Retries exceeded waiting for filesystem to unmount"
          end

          sleep 0.1
        end
      end

      # Returns the new_resource device as per device_type
      def device_fstab
        # Removed "/" from the end of str unless it's a network mount, because it was causing idempotency issue.
        device =
          if @new_resource.device == "/" || @new_resource.device.match?(":/$")
            @new_resource.device
          else
            @new_resource.device.chomp("/")
          end
        case @new_resource.device_type
        when :device
          device
        when :label
          "LABEL=#{device}"
        when :uuid
          "UUID=#{device}"
        end
      end
    end
  end
end
