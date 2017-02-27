require "chef/chef_fs/file_system/base_fs_object"

class Chef
  module ChefFS
    module FileSystem
      module Memory
        class MemoryFile < Chef::ChefFS::FileSystem::BaseFSObject
          def initialize(name, parent, value)
            super(name, parent)
            @value = value
          end

          def read
            @value
          end
        end
      end
    end
  end
end
