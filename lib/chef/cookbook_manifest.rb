# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2015-2016, Chef Software Inc.
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

require "forwardable"
require "chef/mixin/versioned_api"
require "chef/util/path_helper"
require "chef/cookbook/manifest_v0"
require "chef/cookbook/manifest_v2"
require "chef/log"

class Chef

  # Handles the details of representing a cookbook in JSON form for uploading
  # to a Chef Server.
  class CookbookManifest

    extend Forwardable

    attr_reader :cookbook_version

    def_delegator :@cookbook_version, :root_paths
    def_delegator :@cookbook_version, :name
    def_delegator :@cookbook_version, :identifier
    def_delegator :@cookbook_version, :metadata
    def_delegator :@cookbook_version, :full_name
    def_delegator :@cookbook_version, :version
    def_delegator :@cookbook_version, :frozen_version?

    # Create a new CookbookManifest object for the given `cookbook_version`.
    # You can subsequently call #to_hash to get a Hash representation of the
    # cookbook_version in the "manifest" format, or #to_json to get a JSON
    # representation of the cookbook_version.
    #
    # The inferface for this behavior is expected to change as we implement new
    # manifest formats. The entire class should be considered a private API for
    # now.
    #
    # @api private
    # @param policy_mode [Boolean] whether to convert cookbooks to Hash/JSON in
    #   the format used by the `cookbook_artifacts` endpoint (for policyfiles).
    #   Setting this option also changes the behavior of #save_url and
    #   #force_save_url such that CookbookVersions will be uploaded to the new
    #   `cookbook_artifacts` API.
    def initialize(cookbook_version, policy_mode: false)
      @cookbook_version = cookbook_version
      @policy_mode = !!policy_mode

      reset!
    end

    # Resets all lazily computed values.
    def reset!
      @manifest = nil
      @checksums = nil
      @manifest_records_by_path = nil
      true
    end

    # Returns a 'manifest' data structure that can be uploaded to a Chef
    # Server.
    #
    # The format is as follows:
    #
    #     {
    #       :cookbook_name  => name,            # String
    #       :metadata       => metadata,        # Chef::Cookbook::Metadata
    #       :version        => version,         # Chef::Version
    #       :name           => full_name,       # String of "#{name}-#{version}"
    #
    #       :recipes        => Array<FileSpec>,
    #       :definitions    => Array<FileSpec>,
    #       :libraries      => Array<FileSpec>,
    #       :attributes     => Array<FileSpec>,
    #       :files          => Array<FileSpec>,
    #       :templates      => Array<FileSpec>,
    #       :resources      => Array<FileSpec>,
    #       :providers      => Array<FileSpec>,
    #       :root_files     => Array<FileSpec>
    #     }
    #
    # Where a `FileSpec` is a Hash of the form:
    #
    #     {
    #       :name         => file_name,
    #       :path         => path,
    #       :checksum     => csum,
    #       :specificity  => specificity
    #     }
    #
    def manifest
      @manifest || generate_manifest
      @manifest
    end

    def checksums
      @manifest || generate_manifest
      @checksums
    end

    def manifest_records_by_path
      @manifest || generate_manifest
      @manifest_records_by_path
    end

    def policy_mode?
      @policy_mode
    end

    def to_hash
      CookbookManifestVersions.to_hash(self)
    end

    def to_json(*a)
      result = to_hash
      result["json_class"] = "Chef::CookbookVersion"
      Chef::JSONCompat.to_json(result, *a)
    end

    # Return the URL to save (PUT) this object to the server via the
    # REST api. If there is an existing document on the server and it
    # is marked frozen, a PUT will result in a 409 Conflict.
    def save_url
      if policy_mode?
        "#{named_cookbook_url}/#{identifier}"
      else
        "#{named_cookbook_url}/#{version}"
      end
    end

    def named_cookbook_url
      "#{cookbook_url_path}/#{name}"
    end

    # Adds the `force=true` parameter to the upload URL. This allows
    # the user to overwrite a frozen cookbook (a PUT against the
    # normal #save_url raises a 409 Conflict in this case).
    def force_save_url
      "#{save_url}?force=true"
    end

    # Update this CookbookManifest from the contents of another manifest, and
    # make the corresponding changes to the cookbook_version object. Required
    # to provide backward compatibility with CookbookVersion#manifest= method.
    def update_from(new_manifest)
      @manifest = Chef::CookbookManifestVersions.from_hash(new_manifest)
      @checksums = extract_checksums_from_manifest(@manifest)
      @manifest_records_by_path = extract_manifest_records_by_path(@manifest)
    end

    # @api private
    # takes a list of hashes
    def add_files_to_manifest(files)
      manifest[:all_files].concat(Array(files))
      @checksums = extract_checksums_from_manifest(@manifest)
      @manifest_records_by_path = extract_manifest_records_by_path(@manifest)
    end

    def files_for(part)
      return root_files if part.to_s == "root_files"
      manifest[:all_files].select do |file|
        seg = file[:name].split("/")[0]
        part.to_s == seg
      end
    end

    def each_file(excluded_parts: [], &block)
      excluded_parts = Array(excluded_parts).map { |p| p.to_s }

      manifest[:all_files].each do |file|
        seg = file[:name].split("/")[0]
        next if excluded_parts.include?(seg)
        yield file if block_given?
      end
    end

    def by_parent_directory
      @by_parent_directory ||=
        manifest[:all_files].inject({}) do |memo, file|
          parts = file[:name].split("/")
          parent = if parts.length == 1
                     "root_files"
                   else
                     parts[0]
                   end

          memo[parent] ||= []
          memo[parent] << file
          memo
        end
    end

    def root_files
      manifest[:all_files].select do |file|
        file[:name].split("/").length == 1
      end
    end

    private

    def cookbook_url_path
      policy_mode? ? "cookbook_artifacts" : "cookbooks"
    end

    # See #manifest for a description of the manifest return value.
    # See #preferred_manifest_record for a description an individual manifest record.
    def generate_manifest
      manifest = Mash.new({
        all_files: Array.new,
      })
      @checksums = {}

      if !root_paths || root_paths.size == 0
        Chef::Log.error("Cookbook #{name} does not have root_paths! Cannot generate manifest.")
        raise "Cookbook #{name} does not have root_paths! Cannot generate manifest."
      end

      @cookbook_version.all_files.each do |file|
        next if File.directory?(file)

        name, path, specificity = parse_file_from_root_paths(file)

        csum = checksum_cookbook_file(file)
        @checksums[csum] = file
        rs = Mash.new({
          :name => name,
          :path => path,
          :checksum => csum,
          :specificity => specificity,
          # full_path is not a part of the normal manifest, but is very useful to keep around.
          # uploaders should strip this out.
          :full_path => file,
        })

        manifest[:all_files] << rs
      end

      manifest[:metadata] = metadata
      manifest[:version] = metadata.version

      if policy_mode?
        manifest[:name] = name.to_s
        manifest[:identifier] = identifier
      else
        manifest[:name] = full_name
        manifest[:cookbook_name] = name.to_s
      end

      @manifest_records_by_path = extract_manifest_records_by_path(manifest)
      @manifest = manifest
    end

    def parse_file_from_root_paths(file)
      root_paths.each do |root_path|
        pathname = Chef::Util::PathHelper.relative_path_from(root_path, file)

        parts = pathname.each_filename.take(2)
        # Check if path is actually under root_path
        next if parts[0] == ".."

        # if we have a root_file, such as metadata.rb, the first part will be "."
        return [ pathname.to_s, pathname.to_s, "default" ] if parts.length == 1

        segment = parts[0]

        name = File.join(segment, pathname.basename.to_s)

        if segment == "templates" || segment == "files"
          # Check if pathname looks like files/foo or templates/foo (unscoped)
          if pathname.each_filename.to_a.length == 2
            # Use root_default in case the same path exists at root_default and default
            return [ name, pathname.to_s, "root_default" ]
          else
            return [ name, pathname.to_s, parts[1] ]
          end
        else
          return [ name, pathname.to_s, "default" ]
        end
      end
      Chef::Log.error("Cookbook file #{file} not under cookbook root paths #{root_paths.inspect}.")
      raise "Cookbook file #{file} not under cookbook root paths #{root_paths.inspect}."
    end

    def extract_checksums_from_manifest(manifest)
      manifest[:all_files].inject({}) do |memo, manifest_record|
        memo[manifest_record[:checksum]] = nil
        memo
      end
    end

    def checksum_cookbook_file(filepath)
      CookbookVersion.checksum_cookbook_file(filepath)
    end

    def extract_manifest_records_by_path(manifest)
      manifest[:all_files].inject({}) do |memo, manifest_record|
        memo[manifest_record[:path]] = manifest_record
        memo
      end
    end

  end
  class CookbookManifestVersions

    extend Chef::Mixin::VersionedAPIFactory
    add_versioned_api_class Chef::Cookbook::ManifestV0
    add_versioned_api_class Chef::Cookbook::ManifestV2

    def_versioned_delegator :from_hash
    def_versioned_delegator :to_hash
  end
end
