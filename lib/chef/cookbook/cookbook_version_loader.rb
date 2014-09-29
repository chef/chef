
require 'chef/cookbook_version'
require 'chef/cookbook/chefignore'
require 'chef/cookbook/metadata'
require 'chef/util/path_helper'

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

      UPLOADED_COOKBOOK_VERSION_FILE = ".uploaded-cookbook-version.json".freeze

      attr_reader :cookbook_settings
      attr_reader :cookbook_paths
      attr_reader :metadata_filenames
      attr_reader :frozen
      attr_reader :uploaded_cookbook_version_file

      attr_reader :cookbook_path

      # The cookbook's name as inferred from its directory.
      attr_reader :inferred_cookbook_name

      attr_reader :metadata_error

      def initialize(path, chefignore=nil)
        @cookbook_path = File.expand_path( path ) # cookbook_path from which this was loaded
        # We keep a list of all cookbook paths that have been merged in
        @cookbook_paths = [ cookbook_path ]

        @inferred_cookbook_name = File.basename( path )
        @chefignore = chefignore
        @metadata = nil
        @relative_path = /#{Regexp.escape(@cookbook_path)}\/(.+)$/
        @metadata_loaded = false
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
        @metadata_error = nil
      end

      # Load the cookbook. Raises an error if the cookbook_path given to the
      # constructor doesn't point to a valid cookbook.
      def load!
        file_paths_map = load

        if empty?
          raise Exceptions::CookbookNotFoundInRepo, "The directory #{cookbook_path} does not contain a cookbook"
        end
        file_paths_map
      end

      # Load the cookbook. Does not raise an error if given a non-cookbook
      # directory as the cookbook_path. This behavior is provided for
      # compatibility, it is recommended to use #load! instead.
      def load
        metadata # force lazy evaluation to occur

        # re-raise any exception that occurred when reading the metadata
        raise_metadata_error!

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

        if empty?
          Chef::Log.warn "found a directory #{cookbook_name} in the cookbook path, but it contains no cookbook files. skipping."
        end
        @cookbook_settings
      end

      alias :load_cookbooks :load

      def metadata_filenames
        return @metadata_filenames unless @metadata_filenames.empty?
        if File.exists?(File.join(cookbook_path, UPLOADED_COOKBOOK_VERSION_FILE))
          @uploaded_cookbook_version_file = File.join(cookbook_path, UPLOADED_COOKBOOK_VERSION_FILE)
        end

        if File.exists?(File.join(cookbook_path, "metadata.rb"))
          @metadata_filenames << File.join(cookbook_path, "metadata.rb")
        elsif File.exists?(File.join(cookbook_path, "metadata.json"))
          @metadata_filenames << File.join(cookbook_path, "metadata.json")
        elsif @uploaded_cookbook_version_file
          @metadata_filenames << @uploaded_cookbook_version_file
        end

        # Set frozen based on .uploaded-cookbook-version.json
        set_frozen
        @metadata_filenames
      end

      def cookbook_version
        return nil if empty?

        Chef::CookbookVersion.new(cookbook_name, *cookbook_paths).tap do |c|
          c.attribute_filenames  = cookbook_settings[:attribute_filenames].values
          c.definition_filenames = cookbook_settings[:definition_filenames].values
          c.recipe_filenames     = cookbook_settings[:recipe_filenames].values
          c.template_filenames   = cookbook_settings[:template_filenames].values
          c.file_filenames       = cookbook_settings[:file_filenames].values
          c.library_filenames    = cookbook_settings[:library_filenames].values
          c.resource_filenames   = cookbook_settings[:resource_filenames].values
          c.provider_filenames   = cookbook_settings[:provider_filenames].values
          c.root_filenames       = cookbook_settings[:root_filenames].values
          c.metadata_filenames   = metadata_filenames
          c.metadata             = metadata

          c.freeze_version if @frozen
        end
      end

      def cookbook_name
        # The `name` attribute is now required in metadata, so
        # inferred_cookbook_name generally should not be used. Per CHEF-2923,
        # we have to not raise errors in cookbook metadata immediately, so that
        # users can still `knife cookbook upload some-cookbook` when an
        # unrelated cookbook has an error in its metadata.  This situation
        # could prevent us from reading the `name` attribute from the metadata
        # entirely, but the name is used as a hash key in CookbookLoader, so we
        # fall back to the inferred name here.
        (metadata.name || @inferred_cookbook_name).to_sym
      end

      # Generates the Cookbook::Metadata object
      def metadata
        return @metadata unless @metadata.nil?

        @metadata = Chef::Cookbook::Metadata.new

        metadata_filenames.each do |metadata_file|
          case metadata_file
          when /\.rb$/
            apply_ruby_metadata(metadata_file)
          when @uploaded_cookbook_version_file
            apply_json_cookbook_version_metadata(metadata_file)
          when /\.json$/
            apply_json_metadata(metadata_file)
          else
            raise RuntimeError, "Invalid metadata file: #{metadata_file} for cookbook: #{cookbook_version}"
          end
        end

        @metadata

        # Rescue errors so that users can upload cookbooks via `knife cookbook
        # upload` even if some cookbooks in their chef-repo have errors in
        # their metadata. We only rescue StandardError because you have to be
        # doing something *really* terrible to raise an exception that inherits
        # directly from Exception in your metadata.rb file.
      rescue StandardError => e
        @metadata_error = e
        @metadata
      end

      def raise_metadata_error!
        raise @metadata_error unless @metadata_error.nil?
        # Metadata won't be valid if the cookbook is empty. If the cookbook is
        # actually empty, a metadata error here would be misleading, so don't
        # raise it (if called by #load!, a different error is raised).
        if !empty? && !metadata.valid?
          message = "Cookbook loaded at path(s) [#{@cookbook_paths.join(', ')}] has invalid metadata: #{metadata.errors.join('; ')}"
          raise Exceptions::MetadataNotValid, message
        end
        false
      end

      def empty?
        cookbook_settings.values.all? { |files_hash| files_hash.empty? } && metadata_filenames.size == 0
      end

      def merge!(other_cookbook_loader)
        other_cookbook_settings = other_cookbook_loader.cookbook_settings
        cookbook_settings.each do |file_type, file_list|
          file_list.merge!(other_cookbook_settings[file_type])
        end
        metadata_filenames.concat(other_cookbook_loader.metadata_filenames)
        @cookbook_paths += other_cookbook_loader.cookbook_paths
        @frozen = true if other_cookbook_loader.frozen
        @metadata = nil # reset metadata so it gets reloaded and all metadata files applied.
        self
      end

      def chefignore
        @chefignore ||= Chefignore.new(File.basename(cookbook_path))
      end

      def load_root_files
        Dir.glob(File.join(Chef::Util::PathHelper.escape_glob(cookbook_path), '*'), File::FNM_DOTMATCH).each do |file|
          file = Chef::Util::PathHelper.cleanpath(file)
          next if File.directory?(file)
          next if File.basename(file) == UPLOADED_COOKBOOK_VERSION_FILE
          name = Chef::Util::PathHelper.relative_path_from(@cookbook_path, file)
          cookbook_settings[:root_filenames][name] = file
        end
      end

      def load_recursively_as(category, category_dir, glob)
        file_spec = File.join(Chef::Util::PathHelper.escape_glob(cookbook_path, category_dir), '**', glob)
        Dir.glob(file_spec, File::FNM_DOTMATCH).each do |file|
          file = Chef::Util::PathHelper.cleanpath(file)
          next if File.directory?(file)
          name = Chef::Util::PathHelper.relative_path_from(@cookbook_path, file)
          cookbook_settings[category][name] = file
        end
      end

      def load_as(category, *path_glob)
        Dir[File.join(Chef::Util::PathHelper.escape_glob(cookbook_path), *path_glob)].each do |file|
          file = Chef::Util::PathHelper.cleanpath(file)
          name = Chef::Util::PathHelper.relative_path_from(@cookbook_path, file)
          cookbook_settings[category][name] = file
        end
      end

      def remove_ignored_files
        cookbook_settings.each_value do |file_list|
          file_list.reject! do |relative_path, full_path|
            chefignore.ignored?(relative_path)
          end
        end
      end

      def apply_ruby_metadata(file)
        begin
          @metadata.from_file(file)
        rescue Chef::Exceptions::JSON::ParseError
          Chef::Log.error("Error evaluating metadata.rb for #@inferred_cookbook_name in " + file)
          raise
        end
      end

      def apply_json_metadata(file)
        begin
          @metadata.from_json(IO.read(file))
        rescue Chef::Exceptions::JSON::ParseError
          Chef::Log.error("Couldn't parse cookbook metadata JSON for #@inferred_cookbook_name in " + file)
          raise
        end
      end

      def apply_json_cookbook_version_metadata(file)
        begin
          data = Chef::JSONCompat.parse(IO.read(file))
          @metadata.from_hash(data['metadata'])
          # the JSON cookbok metadata file is only used by chef-zero.
          # The Chef Server API currently does not enforce that the metadata
          # have a `name` field, but that will cause an error when attempting
          # to load the cookbook. To keep compatibility, we fake it by setting
          # the metadata name from the cookbook version object's name.
          #
          # This behavior can be removed if/when Chef Server enforces that the
          # metadata contains a name key.
          @metadata.name(data['cookbook_name']) unless data['metadata'].key?('name')
        rescue Chef::Exceptions::JSON::ParseError
          Chef::Log.error("Couldn't parse cookbook metadata JSON for #@inferred_cookbook_name in " + file)
          raise
        end
      end

      def set_frozen
        if uploaded_cookbook_version_file
          begin
            data = Chef::JSONCompat.parse(IO.read(uploaded_cookbook_version_file))
            @frozen = data['frozen?']
          rescue Chef::Exceptions::JSON::ParseError
            Chef::Log.error("Couldn't parse cookbook metadata JSON for #@inferred_cookbook_name in #{uploaded_cookbook_version_file}")
            raise
          end
        end
      end
    end
  end
end
