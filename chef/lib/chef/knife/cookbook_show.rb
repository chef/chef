#
# Author:: Adam Jacob (<adam@opscode.com>)
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

require 'chef/knife'
require 'json'
require 'uri'

class Chef
  class Knife
    class CookbookShow < Knife

      banner "Sub-Command: cookbook show COOKBOOK [PART] [FILENAME] (options)"

      option :fqdn,
       :short => "-f FQDN",
       :long => "--fqdn FQDN",
       :description => "The FQDN of the host to see the file for"

      option :platform,
       :short => "-p PLATFORM",
       :long => "--platform PLATFORM",
       :description => "The platform to see the file for"

      option :platform_version,
       :short => "-V VERSION",
       :long => "--platform-version VERSION",
       :description => "The platform version to see the file for"

      def run 
        case @name_args.length
        when 3 # We are showing a specific file
          arguments = { :id => @name_args[2] } 
          arguments[:fqdn] = config[:fqdn] if config.has_key?(:fqdn)
          arguments[:platform] = config[:platform] if config.has_key?(:platform)
          arguments[:version] = config[:platform_version] if config.has_key?(:platform_version)
          result = rest.get_rest("cookbooks/#{@name_args[0]}/#{@name_args[1]}?#{make_query_params(arguments)}")
          pretty_print(result)
        when 2 # We are showing a specific part of the cookbook
          result = rest.get_rest("cookbooks/#{@name_args[0]}")
          json_pretty_print(result[@name_args[1]])
        when 1 # We are showing the whole cookbook data
          json_pretty_print(rest.get_rest("cookbooks/#{@name_args[0]}"))
        end
      end

      def make_query_params(req_opts)
        query_part = Array.new 
        req_opts.keys.sort { |a,b| a.to_s <=> b.to_s }.each do |key|
          query_part << "#{key}=#{URI.escape(req_opts[key])}"
        end
        query_part.join("&")
      end

    end
  end
end




