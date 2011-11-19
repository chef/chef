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
#require 'chef/win32/security'
#require 'chef/windows_file_access_control'

class Chef
  class Provider
    class WindowsFile < Chef::Provider::File
      include Chef::Mixin::Checksum

      def load_current_resource
        @current_resource = Chef::Resource::WindowsFile.new(@new_resource.name)
        @new_resource.path.gsub!(/\\/, "/") # for Windows
        @current_resource.path(@new_resource.path)

        # TODO ADD NEW Win32 SECURITY HOOKS HERE

        # if ::File.exist?(@current_resource.path) && ::File.readable?(@current_resource.path)
        #   cstats = ::File.stat(@current_resource.path)
        #   @current_resource.owner(cstats.uid)
        #   @current_resource.group(cstats.gid)
        #   @current_resource.mode(octal_mode(cstats.mode))
        # end
        @current_resource
      end

      # Compare the ownership of a file.  Returns true if they are the same, false if they are not.
      def compare_owner
        return false if @new_resource.owner.nil?

        # TODO REIMPLEMENT Win32 VERSION

        # @set_user_id = case @new_resource.owner
        # when /^\d+$/, Integer
        #   @new_resource.owner.to_i
        # else
        #   # This raises an ArgumentError if you can't find the user
        #   Etc.getpwnam(@new_resource.owner).uid
        # end

        # @set_user_id == @current_resource.owner
      end

      # Set the ownership on the file, assuming it is not set correctly already.
      def set_owner
        # TODO REIMPLEMENT Win32 VERSION

        # unless compare_owner
        #   @set_user_id = negative_complement(@set_user_id)
        #   ::File.chown(@set_user_id, nil, @new_resource.path)
        #   Chef::Log.info("#{@new_resource} owner changed to #{@set_user_id}")
        #   @new_resource.updated_by_last_action(true)
        # end
      end

      # Compares the group of a file.  Returns true if they are the same, false if they are not.
      def compare_group
        # TODO REIMPLEMENT Win32 VERSION

        # return false if @new_resource.group.nil?

        # @set_group_id = case @new_resource.group
        # when /^\d+$/, Integer
        #   @new_resource.group.to_i
        # else
        #   Etc.getgrnam(@new_resource.group).gid
        # end

        # @set_group_id == @current_resource.group
      end

      def set_group
        # TODO REIMPLEMENT Win32 VERSION

        # unless compare_group
        #   @set_group_id = negative_complement(@set_group_id)
        #   ::File.chown(nil, @set_group_id, @new_resource.path)
        #   Chef::Log.info("#{@new_resource} group changed to #{@set_group_id}")
        #   @new_resource.updated_by_last_action(true)
        # end
      end

      def compare_mode
        # TODO REIMPLEMENT Win32 VERSION

        # case @new_resource.mode
        # when /^\d+$/, Integer
        #   octal_mode(@new_resource.mode) == octal_mode(@current_resource.mode)
        # else
        #   false
        # end
      end

      def set_mode
        # TODO REIMPLEMENT Win32 VERSION

        # unless compare_mode && @new_resource.mode != nil
        #   # CHEF-174, bad mojo around treating integers as octal.  If a string is passed, we try to do the "right" thing
        #   ::File.chmod(octal_mode(@new_resource.mode), @new_resource.path)
        #   Chef::Log.info("#{@new_resource} mode changed to #{sprintf("%o" % octal_mode(@new_resource.mode))}")
        #   @new_resource.updated_by_last_action(true)
        # end
      end

      def set_rights
        # TODO IMPLEMENT
      end

      def action_create
        super
        set_rights unless @new_resource.rights.nil?
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
