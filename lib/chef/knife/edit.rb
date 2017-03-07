require "chef/chef_fs/knife"

class Chef
  class Knife
    class Edit < Chef::ChefFS::Knife
      banner "knife edit [PATTERN1 ... PATTERNn]"

      category "path-based"

      deps do
        require "chef/chef_fs/file_system"
        require "chef/chef_fs/file_system/exceptions"
      end

      option :local,
        :long => "--local",
        :boolean => true,
        :description => "Show local files instead of remote"

      def run
        # Get the matches (recursively)
        error = false
        pattern_args.each do |pattern|
          Chef::ChefFS::FileSystem.list(config[:local] ? local_fs : chef_fs, pattern).each do |result|
            if result.dir?
              ui.error "#{format_path(result)}: is a directory" if pattern.exact_path
              error = true
            else
              begin
                new_value = edit_text(result.read, File.extname(result.name))
                if new_value
                  result.write(new_value)
                  output "Updated #{format_path(result)}"
                else
                  output "#{format_path(result)} unchanged"
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

      def edit_text(text, extension)
        if !config[:disable_editing]
          Tempfile.open([ "knife-edit-", extension ]) do |file|
            # Write the text to a temporary file
            file.write(text)
            file.close

            # Let the user edit the temporary file
            if !system("#{config[:editor]} #{file.path}")
              raise "Please set EDITOR environment variable. See https://docs.chef.io/knife_using.html for details."
            end

            result_text = IO.read(file.path)

            return result_text if result_text != text
          end
        end
      end
    end
  end
end
