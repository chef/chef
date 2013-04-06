require 'chef/chef_fs/knife'
require 'chef/chef_fs/file_system'
require 'chef/chef_fs/file_system/not_found_error'

class Chef
  class Knife
    class Xargs < Chef::ChefFS::Knife
      banner "knife xargs [COMMAND]"

      common_options

      # TODO modify to remote-only / local-only pattern (more like delete)
      option :local,
        :long => '--local',
        :boolean => true,
        :description => "Xargs local files instead of remote"

      option :patterns,
        :long => '--pattern [PATTERN]',
        :short => '-p [PATTERN]',
        :description => "Pattern on command line (if these are not specified, a list of patterns is expected on standard input).  Multiple patterns may be passed in this way.",
        :arg_arity => [1,-1]

      option :diff,
        :long => '--[no-]diff',
        :default => true,
        :boolean => true,
        :description => "Whether to show a diff when files change (default: true)"

      option :dry_run,
        :long => '--dry-run',
        :boolean => true,
        :description => "Prevents changes from actually being uploaded to the server."

      option :force,
        :long => '--[no-]force',
        :boolean => true,
        :default => false,
        :description => "Force upload of files even if they are not changed (quicker and harmless, but doesn't print out what it changed)"

      option :replace_first,
        :short => '-J replacestr',
        :description => "String to replace with filenames.  -J will only replace the FIRST occurrence of the replacement string."

      option :replace_all,
        :short => '-I replacestr',
        :description => "String to replace with filenames.  -I will replace ALL occurrence of the replacement string."

      def run
        error = false
        command = name_args.join(' ')
        # Get the matches (recursively)
        pattern_args_from(get_patterns).each do |pattern|
          Chef::ChefFS::FileSystem.list(config[:local] ? local_fs : chef_fs, pattern) do |result|
            if result.dir?
              # TODO option to include directories
              ui.warn "#{format_path(result)}: is a directory.  Will not run #{command} on it."
            else
              begin
                value = result.read
                tmpfile = Tempfile.open(result.name)
                begin
                  tmpfile.write(value)
                  tmpfile.close

                  # Determine the command name
                  if config[:replace_all]
                    final_command = command.gsub(config[:replace_all], tmpfile.path)
                  elsif config[:replace_first]
                    final_command = command.sub(config[:replace_first], tmpfile.path)
                  else
                    final_command = "#{command} #{tmpfile.path}"
                  end

                  # Run the command
                  output final_command.gsub(tmpfile.path, format_path(result))
                  command_output = `#{final_command}`
                  command_output.gsub!(tmpfile.path, format_path(result))

                  # Check if the output is different
                  tmpfile.open
                  new_value = tmpfile.read
                  tmpfile.close
                  if config[:force] || new_value != value
                    if config[:dry_run]
                      output "Would update #{format_path(result)}"
                    else
                      result.write(new_value)
                      output "Updated #{format_path(result)}"
                    end
                  end

                  if config[:diff] && new_value != value
                    old_file = Tempfile.open(result.name)
                    begin
                      old_file.write(value)
                      old_file.close

                      diff = `diff -u #{old_file.path} #{tmpfile.path}`
                    ensure
                      old_file.close!
                    end
                  end
                ensure
                  tmpfile.close! # Unlink the file now that we're done with it
                end

              rescue Chef::ChefFS::FileSystem::OperationNotAllowedError => e
                ui.error "#{format_path(e.entry)}: #{e.reason}."
                error = true
              rescue Chef::ChefFS::FileSystem::NotFoundError => e
                ui.error "#{format_path(e.entry)}: No such file or directory"
                error = true
              end
            end
          end
        end
        if error
          exit 1
        end
      end

      def get_patterns
        if config[:patterns]
          [ config[:patterns] ].flatten
        else
          stdin.lines.map { |line| line.chomp }
        end
      end
    end
  end
end

