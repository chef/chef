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
        new_url = nil
        if url =~ /^(http|https):\/\//
          new_url = url
        else
          new_url = "cookbooks/#{cookbook}/#{type}?"
          new_url += "id=#{url}"
          platform, version = Chef::Platform.find_platform_and_version(node)
          if type == "files" || type == "templates"
            new_url += "&platform=#{platform}&version=#{version}&fqdn=#{node[:fqdn]}&node_name=#{node.name}"
          end
          if args
            args.each do |key, value|
              new_url += "&#{key}=#{value}"
            end
          end
        end

        return new_url
      end
      
    end
  end
end
