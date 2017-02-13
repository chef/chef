require "chef/chef_fs/knife"

class Chef
  class Knife
    class Deps < Chef::ChefFS::Knife
      banner "knife deps PATTERN1 [PATTERNn]"

      category "path-based"

      deps do
        require "chef/chef_fs/file_system"
        require "chef/run_list"
      end

      option :recurse,
        :long => "--[no-]recurse",
        :boolean => true,
        :description => "List dependencies recursively (default: true). Only works with --tree."
      option :tree,
        :long => "--tree",
        :boolean => true,
        :description => "Show dependencies in a visual tree. May show duplicates."
      option :remote,
        :long => "--remote",
        :boolean => true,
        :description => "List dependencies on the server instead of the local filesystem"

      attr_accessor :exit_code

      def run
        if config[:recurse] == false && !config[:tree]
          ui.error "--no-recurse requires --tree"
          exit(1)
        end
        config[:recurse] = true if config[:recurse].nil?

        @root = config[:remote] ? chef_fs : local_fs
        dependencies = {}
        pattern_args.each do |pattern|
          Chef::ChefFS::FileSystem.list(@root, pattern).each do |entry|
            if config[:tree]
              print_dependencies_tree(entry, dependencies)
            else
              print_flattened_dependencies(entry, dependencies)
            end
          end
        end
        exit exit_code if exit_code
      end

      def print_flattened_dependencies(entry, dependencies)
        if !dependencies[entry.path]
          dependencies[entry.path] = get_dependencies(entry)
          dependencies[entry.path].each do |child|
            child_entry = Chef::ChefFS::FileSystem.resolve_path(@root, child)
            print_flattened_dependencies(child_entry, dependencies)
          end
          output format_path(entry)
        end
      end

      def print_dependencies_tree(entry, dependencies, printed = {}, depth = 0)
        dependencies[entry.path] = get_dependencies(entry) if !dependencies[entry.path]
        output "#{'  ' * depth}#{format_path(entry)}"
        if !printed[entry.path] && (config[:recurse] || depth == 0)
          printed[entry.path] = true
          dependencies[entry.path].each do |child|
            child_entry = Chef::ChefFS::FileSystem.resolve_path(@root, child)
            print_dependencies_tree(child_entry, dependencies, printed, depth + 1)
          end
        end
      end

      def get_dependencies(entry)
        if entry.parent && entry.parent.path == "/cookbooks"
          return entry.chef_object.metadata.dependencies.keys.map { |cookbook| "/cookbooks/#{cookbook}" }

        elsif entry.parent && entry.parent.path == "/nodes"
          node = Chef::JSONCompat.parse(entry.read)
          result = []
          if node["chef_environment"] && node["chef_environment"] != "_default"
            result << "/environments/#{node['chef_environment']}.json"
          end
          if node["run_list"]
            result += dependencies_from_runlist(node["run_list"])
          end
          result

        elsif entry.parent && entry.parent.path == "/roles"
          role = Chef::JSONCompat.parse(entry.read)
          result = []
          if role["run_list"]
            dependencies_from_runlist(role["run_list"]).each do |dependency|
              result << dependency if !result.include?(dependency)
            end
          end
          if role["env_run_lists"]
            role["env_run_lists"].each_pair do |env, run_list|
              dependencies_from_runlist(run_list).each do |dependency|
                result << dependency if !result.include?(dependency)
              end
            end
          end
          result

        elsif !entry.exists?
          raise Chef::ChefFS::FileSystem::NotFoundError.new(entry)

        else
          []
        end
      rescue Chef::ChefFS::FileSystem::NotFoundError => e
        ui.error "#{format_path(e.entry)}: No such file or directory"
        self.exit_code = 2
        []
      end

      def dependencies_from_runlist(run_list)
        chef_run_list = Chef::RunList.new
        chef_run_list.reset!(run_list)
        chef_run_list.map do |run_list_item|
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
