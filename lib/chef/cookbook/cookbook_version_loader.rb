
require "chef/cookbook_version"
require "chef/cookbook/chefignore"
require "chef/cookbook/metadata"
require "chef/util/path_helper"
require "find"

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

      def initialize(path, chefignore = nil)
        @cookbook_path = File.expand_path( path ) # cookbook_path from which this was loaded
        # We keep a list of all cookbook paths that have been merged in
        @cookbook_paths = [ cookbook_path ]

        @inferred_cookbook_name = File.basename( path )
        @chefignore = chefignore
        @metadata = nil
        @relative_path = /#{Regexp.escape(@cookbook_path)}\/(.+)$/
        @metadata_loaded = false
        @cookbook_settings = {
          :all_files            => {},
          :attribute_filenames  => {},
          :definition_filenames => {},
          :recipe_filenames     => {},
          :template_filenames   => {},
          :file_filenames       => {},
          :library_filenames    => {},
          :resource_filenames   => {},
          :provider_filenames   => {},
          :root_filenames       => {},
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

        load_all_files

        remove_ignored_files

        load_as(:attribute_filenames, "attributes", "*.rb")
        load_as(:definition_filenames, "definitions", "*.rb")
        load_as(:recipe_filenames, "recipes", "*.rb")
        load_recursively_as(:library_filenames, "libraries", "*")
        load_recursively_as(:template_filenames, "templates", "*")
        load_recursively_as(:file_filenames, "files", "*")
        load_recursively_as(:resource_filenames, "resources", "*.rb")
        load_recursively_as(:provider_filenames, "providers", "*.rb")
        load_root_files

        if empty?
          Chef::Log.warn "Found a directory #{cookbook_name} in the cookbook path, but it contains no cookbook files. skipping."
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
          c.all_files            = cookbook_settings[:all_files].values
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
            raise "Invalid metadata file: #{metadata_file} for cookbook: #{cookbook_version}"
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

      # Enumerate all the files in a cookbook and assign the resulting list to
      # `cookbook_settings[:all_files]`. In order to behave in a compatible way
      # with previous implementations, directories at the cookbook's root that
      # begin with a dot are ignored. dotfiles are generally not ignored,
      # however if the file is named ".uploaded-cookbook-version.json" it is
      # assumed to be managed by chef-zero and not part of the cookbook.
      def load_all_files
        return unless File.exist?(cookbook_path)

        # If cookbook_path is a symlink, Find on Windows Ruby 2.3 will not traverse it.
        # Dir.entries will do so on all platforms, so we iterate the top level using
        # Dir.entries. Since we have different behavior at the top anyway (hidden
        # directories at the top level are not included for backcompat), this
        # actually keeps things a bit cleaner.
        Dir.entries(cookbook_path).each do |top_filename|
          # Skip top-level directories starting with "."
          top_path = File.join(cookbook_path, top_filename)
          next if File.directory?(top_path) && top_filename.start_with?(".")

          # Use Find.find because it:
          # (a) returns any children, recursively
          # (b) includes top_path as well
          # (c) skips symlinks, which is backcompat (no judgement on whether it was *right*)
          Find.find(top_path) do |path|
            # Only add files, not directories
            next unless File.file?(path)
            # Don't add .uploaded-cookbook-version.json
            next if File.basename(path) == UPLOADED_COOKBOOK_VERSION_FILE

            relative_path = Chef::Util::PathHelper.relative_path_from(cookbook_path, path)
            path = Pathname.new(path).cleanpath.to_s
            cookbook_settings[:all_files][relative_path] = path
          end
        end
      end

      def load_root_files
        select_files_by_glob(File.join(Chef::Util::PathHelper.escape_glob_dir(cookbook_path), "*"), File::FNM_DOTMATCH).each do |file|
          file = Chef::Util::PathHelper.cleanpath(file)
          next if File.directory?(file)
          next if File.basename(file) == UPLOADED_COOKBOOK_VERSION_FILE
          name = Chef::Util::PathHelper.relative_path_from(@cookbook_path, file)
          cookbook_settings[:root_filenames][name] = file
        end
      end

      def load_recursively_as(category, category_dir, glob)
        glob_pattern = File.join(Chef::Util::PathHelper.escape_glob_dir(cookbook_path, category_dir), "**", glob)
        select_files_by_glob(glob_pattern, File::FNM_DOTMATCH).each do |file|
          file = Chef::Util::PathHelper.cleanpath(file)
          name = Chef::Util::PathHelper.relative_path_from(@cookbook_path, file)
          cookbook_settings[category][name] = file
        end
      end

      def load_as(category, *path_glob)
        glob_pattern = File.join(Chef::Util::PathHelper.escape_glob_dir(cookbook_path), *path_glob)
        select_files_by_glob(glob_pattern).each do |file|
          file = Chef::Util::PathHelper.cleanpath(file)
          name = Chef::Util::PathHelper.relative_path_from(@cookbook_path, file)
          cookbook_settings[category][name] = file
        end
      end

      # Mimic Dir.glob inside a cookbook by running `File.fnmatch?` against
      # `cookbook_settings[:all_files]`.
      #
      # @param pattern [String] a glob string passed to `File.fnmatch?`
      # @param option [Integer] Option flag to control globbing behavior. These
      #   are constants defined on `File`, such as `File::FNM_DOTMATCH`.
      #   `File.fnmatch?` and `Dir.glob` only take one option argument, if you
      #   need to combine options, you must `|` the constants together. To make
      #   `File.fnmatch?` behave like `Dir.glob`, `File::FNM_PATHNAME` is
      #   always enabled.
      def select_files_by_glob(pattern, option = 0)
        combined_opts = option | File::FNM_PATHNAME
        cookbook_settings[:all_files].values.select do |path|
          File.fnmatch?(pattern, path, combined_opts)
        end
      end

      def remove_ignored_files
        cookbook_settings[:all_files].reject! do |relative_path, full_path|
          chefignore.ignored?(relative_path)
        end
      end

      def apply_ruby_metadata(file)
        begin
          @metadata.from_file(file)
        rescue Chef::Exceptions::JSON::ParseError
          Chef::Log.error("Error evaluating metadata.rb for #{@inferred_cookbook_name} in " + file)
          raise
        end
      end

      def apply_json_metadata(file)
        begin
          @metadata.from_json(IO.read(file))
        rescue Chef::Exceptions::JSON::ParseError
          Chef::Log.error("Couldn't parse cookbook metadata JSON for #{@inferred_cookbook_name} in " + file)
          raise
        end
      end

      def apply_json_cookbook_version_metadata(file)
        begin
          data = Chef::JSONCompat.parse(IO.read(file))
          @metadata.from_hash(data["metadata"])
          # the JSON cookbok metadata file is only used by chef-zero.
          # The Chef Server API currently does not enforce that the metadata
          # have a `name` field, but that will cause an error when attempting
          # to load the cookbook. To keep compatibility, we fake it by setting
          # the metadata name from the cookbook version object's name.
          #
          # This behavior can be removed if/when Chef Server enforces that the
          # metadata contains a name key.
          @metadata.name(data["cookbook_name"]) unless data["metadata"].key?("name")
        rescue Chef::Exceptions::JSON::ParseError
          Chef::Log.error("Couldn't parse cookbook metadata JSON for #{@inferred_cookbook_name} in " + file)
          raise
        end
      end

      def set_frozen
        if uploaded_cookbook_version_file
          begin
            data = Chef::JSONCompat.parse(IO.read(uploaded_cookbook_version_file))
            @frozen = data["frozen?"]
          rescue Chef::Exceptions::JSON::ParseError
            Chef::Log.error("Couldn't parse cookbook metadata JSON for #{@inferred_cookbook_name} in #{uploaded_cookbook_version_file}")
            raise
          end
        end
      end
    end
  end
end
