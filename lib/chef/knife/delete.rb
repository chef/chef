require 'chef/chef_fs/knife'
require 'chef/chef_fs/file_system'

class Chef
  class Knife
    class Delete < Chef::ChefFS::Knife
      banner "knife delete [PATTERN1 ... PATTERNn]"

      common_options

      option :recurse,
        :long => '--[no-]recurse',
        :boolean => true,
        :default => false,
        :description => "Delete directories recursively."

      def run
        if name_args.length == 0
          show_usage
          ui.fatal("Must specify at least one argument.  If you want to delete everything in this directory, type \"knife delete --recurse .\"")
          exit 1
        end

        # Get the matches (recursively)
        pattern_args.each do |pattern|
          Chef::ChefFS::FileSystem.list(chef_fs, pattern) do |result|
            begin
              result.delete(config[:recurse])
              puts "Deleted #{result.path_for_printing}"
            rescue Chef::ChefFS::FileSystem::NotFoundError
              STDERR.puts "#{result.path_for_printing}: No such file or directory"
            end
          end
        end
      end
    end
  end
end

