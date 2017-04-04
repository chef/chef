#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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

require "chef/chef_fs/command_line"
require "chef/chef_fs/file_system/chef_server/rest_list_dir"
require "chef/chef_fs/file_system/chef_server/cookbook_subdir"
require "chef/chef_fs/file_system/chef_server/cookbook_file"
require "chef/chef_fs/file_system/exceptions"
require "chef/cookbook_version"
require "chef/cookbook_uploader"

class Chef
  module ChefFS
    module FileSystem
      module ChefServer
        # Unversioned cookbook.
        #
        #   /cookbooks/NAME
        #
        # Children look like:
        #
        # - metadata.rb
        # - attributes/
        # - libraries/
        # - recipes/
        #
        class CookbookDir < BaseFSDir
          def initialize(name, parent, options = {})
            super(name, parent)
            @exists = options[:exists]
            @cookbook_name = name
            @version = root.cookbook_version # nil unless --cookbook-version specified in download/diff
          end

          attr_reader :cookbook_name, :version

          def add_child(child)
            @children << child
          end

          def api_path
            "#{parent.api_path}/#{cookbook_name}/#{version || "_latest"}"
          end

          def make_child_entry(name)
            # Since we're ignoring the rules and doing a network request here,
            # we need to make sure we don't rethrow the exception.  (child(name)
            # is not supposed to fail.)

            children.find { |child| child.name == name }
          rescue Chef::ChefFS::FileSystem::NotFoundError
            nil
          end

          def can_have_child?(name, is_dir)
            return name != "root_files" if is_dir
            true
          end

          def children
            if @children.nil?
              @children = []
              manifest = chef_object.cookbook_manifest
              manifest.by_parent_directory.each do |segment, files|
                files.each do |file|
                  parts = file[:path].split("/")
                  # Get or create the path to the file
                  container = self
                  parts[0, parts.length - 1].each do |part|
                    old_container = container
                    container = old_container.children.find { |child| part == child.name }
                    if !container
                      container = CookbookSubdir.new(part, old_container, false, true)
                      old_container.add_child(container)
                    end
                  end
                  # Create the file itself
                  container.add_child(CookbookFile.new(parts[parts.length - 1], container, file))
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
                rest.delete(api_path)
              rescue Timeout::Error => e
                raise Chef::ChefFS::FileSystem::OperationFailedError.new(:delete, self, e, "Timeout deleting: #{e}")
              rescue Net::HTTPServerException
                if $!.response.code == "404"
                  raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
                else
                  raise Chef::ChefFS::FileSystem::OperationFailedError.new(:delete, self, e, "HTTP error deleting: #{e}")
                end
              end
            else
              raise NotFoundError.new(self) if !exists?
              raise MustDeleteRecursivelyError.new(self, "#{path_for_printing} must be deleted recursively")
            end
          end

          # In versioned cookbook mode, actually check if the version exists
          # Probably want to cache this.
          def exists?
            if @exists.nil?
              @exists = parent.children.any? { |child| child.name == name }
            end
            @exists
          end

          def compare_to(other)
            if !other.dir?
              return [ !exists?, nil, nil ]
            end
            are_same = true
            Chef::ChefFS::CommandLine.diff_entries(self, other, nil, :name_only).each do |type, old_entry, new_entry|
              if [ :directory_to_file, :file_to_directory, :deleted, :added, :modified ].include?(type)
                are_same = false
              end
            end
            [ are_same, nil, nil ]
          end

          def copy_from(other, options = {})
            parent.upload_cookbook_from(other, options)
          end

          def rest
            Chef::ServerAPI.new(parent.rest.url, parent.rest.options.merge(version_class: Chef::CookbookManifestVersions))
          end

          def chef_rest
            Chef::ServerAPI.new(parent.chef_rest.url, parent.chef_rest.options.merge(version_class: Chef::CookbookManifestVersions))
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
                @chef_object ||= Chef::CookbookVersion.from_hash(chef_rest.get(api_path))
              ensure
                Chef::Config[:http_retry_count] = old_retry_count
              end

            rescue Timeout::Error => e
              raise Chef::ChefFS::FileSystem::OperationFailedError.new(:read, self, e, "Timeout reading: #{e}")

            rescue Net::HTTPServerException => e
              if e.response.code == "404"
                @could_not_get_chef_object = e
                raise Chef::ChefFS::FileSystem::NotFoundError.new(self, @could_not_get_chef_object)
              else
                raise Chef::ChefFS::FileSystem::OperationFailedError.new(:read, self, e, "HTTP error reading: #{e}")
              end

            # Chef bug http://tickets.opscode.com/browse/CHEF-3066 ... instead of 404 we get 500 right now.
            # Remove this when that bug is fixed.
            rescue Net::HTTPFatalError => e
              if e.response.code == "500"
                @could_not_get_chef_object = e
                raise Chef::ChefFS::FileSystem::NotFoundError.new(self, @could_not_get_chef_object)
              else
                raise Chef::ChefFS::FileSystem::OperationFailedError.new(:read, self, e, "HTTP error reading: #{e}")
              end
            end
          end
        end
      end
    end
  end
end
