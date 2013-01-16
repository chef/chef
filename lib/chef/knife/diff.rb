require 'chef/chef_fs/knife'
require 'chef/chef_fs/command_line'

class Chef
  class Knife
    class Diff < Chef::ChefFS::Knife
      banner "knife diff PATTERNS"

      common_options

      option :recurse,
        :long => '--[no-]recurse',
        :boolean => true,
        :default => true,
        :description => "List directories recursively."

      option :name_only,
        :long => '--name-only',
        :boolean => true,
        :description => "Only show names of modified files."

      option :name_status,
        :long => '--name-status',
        :boolean => true,
        :description => "Only show names and statuses of modified files: Added, Deleted, Modified, and Type Changed."

      def run
        if config[:name_only]
          output_mode = :name_only
        end
        if config[:name_status]
          output_mode = :name_status
        end
        patterns = pattern_args_from(name_args.length > 0 ? name_args : [ "" ])

        # Get the matches (recursively)
        error = false
        patterns.each do |pattern|
          found_match = Chef::ChefFS::CommandLine.diff_print(pattern, chef_fs, local_fs, config[:recurse] ? nil : 1, output_mode, proc { |entry| format_path(entry) } ) do |diff|
            stdout.print diff
          end
          if !found_match
            ui.error "#{pattern}: No such file or directory on remote or local"
            error = true
          end
        end
        if error
          exit 1
        end
      end
    end
  end
end

