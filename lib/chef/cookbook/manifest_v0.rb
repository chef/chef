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

require "chef/json_compat"
require "chef/mixin/versioned_api"

class Chef
  class Cookbook
    class ManifestV0
      extend Chef::Mixin::VersionedAPI

      minimum_api_version 0

      COOKBOOK_SEGMENTS = %w{ resources providers recipes definitions libraries attributes files templates root_files }

      def self.from_hash(hash)
        response = Mash.new(hash)
        response[:all_files] = COOKBOOK_SEGMENTS.inject([]) do |memo, segment|
          next memo if hash[segment].nil? || hash[segment].empty?
          hash[segment].each do |file|
            file["name"] = "#{segment}/#{file["name"]}" unless segment == "root_files"
            memo << file
          end
          response.delete(segment)
          memo
        end
        response
      end

      def self.to_hash(manifest)
        result = manifest.manifest.dup
        result.delete("all_files")

        files = manifest.by_parent_directory
        files.keys.each_with_object(result) do |parent, memo|
          if COOKBOOK_SEGMENTS.include?(parent)
            memo[parent] ||= []
            files[parent].each do |file|
              file["name"] = file["name"].split("/")[1] unless parent == "root_files"
              file.delete("full_path")
              memo[parent] << file
            end
          end
        end
        # Ensure all segments are set to [] if they don't exist.
        # See https://github.com/chef/chef/issues/6044
        COOKBOOK_SEGMENTS.each do |segment|
          result[segment] ||= []
        end

        result.merge({ "frozen?" => manifest.frozen_version?, "chef_type" => "cookbook_version" })
      end
    end
  end
end
