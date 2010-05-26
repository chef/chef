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

require 'chef/provider/file'
require 'chef/provider/directory'
#require 'chef/rest'
#require 'chef/mixin/find_preferred_file'
require 'chef/resource/directory'
require 'chef/resource/remote_file'
require 'chef/platform'
require 'uri'
require 'tempfile'
require 'net/https'
require 'set'

class Chef
  class Provider
    class RemoteDirectory < Chef::Provider::Directory

      include ::Chef::Mixin::FindPreferredFile
      
      def action_create
        super
        do_recursive
      end
    
      protected
      
      def do_recursive
        if Chef::Config[:solo]
          Chef::Log.debug("Doing a local recursive directory copy for #{@new_resource}")
        else
          Chef::Log.debug("Doing a remote recursive directory transfer for #{@new_resource}")
        end
          
        existing_files = Set.new Dir[::File.join(@new_resource.path, '**', '*')]

        files_to_transfer.each do |cookbook_file_relative_path|
          create_cookbook_file(cookbook_file_relative_path)
          existing_files.delete(::File.join(@new_resource.path, cookbook_file_relative_path))
        end
        if @new_resource.purge
          existing_files.sort { |a,b| b <=> a }.each do |f|
            if ::File.directory?(f)
              Chef::Log.debug("Removing directory #{f}")
              Dir::rmdir(f)
            else
              Chef::Log.debug("Deleting file #{f}")
              ::File.delete(f)
            end
          end
        end
      end
      
      def files_to_transfer
        file_list = Dir[directory_root_in_cookbook_cache + '/**/*'].sort.reverse.select do |file|
          file[/^#{directory_root_in_cookbook_cache}\/(.+)$/, 1] unless ::File.directory?(file)
        end
        Chef::Log.debug("Generated file manifest for #{@new_resource}:\n#{file_list.join("\n")}")
        file_list
      end
      
      def directory_root_in_cookbook_cache
        @directory_root_in_cookbook_cache ||= begin
          cookbook = run_context.cookbook_collection[resource_cookbook]
          cookbook.preferred_filename_on_disk_location(node, :files, @new_resource.source, @new_resource.path)
        end
      end
      
      # def generate_solo_file_list
      #   # Pulled from chef-server-slice files controller
      #   directory = find_preferred_file(
      #     @new_resource.cookbook_name, 
      #     :remote_file, 
      #     @new_resource.source, 
      #     @node[:fqdn],
      #     @node[:platform],
      #     @node[:platform_version]
      #   )
      # 
      #   unless (directory && ::File.directory?(directory))
      #     raise NotFound, "Cannot find a suitable directory"
      #   end
      # 
      #   file_list = Array.new
      #   Dir[::File.join(directory, '**', '*')].sort.reverse.select do |file|
      #     unless ::File.directory?(file)
      #       file_list << file[/^#{directory}\/(.+)$/, 1]
      #     end
      #   end
      #   file_list
      # end
      
      # def generate_client_file_list
      #   r = Chef::REST.new(Chef::Config[:remotefile_url])
      #   r.get_rest(generate_url(@new_resource.source, "files", { :recursive => "true" }))
      # end
      
      def fetch_remote_file(remote_file_source)
        full_path = ::File.join(@new_resource.path, remote_file_source)
        
        ensure_directory_exists(::File.dirname(full_path))
        
        file_to_fetch = cookbook_file_resource(full_path, remote_file_source)
        file_to_fetch.run_action(:create)
        @new_resource.updated = true if file_to_fetch.new_resource.updated        
      end
      
      def cookbook_file_resource(path, source)
        cookbook_file = Chef::Resource::CookbookFile.new(path, @run_context)
        cookbook_file.cookbook_name = @new_resource.cookbook || @new_resource.cookbook_name
        cookbook_file.source(::File.join(@new_resource.source, source))
        cookbook_file.mode(@new_resource.files_mode) if @new_resource.files_mode
        cookbook_file.group(@new_resource.files_group) if @new_resource.files_group
        cookbook_file.owner(@new_resource.files_owner) if @new_resource.files_owner
        cookbook_file.backup(@new_resource.files_backup) if @new_resource.files_backup
        
        cookbook_file
        #Chef::Platform.provider_for_node(@node, remote_file)
      end
      
      def ensure_directory_exists(path)
        unless ::File.directory?(path)
          directory_to_create = provider_for_directory(path)
          directory_to_create.load_current_resource
          directory_to_create.action_create
          @new_resource.updated = true if directory_to_create.new_resource.updated  
        end
      end
      
      def provider_for_directory(path)
        new_dir = Chef::Resource::Directory.new(path, nil, @node)
        new_dir.cookbook_name = @new_resource.cookbook || @new_resource.cookbook_name            
        new_dir.mode(@new_resource.mode)
        new_dir.group(@new_resource.group)
        new_dir.owner(@new_resource.owner)
        new_dir.recursive(true)
        
        Chef::Platform.provider_for_node(@node, new_dir)
      end
            
      def action_create_if_missing
        raise Chef::Exceptions::UnsupportedAction, "Remote Directories do not support create_if_missing."
      end

    end
  end
end
