
require 'chef/config'
require 'chef/cookbook_version'
require 'chef/cookbook/chefignore'
require 'chef/cookbook/metadata'

class Chef
  class Cookbook
    class CookbookVersionLoader

      FILETYPES_SUBJECT_TO_IGNORE = [ :attribute_filenames,
                                      :definition_filenames,
                                      :recipe_filenames,
                                      :template_filenames,
                                      :file_filenames,
                                      :library_filenames,
                                      :resource_filenames,
                                      :provider_filenames]


      attr_reader :cookbook_name
      attr_reader :cookbook_settings
      attr_reader :metadata_filenames

      def initialize(path, chefignore=nil)
        @cookbook_path = File.expand_path( path )
        @cookbook_name = File.basename( path )
        @chefignore = chefignore
        @metadata = Hash.new
        @relative_path = /#{Regexp.escape(@cookbook_path)}\/(.+)$/
        @cookbook_settings = {
          :attribute_filenames  => {},
          :definition_filenames => {},
          :recipe_filenames     => {},
          :template_filenames   => {},
          :file_filenames       => {},
          :library_filenames    => {},
          :resource_filenames   => {},
          :provider_filenames   => {},
          :root_filenames       => {}
        }

        @metadata_filenames = []
      end

      def load_cookbooks
        load_as(:attribute_filenames, 'attributes', '*.rb')
        load_as(:definition_filenames, 'definitions', '*.rb')
        load_as(:recipe_filenames, 'recipes', '*.rb')
        load_as(:library_filenames, 'libraries', '*.rb')
        load_recursively_as(:template_filenames, "templates", "*")
        load_recursively_as(:file_filenames, "files", "*")
        load_recursively_as(:resource_filenames, "resources", "*.rb")
        load_recursively_as(:provider_filenames, "providers", "*.rb")
        load_root_files

        remove_ignored_files

        if File.exists?(File.join(@cookbook_path, "metadata.rb"))
          @metadata_filenames << File.join(@cookbook_path, "metadata.rb")
        elsif File.exists?(File.join(@cookbook_path, "metadata.json"))
          @metadata_filenames << File.join(@cookbook_path, "metadata.json")
        end

        if empty?
          Chef::Log.warn "found a directory #{cookbook_name} in the cookbook path, but it contains no cookbook files. skipping."
        end
        @cookbook_settings
      end

      def cookbook_version
        return nil if empty?

        Chef::CookbookVersion.new(@cookbook_name.to_sym).tap do |c|
          c.root_dir             = @cookbook_path
          c.attribute_filenames  = cookbook_settings[:attribute_filenames].values
          c.definition_filenames = cookbook_settings[:definition_filenames].values
          c.recipe_filenames     = cookbook_settings[:recipe_filenames].values
          c.template_filenames   = cookbook_settings[:template_filenames].values
          c.file_filenames       = cookbook_settings[:file_filenames].values
          c.library_filenames    = cookbook_settings[:library_filenames].values
          c.resource_filenames   = cookbook_settings[:resource_filenames].values
          c.provider_filenames   = cookbook_settings[:provider_filenames].values
          c.root_filenames       = cookbook_settings[:root_filenames].values
          c.metadata_filenames   = @metadata_filenames
          c.metadata             = metadata(c)
        end
      end

      # Generates the Cookbook::Metadata object
      def metadata(cookbook_version)
        @metadata = Chef::Cookbook::Metadata.new(cookbook_version)
        @metadata_filenames.each do |metadata_file|
          case metadata_file
          when /\.rb$/
            apply_ruby_metadata(metadata_file)
          when /\.json$/
            apply_json_metadata(metadata_file)
          else
            raise RuntimeError, "Invalid metadata file: #{metadata_file} for cookbook: #{cookbook_version}"
          end
        end
        @metadata
      end

      def empty?
        @cookbook_settings.values.all? { |files_hash| files_hash.empty? }
      end

      def merge!(other_cookbook_loader)
        other_cookbook_settings = other_cookbook_loader.cookbook_settings
        @cookbook_settings.each do |file_type, file_list|
          file_list.merge!(other_cookbook_settings[file_type])
        end
        @metadata_filenames.concat(other_cookbook_loader.metadata_filenames)
      end

      def chefignore
        @chefignore ||= Chefignore.new(File.basename(@cookbook_path))
      end

      def load_root_files
        Dir.glob(File.join(@cookbook_path, '*'), File::FNM_DOTMATCH).each do |file|
          next if File.directory?(file)
          @cookbook_settings[:root_filenames][file[@relative_path, 1]] = file
        end
      end

      def load_recursively_as(category, category_dir, glob)
        file_spec = File.join(@cookbook_path, category_dir, '**', glob)
        Dir.glob(file_spec, File::FNM_DOTMATCH).each do |file|
          next if File.directory?(file)
          @cookbook_settings[category][file[@relative_path, 1]] = file
        end
      end

      def load_as(category, *path_glob)
        Dir[File.join(@cookbook_path, *path_glob)].each do |file|
          @cookbook_settings[category][file[@relative_path, 1]] = file
        end
      end

      def remove_ignored_files
        @cookbook_settings.each_value do |file_list|
          file_list.reject! do |relative_path, full_path|
            chefignore.ignored?(relative_path)
          end
        end
      end

      def apply_ruby_metadata(file)
        begin
          @metadata.from_file(file)
        rescue JSON::ParserError
          Chef::Log.error("Error evaluating metadata.rb for #@cookbook_name in " + file)
          raise
        end
      end

      def apply_json_metadata(file)
        begin
          @metadata.from_json(IO.read(file))
        rescue JSON::ParserError
          Chef::Log.error("Couldn't parse cookbook metadata JSON for #@cookbook_name in " + file)
          raise
        end
      end

    end
  end
end
