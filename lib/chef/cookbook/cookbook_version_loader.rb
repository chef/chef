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

require_relative "../cookbook_version"
require_relative "chefignore"
require_relative "metadata"
require_relative "../util/path_helper"
require "find" unless defined?(Find.find)

class Chef
  class Cookbook
    # This class is only used directly from the Chef::CookbookLoader and from chef-fs,
    # so it only affects legacy-mode chef-client runs and knife.  It is not used by
    # server or zolo/zero modes.
    #
    # This seems to be mostly a glorified factory method for creating CookbookVersion
    # objects now, with creating Metadata objects bolted onto the side?  It used
    # to be also responsible for the merging of multiple objects when creating
    # shadowed/merged cookbook versions from multiple sources.  It also handles
    # Chefignore files.
    #
    class CookbookVersionLoader

      UPLOADED_COOKBOOK_VERSION_FILE = ".uploaded-cookbook-version.json".freeze

      attr_reader :cookbook_settings
      attr_reader :frozen
      attr_reader :uploaded_cookbook_version_file

      attr_reader :cookbook_path

      # The cookbook's name as inferred from its directory.
      attr_reader :inferred_cookbook_name

      attr_reader :metadata_error

      def initialize(path, chefignore = nil)
        @cookbook_path = File.expand_path( path ) # cookbook_path from which this was loaded

        @inferred_cookbook_name = File.basename( path )
        @chefignore = chefignore
        @metadata = nil
        @relative_path = %r{#{Regexp.escape(cookbook_path)}/(.+)$}
        @metadata_loaded = false
        @cookbook_settings = {
          all_files: {},
        }

        @metadata_filenames = []
        @metadata_error = nil
      end

      # Load the cookbook. Raises an error if the cookbook_path given to the
      # constructor doesn't point to a valid cookbook.
      def load!
        metadata # force lazy evaluation to occur

        # re-raise any exception that occurred when reading the metadata
        raise_metadata_error!

        load_all_files

        remove_ignored_files

        if empty?
          raise Exceptions::CookbookNotFoundInRepo, "The directory #{cookbook_path} does not contain a cookbook"
        end

        cookbook_settings
      end

      def load
        Chef.deprecated(:internal_api, "Chef::Cookbook::CookbookVersionLoader's load method is deprecated. Please use load! instead.")
        metadata # force lazy evaluation to occur

        # re-raise any exception that occurred when reading the metadata
        raise_metadata_error!

        load_all_files

        remove_ignored_files

        if empty?
          Chef::Log.warn "Found a directory #{cookbook_name} in the cookbook path, but it contains no cookbook files. skipping."
        end

        cookbook_settings
      end

      alias :load_cookbooks :load

      def cookbook_version
        return nil if empty?

        Chef::CookbookVersion.new(cookbook_name, cookbook_path).tap do |c|
          c.all_files            = cookbook_settings[:all_files].values
          c.metadata             = metadata

          c.freeze_version if frozen
        end
      end

      # Generates the Cookbook::Metadata object
      def metadata
        return @metadata unless @metadata.nil?

        @metadata = Chef::Cookbook::Metadata.new

        metadata_filenames.each do |metadata_file|
          case metadata_file
          when /\.rb$/
            apply_ruby_metadata(metadata_file)
          when uploaded_cookbook_version_file
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

      def cookbook_name
        # The `name` attribute is now required in metadata, so
        # inferred_cookbook_name generally should not be used. Per CHEF-2923,
        # we have to not raise errors in cookbook metadata immediately, so that
        # users can still `knife cookbook upload some-cookbook` when an
        # unrelated cookbook has an error in its metadata.  This situation
        # could prevent us from reading the `name` attribute from the metadata
        # entirely, but the name is used as a hash key in CookbookLoader, so we
        # fall back to the inferred name here.
        (metadata.name || inferred_cookbook_name).to_sym
      end

      private

      def metadata_filenames
        return @metadata_filenames unless @metadata_filenames.empty?

        if File.exist?(File.join(cookbook_path, UPLOADED_COOKBOOK_VERSION_FILE))
          @uploaded_cookbook_version_file = File.join(cookbook_path, UPLOADED_COOKBOOK_VERSION_FILE)
        end

        if File.exist?(File.join(cookbook_path, "metadata.json"))
          @metadata_filenames << File.join(cookbook_path, "metadata.json")
        elsif File.exist?(File.join(cookbook_path, "metadata.rb"))
          @metadata_filenames << File.join(cookbook_path, "metadata.rb")
        elsif uploaded_cookbook_version_file
          @metadata_filenames << uploaded_cookbook_version_file
        end

        # Set frozen based on .uploaded-cookbook-version.json
        set_frozen
        @metadata_filenames
      end

      def raise_metadata_error!
        raise metadata_error unless metadata_error.nil?

        # Metadata won't be valid if the cookbook is empty. If the cookbook is
        # actually empty, a metadata error here would be misleading, so don't
        # raise it (if called by #load!, a different error is raised).
        if !empty? && !metadata.valid?
          message = "Cookbook loaded at path [#{cookbook_path}] has invalid metadata: #{metadata.errors.join("; ")}"
          raise Exceptions::MetadataNotValid, message
        end
        false
      end

      def empty?
        cookbook_settings.values.all?(&:empty?) && metadata_filenames.size == 0
      end

      def chefignore
        @chefignore ||= Chefignore.new(cookbook_path)
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

      def remove_ignored_files
        cookbook_settings[:all_files].reject! do |relative_path, full_path|
          chefignore.ignored?(relative_path)
        end
      end

      def apply_ruby_metadata(file)
        @metadata.from_file(file)
      rescue Chef::Exceptions::JSON::ParseError
        Chef::Log.error("Error evaluating metadata.rb for #{inferred_cookbook_name} in " + file)
        raise
      end

      def apply_json_metadata(file)
        @metadata.from_json(IO.read(file))
      rescue Chef::Exceptions::JSON::ParseError
        Chef::Log.error("Couldn't parse cookbook metadata JSON for #{inferred_cookbook_name} in " + file)
        raise
      end

      def apply_json_cookbook_version_metadata(file)
        data = Chef::JSONCompat.parse(IO.read(file))
        @metadata.from_hash(data["metadata"])
        # the JSON cookbook metadata file is only used by chef-zero.
        # The Chef Server API currently does not enforce that the metadata
        # have a `name` field, but that will cause an error when attempting
        # to load the cookbook. To keep compatibility, we fake it by setting
        # the metadata name from the cookbook version object's name.
        #
        # This behavior can be removed if/when Chef Server enforces that the
        # metadata contains a name key.
        @metadata.name(data["cookbook_name"]) unless data["metadata"].key?("name")
      rescue Chef::Exceptions::JSON::ParseError
        Chef::Log.error("Couldn't parse cookbook metadata JSON for #{inferred_cookbook_name} in " + file)
        raise
      end

      def set_frozen
        if uploaded_cookbook_version_file
          begin
            data = Chef::JSONCompat.parse(IO.read(uploaded_cookbook_version_file))
            @frozen = data["frozen?"]
          rescue Chef::Exceptions::JSON::ParseError
            Chef::Log.error("Couldn't parse cookbook metadata JSON for #{inferred_cookbook_name} in #{uploaded_cookbook_version_file}")
            raise
          end
        end
      end
    end
  end
end
