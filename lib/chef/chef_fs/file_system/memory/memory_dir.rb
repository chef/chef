require "chef/chef_fs/file_system/base_fs_dir"
require "chef/chef_fs/file_system/memory/memory_file"

class Chef
  module ChefFS
    module FileSystem
      module Memory
        class MemoryDir < Chef::ChefFS::FileSystem::BaseFSDir
          def initialize(name, parent)
            super(name, parent)
            @children = []
          end

          attr_reader :children

          def make_child_entry(name)
            @children.find { |child| child.name == name }
          end

          def add_child(child)
            @children.push(child)
          end

          def can_have_child?(name, is_dir)
            root.cannot_be_in_regex ? (name !~ root.cannot_be_in_regex) : true
          end

          def add_file(path, value)
            path_parts = path.split("/")
            dir = add_dir(path_parts[0..-2].join("/"))
            file = MemoryFile.new(path_parts[-1], dir, value)
            dir.add_child(file)
            file
          end

          def add_dir(path)
            path_parts = path.split("/")
            dir = self
            path_parts.each do |path_part|
              subdir = dir.child(path_part)
              if !subdir.exists?
                subdir = MemoryDir.new(path_part, dir)
                dir.add_child(subdir)
              end
              dir = subdir
            end
            dir
          end
        end
      end
    end
  end
end
