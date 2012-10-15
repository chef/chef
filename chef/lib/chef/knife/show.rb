require 'chef/chef_fs/knife'
require 'chef/chef_fs/file_system'

class Chef
  class Knife
    class Show < Chef::ChefFS::Knife
      banner "knife show [PATTERN1 ... PATTERNn]"

      common_options

      def run
        # Get the matches (recursively)
        pattern_args.each do |pattern|
          Chef::ChefFS::FileSystem.list(chef_fs, pattern) do |result|
            if result.dir?
              STDERR.puts "#{result.path_for_printing}: is a directory" if pattern.exact_path
            else
              begin
                value = result.read
                puts "#{result.path_for_printing}:"
                output(format_for_display(value))
              rescue Chef::ChefFS::FileSystem::NotFoundError
                STDERR.puts "#{result.path_for_printing}: No such file or directory"
              end
            end
          end
        end
      end
    end
  end
end

