# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Nuo Yan (<nuo@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Author:: Seth Falcon (<seth@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright 2008-2011 Opscode, Inc.
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

require 'chef/log'
require 'chef/cookbook/file_vendor'
require 'chef/cookbook/metadata'
require 'chef/version_class'
require 'chef/digester'
require 'chef/cookbook_manifest'

class Chef

  # == Chef::CookbookVersion
  # CookbookVersion is a model object encapsulating the data about a Chef
  # cookbook. Chef supports maintaining multiple versions of a cookbook on a
  # single server; each version is represented by a distinct instance of this
  # class.
  class CookbookVersion

    include Comparable

    COOKBOOK_SEGMENTS = [ :resources, :providers, :recipes, :definitions, :libraries, :attributes, :files, :templates, :root_files ]

    attr_accessor :root_paths
    attr_accessor :definition_filenames
    attr_accessor :template_filenames
    attr_accessor :file_filenames
    attr_accessor :library_filenames
    attr_accessor :resource_filenames
    attr_accessor :provider_filenames
    attr_accessor :root_filenames
    attr_accessor :name
    attr_accessor :metadata_filenames

    def status=(new_status)
      Chef::Log.deprecation("Deprecated method `status' called from #{caller(1).first}. This method will be removed")
      @status = new_status
    end

    def status
      Chef::Log.deprecation("Deprecated method `status' called from #{caller(1).first}. This method will be removed")
      @status
    end

    # A Chef::Cookbook::Metadata object. It has a setter that fixes up the
    # metadata to add descriptions of the recipes contained in this
    # CookbookVersion.
    attr_reader :metadata

    # attribute_filenames also has a setter that has non-default
    # functionality.
    attr_reader :attribute_filenames

    # recipe_filenames also has a setter that has non-default
    # functionality.
    attr_reader :recipe_filenames

    attr_reader :recipe_filenames_by_name
    attr_reader :attribute_filenames_by_short_filename

    attr_accessor :chef_server_rest

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

    # This is the one and only method that knows how cookbook files'
    # checksums are generated.
    def self.checksum_cookbook_file(filepath)
      Chef::Digester.generate_md5_checksum_for_file(filepath)
    rescue Errno::ENOENT
      Chef::Log.debug("File #{filepath} does not exist, so there is no checksum to generate")
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

      @attribute_filenames = Array.new
      @definition_filenames = Array.new
      @template_filenames = Array.new
      @file_filenames = Array.new
      @recipe_filenames = Array.new
      @recipe_filenames_by_name = Hash.new
      @library_filenames = Array.new
      @resource_filenames = Array.new
      @provider_filenames = Array.new
      @metadata_filenames = Array.new
      @root_filenames = Array.new

      # deprecated
      @status = :ready
      @file_vendor = nil
      @metadata = Chef::Cookbook::Metadata.new
      @chef_server_rest = chef_server_rest
    end

    def version
      metadata.version
    end

    # Indicates if this version is frozen or not. Freezing a coobkook version
    # indicates that a new cookbook with the same name and version number
    # shoule
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

    def attribute_filenames=(*filenames)
      @attribute_filenames = filenames.flatten
      @attribute_filenames_by_short_filename = filenames_by_name(attribute_filenames)
      attribute_filenames
    end

    def metadata=(metadata)
      @metadata = metadata
      @metadata.recipes_from_cookbook_version(self)
      @metadata
    end

    ## BACKCOMPAT/DEPRECATED - Remove these and fix breakage before release [DAN - 5/20/2010]##
    alias :attribute_files :attribute_filenames
    alias :attribute_files= :attribute_filenames=

    def manifest
      cookbook_manifest.manifest
    end

    # Returns a hash of checksums to either nil or the on disk path (which is
    # done by generate_manifest).
    def checksums
      cookbook_manifest.checksums
    end

    def manifest_records_by_path
      cookbook_manifest.manifest_records_by_path
    end

    def manifest=(new_manifest)
      cookbook_manifest.update_from(new_manifest)
    end

    # Return recipe names in the form of cookbook_name::recipe_name
    def fully_qualified_recipe_names
      results = Array.new
      recipe_filenames_by_name.each_key do |rname|
        results << "#{name}::#{rname}"
      end
      results
    end

    def recipe_filenames=(*filenames)
      @recipe_filenames = filenames.flatten
      @recipe_filenames_by_name = filenames_by_name(recipe_filenames)
      recipe_filenames
    end

    ## BACKCOMPAT/DEPRECATED - Remove these and fix breakage before release [DAN - 5/20/2010]##
    alias :recipe_files :recipe_filenames
    alias :recipe_files= :recipe_filenames=

    # called from DSL
    def load_recipe(recipe_name, run_context)
      unless recipe_filenames_by_name.has_key?(recipe_name)
        raise Chef::Exceptions::RecipeNotFound, "could not find recipe #{recipe_name} for cookbook #{name}"
      end

      Chef::Log.debug("Found recipe #{recipe_name} in cookbook #{name}")
      recipe = Chef::Recipe.new(name, recipe_name, run_context)
      recipe_filename = recipe_filenames_by_name[recipe_name]

      unless recipe_filename
        raise Chef::Exceptions::RecipeNotFound, "could not find #{recipe_name} files for cookbook #{name}"
      end

      recipe.from_file(recipe_filename)
      recipe
    end

    def segment_filenames(segment)
      unless COOKBOOK_SEGMENTS.include?(segment)
        raise ArgumentError, "invalid segment #{segment}: must be one of #{COOKBOOK_SEGMENTS.join(', ')}"
      end

      case segment.to_sym
      when :resources
        @resource_filenames
      when :providers
        @provider_filenames
      when :recipes
        @recipe_filenames
      when :libraries
        @library_filenames
      when :definitions
        @definition_filenames
      when :attributes
        @attribute_filenames
      when :files
        @file_filenames
      when :templates
        @template_filenames
      when :root_files
        @root_filenames
      end
    end

    def replace_segment_filenames(segment, filenames)
      case segment.to_sym
      when :recipes
        self.recipe_filenames = filenames
      when :attributes
        self.attribute_filenames = filenames
      else
        segment_filenames(segment).replace(filenames)
      end
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
        if segment == :files || segment == :templates
          error_message = "Cookbook '#{name}' (#{version}) does not contain a file at any of these locations:\n"
          error_locations = if filename.is_a?(Array)
            filename.map{|name| "  #{File.join(segment.to_s, name)}"}
          else
            [
              "  #{segment}/#{node[:platform]}-#{node[:platform_version]}/#{filename}",
              "  #{segment}/#{node[:platform]}/#{filename}",
              "  #{segment}/default/#{filename}",
              "  #{segment}/#{filename}",
            ]
          end
          error_message << error_locations.join("\n")
          existing_files = segment_filenames(segment)
          # Strip the root_dir prefix off all files for readability
          existing_files.map!{|path| path[root_dir.length+1..-1]} if root_dir
          # Show the files that the cookbook does have. If the user made a typo,
          # hopefully they'll see it here.
          unless existing_files.empty?
            error_message << "\n\nThis cookbook _does_ contain: ['#{existing_files.join("','")}']"
          end
          raise Chef::Exceptions::FileNotFound, error_message
        else
          raise Chef::Exceptions::FileNotFound, "cookbook #{name} does not contain file #{segment}/#{filename}"
        end
      end
    end

    def preferred_filename_on_disk_location(node, segment, filename, current_filepath=nil)
      manifest_record = preferred_manifest_record(node, segment, filename)
      if current_filepath && (manifest_record['checksum'] == self.class.checksum_cookbook_file(current_filepath))
        nil
      else
        file_vendor.get_filename(manifest_record['path'])
      end
    end

    def relative_filenames_in_preferred_directory(node, segment, dirname)
      preferences = preferences_for_path(node, segment, dirname)
      filenames_by_pref = Hash.new
      preferences.each { |pref| filenames_by_pref[pref] = Array.new }

      manifest[segment].each do |manifest_record|
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
        if manifest_record_path =~ /(#{Regexp.escape(segment.to_s)}\/[^\/]+\/#{Regexp.escape(dirname)})\/.+$/
          specificity_dirname = $1
          non_specific_path = manifest_record_path[/#{Regexp.escape(segment.to_s)}\/[^\/]+\/#{Regexp.escape(dirname)}\/(.+)$/, 1]
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
      records_by_pref = Hash.new
      preferences.each { |pref| records_by_pref[pref] = Array.new }

      manifest[segment].each do |manifest_record|
        manifest_record_path = manifest_record[:path]

        # extract the preference part from the path.
        if manifest_record_path =~ /(#{Regexp.escape(segment.to_s)}\/[^\/]+\/#{Regexp.escape(dirname)})\/.+$/
          # Note the specificy_dirname includes the segment and
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
            if e.message =~ /Cannot find a (?:platform|version)/
              platform = "/unknown_platform/"
              version = "/unknown_platform_version/"
            else
              raise
            end
          end

          fqdn = node[:fqdn]

          # Break version into components, eg: "5.7.1" => [ "5.7.1", "5.7", "5" ]
          search_versions = []
          parts = version.to_s.split('.')

          parts.size.times do
            search_versions << parts.join('.')
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
        relative_search_path.map {|relative_path| File.join(segment.to_s, relative_path)}
      else
        [File.join(segment, path)]
      end
    end
    private :preferences_for_path

    def self.json_create(o)
      cookbook_version = new(o["cookbook_name"])
      # We want the Chef::Cookbook::Metadata object to always be inflated
      cookbook_version.metadata = Chef::Cookbook::Metadata.from_hash(o["metadata"])
      cookbook_version.manifest = o

      # We don't need the following step when we decide to stop supporting deprecated operators in the metadata (e.g. <<, >>)
      cookbook_version.manifest["metadata"] = Chef::JSONCompat.from_json(Chef::JSONCompat.to_json(cookbook_version.metadata))

      cookbook_version.freeze_version if o["frozen?"]
      cookbook_version
    end

    def self.from_cb_artifact_data(o)
      cookbook_version = new(o["name"])
      # We want the Chef::Cookbook::Metadata object to always be inflated
      cookbook_version.metadata = Chef::Cookbook::Metadata.from_hash(o["metadata"])
      cookbook_version.manifest = o
      cookbook_version.identifier = o["identifier"]
      cookbook_version
    end

    # @deprecated This method was used by the Ruby Chef Server and is no longer
    #   needed. There is no replacement.
    def generate_manifest_with_urls(&url_generator)
      Chef::Log.deprecation("Deprecated method #generate_manifest_with_urls called from #{caller(1).first}")

      rendered_manifest = manifest.dup
      COOKBOOK_SEGMENTS.each do |segment|
        if rendered_manifest.has_key?(segment)
          rendered_manifest[segment].each do |manifest_record|
            url_options = { :cookbook_name => name.to_s, :cookbook_version => version, :checksum => manifest_record["checksum"] }
            manifest_record["url"] = url_generator.call(url_options)
          end
        end
      end
      rendered_manifest
    end


    def to_hash
      # TODO: this should become deprecated when the API for CookbookManifest becomes stable
      cookbook_manifest.to_hash
    end

    def to_json(*a)
      # TODO: this should become deprecated when the API for CookbookManifest becomes stable
      cookbook_manifest.to_json
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

    ##
    # REST API
    ##

    def save_url
      # TODO: this should become deprecated when the API for CookbookManifest becomes stable
      cookbook_manifest.save_url
    end

    def force_save_url
      # TODO: this should become deprecated when the API for CookbookManifest becomes stable
      cookbook_manifest.force_save_url
    end

    def chef_server_rest
      @chef_server_rest ||= self.chef_server_rest
    end

    def self.chef_server_rest
      Chef::REST.new(Chef::Config[:chef_server_url])
    end

    def destroy
      chef_server_rest.delete_rest("cookbooks/#{name}/#{version}")
      self
    end

    def self.load(name, version="_latest")
      version = "_latest" if version == "latest"
      chef_server_rest.get_rest("cookbooks/#{name}/#{version}")
    end

    # The API returns only a single version of each cookbook in the result from the cookbooks method
    def self.list
      chef_server_rest.get_rest('cookbooks')
    end

    # Alias latest_cookbooks as list
    class << self
      alias :latest_cookbooks :list
    end

    def self.list_all_versions
      chef_server_rest.get_rest('cookbooks?num_versions=all')
    end

    ##
    # Given a +cookbook_name+, get a list of all versions that exist on the
    # server.
    # ===Returns
    # [String]::  Array of cookbook versions, which are strings like 'x.y.z'
    # nil::       if the cookbook doesn't exist. an error will also be logged.
    def self.available_versions(cookbook_name)
      chef_server_rest.get_rest("cookbooks/#{cookbook_name}")[cookbook_name]["versions"].map do |cb|
        cb["version"]
      end
    rescue Net::HTTPServerException => e
      if e.to_s =~ /^404/
        Chef::Log.error("Cannot find a cookbook named #{cookbook_name}")
        nil
      else
        raise
      end
    end

    def <=>(o)
      raise Chef::Exceptions::CookbookVersionNameMismatch if self.name != o.name
      # FIXME: can we change the interface to the Metadata class such
      # that metadata.version returns a Chef::Version instance instead
      # of a string?
      Chef::Version.new(self.version) <=> Chef::Version.new(o.version)
    end

    private

    def cookbook_manifest
      @cookbook_manifest ||= CookbookManifest.new(self)
    end

    def find_preferred_manifest_record(node, segment, filename)
      preferences = preferences_for_path(node, segment, filename)

      # in order of prefernce, look for the filename in the manifest
      preferences.find {|preferred_filename| manifest_records_by_path[preferred_filename] }
    end

    # For each filename, produce a mapping of base filename (i.e. recipe name
    # or attribute file) to on disk location
    def filenames_by_name(filenames)
      filenames.select{|filename| filename =~ /\.rb$/}.inject({}){|memo, filename| memo[File.basename(filename, '.rb')] = filename ; memo }
    end

    def file_vendor
      unless @file_vendor
        @file_vendor = Chef::Cookbook::FileVendor.create_from_manifest(manifest)
      end
      @file_vendor
    end

  end
end
