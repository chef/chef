#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'chef/platform'

class Chef
  module Mixin
    module GenerateURL
    
      def generate_cookbook_url(url, cookbook, type, node, args=nil)
        Chef::Log.debug("generating cookbook url for url=#{url}, cookbook=#{cookbook.inspect}, type=#{type}, node=#{node}")
        new_url = nil
        if url =~ /^(http|https):\/\//
          new_url = url
        else
          new_url = "cookbooks/#{cookbook}/#{type}?"
          new_url += "id=#{url}"
          new_url = generate_cookbook_url_from_uri(new_url, node, args)
        end
        Chef::Log.debug("generated cookbook url: #{new_url}")
        return new_url
      end

      def generate_cookbook_url_from_uri(uri, node, args=nil)
        platform, version = Chef::Platform.find_platform_and_version(node)
        uri =~ /cookbooks\/(.+?)\/(.+)\?/
        cookbook = $1
        type = $2
        if type == "files" || type == "templates"
          uri += "&platform=#{platform}&version=#{version}&fqdn=#{node[:fqdn]}&node_name=#{node.name}"
        end
        if args
          args.each do |key, value|
            uri += "&#{key}=#{value}"
          end
        end

        uri
      end
      
    end
  end
end
