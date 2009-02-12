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

require 'chef/config'
require 'chef/log'
require 'chef/resource/file'
require 'chef/mixin/checksum'
require 'chef/mixin/generate_url'
require 'chef/provider'
require 'etc'
require 'fileutils'

class Chef
  class Provider
    class File < Chef::Provider
      include Chef::Mixin::Checksum
      include Chef::Mixin::GenerateURL
      
      def load_current_resource
        @current_resource = Chef::Resource::File.new(@new_resource.name)
        @current_resource.path(@new_resource.path)
        if ::File.exist?(@current_resource.path) && ::File.readable?(@current_resource.path)
          cstats = ::File.stat(@current_resource.path)
          @current_resource.owner(cstats.uid)
          @current_resource.group(cstats.gid)
          @current_resource.mode("%o" % (cstats.mode & 007777))
          @current_resource.checksum(checksum(@current_resource.path))
        end
        @current_resource
      end
      
      # Compare the ownership of a file.  Returns true if they are the same, false if they are not.
      def compare_owner
        if @new_resource.owner != nil
          case @new_resource.owner
          when /^\d+$/, Integer
            @set_user_id = @new_resource.owner.to_i
            @set_user_id == @current_resource.owner
          else
            # This raises an ArugmentError if you can't find the user         
            user_info = Etc.getpwnam(@new_resource.owner)
            @set_user_id = user_info.uid
            @set_user_id == @current_resource.owner
          end
        end
      end
      
      # Set the ownership on the file, assuming it is not set correctly already.
      def set_owner
        unless compare_owner
          Chef::Log.info("Setting owner to #{@set_user_id} for #{@new_resource}")
          ::File.chown(@set_user_id, nil, @new_resource.path)
          @new_resource.updated = true
        end
      end
      
      # Compares the group of a file.  Returns true if they are the same, false if they are not.
      def compare_group
        if @new_resource.group != nil
          case @new_resource.group
          when /^\d+$/, Integer
            @set_group_id = @new_resource.group.to_i
            @set_group_id == @current_resource.group
          else
            group_info = Etc.getgrnam(@new_resource.group)
            @set_group_id = group_info.gid
            @set_group_id == @current_resource.group
          end
        end
      end
      
      def set_group
        unless compare_group
          Chef::Log.info("Setting group to #{@set_group_id} for #{@new_resource}")
          ::File.chown(nil, @set_group_id, @new_resource.path)
          @new_resource.updated = true
        end
      end
      
      def compare_mode
        if @new_resource.mode != nil
          case @new_resource.mode
          when /^\d+$/, Integer
            real_mode = sprintf("%o" % (@new_resource.mode & 007777))
            real_mode.to_i == @current_resource.mode.to_i
          end
        end
      end
      
      def set_mode
        unless compare_mode && @new_resource.mode != nil
          Chef::Log.info("Setting mode to #{sprintf("%o" % (@new_resource.mode & 007777))
          } for #{@new_resource}")
          ::File.chmod(@new_resource.mode.to_i, @new_resource.path)
          @new_resource.updated = true
        end
      end
      
      def action_create
        unless ::File.exists?(@new_resource.path)
          Chef::Log.info("Creating #{@new_resource} at #{@new_resource.path}")
          ::File.open(@new_resource.path, "w+") { |f| }
          @new_resource.updated = true
        end
        set_owner if @new_resource.owner != nil
        set_group if @new_resource.group != nil
        set_mode if @new_resource.mode != nil
      end
      
      def action_create_if_missing
        action_create
      end
      
      def action_delete
        if ::File.exists?(@new_resource.path) && ::File.writable?(@new_resource.path)
          backup
          Chef::Log.info("Deleting #{@new_resource} at #{@new_resource.path}")
          ::File.delete(@new_resource.path)
          @new_resource.updated = true
        else
          raise "Cannot delete #{@new_resource} at #{@new_resource_path}!"
        end
      end
      
      def action_touch
        action_create
        time = Time.now
        Chef::Log.info("Updating #{@new_resource} with new atime/mtime of #{time}")
        ::File.utime(time, time, @new_resource.path)
        @new_resource.updated = true
      end
      
      def backup(file=nil)
        file ||= @new_resource.path
        if @new_resource.backup && ::File.exist?(file)
          time = Time.now
          savetime = time.strftime("%Y%m%d%H%M%S")
          backup_filename = "#{@new_resource.path}.chef-#{savetime}"
          Chef::Log.info("Backing up #{@new_resource} to #{backup_filename}")
          FileUtils.cp(file, backup_filename)
          
          # Clean up after the number of backups
          slice_number = @new_resource.backup - 1
          backup_files = Dir["#{@new_resource.path}.chef-*"].sort { |a,b| b <=> a }
          if backup_files.length >= @new_resource.backup
            remainder = backup_files.slice(slice_number..-1)
            remainder.each do |backup_to_delete|
              Chef::Log.info("Removing backup of #{@new_resource} at #{backup_to_delete}")
              FileUtils.rm(backup_to_delete)
            end
          end

        end
      end
      
      def generate_url(url, type, args=nil)
        cookbook_name = @new_resource.cookbook || @new_resource.cookbook_name
        generate_cookbook_url(url, cookbook_name, type, @node, args)
      end
      
    end
  end
end