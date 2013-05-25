require 'chef/chef_fs/file_system/base_fs_dir'
require 'chef/chef_fs/file_system/nonexistent_fs_object'
require 'chef/chef_fs/file_system/memory_file'

class Chef
  module ChefFS
    module FileSystem
      class MemoryDir < Chef::ChefFS::FileSystem::BaseFSDir
        def initialize(name, parent)
          super(name, parent)
          @children = []
        end

        attr_reader :children

        def child(name)
          @children.select { |child| child.name == name }.first || Chef::ChefFS::FileSystem::NonexistentFSObject.new(name, self)
        end

        def add_child(child)
          @children.push(child)
        end

        def can_have_child?(name, is_dir)
          root.cannot_be_in_regex ? (name !~ root.cannot_be_in_regex) : true
        end

        def add_file(path, value)
          path_parts = path.split('/')
          if path_parts.length == 1
            add_child(MemoryFile.new(path_parts[0], self, value))
          else
            if !child(path_parts[0]).exists?
              add_child(MemoryDir.new(path_parts[0], self))
            end
            child(path_parts[0]).add_file(path_parts[1..-1], value)
          end
        end
      end
    end
  end
end
