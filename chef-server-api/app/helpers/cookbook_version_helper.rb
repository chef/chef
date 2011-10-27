#
# Author:: Stephen Delano (<stephen@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

    include Merb::ControllerExceptions

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

    # validate and return the number of versions requested
    # by the user
    #
    # raises an exception if an invalid number is requested
    #
    # params:
    # - default: the number of versions to default to
    #
    # valid num_versions query parameter:
    # - an integer >= 0
    # - the string "all"
    def num_versions!(default="1")
      input = params[:num_versions]
      result = if input
                 valid_input = (input == "all" || Integer(input) >= 0) rescue false
                 raise BadRequest, "You have requested an invalid number of versions (x >= 0 || 'all')" unless valid_input
                 input
               else
                 default
               end
    end
  end
end