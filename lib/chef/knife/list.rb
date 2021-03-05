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
    class List < Chef::ChefFS::Knife
      banner "knife list [-dfR1p] [PATTERN1 ... PATTERNn] (options)"

      category "path-based"

      deps do
        require "chef/chef_fs/file_system" unless defined?(Chef::ChefFS::FileSystem)
        require "tty-screen"
      end

      option :recursive,
        short: "-R",
        boolean: true,
        description: "List directories recursively."

      option :bare_directories,
        short: "-d",
        boolean: true,
        description: "When directories match the pattern, do not show the directories' children."

      option :local,
        long: "--local",
        boolean: true,
        description: "List local directory instead of remote."

      option :flat,
        short: "-f",
        long: "--flat",
        boolean: true,
        description: "Show a list of filenames rather than the prettified ls-like output normally produced."

      option :one_column,
        short: "-1",
        boolean: true,
        description: "Show only one column of results."

      option :trailing_slashes,
        short: "-p",
        boolean: true,
        description: "Show trailing slashes after directories."

      attr_accessor :exit_code

      def run
        patterns = name_args.length == 0 ? [""] : name_args

        # Get the top-level matches
        all_results = parallelize(pattern_args_from(patterns)) do |pattern|
          pattern_results = Chef::ChefFS::FileSystem.list(config[:local] ? local_fs : chef_fs, pattern).to_a

          if pattern_results.first && !pattern_results.first.exists? && pattern.exact_path
            ui.error "#{format_path(pattern_results.first)}: No such file or directory"
            self.exit_code = 1
          end
          pattern_results
        end.flatten(1).to_a

        # Process directories
        if !config[:bare_directories]
          dir_results = parallelize(all_results.select(&:dir?)) do |result|
            add_dir_result(result)
          end.flatten(1)

        else
          dir_results = []
        end

        # Process all other results
        results = all_results.select { |result| result.exists? && (!result.dir? || config[:bare_directories]) }.to_a

        # Flatten out directory results if necessary
        if config[:flat]
          dir_results.each do |result, children| # rubocop:disable Style/HashEachMethods
            results += children
          end
          dir_results = []
        end

        # Sort by path for happy output
        results = results.sort_by(&:path)
        dir_results = dir_results.sort_by { |result| result[0].path }

        # Print!
        if results.length == 0 && dir_results.length == 1
          results = dir_results[0][1]
          dir_results = []
        end

        print_result_paths results
        printed_something = results.length > 0
        dir_results.each do |result, children|
          if printed_something
            output ""
          else
            printed_something = true
          end
          output "#{format_path(result)}:"
          print_results(children.map { |result| maybe_add_slash(result.display_name, result.dir?) }.sort, "")
        end

        exit exit_code if exit_code
      end

      def add_dir_result(result)
        begin
          children = result.children.sort_by(&:name)
        rescue Chef::ChefFS::FileSystem::NotFoundError => e
          ui.error "#{format_path(e.entry)}: No such file or directory"
          return []
        end

        result = [ [ result, children ] ]
        if config[:recursive]
          child_dirs = children.select(&:dir?)
          result += parallelize(child_dirs) { |child| add_dir_result(child) }.flatten(1).to_a
        end
        result
      end

      def print_result_paths(results, indent = "")
        print_results(results.map { |result| maybe_add_slash(format_path(result), result.dir?) }, indent)
      end

      def print_results(results, indent)
        return if results.length == 0

        print_space = results.map(&:length).max + 2
        if config[:one_column] || !stdout.isatty
          columns = 0
        else
          columns = TTY::Screen.columns
        end
        current_line = ""
        results.each do |result|
          if current_line.length > 0 && current_line.length + print_space > columns
            output current_line.rstrip
            current_line = ""
          end
          if current_line.length == 0
            current_line << indent
          end
          current_line << result
          current_line << (" " * (print_space - result.length))
        end
        output current_line.rstrip if current_line.length > 0
      end

      def maybe_add_slash(path, is_dir)
        if config[:trailing_slashes] && is_dir
          "#{path}/"
        else
          path
        end
      end
    end
  end
end
