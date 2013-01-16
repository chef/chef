require 'chef/chef_fs/knife'
require 'chef/chef_fs/file_system'

class Chef
  class Knife
    class Delete < Chef::ChefFS::Knife
      banner "knife delete [PATTERN1 ... PATTERNn]"

      common_options

      option :recurse,
        :short => '-r',
        :long => '--[no-]recurse',
        :boolean => true,
        :default => false,
        :description => "Delete directories recursively."
      option :remote_only,
        :long => '--remote-only',
        :boolean => true,
        :default => false,
        :description => "Only delete the remote copy (leave the local copy)."
      option :local_only,
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
        succeeded = true
        if config[:remote_only]
          pattern_args.each do |pattern|
            Chef::ChefFS::FileSystem.list(chef_fs, pattern) do |result|
              if !delete_result(result)
                succeeded = false
              end
            end
          end
        elsif config[:local_only]
          pattern_args.each do |pattern|
            Chef::ChefFS::FileSystem.list(local_fs, pattern) do |result|
              if !delete_result(result)
                succeeded = false
              end
            end
          end
        else
          pattern_args.each do |pattern|
            Chef::ChefFS::FileSystem.list_pairs(pattern, chef_fs, local_fs) do |chef_result, local_result|
              if !delete_result(chef_result, local_result)
                succeeded = false
              end
            end
          end
        end

        if !succeeded
          exit 1
        end
      end

      def delete_result(*results)
        deleted_any = false
        found_any = false
        errors = false
        results.each do |result|
          begin
            result.delete(config[:recurse])
            deleted_any = true
            found_any = true
          rescue Chef::ChefFS::FileSystem::NotFoundError
          rescue Chef::ChefFS::FileSystem::MustDeleteRecursivelyError => e
            ui.error "#{format_path(e.entry.path)} must be deleted recursively!  Pass -r to knife delete."
            found_any = true
            errors = true
          rescue Chef::ChefFS::FileSystem::OperationNotAllowedError => e
            ui.error "#{format_path(e.entry.path)} #{e.reason}."
            found_any = true
            errors = true
          end
        end
        if deleted_any
          output("Deleted #{format_path(results[0].path)}")
        elsif !found_any
          ui.error "#{format_path(results[0].path)}: No such file or directory"
          errors = true
        end
        !errors
      end
    end
  end
end

