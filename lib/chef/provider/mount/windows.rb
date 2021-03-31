#
# Author:: Doug MacEachern (<dougm@vmware.com>)
# Copyright:: Copyright 2010-2016, VMware, Inc.
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
if RUBY_PLATFORM.match?(/mswin|mingw32|windows/)
  require_relative "../../util/windows/net_use"
  require_relative "../../util/windows/volume"
end

class Chef
  class Provider
    class Mount
      class Windows < Chef::Provider::Mount

        provides :mount, os: "windows"

        def is_volume(name)
          /^\\\\\?\\Volume\{[\w-]+\}\\$/.match?(name) ? true : false
        end

        def initialize(new_resource, run_context)
          super
          @mount = nil
        end

        def load_current_resource
          if is_volume(@new_resource.device)
            @mount = Chef::Util::Windows::Volume.new(@new_resource.mount_point)
          else # assume network drive
            @mount = Chef::Util::Windows::NetUse.new(@new_resource.mount_point)
          end

          @current_resource = Chef::Resource::Mount.new(@new_resource.name)
          @current_resource.mount_point(@new_resource.mount_point)
          logger.trace("Checking for mount point #{@current_resource.mount_point}")

          begin
            @current_resource.device(@mount.device)
            logger.trace("#{@current_resource.device} mounted on #{@new_resource.mount_point}")
            @current_resource.mounted(true)
          rescue ArgumentError => e
            @current_resource.mounted(false)
            logger.trace("#{@new_resource.mount_point} is not mounted: #{e.message}")
          end
        end

        def mount_fs
          unless @current_resource.mounted
            @mount.add(remote: @new_resource.device,
                       username: @new_resource.username,
                       domainname: @new_resource.domain,
                       password: @new_resource.password)
            logger.trace("#{@new_resource} is mounted at #{@new_resource.mount_point}")
          else
            logger.debug("#{@new_resource} is already mounted at #{@new_resource.mount_point}")
          end
        end

        def umount_fs
          if @current_resource.mounted
            @mount.delete
            logger.trace("#{@new_resource} is no longer mounted at #{@new_resource.mount_point}")
          else
            logger.trace("#{@new_resource} is not mounted at #{@new_resource.mount_point}")
          end
        end

        private

        def mount_options_unchanged?
          @current_resource.device == @new_resource.device
        end

      end
    end
  end
end
