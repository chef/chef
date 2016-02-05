#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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

require "chef/chef_fs/file_system/repository/chef_repository_file_system_entry"
require "chef/chef_fs/data_handler/data_bag_item_data_handler"

class Chef
  module ChefFS
    module FileSystem
      module Repository

        # Original Class/superclass
        #class ChefRepositoryFileSystemDataBagsDir < ChefRepositoryFileSystemEntry

        # With ChefRepositoryFileSystemEntry inlined:
        #class ChefRepositoryFileSystemDataBagsDir < FileSystemEntry

        # With FileSystemEntry inlined
        # class ChefRepositoryFileSystemDataBagsDir < BaseFSDir

        # With BaseFSDir inlined
        class ChefRepositoryFileSystemDataBagsDir < BaseFSObject

          # Original
          ## def initialize(name, parent, path = nil)
          ##   super(name, parent, path, Chef::ChefFS::DataHandler::DataBagItemDataHandler.new)
          ## end

          # ChefRepositoryFileSystemEntry#initialize
          ## def initialize(name, parent, file_path = nil, data_handler = nil)
          ##   super(name, parent, file_path)
          ##   @data_handler = data_handler
          ## end

          # FileSystemEntry#initialize
          ## def initialize(name, parent, file_path = nil)
          ##   super(name, parent)
          ##   @file_path = file_path || "#{parent.file_path}/#{name}"
          ## end

          # inlined initialize
          #
          # original method signature: def initialize(name, parent, file_path = nil)
          #
          # the only caller of this should never give a nil path
          def initialize(name, parent, file_path)
            super(name, parent)
            @file_path = file_path # || "#{parent.file_path}/#{name}"
            # Seems like this has to be important, but where is it used?
            #@data_handler = Chef::ChefFS::DataHandler::DataBagItemDataHandler.new
          end


          ##############################
          # Original
          ##############################

          def can_have_child?(name, is_dir)
            is_dir && !name.start_with?(".")
          end

          ##############################
          # Inlined from ChefRepositoryFileSystemEntry
          ##############################

          # Inherited from ChefRepositoryFileSystemEntry, but apparently unused
          ## def write_pretty_json=(value)
          ##   @write_pretty_json = value
          ## end

          # Inherited from ChefRepositoryFileSystemEntry, but apparently unused
          ## def write_pretty_json
          ##   @write_pretty_json.nil? ? root.write_pretty_json : @write_pretty_json
          ## end

          # Inherited from ChefRepositoryFileSystemEntry, but has different behavior here:
          ## def data_handler
          ##   @data_handler || parent.data_handler
          ## end

          # Inlined version of the above
          # Seems like this has to be important, but where is it used?
          ##def data_handler
          ##  @data_handler
          ##end

          # Inherited from ChefRepositoryFileSystemEntry, but apparently unused
          ## def chef_object
          ##   begin
          ##     return data_handler.chef_object(Chef::JSONCompat.parse(read))
          ##   rescue
          ##     Chef::Log.error("Could not read #{path_for_printing} into a Chef object: #{$!}")
          ##   end
          ##   nil
          ## end

          # Overridden by subclass
          ## def can_have_child?(name, is_dir)
          ##   !is_dir && name[-5..-1] == ".json"
          ## end

          # Inherited from ChefRepositoryFileSystemEntry, but apparently unused
          ## def write(file_contents)
          ##   if file_contents && write_pretty_json && name[-5..-1] == ".json"
          ##     file_contents = minimize(file_contents, self)
          ##   end
          ##   super(file_contents)
          ## end

          # Inherited from ChefRepositoryFileSystemEntry, but apparently unused
          ## def minimize(file_contents, entry)
          ##   object = Chef::JSONCompat.parse(file_contents)
          ##   object = data_handler.normalize(object, entry)
          ##   object = data_handler.minimize(object, entry)
          ##   Chef::JSONCompat.to_json_pretty(object)
          ## end

          protected

          def make_child_entry(child_name)
            ChefRepositoryFileSystemEntry.new(child_name, self)
          end

          public

          ##############################
          # Inlined from FileSystemEntry
          ##############################

          attr_reader :file_path

          def path_for_printing
            file_path
          end

          def children
            # Except cookbooks and data bag dirs, all things must be json files
            begin
              Dir.entries(file_path).sort.
                  map { |child_name| make_child_entry(child_name) }.
                  select { |child| child && can_have_child?(child.name, child.dir?) }
            rescue Errno::ENOENT
              raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
            end
          end

          # Inherited from FileSystemEntry but has extra cases we cannot hit all the cases
          ## def create_child(child_name, file_contents=nil)
          ##   child = make_child_entry(child_name)
          ##   if child.exists?
          ##     raise Chef::ChefFS::FileSystem::AlreadyExistsError.new(:create_child, child)
          ##   end
          ##   if file_contents
          ##     child.write(file_contents)
          ##   else
          ##     begin
          ##       Dir.mkdir(child.file_path)
          ##     rescue Errno::EEXIST
          ##       raise Chef::ChefFS::FileSystem::AlreadyExistsError.new(:create_child, child)
          ##     end
          ##   end
          ##   child
          ## end

          # Inherited from FileSystemEntry, modified to remove code we can't hit
          def create_child(child_name, file_contents=nil)
            child = make_child_entry(child_name)
            if child.exists?
              raise Chef::ChefFS::FileSystem::AlreadyExistsError.new(:create_child, child)
            end
            begin
              Dir.mkdir(child.file_path)
            rescue Errno::EEXIST
              raise Chef::ChefFS::FileSystem::AlreadyExistsError.new(:create_child, child)
            end
            child
          end

          # Inherited from FileSystemEntry but this is a data bag dir, it should always be a dir
          ## def dir?
          ##   File.directory?(file_path)
          ## end

          # Inherited from FileSystemEntry but with other stuff inlined we don't need it any more
          ## def dir?
          ##   true
          ## end

          # Inherited from FileSystemEntry but it seems we cannot hit all of these cases
          ## def delete(recurse)
          ##   begin
          ##     if dir?
          ##       if !recurse
          ##         raise MustDeleteRecursivelyError.new(self, $!)
          ##       end
          ##       FileUtils.rm_r(file_path)
          ##     else
          ##       File.delete(file_path)
          ##     end
          ##   rescue Errno::ENOENT
          ##     raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
          ##   end
          ## end

          # Inherited from FileSystemEntry but it seems we cannot hit all of these cases
          def delete(recurse)
            if exists?
              if !recurse
                raise MustDeleteRecursivelyError.new(self, $!)
              end
              FileUtils.rm_r(file_path)
            else
              raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
            end
          end


          # Inherited from FileSystemEntry but it seems we cannot hit all of these cases
          ## def exists?
          ##   File.exists?(file_path) && (parent.nil? || parent.can_have_child?(name, dir?))
          ## end

          # Inherited from FileSystemEntry but there are extra cases we don't seem to hit
          def exists?
            File.exists?(file_path) # && (parent.nil? || parent.can_have_child?(name, dir?))
          end

          # Inherited from FileSystemEntry but seems unused
          ## def read
          ##   begin
          ##     File.open(file_path, "rb") {|f| f.read}
          ##   rescue Errno::ENOENT
          ##     raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
          ##   end
          ## end

          # Inherited from FileSystemEntry but seems unused
          ## def write(content)
          ##   File.open(file_path, "wb") do |file|
          ##     file.write(content)
          ##   end
          ## end

          # Overridden in superclass (ChefRepositoryFileSystemEntry)
          ## protected

          ## def make_child_entry(child_name)
          ##   FileSystemEntry.new(child_name, self)
          ## end

          ##############################
          # Inlined from BaseFSDir
          ##############################

          # trivial initializer
          ## def initialize(name, parent)
          ##   super
          ## end

          # overridden in superclass
          ## def dir?
          ##   true
          ## end

          # overridden in superclass
          ## def can_have_child?(name, is_dir)
          ##   true
          ## end

          # An empty children array is an empty dir
          def empty?
            children.empty?
          end
        end

      end
    end
  end
end
