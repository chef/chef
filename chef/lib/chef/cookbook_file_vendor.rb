#
# Author:: Christopher Walters (<cw@opscode.com>)
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


# This class handles fetching of cookbook files based on specificity. A local
# filesystem cache is maintained based on the checksum of files retrieved.
class Chef
  class CookbookFileVendor
    def initialize
      @cookbook_cache = Hash.new
      @checksum_cache = Chef::Cache::FileCacheByChecksum.new
    end

    # Gets the full pathname for the given cookbook part, returned in specificity 
    # preference order.
    def get_filename(node, cookbook_name, segment, filename)
      checksum = get_preferred_checksum(node, cookbook_name, segment, filename)
      raise Chef::Exceptions::FileNotFound, "missing file #{segment}/#{filename} for cookbook #{cookbook_name}" unless checksum

      checksum_filename = @checksum_cache.get_path(checksum)
      unless checksum_filename
        # We don't have that checksum in the cache. Fetch it.
        # TODO: timh: 2010-4-7: Make this download streaming instead of loading it all in memory
        url = "/cookbooks/#{cookbook_name}/#{cookbook_version}/#{checksum}"
        
        # Second argument is true, so we treat the result as raw, not JSON
        tempfile = rest.get_rest(url, true)
        checksum_filename = @checksum_cache.put(checksum, tempfile.path)
        tempfile.close
      end
      checksum_filename
    end

    # Figure out the checksum for a given segment/filename based on finding
    # the most specific version of the file available.
    def get_preferred_checksum(node, cookbook_name, segment, filename)
      platform, version = Chef::Platform.find_platform_and_version(node)
      fqdn = node[:fqdn]

      # Most specific to least specific places to find the filename
      preferences = [
        File.join("host-#{fqdn}", filename),
        File.join("#{platform}-#{version}", filename),
        File.join(platform, filename),
        File.join("default", filename)
      ]
      
      cookbook = get_cookbook(cookbook_name)

      cookbook_checksum_by_filename = Hash.new
      [ :resources, :providers, :recipes, :definitions, :libraries, :attributes, :files, :templates, :root_files ].each do |segment|
        cookbook[segment].inject(cookbook_checksum_by_filename) do |memo, segment_file|
          checksum = segment_file['checksum']
          memo[segment_file.path] = checksum
          memo
        end
      end
      
      # Walk most- to least-specific until we find the filename.
      preferences.find { |filename| cookbook_checksum_by_filename[filename] }
    end
    
    # Get the cookbook from the cache or fetch if it's not yet in the
    # cache.
    def get_cookbook(cookbook_name)
      unless @cookbook_cache[cookbook_name]
        url = "/cookbooks/#{cookbook_name}"
        @cookbook_cache[cookbook_name] = rest.get_rest(url)
      end
      
      @cookbook_cache[cookbook_name]
    end
    
  end
end
