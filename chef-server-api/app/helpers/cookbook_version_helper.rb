#
# Author:: Stephen Delano (<stephen@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

module Merb
  module CookbookVersionHelper

    # takes a cookbook_name and an array of versions and returns a hash
    # params:
    # - cookbook_name: the name of the cookbook
    # - versions: a sorted list of version strings
    #
    # returns:
    # {
    #   :url => http://url,
    #   :versions => [
    #     { :version => version, :url => http://url/version },
    #     { :version => version, :url => http://url/version }
    #   ]  
    # }
    def expand_cookbook_urls(cookbook_name, versions, num_versions)
      versions = versions[0...num_versions.to_i] unless num_versions == "all"
      version_list = versions.inject([]) do |res, version|
        res.push({ 
          :url => absolute_url(:cookbook_version, :cookbook_name => cookbook_name, :cookbook_version => version),
          :version => version
        })
        res
      end
      url = absolute_url(:cookbook, :cookbook_name => cookbook_name)
      {:url => url, :versions => version_list}
    end

  end
end