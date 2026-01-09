# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "../json_compat"
require_relative "../mixin/versioned_api"

class Chef
  class Cookbook
    class ManifestV2
      extend Chef::Mixin::VersionedAPI

      minimum_api_version 2

      class << self
        def from_hash(hash)
          Chef::Log.trace "processing manifest: #{hash}"
          Mash.new hash
        end

        def to_h(manifest)
          result = manifest.manifest.dup
          result["all_files"].map! { |file| file.delete("full_path"); file }
          result["frozen?"] = manifest.frozen_version?
          result["chef_type"] = "cookbook_version"
          result.to_hash
        end

        alias_method :to_hash, :to_h
      end

    end
  end
end
