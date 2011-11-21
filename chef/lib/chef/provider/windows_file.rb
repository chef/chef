#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'chef/provider/file'
require 'chef/mixin/checksum'
require 'chef/win32/file'
require 'chef/win32/security'
require 'chef/windows_file_access_control'

class Chef
  class Provider
    class WindowsFile < Chef::Provider::File
      include Chef::Mixin::Checksum

      def load_current_resource
        @current_resource = Chef::Resource::WindowsFile.new(@new_resource.name)
        @new_resource.path.gsub!(/\\/, "/") # for Windows
        @current_resource.path(@new_resource.path)

        # TODO ADD NEW Win32 SECURITY HOOKS HERE
        if ::File.exist?(@current_resource.path) && ::File.readable?(@current_resource.path)
          # @current_resource.owner()
          # @current_resource.group()
          # @current_resource.rights()
        end
        # if ::File.exist?(@current_resource.path) && ::File.readable?(@current_resource.path)
        #   #cstats = ::File.stat(@current_resource.path)
        #   @current_resource.owner(cstats.uid)
        #   @current_resource.group(cstats.gid)
        #   @current_resource.mode(octal_mode(cstats.mode))
        # end

        @current_resource
      end

      # Set the ownership on the file, assuming it is not set correctly already.
      def set_owner
        # TODO REMOVE THIS STUB
      end

      def set_group
        # TODO REMOVE THIS STUB
      end

      def set_mode
        # TODO REMOVE THIS STUB
      end

      def set_rights
        # TODO IMPLEMENT
      end

      def set_all_access_controls(file)
        modified = Chef::WindowsFileAccessControl.apply_security_policy(@new_resource, file)
        @new_resource.updated_by_last_action(modified)
      end

      def action_create
        super
        set_all_access_controls(@new_resource.path) unless @new_resource.rights.nil?
      end

      def action_create_if_missing
        super
      end

      def action_delete
        super
      end

      def action_touch
        super
      end

    end
  end
end
