require "chef/chef_fs/file_system/memory/memory_dir"

class Chef
  module ChefFS
    module FileSystem
      module Memory
        class MemoryRoot < MemoryDir
          def initialize(pretty_name, cannot_be_in_regex = nil)
            super("", nil)
            @pretty_name = pretty_name
            @cannot_be_in_regex = cannot_be_in_regex
          end

          attr_reader :cannot_be_in_regex

          def path_for_printing
            @pretty_name
          end
        end
      end
    end
  end
end
