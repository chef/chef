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
        :short => '-J REPLACESTR',
        :description => "String to replace with filenames.  -J will only replace the FIRST occurrence of the replacement string."

      option :replace_all,
        :short => '-I REPLACESTR',
        :description => "String to replace with filenames.  -I will replace ALL occurrence of the replacement string."

      option :max_arguments_per_command,
        :short => '-n MAXARGS',
        :description => "Maximum number of arguments per command line."

      def run
        error = false
        # Get the matches (recursively)
        files = []
        pattern_args_from(get_patterns).each do |pattern|
          Chef::ChefFS::FileSystem.list(config[:local] ? local_fs : chef_fs, pattern) do |result|
            if result.dir?
              # TODO option to include directories
              ui.warn "#{format_path(result)}: is a directory.  Will not run #{command} on it."
            else
              files << result
              if config[:max_arguments_per_command] && files.size >= config[:max_arguments_per_command].to_i
                error = true if xargs_files(files)
                files = []
              end
            end
          end
        end
        if files.size > 0
          error = true if xargs_files(files)
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

      def xargs_files(files)
        command = name_args.join(' ')

        tempfiles = {}
        begin
          # Create and fill in the temporary files
          files.each do |file|
            begin
              value = file.read
              tempfile = Tempfile.open(file.name)
              tempfiles[tempfile] = { :file => file, :value => value }
              tempfile.write(value)
              tempfile.close
            rescue Chef::ChefFS::FileSystem::OperationNotAllowedError => e
              ui.error "#{format_path(e.entry)}: #{e.reason}."
              error = true
            rescue Chef::ChefFS::FileSystem::NotFoundError => e
              ui.error "#{format_path(e.entry)}: No such file or directory"
              error = true
              next
            end
          end

          # Determine the full command
          paths = tempfiles.keys.map { |tempfile| tempfile.path }.join(' ')
          if config[:replace_all]
            final_command = command.gsub(config[:replace_all], paths)
          elsif config[:replace_first]
            final_command = command.sub(config[:replace_first], paths)
          else
            final_command = "#{command} #{paths}"
          end

          # Run the command
          output sub_filenames(final_command, tempfiles)
          command_output = `#{final_command}`
          command_output = sub_filenames(command_output, tempfiles)

          # Check if the output is different
          tempfiles.each_pair do |tempfile, file|
            # Read the new output
            new_value = IO.binread(tempfile.path)

            # Upload the output if different
            if config[:force] || new_value != file[:value]
              if config[:dry_run]
                output "Would update #{format_path(file[:file])}"
              else
                file[:file].write(new_value)
                output "Updated #{format_path(file[:file])}"
              end
            end

            # Print a diff of what was uploaded
            if config[:diff] && new_value != file[:value]
              old_file = Tempfile.open(file[:file].name)
              begin
                old_file.write(file[:value])
                old_file.close

                diff = `diff -u #{old_file.path} #{tempfile.path}`
                diff.gsub!(old_file.path, "#{file[:file].name} (old)")
                diff.gsub!(tempfile.path, "#{file[:file].name} (new)")
                output diff
              ensure
                old_file.close!
              end
            end
          end

        ensure
          # Unlink the files now that we're done with them
          tempfiles.keys.each { |tempfile| tempfile.close! }
        end
      end

      def sub_filenames(str, tempfiles)
        tempfiles.each_pair do |tempfile, file|
          str.gsub!(tempfile.path, format_path(file[:file]))
        end
        str
      end

    end
  end
end

