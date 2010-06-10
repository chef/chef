#
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

require 'chef/cookbook/file_vendor'

# This FileVendor loads files from Chef::Config.cookbook_path. The
# thing that's sort of janky about this FileVendor implementation is
# that it basically takes only the cookbook's name from the manifest
# and throws the rest away then re-builds the list of files on the
# disk. This is due to the manifest not having the on-disk file
# locations, since in the chef-client case, that information is
# non-sensical.
class Chef
  class Cookbook
    class RemoteFileVendor < FileVendor
      
      def initialize(manifest, rest)
        @manifest = manifest
        @cookbook_name = @manifest[:cookbook_name]
        @rest = rest
      end
      
      # Implements abstract base's requirement. It looks in the
      # Chef::Config.cookbook_path file hierarchy for the requested
      # file.
      def get_filename(filename)
        if filename =~ /([^\/]+)\/(.+)$/
          segment = $1
        else
          raise "get_filename: cannot determine segment/filename for incoming filename #{filename}"
        end
        
        raise "no such segment #{segment} in cookbook #{@cookbook_name}" unless @manifest[segment]
        found_manifest_record = @manifest[segment].find {|manifest_record| manifest_record[:path] == filename }
        puts "@manifest = #{@manifest.inspect}"
        raise "no such file #{filename} in #{@cookbook_name}" unless found_manifest_record
        
        cache_filename = File.join("cookbooks", @cookbook_name, found_manifest_record['path'])

        current_checksum = nil
        if Chef::FileCache.has_key?(cache_filename)
          current_checksum = Chef::CookbookVersion.checksum_cookbook_file(Chef::FileCache.load(cache_filename, false))
        end

        # If the checksums are different between on-disk (current) and on-server
        # (remote, per manifest), do the update. This will also execute if there
        # is no current checksum.
        if current_checksum != found_manifest_record['checksum']
          raw_file = @rest.get_rest(found_manifest_record[:url], true)

          Chef::Log.info("Storing updated #{cache_filename} in the cache.")
          Chef::FileCache.move_to(raw_file.path, cache_filename)
        else
          Chef::Log.info("Not storing #{cache_filename}, as the cache is up to date.")
        end

        full_path_cache_filename = Chef::FileCache.load(cache_filename, false)
        Chef::Log.debug("full_path_cache_filename = #{full_path_cache_filename}")

        # return the filename, not the contents (second argument= false)
        full_path_cache_filename
      end
      
    end
  end
end
