#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'chef/provider'
require 'chef/provider/directory'
require 'chef/file_access_control'

class Chef
  class Provider
    class WindowsDirectory < Chef::Provider::Directory
      def load_current_resource
        @current_resource = Chef::Resource::WindowsDirectory.new(@new_resource.name)
        @current_resource.path(@new_resource.path)

        # TODO ADD NEW Win32 SECURITY HOOKS HERE
        # if ::File.exist?(@current_resource.path) && ::File.directory?(@current_resource.path)
        #   cstats = ::File.stat(@current_resource.path)
        #   @current_resource.owner(cstats.uid)
        #   @current_resource.group(cstats.gid)
        #   @current_resource.mode("%o" % (cstats.mode & 007777))
        # end

        @current_resource
      end

      def set_owner
        # TODO REMOVE THIS STUB
      end

      def set_group
        # TODO REMOVE THIS STUB
      end

      def set_mode
        # TODO REMOVE THIS STUB
      end

      # TODO make a Securable mixin
      def set_all_access_controls(directory)
        access_controls = Chef::FileAccessControl.new(@new_resource, directory)
        access_controls.set_all
        @new_resource.updated_by_last_action(access_controls.modified?)
      end

      def action_create
        super
        set_all_access_controls(@new_resource.path)
      end

      def action_delete
        super
      end
    end
  end
end
