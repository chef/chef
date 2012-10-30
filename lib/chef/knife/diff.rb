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
        patterns.each do |pattern|
          Chef::ChefFS::CommandLine.diff(pattern, chef_fs, local_fs, config[:recurse] ? nil : 1, output_mode) do |diff|
            puts diff
          end
        end
      end
    end
  end
end

