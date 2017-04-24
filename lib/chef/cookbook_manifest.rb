# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2015-2017, Chef Software Inc.
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
require "chef/cookbook_manifest/file"
require "chef/cookbook_manifest/versions"
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
    def_delegator :@cookbook_version, :manifest_records_by_path
    def_delegator :@cookbook_version, :files_for
    def_delegator :@cookbook_version, :root_files
    def_delegator :@cookbook_version, :each_file

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
      generate_manifest
      @manifest
    end

    def checksums
      generate_manifest
      @checksums
    end

    def policy_mode?
      @policy_mode
    end

    def all_files
      @cookbook_version.all_files
    end

    def to_hash
      CookbookManifest::Versions.to_hash(self)
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
      manifest = CookbookManifest::Versions.from_hash(new_manifest)
      cookbook_version.cb_files = manifest[:all_files].each_with_object([]) do |file, memo|
        memo << CookbookManifest::File.from_hash(file)
      end
    end

    def by_parent_directory
      @by_parent_directory ||=
        all_files.each_with_object({}) do |file, memo|
          parent = file.part
          memo[parent] ||= []
          memo[parent] << file
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

      all_files.each do |file|
        csum = file.checksum
        @checksums[csum] = file

        manifest[:all_files] << file.to_hash
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

      @manifest = manifest
    end

  end
end
