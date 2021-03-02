#
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative "../chef_fs/knife"

class Chef
  class Knife
    class Xargs < Chef::ChefFS::Knife
      banner "knife xargs [COMMAND] (options)"

      category "path-based"

      deps do
        require "chef/chef_fs/file_system" unless defined?(Chef::ChefFS::FileSystem)
        require "chef/chef_fs/file_system/exceptions" unless defined?(Chef::ChefFS::FileSystem::Exceptions)
      end

      # TODO modify to remote-only / local-only pattern (more like delete)
      option :local,
        long: "--local",
        boolean: true,
        description: "Xargs local files instead of remote."

      option :patterns,
        long: "--pattern [PATTERN]",
        short: "-p [PATTERN]",
        description: "Pattern on command line (if these are not specified, a list of patterns is expected on standard input). Multiple patterns may be passed in this way.",
        arg_arity: [1, -1]

      option :diff,
        long: "--[no-]diff",
        default: true,
        boolean: true,
        description: "Whether to show a diff when files change (default: true)."

      option :dry_run,
        long: "--dry-run",
        boolean: true,
        description: "Prevents changes from actually being uploaded to the server."

      option :force,
        long: "--[no-]force",
        boolean: true,
        default: false,
        description: "Force upload of files even if they are not changed (quicker and harmless, but doesn't print out what it changed)."

      option :replace_first,
        long: "--replace-first REPLACESTR",
        short: "-J REPLACESTR",
        description: "String to replace with filenames. -J will only replace the FIRST occurrence of the replacement string."

      option :replace_all,
        long: "--replace REPLACESTR",
        short: "-I REPLACESTR",
        description: "String to replace with filenames. -I will replace ALL occurrence of the replacement string."

      option :max_arguments_per_command,
        long: "--max-args MAXARGS",
        short: "-n MAXARGS",
        description: "Maximum number of arguments per command line."

      option :max_command_line,
        long: "--max-chars LENGTH",
        short: "-s LENGTH",
        description: "Maximum size of command line, in characters."

      option :verbose_commands,
        short: "-t",
        description: "Print command to be run on the command line."

      option :null_separator,
        short: "-0",
        boolean: true,
        description: "Use the NULL character (\0) as a separator, instead of whitespace."

      def run
        error = false
        # Get the matches (recursively)
        files = []
        pattern_args_from(get_patterns).each do |pattern|
          Chef::ChefFS::FileSystem.list(config[:local] ? local_fs : chef_fs, pattern).each do |result|
            if result.dir?
              # TODO option to include directories
              ui.warn "#{format_path(result)}: is a directory. Will not run #{command} on it."
            else
              files << result
              ran = false

              # If the command would be bigger than max command line, back it off a bit
              # and run a slightly smaller command (with one less arg)
              if config[:max_command_line]
                command, tempfiles = create_command(files)
                begin
                  if command.length > config[:max_command_line].to_i
                    if files.length > 1
                      command, tempfiles_minus_one = create_command(files[0..-2])
                      begin
                        error = true if xargs_files(command, tempfiles_minus_one)
                        files = [ files[-1] ]
                        ran = true
                      ensure
                        destroy_tempfiles(tempfiles)
                      end
                    else
                      error = true if xargs_files(command, tempfiles)
                      files = [ ]
                      ran = true
                    end
                  end
                ensure
                  destroy_tempfiles(tempfiles)
                end
              end

              # If the command has hit the limit for the # of arguments, run it
              if !ran && config[:max_arguments_per_command] && files.size >= config[:max_arguments_per_command].to_i
                command, tempfiles = create_command(files)
                begin
                  error = true if xargs_files(command, tempfiles)
                  files = []
                  ran = true
                ensure
                  destroy_tempfiles(tempfiles)
                end
              end
            end
          end
        end

        # Any leftovers commands shall be run
        if files.size > 0
          command, tempfiles = create_command(files)
          begin
            error = true if xargs_files(command, tempfiles)
          ensure
            destroy_tempfiles(tempfiles)
          end
        end

        if error
          exit 1
        end
      end

      def get_patterns
        if config[:patterns]
          [ config[:patterns] ].flatten
        elsif config[:null_separator]
          stdin.binmode
          stdin.read.split("\000")
        else
          stdin.read.split(/\s+/)
        end
      end

      def create_command(files)
        command = name_args.join(" ")

        # Create the (empty) tempfiles
        tempfiles = {}
        begin
          # Create the temporary files
          files.each do |file|
            tempfile = Tempfile.new(file.name)
            tempfiles[tempfile] = { file: file }
          end
        rescue
          destroy_tempfiles(files)
          raise
        end

        # Create the command
        paths = tempfiles.keys.map(&:path).join(" ")
        if config[:replace_all]
          final_command = command.gsub(config[:replace_all], paths)
        elsif config[:replace_first]
          final_command = command.sub(config[:replace_first], paths)
        else
          final_command = "#{command} #{paths}"
        end

        [final_command, tempfiles]
      end

      def destroy_tempfiles(tempfiles)
        # Unlink the files now that we're done with them
        tempfiles.each_key(&:close!)
      end

      def xargs_files(command, tempfiles)
        error = false
        # Create the temporary files
        tempfiles.each_pair do |tempfile, file|

          value = file[:file].read
          file[:value] = value
          tempfile.open
          tempfile.write(value)
          tempfile.close
        rescue Chef::ChefFS::FileSystem::OperationNotAllowedError => e
          ui.error "#{format_path(e.entry)}: #{e.reason}."
          error = true
          tempfile.close!
          tempfiles.delete(tempfile)
          next
        rescue Chef::ChefFS::FileSystem::NotFoundError => e
          ui.error "#{format_path(e.entry)}: No such file or directory"
          error = true
          tempfile.close!
          tempfiles.delete(tempfile)
          next

        end

        return error if error && tempfiles.size == 0

        # Run the command
        if config[:verbose_commands] || Chef::Config[:verbosity] && Chef::Config[:verbosity] >= 1
          output sub_filenames(command, tempfiles)
        end
        command_output = `#{command}`
        command_output = sub_filenames(command_output, tempfiles)
        stdout.write command_output

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
              diff.gsub!(old_file.path, "#{format_path(file[:file])} (old)")
              diff.gsub!(tempfile.path, "#{format_path(file[:file])} (new)")
              stdout.write diff
            ensure
              old_file.close!
            end
          end
        end

        error
      end

      def sub_filenames(str, tempfiles)
        tempfiles.each_pair do |tempfile, file|
          str = str.gsub(tempfile.path, format_path(file[:file]))
        end
        str
      end

    end
  end
end
