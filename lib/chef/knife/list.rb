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
      option :local,
        :long => '--local',
        :boolean => true,
        :description => "List local directory instead of remote"
      option :flat,
        :long => '--flat',
        :boolean => true,
        :description => "Show a list of filenames rather than the prettified ls-like output normally produced"

      def run
        patterns = name_args.length == 0 ? [""] : name_args

        # Get the matches (recursively)
        results = []
        dir_results = []
        pattern_args_from(patterns).each do |pattern|
          Chef::ChefFS::FileSystem.list(config[:local] ? local_fs : chef_fs, pattern) do |result|
            if result.dir? && !config[:bare_directories]
              dir_results += add_dir_result(result)
            elsif result.exists?
              results << result
            elsif pattern.exact_path
              ui.error "#{format_path(result.path)}: No such file or directory"
            end
          end
        end

        if config[:flat]
          dir_results.each do |result, children|
            results += children
          end
          dir_results = []
        end

        results = results.sort_by { |result| result.path }
        dir_results = dir_results.sort_by { |result| result[0].path }

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
          output "#{format_path(result.path)}:"
          print_results(children.map { |result| result.name }.sort, "")
        end
      end

      def add_dir_result(result)
        begin
          children = result.children.sort_by { |child| child.name }
        rescue Chef::ChefFS::FileSystem::NotFoundError
          ui.error "#{format_path(result.path)}: No such file or directory"
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
        columns = stdout.isatty ? Integer(`tput cols`) : 0
        current_line = ''
        results.each do |result|
          if current_line.length > 0 && current_line.length + print_space > columns
            output current_line.rstrip
            current_line = ''
          end
          if current_line.length == 0
            current_line << indent
          end
          current_line << result
          current_line << (' ' * (print_space - result.length))
        end
        output current_line.rstrip if current_line.length > 0
      end
    end
  end
end

