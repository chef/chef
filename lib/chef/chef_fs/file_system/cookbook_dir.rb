#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'chef/chef_fs/file_system/rest_list_dir'
require 'chef/chef_fs/file_system/cookbook_subdir'
require 'chef/chef_fs/file_system/cookbook_file'
require 'chef/chef_fs/file_system/not_found_error'
require 'chef/cookbook_version'
require 'chef/cookbook_uploader'

class Chef
  module ChefFS
    module FileSystem
      class CookbookDir < BaseFSDir
        def initialize(name, parent, options = {})
          super(name, parent)
          @existance     = options[:existance]
          @cookbook_name = options[:cookbook_name]
          @version       = options[:version] || "_latest"
        end

        attr_reader :existance, :cookbook_name, :version

        COOKBOOK_SEGMENT_INFO = {
          :attributes => { :ruby_only => true },
          :definitions => { :ruby_only => true },
          :recipes => { :ruby_only => true },
          :libraries => { :ruby_only => true },
          :templates => { :recursive => true },
          :files => { :recursive => true },
          :resources => { :ruby_only => true, :recursive => true },
          :providers => { :ruby_only => true, :recursive => true },
          :root_files => { }
        }

        # See Erchef code
        # https://github.com/opscode/chef_objects/blob/968a63344d38fd507f6ace05f73d53e9cd7fb043/src/chef_regex.erl#L94
        VALID_VERSIONED_COOKBOOK_NAME = /^([.a-zA-Z0-9_-]+)-(\d+\.\d+\.\d+)$/

        def add_child(child)
          @children << child
        end

        def api_path
          "#{parent.api_path}/#{cookbook_name}/#{version}"
        end

        def child(name)
          # Since we're ignoring the rules and doing a network request here,
          # we need to make sure we don't rethrow the exception.  (child(name)
          # is not supposed to fail.)
          begin
            result = children.select { |child| child.name == name }.first
            return result if result
          rescue Chef::ChefFS::FileSystem::NotFoundError
          end
          return NonexistentFSObject.new(name, self)
        end

        def can_have_child?(name, is_dir)
          # A cookbook's root may not have directories unless they are segment directories
          return name != 'root_files' && COOKBOOK_SEGMENT_INFO.keys.include?(name.to_sym) if is_dir
          return true
        end

        def children
          if @children.nil?
            @children = []
            manifest = chef_object.manifest
            COOKBOOK_SEGMENT_INFO.each do |segment, segment_info|
              next unless manifest.has_key?(segment)

              # Go through each file in the manifest for the segment, and
              # add cookbook subdirs and files for it.
              manifest[segment].each do |segment_file|
                parts = segment_file[:path].split('/')
                # Get or create the path to the file
                container = self
                parts[0,parts.length-1].each do |part|
                  old_container = container
                  container = old_container.children.select { |child| part == child.name }.first
                  if !container
                    container = CookbookSubdir.new(part, old_container, segment_info[:ruby_only], segment_info[:recursive])
                    old_container.add_child(container)
                  end
                end
                # Create the file itself
                container.add_child(CookbookFile.new(parts[parts.length-1], container, segment_file))
              end
            end
            @children = @children.sort_by { |c| c.name }
          end
          @children
        end

        def dir?
          exists?
        end

        def delete(recurse)
          if recurse
            begin
              rest.delete_rest(api_path)
            rescue Net::HTTPServerException
              if $!.response.code == "404"
                raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
              end
            end
          else
            raise NotFoundError.new(self) if !exists?
            raise MustDeleteRecursivelyError.new(self), "#{path_for_printing} must be deleted recursively"
          end
        end

        # In versioned cookbook mode, actually check if the version exists
        # Probably want to cache this.
        def exists?
          return @existance unless @existance.nil?
          child = parent.child(name, :force => true)
          if child
            @existance = child.existance
            @version = child.version
          end
          !!@existance
        end

        def compare_to(other)
          if !other.dir?
            return [ !exists?, nil, nil ]
          end
          are_same = true
          Chef::ChefFS::CommandLine::diff_entries(self, other, nil, :name_only) do |type, old_entry, new_entry|
            if [ :directory_to_file, :file_to_directory, :deleted, :added, :modified ].include?(type)
              are_same = false
            end
          end
          [ are_same, nil, nil ]
        end

        def copy_from(other)
          parent.upload_cookbook_from(other)
        end

        def rest
          parent.rest
        end

        def chef_object
          # We cheat and cache here, because it seems like a good idea to keep
          # the cookbook view consistent with the directory structure.
          return @chef_object if @chef_object

          # The negative (not found) response is cached
          if @could_not_get_chef_object
            raise Chef::ChefFS::FileSystem::NotFoundError.new(self, @could_not_get_chef_object)
          end

          begin
            # We want to fail fast, for now, because of the 500 issue :/
            # This will make things worse for parallelism, a little, because
            # Chef::Config is global and this could affect other requests while
            # this request is going on.  (We're not parallel yet, but we will be.)
            # Chef bug http://tickets.opscode.com/browse/CHEF-3066
            old_retry_count = Chef::Config[:http_retry_count]
            begin
              Chef::Config[:http_retry_count] = 0
              @chef_object ||= rest.get_rest(api_path)
            ensure
              Chef::Config[:http_retry_count] = old_retry_count
            end
          rescue Net::HTTPServerException
            if $!.response.code == "404"
              @could_not_get_chef_object = $!
              raise Chef::ChefFS::FileSystem::NotFoundError.new(self, @could_not_get_chef_object)
            else
              raise
            end

          # Chef bug http://tickets.opscode.com/browse/CHEF-3066 ... instead of 404 we get 500 right now.
          # Remove this when that bug is fixed.
          rescue Net::HTTPFatalError
            if $!.response.code == "500"
              @could_not_get_chef_object = $!
              raise Chef::ChefFS::FileSystem::NotFoundError.new(self, @could_not_get_chef_object)
            else
              raise
            end
          end
        end
      end
    end
  end
end
