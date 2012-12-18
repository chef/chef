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
      option :remote_only,
        :short => '-R',
        :long => '--remote-only',
        :boolean => true,
        :default => false,
        :description => "Only delete the remote copy (leave the local copy)."
      option :local_only,
        :short => '-L',
        :long => '--local-only',
        :boolean => true,
        :default => false,
        :description => "Only delete the local copy (leave the remote copy)."

      def run
        if name_args.length == 0
          show_usage
          ui.fatal("Must specify at least one argument.  If you want to delete everything in this directory, type \"knife delete --recurse .\"")
          exit 1
        end

        # Get the matches (recursively)
        if config[:remote_only]
          pattern_args.each do |pattern|
            Chef::ChefFS::FileSystem.list(chef_fs, pattern) do |result|
              delete_result(result)
            end
          end
        elsif config[:local_only]
          pattern_args.each do |pattern|
            Chef::ChefFS::FileSystem.list(local_fs, pattern) do |result|
              delete_result(result)
            end
          end
        else
          pattern_args.each do |pattern|
            Chef::ChefFS::FileSystem.list_pairs(pattern, chef_fs, local_fs) do |chef_result, local_result|
              delete_result(chef_result, local_result)
            end
          end
        end
      end

      def delete_result(*results)
        deleted_any = false
        results.each do |result|
          begin
            result.delete(config[:recurse])
            deleted_any = true
          rescue Chef::ChefFS::FileSystem::NotFoundError
          end
        end
        if deleted_any
          puts "Deleted #{format_path(results[0].path)}"
        else
          STDERR.puts "#{format_path(results[0].path)}: No such file or directory"
        end
      end
    end
  end
end

