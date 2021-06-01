# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Nuo Yan (<nuo@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Author:: Tim Hinderliter (<tim@chef.io>)
# Author:: Seth Falcon (<seth@chef.io>)
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "log"
require_relative "cookbook/file_vendor"
require_relative "cookbook/metadata"
require_relative "version_class"
require_relative "digester"
require_relative "cookbook_manifest"
require_relative "server_api"

class Chef

  # == Chef::CookbookVersion
  # CookbookVersion is a model object encapsulating the data about a Chef
  # cookbook. Chef supports maintaining multiple versions of a cookbook on a
  # single server; each version is represented by a distinct instance of this
  # class.
  class CookbookVersion

    include Comparable
    extend Forwardable

    def_delegator :@cookbook_manifest, :files_for
    def_delegator :@cookbook_manifest, :each_file

    COOKBOOK_SEGMENTS = %i{resources providers recipes definitions libraries attributes files templates root_files}.freeze

    attr_reader :all_files

    attr_accessor :root_paths
    attr_accessor :name

    # A Chef::Cookbook::Metadata object. It has a setter that fixes up the
    # metadata to add descriptions of the recipes contained in this
    # CookbookVersion.
    attr_reader :metadata

    # The `identifier` field is used for cookbook_artifacts, which are
    # organized on the chef server according to their content. If the
    # policy_mode option to CookbookManifest is set to true it will include
    # this field in the manifest Hash and in the upload URL.
    #
    # This field may be removed or have different behavior in the future, don't
    # use it in 3rd party code.
    # @api private
    attr_accessor :identifier

    # The first root path is the primary cookbook dir, from which metadata is loaded
    def root_dir
      root_paths[0]
    end

    def all_files=(files)
      @all_files = Array(files)
      cookbook_manifest.reset!
    end

    # This is the one and only method that knows how cookbook files'
    # checksums are generated.
    def self.checksum_cookbook_file(filepath)
      Chef::Digester.generate_md5_checksum_for_file(filepath)
    rescue Errno::ENOENT
      Chef::Log.trace("File #{filepath} does not exist, so there is no checksum to generate")
      nil
    end

    def self.cache
      Chef::FileCache
    end

    # Creates a new Chef::CookbookVersion object.
    #
    # === Returns
    # object<Chef::CookbookVersion>:: Duh. :)
    def initialize(name, *root_paths, chef_server_rest: nil)
      @name = name
      @root_paths = root_paths
      @frozen = false

      @all_files = []

      @file_vendor = nil
      @cookbook_manifest = Chef::CookbookManifest.new(self)
      @metadata = Chef::Cookbook::Metadata.new
      @chef_server_rest = chef_server_rest
    end

    def version
      metadata.version
    end

    # Indicates if this version is frozen or not. Freezing a cookbook version
    # indicates that a new cookbook with the same name and version number
    # should
    def frozen_version?
      @frozen
    end

    def freeze_version
      @frozen = true
    end

    def version=(new_version)
      cookbook_manifest.reset!
      metadata.version(new_version)
    end

    def full_name
      "#{name}-#{version}"
    end

    def attribute_filenames_by_short_filename
      @attribute_filenames_by_short_filename ||= begin
        name_map = filenames_by_name(files_for("attributes"))
        root_alias = cookbook_manifest.root_files.find { |record| record[:name] == "root_files/attributes.rb" }
        name_map["default"] = root_alias[:full_path] if root_alias
        name_map
      end
    end

    def recipe_yml_filenames_by_name
      @recipe_yml_filenames_by_name ||= begin
        name_map = yml_filenames_by_name(files_for("recipes"))
        root_alias = cookbook_manifest.root_files.find { |record|
          record[:name] == "root_files/recipe.yml" ||
            record[:name] == "root_files/recipe.yaml"
        }
        if root_alias
          Chef::Log.error("Cookbook #{name} contains both recipe.yml and recipes/default.yml, ignoring recipes/default.yml") if name_map["default"]
          name_map["default"] = root_alias[:full_path]
        end
        name_map
      end
    end

    def recipe_filenames_by_name
      @recipe_filenames_by_name ||= begin
        name_map = filenames_by_name(files_for("recipes"))
        root_alias = cookbook_manifest.root_files.find { |record| record[:name] == "root_files/recipe.rb" }
        if root_alias
          Chef::Log.error("Cookbook #{name} contains both recipe.rb and and recipes/default.rb, ignoring recipes/default.rb") if name_map["default"]
          name_map["default"] = root_alias[:full_path]
        end
        name_map
      end
    end

    def metadata=(metadata)
      @metadata = metadata
      @metadata.recipes_from_cookbook_version(self)
    end

    def manifest
      cookbook_manifest.manifest
    end

    def manifest=(new_manifest)
      cookbook_manifest.update_from(new_manifest)
    end

    # Returns a hash of checksums to either nil or the on disk path (which is
    # done by generate_manifest).
    def checksums
      cookbook_manifest.checksums
    end

    def manifest_records_by_path
      cookbook_manifest.manifest_records_by_path
    end

    # Return recipe names in the form of cookbook_name::recipe_name
    def fully_qualified_recipe_names
      files_for("recipes").inject([]) do |memo, recipe|
        rname = recipe[:name].split("/")[1]
        rname = File.basename(rname, ".rb")
        memo << "#{name}::#{rname}"
        memo
      end
    end

    # called from DSL
    def load_recipe(recipe_name, run_context)
      if recipe_filenames_by_name.key?(recipe_name)
        load_ruby_recipe(recipe_name, run_context)
      elsif recipe_yml_filenames_by_name.key?(recipe_name)
        load_yml_recipe(recipe_name, run_context)
      else
        raise Chef::Exceptions::RecipeNotFound, "could not find recipe #{recipe_name} for cookbook #{name}"
      end
    end

    def load_yml_recipe(recipe_name, run_context)
      Chef::Log.trace("Found recipe #{recipe_name} in cookbook #{name}")
      recipe = Chef::Recipe.new(name, recipe_name, run_context)
      recipe_filename = recipe_yml_filenames_by_name[recipe_name]

      unless recipe_filename
        raise Chef::Exceptions::RecipeNotFound, "could not find #{recipe_name} files for cookbook #{name}"
      end

      recipe.from_yaml_file(recipe_filename)
      recipe
    end

    def load_ruby_recipe(recipe_name, run_context)
      Chef::Log.trace("Found recipe #{recipe_name} in cookbook #{name}")
      recipe = Chef::Recipe.new(name, recipe_name, run_context)
      recipe_filename = recipe_filenames_by_name[recipe_name]

      unless recipe_filename
        raise Chef::Exceptions::RecipeNotFound, "could not find #{recipe_name} files for cookbook #{name}"
      end

      recipe.from_file(recipe_filename)
      recipe
    end

    def segment_filenames(segment)
      files_for(segment).map { |f| f["full_path"] || File.join(root_dir, f["path"]) }
    end

    # Query whether a template file +template_filename+ is available. File
    # specificity for the given +node+ is obeyed in the lookup.
    def has_template_for_node?(node, template_filename)
      !!find_preferred_manifest_record(node, :templates, template_filename)
    end

    # Query whether a cookbook_file file +cookbook_filename+ is available. File
    # specificity for the given +node+ is obeyed in the lookup.
    def has_cookbook_file_for_node?(node, cookbook_filename)
      !!find_preferred_manifest_record(node, :files, cookbook_filename)
    end

    # Determine the most specific manifest record for the given
    # segment/filename, given information in the node. Throws
    # FileNotFound if there is no such segment and filename in the
    # manifest.
    #
    # A manifest record is a Mash that follows the following form:
    # {
    #   :name => "example.rb",
    #   :path => "files/default/example.rb",
    #   :specificity => "default",
    #   :checksum => "1234"
    # }
    def preferred_manifest_record(node, segment, filename)
      found_pref = find_preferred_manifest_record(node, segment, filename)
      if found_pref
        manifest_records_by_path[found_pref]
      else
        if %i{files templates}.include?(segment)
          error_message = "Cookbook '#{name}' (#{version}) does not contain a file at any of these locations:\n"
          error_locations = if filename.is_a?(Array)
                              filename.map { |name| "  #{File.join(segment.to_s, name)}" }
                            else
                              [
                                "  #{segment}/host-#{node[:fqdn]}/#{filename}",
                                "  #{segment}/#{node[:platform]}-#{node[:platform_version]}/#{filename}",
                                "  #{segment}/#{node[:platform]}/#{filename}",
                                "  #{segment}/default/#{filename}",
                                "  #{segment}/#{filename}",
                              ]
                            end
          error_message << error_locations.join("\n")
          existing_files = segment_filenames(segment)
          # Strip the root_dir prefix off all files for readability
          pretty_existing_files = existing_files.map do |path|
            if root_dir
              path[root_dir.length + 1..-1]
            else
              path
            end
          end
          # Show the files that the cookbook does have. If the user made a typo,
          # hopefully they'll see it here.
          unless pretty_existing_files.empty?
            error_message << "\n\nThis cookbook _does_ contain: ['#{pretty_existing_files.join("','")}']"
          end
          raise Chef::Exceptions::FileNotFound, error_message
        else
          raise Chef::Exceptions::FileNotFound, "cookbook #{name} does not contain file #{segment}/#{filename}"
        end
      end
    end

    def preferred_filename_on_disk_location(node, segment, filename, current_filepath = nil)
      manifest_record = preferred_manifest_record(node, segment, filename)
      if current_filepath && (manifest_record["checksum"] == self.class.checksum_cookbook_file(current_filepath))
        nil
      else
        file_vendor.get_filename(manifest_record["path"])
      end
    end

    def relative_filenames_in_preferred_directory(node, segment, dirname)
      preferences = preferences_for_path(node, segment, dirname)
      filenames_by_pref = {}
      preferences.each { |pref| filenames_by_pref[pref] = [] }

      files_for(segment).each do |manifest_record|
        manifest_record_path = manifest_record[:path]

        # find the NON SPECIFIC filenames, but prefer them by filespecificity.
        # For example, if we have a file:
        # 'files/default/somedir/somefile.conf' we only keep
        # 'somedir/somefile.conf'. If there is also
        # 'files/$hostspecific/somedir/otherfiles' that matches the requested
        # hostname specificity, that directory will win, as it is more specific.
        #
        # This is clearly ugly b/c the use case is for remote directory, where
        # we're just going to make cookbook_files out of these and make the
        # cookbook find them by filespecificity again. but it's the shortest
        # path to "success" for now.
        if manifest_record_path =~ %r{(#{Regexp.escape(segment.to_s)}/[^/]*/?#{Regexp.escape(dirname)})/.+$}
          specificity_dirname = $1
          non_specific_path = manifest_record_path[%r{#{Regexp.escape(segment.to_s)}/[^/]*/?#{Regexp.escape(dirname)}/(.+)$}, 1]
          # Record the specificity_dirname only if it's in the list of
          # valid preferences
          if filenames_by_pref[specificity_dirname]
            filenames_by_pref[specificity_dirname] << non_specific_path
          end
        end
      end

      best_pref = preferences.find { |pref| !filenames_by_pref[pref].empty? }

      raise Chef::Exceptions::FileNotFound, "cookbook #{name} has no directory #{segment}/default/#{dirname}" unless best_pref

      filenames_by_pref[best_pref]
    end

    # Determine the manifest records from the most specific directory
    # for the given node. See #preferred_manifest_record for a
    # description of entries of the returned Array.
    def preferred_manifest_records_for_directory(node, segment, dirname)
      preferences = preferences_for_path(node, segment, dirname)
      records_by_pref = {}
      preferences.each { |pref| records_by_pref[pref] = [] }

      files_for(segment).each do |manifest_record|
        manifest_record_path = manifest_record[:path]

        # extract the preference part from the path.
        if manifest_record_path =~ %r{(#{Regexp.escape(segment.to_s)}/[^/]+/#{Regexp.escape(dirname)})/.+$}
          # Note the specificity_dirname includes the segment and
          # dirname argument as above, which is what
          # preferences_for_path returns. It could be
          # "files/ubuntu-9.10/dirname", for example.
          specificity_dirname = $1

          # Record the specificity_dirname only if it's in the list of
          # valid preferences
          if records_by_pref[specificity_dirname]
            records_by_pref[specificity_dirname] << manifest_record
          end
        end
      end

      best_pref = preferences.find { |pref| !records_by_pref[pref].empty? }

      raise Chef::Exceptions::FileNotFound, "cookbook #{name} (#{version}) has no directory #{segment}/default/#{dirname}" unless best_pref

      records_by_pref[best_pref]
    end

    # Given a node, segment and path (filename or directory name),
    # return the priority-ordered list of preference locations to
    # look.
    def preferences_for_path(node, segment, path)
      # only files and templates can be platform-specific
      if segment.to_sym == :files || segment.to_sym == :templates
        relative_search_path = if path.is_a?(Array)
                                 path
                               else
                                 begin
                                   platform, version = Chef::Platform.find_platform_and_version(node)
                                 rescue ArgumentError => e
                                   # Skip platform/version if they were not found by find_platform_and_version
                                   if /Cannot find a (?:platform|version)/.match?(e.message)
                                     platform = "/unknown_platform/"
                                     version = "/unknown_platform_version/"
                                   else
                                     raise
                                   end
                                 end

                                 fqdn = node[:fqdn]

                                 # Break version into components, eg: "5.7.1" => [ "5.7.1", "5.7", "5" ]
                                 search_versions = []
                                 parts = version.to_s.split(".")

                                 parts.size.times do
                                   search_versions << parts.join(".")
                                   parts.pop
                                 end

                                 # Most specific to least specific places to find the path
                                 search_path = [ File.join("host-#{fqdn}", path) ]
                                 search_versions.each do |v|
                                   search_path << File.join("#{platform}-#{v}", path)
                                 end
                                 search_path << File.join(platform.to_s, path)
                                 search_path << File.join("default", path)
                                 search_path << path

                                 search_path
                               end
        relative_search_path.map { |relative_path| File.join(segment.to_s, relative_path) }
      else
        if segment.to_sym == :root_files
          [path]
        else
          [File.join(segment, path)]
        end
      end
    end
    private :preferences_for_path

    def display
      output = Mash.new
      output["cookbook_name"] = name
      output["name"] = full_name
      output["frozen?"] = frozen_version?
      output["metadata"] = metadata.to_h
      output["version"] = version
      output.merge(cookbook_manifest.by_parent_directory)
    end

    def self.from_hash(o)
      cookbook_version = new(o["cookbook_name"] || o["name"])

      # We want the Chef::Cookbook::Metadata object to always be inflated
      cookbook_version.manifest = o
      cookbook_version.metadata = Chef::Cookbook::Metadata.from_hash(o["metadata"])
      cookbook_version.identifier = o["identifier"] if o.key?("identifier")

      # We don't need the following step when we decide to stop supporting deprecated operators in the metadata (e.g. <<, >>)
      cookbook_version.manifest["metadata"] = Chef::JSONCompat.from_json(Chef::JSONCompat.to_json(cookbook_version.metadata))

      cookbook_version.freeze_version if o["frozen?"]
      cookbook_version
    end

    def self.from_cb_artifact_data(o)
      from_hash(o)
    end

    def metadata_json_file
      File.join(root_paths[0], "metadata.json")
    end

    def metadata_rb_file
      File.join(root_paths[0], "metadata.rb")
    end

    def reload_metadata!
      if File.exists?(metadata_json_file)
        metadata.from_json(IO.read(metadata_json_file))
      end
    end

    def has_metadata_file?
      all_files.include?(metadata_json_file) || all_files.include?(metadata_rb_file)
    end

    ##
    # REST API
    ##

    def chef_server_rest
      @chef_server_rest ||= chef_server_rest
    end

    def self.chef_server_rest
      Chef::ServerAPI.new(Chef::Config[:chef_server_url], { version_class: Chef::CookbookManifestVersions })
    end

    def destroy
      chef_server_rest.delete("cookbooks/#{name}/#{version}")
      self
    end

    def self.load(name, version = "_latest")
      version = "_latest" if version == "latest"
      from_hash(chef_server_rest.get("cookbooks/#{name}/#{version}"))
    end

    # The API returns only a single version of each cookbook in the result from the cookbooks method
    def self.list
      chef_server_rest.get("cookbooks")
    end

    # Alias latest_cookbooks as list
    class << self
      alias :latest_cookbooks :list
    end

    def self.list_all_versions
      chef_server_rest.get("cookbooks?num_versions=all")
    end

    ##
    # Given a +cookbook_name+, get a list of all versions that exist on the
    # server.
    # ===Returns
    # [String]::  Array of cookbook versions, which are strings like 'x.y.z'
    # nil::       if the cookbook doesn't exist. an error will also be logged.
    def self.available_versions(cookbook_name)
      chef_server_rest.get("cookbooks/#{cookbook_name}")[cookbook_name]["versions"].map do |cb|
        cb["version"]
      end
    rescue Net::HTTPClientException => e
      if /^404/.match?(e.to_s)
        Chef::Log.error("Cannot find a cookbook named #{cookbook_name}")
        nil
      else
        raise
      end
    end

    def <=>(other)
      raise Chef::Exceptions::CookbookVersionNameMismatch if name != other.name

      # FIXME: can we change the interface to the Metadata class such
      # that metadata.version returns a Chef::Version instance instead
      # of a string?
      Chef::Version.new(version) <=> Chef::Version.new(other.version)
    end

    def cookbook_manifest
      @cookbook_manifest ||= CookbookManifest.new(self)
    end

    def compile_metadata(path = root_dir)
      json_file = "#{path}/metadata.json"
      rb_file = "#{path}/metadata.rb"
      return nil if File.exist?(json_file)

      md = Chef::Cookbook::Metadata.new
      md.from_file(rb_file)
      f = File.open(json_file, "w")
      f.write(Chef::JSONCompat.to_json_pretty(md))
      f.close
      f.path
    end

    private

    def find_preferred_manifest_record(node, segment, filename)
      preferences = preferences_for_path(node, segment, filename)

      # in order of preference, look for the filename in the manifest
      preferences.find { |preferred_filename| manifest_records_by_path[preferred_filename] }
    end

    # For each manifest record, produce a mapping of base filename (i.e. recipe name
    # or attribute file) to on disk location
    def relative_paths_by_name(records)
      records.select { |record| record[:name] =~ /\.rb$/ }.inject({}) { |memo, record| memo[File.basename(record[:name], ".rb")] = record[:path]; memo }
    end

    # For each manifest record, produce a mapping of base filename (i.e. recipe name
    # or attribute file) to on disk location
    def filenames_by_name(records)
      records.select { |record| record[:name] =~ /\.rb$/ }.inject({}) { |memo, record| memo[File.basename(record[:name], ".rb")] = record[:full_path]; memo }
    end

    # Filters YAML files from the superset of provided files.
    # Checks for duplicate basenames with differing extensions (eg yaml v yml)
    # and raises error if any are detected.
    # This prevents us from arbitrarily the ".yaml" or ".yml" version when both are present,
    # because we don't know which is correct.
    # This method runs in O(n^2) where N = number of yml files present. This number should be consistently
    # low enough that there's no noticeable perf impact.
    def yml_filenames_by_name(records)
      yml_files = records.select { |record| record[:name] =~ /\.(y[a]?ml)$/ }
      result = yml_files.inject({}) do |acc, record|
        filename = record[:name]
        base_dup_name = File.join(File.dirname(filename), File.basename(filename, File.extname(filename)))
        yml_files.each do |other|
          if other[:name] =~ /#{(File.extname(filename) == ".yml") ? "#{base_dup_name}.yaml" : "#{base_dup_name}.yml"}$/
            raise Chef::Exceptions::AmbiguousYAMLFile.new("Cookbook #{name}@#{version} contains ambiguous files: #{filename} and #{other[:name]}. Please update the cookbook to remove the incorrect file.")
          end
        end
        acc[File.basename(record[:name], File.extname(record[:name]))] = record[:full_path]
        acc
      end
      result
    end

    def file_vendor
      @file_vendor ||= Chef::Cookbook::FileVendor.create_from_manifest(cookbook_manifest)
    end

  end
end
