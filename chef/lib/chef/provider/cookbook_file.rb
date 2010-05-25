#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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
require 'tempfile'

class Chef
  class Provider
    class CookbookFile < Chef::Provider::File
      
      def action_create
         if file_cache_location
           Chef::Log.debug("content of file #{@new_resource.path} requires update")
           backup_new_resource
           Tempfile.open(@new_resource.name) do |staging_file|
             Chef::Log.debug("staging #{file_cache_location} to #{staging_file.path}")
             staging_file.close
             stage_file_to_tmpdir(staging_file.path)
             FileUtils.mv(staging_file.path, @new_resource.path)
           end
           @new_resource.updated = true
         else
           set_all_access_controls(@new_resource.path)
         end
         @new_resource.updated
       end

      def action_create_if_missing
        if ::File.exists?(@new_resource.path)
          Chef::Log.debug("File #{@new_resource.path} exists, taking no action.")
        else
          action_create
        end
      end
      
      def file_cache_location
        @file_cache_location ||= begin
          cookbook = run_context.cookbook_collection[resource_cookbook]
          cookbook.preferred_filename_on_disk_location(node, :files, @new_resource.source, @new_resource.path)
        end
      end
      
      # Determine the cookbook to get the file from. If new resource sets an 
      # explicit cookbook, use it, otherwise fall back to the implicit cookbook
      # i.e., the cookbook the resource was declared in.
      def resource_cookbook
        @new_resource.cookbook || @new_resource.cookbook_name
      end
      
      # Copy the file from the cookbook cache to a temporary location and then
      # set its file access control settings.
      def stage_file_to_tmpdir(staging_file_location)
        FileUtils.cp(file_cache_location, staging_file_location)
        set_all_access_controls(staging_file_location)
      end

      def set_all_access_controls(file)
        access_controls = FileAccessControl.new(@new_resource, file)
        access_controls.set_all
        @new_resource.updated = access_controls.modified?
      end

      def backup_new_resource
        if ::File.exists?(@new_resource.path)
          Chef::Log.info "Backing up current file at #{@new_resource.path}"
          backup @new_resource.path
        end
      end

      class FileAccessControl
        UINT = (1 << 32)
        UID_MAX = (1 << 30)
        
        attr_reader :resource
        
        attr_reader :file
        
        # FileAccessControl objects set the owner, group and mode of +file+ to
        # the values specified by +resource+. +file+ is completely independent
        # of any file or path attribute on +resource+, so it is possible to set
        # access control settings on a tempfile (for example).
        # === Arguments:
        # resource:   probably a Chef::Resource::File object (or subclass), but
        #             this is not required. Must respond to +owner+, +group+,
        #             and +mode+
        # file:       The file whose access control settings you wish to modify,
        #             given as a String.
        def initialize(resource, file)
          @resource, @file = resource, file
          @modified = false
        end
        
        def modified?
          @modified
        end
        
        def set_all
          set_owner
          set_group
          set_mode
        end
        
        # Workaround the fact that Ruby's Etc module doesn't believe in negative
        # uids, so negative uids show up as the diminished radix complement of
        # the maximum fixnum size. For example, a uid of -2 is reported as 
        def dimished_radix_complement(int)
          if int > UID_MAX
            int - UINT
          else
            int
          end
        end
        
        def target_uid
          return nil if resource.owner.nil?
          if resource.owner.kind_of?(String)
            dimished_radix_complement( Etc.getpwnam(resource.owner).uid )
          elsif resource.owner.kind_of?(Integer)
            resource.owner
          else
            raise ArgumentError, "cannot resolve #{resource.owner.inspect} to uid, owner must be a string or integer"
          end
        rescue ArgumentError
          raise Chef::Exceptions::UserIDNotFound, "cannot resolve user id for '#{resource.owner}'"
        end
        
        def set_owner
          if (uid = target_uid) && (uid != stat.uid)
            Chef::Log.debug("setting owner on #{file} to #{uid}")
            FileUtils.chown(uid, nil, file)
            modified
          end
        end
        
        def target_gid
          return nil if resource.group.nil?
          if resource.group.kind_of?(String)
            dimished_radix_complement( Etc.getgrnam(resource.group).gid )
          elsif resource.group.kind_of?(Integer)
            resource.group
          else
            raise ArgumentError, "cannot resolve #{resource.group.inspect} to gid, group must be a string or integer"
          end
        rescue ArgumentError
          raise Chef::Exceptions::GroupIDNotFound, "cannot resolve group id for '#{resource.group}'"
        end
        
        def set_group
          if (gid = target_gid) && (gid != stat.gid)
            Chef::Log.debug("setting group on #{file} to #{gid}")
            FileUtils.chown(nil, gid, file)
            modified
          end
        end

        def target_mode
          return nil if resource.mode.nil?
          (resource.mode.respond_to?(:oct) ? resource.mode.oct : resource.mode.to_i) & 007777
        end

        def set_mode
          if (mode = target_mode) && (mode != (stat.mode & 007777))
            Chef::Log.debug("setting mode on #{file} to #{mode.to_s(8)}")
            FileUtils.chmod(target_mode, file)
            modified
          end
        end
        

        def stat
          @stat ||= ::File.stat(file)
        end
        
        private
        
        def modified
          @modified = true
        end
        
      end

    end
  end
end