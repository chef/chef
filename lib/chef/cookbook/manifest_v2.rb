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
    class ManifestV2
      extend Chef::Mixin::VersionedAPI

      minimum_api_version 2

      def self.from_hash(hash)
        Chef::Log.debug "processing manifest: #{hash}"
        Mash.new hash
      end

      def self.to_hash(manifest)
        result = manifest.manifest.dup
        result["all_files"].map! { |file| file.delete("full_path"); file }
        result["frozen?"] = manifest.frozen_version?
        result["chef_type"] = "cookbook_version"
        result.to_hash
      end

    end
  end
end
