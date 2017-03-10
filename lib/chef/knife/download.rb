require "chef/chef_fs/knife"

class Chef
  class Knife
    class Download < Chef::ChefFS::Knife
      banner "knife download PATTERNS"

      category "path-based"

      deps do
        require "chef/chef_fs/command_line"
      end

      option :recurse,
        :long => "--[no-]recurse",
        :boolean => true,
        :default => true,
        :description => "List directories recursively."

      option :purge,
        :long => "--[no-]purge",
        :boolean => true,
        :default => false,
        :description => "Delete matching local files and directories that do not exist remotely."

      option :force,
        :long => "--[no-]force",
        :boolean => true,
        :default => false,
        :description => "Force upload of files even if they match (quicker and harmless, but doesn't print out what it changed)"

      option :dry_run,
        :long => "--dry-run",
        :short => "-n",
        :boolean => true,
        :default => false,
        :description => "Don't take action, only print what would happen"

      option :diff,
        :long => "--[no-]diff",
        :boolean => true,
        :default => true,
        :description => "Turn off to avoid uploading existing files; only new (and possibly deleted) files with --no-diff"

      option :cookbook_version,
        :long => "--cookbook-version VERSION",
        :description => "Version of cookbook to download (if there are multiple versions and cookbook_versions is false)"

      def run
        if name_args.length == 0
          show_usage
          ui.fatal("You must specify at least one argument. If you want to download everything in this directory, run \"knife download .\"")
          exit 1
        end

        error = false
        pattern_args.each do |pattern|
          if Chef::ChefFS::FileSystem.copy_to(pattern, chef_fs, local_fs, config[:recurse] ? nil : 1, config, ui, proc { |entry| format_path(entry) })
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
