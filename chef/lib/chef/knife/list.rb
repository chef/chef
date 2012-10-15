require 'chef/chef_fs/knife'
require 'chef/chef_fs/file_system'

class Chef
  class Knife
    class List < Chef::ChefFS::Knife
      banner "knife list [-dR] [PATTERN1 ... PATTERNn]"

      common_options

      option :recursive,
        :short => '-R',
        :boolean => true,
        :description => "List directories recursively."
      option :bare_directories,
        :short => '-d',
        :boolean => true,
        :description => "When directories match the pattern, do not show the directories' children."

      def run
        patterns = name_args.length == 0 ? [""] : name_args

        # Get the matches (recursively)
        results = []
        dir_results = []
        pattern_args_from(patterns).each do |pattern|
          Chef::ChefFS::FileSystem.list(chef_fs, pattern) do |result|
            if result.dir? && !config[:bare_directories]
              dir_results += add_dir_result(result)
            elsif result.exists?
              results << result
            elsif pattern.exact_path
              STDERR.puts "#{format_path(result.path)}: No such file or directory"
            end
          end
        end

        results = results.sort_by { |result| result.path }
        dir_results = dir_results.sort_by { |result| result[0].path }

        if results.length == 0 && dir_results.length == 1
          results = dir_results[0][1]
          dir_results = []
        end

        print_result_paths results
        dir_results.each do |result, children|
          puts ""
          puts "#{format_path(result.path)}:"
          print_results(children.map { |result| result.name }.sort, "")
        end
      end

      def add_dir_result(result)
        begin
          children = result.children.sort_by { |child| child.name }
        rescue Chef::ChefFS::FileSystem::NotFoundError
          STDERR.puts "#{format_path(result.path)}: No such file or directory"
          return []
        end

        result = [ [ result, children ] ]
        if config[:recursive]
          children.each do |child|
            if child.dir?
              result += add_dir_result(child)
            end
          end
        end
        result
      end

      def list_dirs_recursive(children)
        results = children.select { |child| child.dir? }.to_a
        results.each do |child|
          results += list_dirs_recursive(child.children)
        end
        results
      end

      def print_result_paths(results, indent = "")
        print_results(results.map { |result| format_path(result.path) }, indent)
      end

      def print_results(results, indent)
        return if results.length == 0

        print_space = results.map { |result| result.length }.max + 2
        # TODO: tput cols is not cross platform
        columns = $stdout.isatty ? Integer(`tput cols`) : 0
        current_column = 0
        results.each do |result|
          if current_column != 0 && current_column + print_space > columns
            puts ""
            current_column = 0
          end
          if current_column == 0
            print indent
            current_column += indent.length
          end
          print result + (' ' * (print_space - result.length))
          current_column += print_space
        end
        puts ""
      end
    end
  end
end

