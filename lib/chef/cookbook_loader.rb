#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) Chef Software Inc.
# Copyright:: Copyright 2009-2016, Daniel DeLeo
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

require_relative "config"
require_relative "exceptions"
require_relative "cookbook/cookbook_version_loader"
require_relative "cookbook_version"
require_relative "cookbook/chefignore"
require_relative "cookbook/metadata"

class Chef
  # This class is used by knife, cheffs and legacy chef-solo modes.  It is not used by the server mode
  # of chef-client or zolo/zero modes.
  #
  # This class implements orchestration around producing a single cookbook_version for a cookbook or
  # loading a Mash of all cookbook_versions, using the cookbook_version_loader class, and doing
  # lazy-access and memoization to only load each cookbook once on demand.
  #
  # This implements a key-value style each which makes it appear to be a Hash of String => CookbookVersion
  # pairs where the String is the cookbook name.  The use of Enumerable combined with the Hash-style
  # each is likely not entirely sane.
  #
  # This object is also passed and injected into the CookbookCollection object where it is converted
  # to a Mash that looks almost exactly like the cookbook_by_name Mash in this object.
  #
  class CookbookLoader
    # @return [Array<String>] the array of repo paths containing cookbook dirs
    attr_reader :repo_paths

    # XXX: this is highly questionable combined with the Hash-style each method
    include Enumerable

    # @param repo_paths [Array<String>] the array of repo paths containing cookbook dirs
    def initialize(*repo_paths)
      @repo_paths = repo_paths.flatten.compact.map { |p| File.expand_path(p) }
      raise ArgumentError, "You must specify at least one cookbook repo path" if @repo_paths.empty?
    end

    # The primary function of this class is to build this Mash mapping cookbook names as a string to
    # the CookbookVersion objects for them.  Callers must call "load_cookbooks" first.
    #
    # @return [Mash<String, Chef::CookbookVersion>]
    def cookbooks_by_name
      @cookbooks_by_name ||= Mash.new
    end

    # This class also builds a mapping of cookbook names to their Metadata objects.  Callers must call
    # "load_cookbooks" first.
    #
    # @return [Mash<String, Chef::Cookbook::Metadata>]
    def metadata
      @metadata ||= Mash.new
    end

    # Loads all cookbooks across all repo_paths
    #
    # @return [Mash<String, Chef::CookbookVersion>] the cookbooks_by_name Mash
    def load_cookbooks
      cookbook_version_loaders.each_key do |cookbook_name|
        load_cookbook(cookbook_name)
      end
      cookbooks_by_name
    end

    # Loads a single cookbook by its name.
    #
    # @param [String]
    # @return [Chef::CookbookVersion]
    def load_cookbook(cookbook_name)
      unless cookbook_version_loaders.key?(cookbook_name)
        raise Exceptions::CookbookNotFoundInRepo, "Cannot find a cookbook named #{cookbook_name}; did you forget to add metadata to a cookbook? (https://docs.chef.io/config_rb_metadata/)"
      end

      return cookbooks_by_name[cookbook_name] if cookbooks_by_name.key?(cookbook_name)

      loader = cookbook_version_loaders[cookbook_name]

      loader.load!

      cookbook_version = loader.cookbook_version
      cookbooks_by_name[cookbook_name] = cookbook_version
      metadata[cookbook_name] = cookbook_version.metadata unless cookbook_version.nil?
      cookbook_version
    end

    def [](cookbook)
      load_cookbook(cookbook)
    end

    alias :fetch :[]

    def has_key?(cookbook_name)
      not self[cookbook_name.to_sym].nil?
    end

    alias :cookbook_exists? :has_key?
    alias :key? :has_key?

    def each
      cookbooks_by_name.keys.sort_by(&:to_s).each do |cname|
        yield(cname, cookbooks_by_name[cname])
      end
    end

    def each_key(&block)
      cookbook_names.each(&block)
    end

    def each_value(&block)
      values.each(&block)
    end

    def cookbook_names
      cookbooks_by_name.keys.sort
    end

    def values
      cookbooks_by_name.values
    end

    # This method creates tmp directory and copies all cookbooks into it and creates cookbook loader object which points to tmp directory
    def self.copy_to_tmp_dir_from_array(cookbooks)
      Dir.mktmpdir do |tmp_dir|
        cookbooks.each do |cookbook|
          checksums_to_on_disk_paths = cookbook.checksums
          cookbook.each_file do |manifest_record|
            path_in_cookbook = manifest_record[:path]
            on_disk_path = checksums_to_on_disk_paths[manifest_record[:checksum]]
            dest = File.join(tmp_dir, cookbook.name.to_s, path_in_cookbook)
            FileUtils.mkdir_p(File.dirname(dest))
            FileUtils.cp_r(on_disk_path, dest)
          end
        end
        tmp_cookbook_loader ||= begin
          Chef::Cookbook::FileVendor.fetch_from_disk(tmp_dir)
          CookbookLoader.new(tmp_dir)
        end
        yield tmp_cookbook_loader
      end
    end

    # generates metadata.json adds it in the manifest
    def compile_metadata
      each do |cookbook_name, cookbook|
        compiled_metadata = cookbook.compile_metadata
        if compiled_metadata
          cookbook.all_files << compiled_metadata
          cookbook.cookbook_manifest.send(:generate_manifest)
        end
      end
    end

    # freeze versions of all the cookbooks
    def freeze_versions
      each do |cookbook_name, cookbook|
        cookbook.freeze_version
      end
    end

    alias :cookbooks :values

    private

    # Helper method to lazily create and remember the chefignore object
    # for a given repo_path.
    #
    # @param [String] repo_path the full path to the cookbook directory of the repo
    # @return [Chef::Cookbook::Chefignore] the chefignore object for the repo_path
    def chefignore(repo_path)
      @chefignores ||= {}
      @chefignores[repo_path] ||= Cookbook::Chefignore.new(repo_path)
    end

    def all_directories_in_repo_paths
      @all_directories_in_repo_paths ||=
        all_files_in_repo_paths.select { |path| File.directory?(path) }
    end

    def all_files_in_repo_paths
      @all_files_in_repo_paths ||=
        repo_paths.inject([]) do |all_children, repo_path|
          all_children + Dir[File.join(Chef::Util::PathHelper.escape_glob_dir(repo_path), "*")]
        end
    end

    # This method creates a Mash of the CookbookVersionLoaders for each cookbook.
    #
    # @return [Mash<String, Cookbook::CookbookVersionLoader>]
    def cookbook_version_loaders
      @cookbook_version_loaders ||=
        begin
          mash = Mash.new
          all_directories_in_repo_paths.each do |cookbook_path|
            loader = Cookbook::CookbookVersionLoader.new(cookbook_path, chefignore(cookbook_path))
            cookbook_name = loader.cookbook_name
            if mash.key?(cookbook_name)
              raise Chef::Exceptions::CookbookMergingError, "Cookbook merging is no longer supported, the cookbook named #{cookbook_name} can only appear once in the cookbook_path"
            end

            mash[cookbook_name] = loader
          end
          mash
        end
    end
  end
end
