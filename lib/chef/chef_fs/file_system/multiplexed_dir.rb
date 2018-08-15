require "chef/chef_fs/file_system/base_fs_object"
require "chef/chef_fs/file_system/nonexistent_fs_object"

class Chef
  module ChefFS
    module FileSystem
      class MultiplexedDir < BaseFSDir
        def initialize(*multiplexed_dirs)
          @multiplexed_dirs = multiplexed_dirs.flatten
          super(@multiplexed_dirs[0].name, @multiplexed_dirs[0].parent)
        end

        attr_reader :multiplexed_dirs

        def write_dir
          multiplexed_dirs[0]
        end

        def children
          result = []
          seen = {}
            # If multiple things have the same name, the first one wins.
          multiplexed_dirs.each do |dir|
            dir.children.each do |child|
              if seen[child.name]
                Chef::Log.warn("Child with name '#{child.name}' found in multiple directories: #{seen[child.name].path_for_printing} and #{child.path_for_printing}") unless seen[child.name].path_for_printing == child.path_for_printing
              else
                result << child
                seen[child.name] = child
              end
            end
          end
          result
        end

        def make_child_entry(name)
          result = nil
          multiplexed_dirs.each do |dir|
            child_entry = dir.child(name)
            if child_entry.exists?
              if result
                Chef::Log.trace("Child with name '#{child_entry.name}' found in multiple directories: #{result.parent.path_for_printing} and #{child_entry.parent.path_for_printing}")
              else
                result = child_entry
              end
            end
          end
          result
        end

        def can_have_child?(name, is_dir)
          write_dir.can_have_child?(name, is_dir)
        end

        def create_child(name, file_contents = nil)
          @children = nil
          write_dir.create_child(name, file_contents)
        end
      end
    end
  end
end
