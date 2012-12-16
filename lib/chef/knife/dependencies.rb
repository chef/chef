require 'chef/chef_fs/knife'
require 'chef/chef_fs/file_system'

class Chef
  class Knife
    class Dependencies < Chef::ChefFS::Knife
      banner "knife dependencies PATTERN1 [PATTERNn]"

      common_options

      option :recurse,
        :long => '--[no-]recurse',
        :boolean => true,
        :description => "List dependencies recursively (default: true).  Only works with --tree."
      option :tree,
        :long => '--tree',
        :boolean => true,
        :description => "Show dependencies in a visual tree.  May show duplicates."
      option :remote,
        :long => '--remote',
        :boolean => true,
        :description => "List dependencies on the server instead of the local filesystem"

      def run
        if config[:tree] && config[:recurse]
          STDERR.puts "--recurse requires --tree"
          exit(1)
        end
        config[:recurse] = true if config[:recurse].nil?

        @root = config[:remote] ? chef_fs : local_fs
        dependencies = {}
        pattern_args.each do |pattern|
          Chef::ChefFS::FileSystem.list(@root, pattern) do |entry|
            if config[:tree]
              print_dependencies_tree(entry, dependencies)
            else
              print_flattened_dependencies(entry, dependencies)
            end
          end
        end
      end

      def print_flattened_dependencies(entry, dependencies)
        if !dependencies[entry.path]
          puts format_path(entry.path)
          dependencies[entry.path] = get_dependencies(entry)
          dependencies[entry.path].each do |child|
            child_entry = Chef::ChefFS::FileSystem.resolve_path(@root, child)
            print_flattened_dependencies(child_entry, dependencies)
          end
        end
      end

      def print_dependencies_tree(entry, dependencies, printed = {}, depth = 0)
        dependencies[entry.path] = get_dependencies(entry) if !dependencies[entry.path]
        puts "#{'  '*depth}#{format_path(entry.path)}"
        if !printed[entry.path] && (config[:recurse] || depth <= 1)
          printed[entry.path] = true
          dependencies[entry.path].each do |child|
            child_entry = Chef::ChefFS::FileSystem.resolve_path(@root, child)
            print_dependencies_tree(child_entry, dependencies, printed, depth+1)
          end
        end
      end

      def get_dependencies(entry)
        begin
          object = entry.chef_object
        rescue Chef::ChefFS::FileSystem::NotFoundError
          STDERR.puts "#{result.path_for_printing}: No such file or directory"
          return []
        end
        if !object
          STDERR.puts "ERROR: #{entry} is not a Chef object!"
          return []
        end

        if object.is_a?(Chef::CookbookVersion)
          return object.metadata.dependencies.keys.map { |cookbook| "/cookbooks/#{cookbook}"}
        elsif object.is_a?(Chef::Node)
          return [ "/environments/#{object.chef_environment}.json" ] + dependencies_from_runlist(object.run_list)
        elsif object.is_a?(Chef::Role)
          result = []
          object.env_run_lists.each_pair do |env,run_list|
            dependencies_from_runlist(run_list).each do |dependency|
              result << dependency if !result.include?(dependency)
            end
          end
          return result
        else
          return []
        end
      end

      def dependencies_from_runlist(run_list)
        result = run_list.map do |run_list_item|
          case run_list_item.type
          when :role
            "/roles/#{run_list_item.name}.json"
          when :recipe
            if run_list_item.name =~ /(.+)::[^:]*/
              "/cookbooks/#{$1}"
            else
              "/cookbooks/#{run_list_item.name}"
            end
          else
            raise "Unknown run list item type #{run_list_item.type}"
          end
        end
      end
    end
  end
end

