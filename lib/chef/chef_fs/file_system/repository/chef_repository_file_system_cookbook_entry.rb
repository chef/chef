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
require "chef/chef_fs/file_system/repository/chef_repository_file_system_cookbooks_dir"
require "chef/chef_fs/file_system/not_found_error"

class Chef
  module ChefFS
    module FileSystem
      module Repository

        # NB: unlike most other things in chef_fs/file_system/repository, this
        # class represents both files and directories, so it needs to have the
        # methods/if branches for each.

        # Original
        #class ChefRepositoryFileSystemCookbookEntry < ChefRepositoryFileSystemEntry

        # With ChefRepositoryFileSystemEntry inlined
        #class ChefRepositoryFileSystemCookbookEntry < FileSystemEntry

        # With FileSystemEntry inlined
        #class ChefRepositoryFileSystemCookbookEntry < BaseFSDir

        # With BaseFSDir inlined
        #class ChefRepositoryFileSystemCookbookEntry < BaseFSObject

        # Fully inlined
        class ChefRepositoryFileSystemCookbookEntry
          # Original initialize
          ##  def initialize(name, parent, file_path = nil, ruby_only = false, recursive = false)
          ##    super(name, parent, file_path)
          ##    @ruby_only = ruby_only
          ##    @recursive = recursive
          ##  end

          # ChefRepositoryFileSystemEntry#initialize
          ##  def initialize(name, parent, file_path = nil, data_handler = nil)
          ##    super(name, parent, file_path)
          ##    @data_handler = data_handler
          ##  end

          # FileSystemEntry#initialize
          ##  def initialize(name, parent, file_path = nil)
          ##    super(name, parent)
          ##    @file_path = file_path || "#{parent.file_path}/#{name}"
          ##  end

          # BaseFSObject#initialize
          ##  def initialize(name, parent)
          ##    @parent = parent
          ##    @name = name
          ##    if parent
          ##      @path = Chef::ChefFS::PathUtils::join(parent.path, name)
          ##    else
          ##      if name != ""
          ##        raise ArgumentError, "Name of root object must be empty string: was '#{name}' instead"
          ##      end
          ##      @path = "/"
          ##    end
          ##  end

          # inlined initialize
          def initialize(name, parent, file_path = nil, ruby_only = false, recursive = false)
            @parent = parent
            @name = name
            #if parent
              @path = Chef::ChefFS::PathUtils::join(parent.path, name)
            #else
            #  if name != ""
            #    raise ArgumentError, "Name of root object must be empty string: was '#{name}' instead"
            #  end
            #  @path = "/"
            #end
            @ruby_only = ruby_only
            @recursive = recursive
            @data_handler = nil
            @file_path = file_path || "#{parent.file_path}/#{name}"
          end

          attr_reader :ruby_only
          attr_reader :recursive

          # modifies superclass; see inlined
          ## def children
          ##   super.select { |entry| !(entry.dir? && entry.children.size == 0 ) }
          ## end

          # inlined version
          def children
            # Except cookbooks and data bag dirs, all things must be json files
            begin
              entries = Dir.entries(file_path).sort.
                  map { |child_name| make_child_entry(child_name) }.
                  select { |child| child && can_have_child?(child.name, child.dir?) }
              entries.select { |entry| !(entry.dir? && entry.children.size == 0 ) }
            rescue Errno::ENOENT
              raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
            end
          end

          def can_have_child?(name, is_dir)
            if is_dir
              return recursive && name != "." && name != ".."
            elsif ruby_only
              return false if name[-3..-1] != ".rb"
            end

            # Check chefignore
            ignorer = parent
            loop do
              if ignorer.is_a?(ChefRepositoryFileSystemCookbooksDir)
                # Grab the path from entry to child
                path_to_child = name
                child = self
                while child.parent != ignorer
                  path_to_child = PathUtils.join(child.name, path_to_child)
                  child = child.parent
                end
                # Check whether that relative path is ignored
                return !ignorer.chefignore || !ignorer.chefignore.ignored?(path_to_child)
              end
              ignorer = ignorer.parent
              break unless ignorer
            end

            true
          end

          def write_pretty_json
            false
          end

          protected

          def make_child_entry(child_name)
            ChefRepositoryFileSystemCookbookEntry.new(child_name, self, nil, ruby_only, recursive)
          end

          public

          ##############################
          # inlined from ChefRepositoryFileSystemEntry
          ##############################

          # overriden by superclass
          ##  def write_pretty_json
          ##    @write_pretty_json.nil? ? root.write_pretty_json : @write_pretty_json
          ##  end

          # unused?
          ##  def data_handler
          ##    @data_handler || parent.data_handler
          ##  end

          # unused?
          ##  def chef_object
          ##    begin
          ##      return data_handler.chef_object(Chef::JSONCompat.parse(read))
          ##    rescue
          ##      Chef::Log.error("Could not read #{path_for_printing} into a Chef object: #{$!}")
          ##    end
          ##    nil
          ##  end

          # overriden by superclass
          ##  def can_have_child?(name, is_dir)
          ##    !is_dir && name[-5..-1] == ".json"
          ##  end

          # unused?
          ##  def write(file_contents)
          ##    if file_contents && write_pretty_json && name[-5..-1] == ".json"
          ##      file_contents = minimize(file_contents, self)
          ##    end
          ##    super(file_contents)
          ##  end

          # unused?
          ##  def minimize(file_contents, entry)
          ##    object = Chef::JSONCompat.parse(file_contents)
          ##    object = data_handler.normalize(object, entry)
          ##    object = data_handler.minimize(object, entry)
          ##    Chef::JSONCompat.to_json_pretty(object)
          ##  end

          # overriden by superclass
          ## protected

          ## def make_child_entry(child_name)
          ##   ChefRepositoryFileSystemEntry.new(child_name, self)
          ## end

          ##############################
          # inlined from FileSystemEntry
          ##############################

          attr_reader :file_path

          def path_for_printing
            file_path
          end

          # combined into inlined version from subclass
          ##  def children
          ##    # Except cookbooks and data bag dirs, all things must be json files
          ##    begin
          ##      Dir.entries(file_path).sort.
          ##          map { |child_name| make_child_entry(child_name) }.
          ##          select { |child| child && can_have_child?(child.name, child.dir?) }
          ##    rescue Errno::ENOENT
          ##      raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
          ##    end
          ##  end

          def create_child(child_name, file_contents=nil)
            child = make_child_entry(child_name)
            if child.exists?
              raise Chef::ChefFS::FileSystem::AlreadyExistsError.new(:create_child, child)
            end
            if file_contents
              child.write(file_contents)
            else
              begin
                Dir.mkdir(child.file_path)
              rescue Errno::EEXIST
                raise Chef::ChefFS::FileSystem::AlreadyExistsError.new(:create_child, child)
              end
            end
            child
          end

          def dir?
            File.directory?(file_path)
          end

          def delete(recurse)
            begin
              if dir?
                if !recurse
                  raise MustDeleteRecursivelyError.new(self, $!)
                end
                FileUtils.rm_r(file_path)
              else
                File.delete(file_path)
              end
            rescue Errno::ENOENT
              raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
            end
          end

          def exists?
            File.exists?(file_path) && (parent.nil? || parent.can_have_child?(name, dir?))
          end

          def read
            begin
              File.open(file_path, "rb") {|f| f.read}
            rescue Errno::ENOENT
              raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
            end
          end

          def write(content)
            File.open(file_path, "wb") do |file|
              file.write(content)
            end
          end

          # overriden by subclass
          ##  protected

          ##  def make_child_entry(child_name)
          ##    FileSystemEntry.new(child_name, self)
          ##  end

          ##############################
          # inlined from BaseFSDir
          ##############################

          # trivial initializer
          ##  def initialize(name, parent)
          ##    super
          ##  end

          # overriden by subclass
          ##  def dir?
          ##    true
          ##  end

          # overriden by subclass
          ##  def can_have_child?(name, is_dir)
          ##    true
          ##  end

          # An empty children array is an empty dir
          def empty?
            children.empty?
          end

          ##############################
          # inlined from BaseFSObject
          ##############################

          attr_reader :name
          attr_reader :parent
          attr_reader :path

          # unused?
          ##  def compare_to(other)
          ##    nil
          ##  end

          # overriden by subclass
          ##  def can_have_child?(name, is_dir)
          ##    false
          ##  end

          def child(name)
            if can_have_child?(name, true) || can_have_child?(name, false)
              result = make_child_entry(name)
            end
            result || NonexistentFSObject.new(name, self)
          end

          # overridden by subclass
          ##  def children
          ##    raise NotFoundError.new(self) if !exists?
          ##    []
          ##  end

          # unused?
          ##  def chef_object
          ##    raise NotFoundError.new(self) if !exists?
          ##    nil
          ##  end

          # overridden by subclass
          ##  def create_child(name, file_contents)
          ##    raise NotFoundError.new(self) if !exists?
          ##    raise OperationNotAllowedError.new(:create_child, self)
          ##  end

          # overridden by subclass
          ##  def delete(recurse)
          ##    raise NotFoundError.new(self) if !exists?
          ##    raise OperationNotAllowedError.new(:delete, self)
          ##  end

          # overridden by subclass
          ##  def dir?
          ##    false
          ##  end

          # overridden by subclass
          ##  def exists?
          ##    true
          ##  end

          # Printable path, generally used to distinguish paths in one root from
          # paths in another.
          def path_for_printing
            if parent
              parent_path = parent.path_for_printing
              if parent_path == "."
                name
              else
                Chef::ChefFS::PathUtils::join(parent.path_for_printing, name)
              end
            else
              name
            end
          end

          # this class isnt a root don't need a branch
          ##  def root
          ##    parent ? parent.root : self
          ##  end

          # just the behavior we need
          def root
            parent.root
          end

          # overridden by subclass
          ##  def read
          ##    raise NotFoundError.new(self) if !exists?
          ##    raise OperationNotAllowedError.new(:read, self)
          ##  end

          # overridden by subclass
          ##  def write(file_contents)
          ##    raise NotFoundError.new(self) if !exists?
          ##    raise OperationNotAllowedError.new(:write, self)
          ##  end
        end
      end
    end
  end
end
