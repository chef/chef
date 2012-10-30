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

class Chef
  class Knife
    class CookbookShow < Knife

      deps do
        require 'chef/json_compat'
        require 'uri'
        require 'chef/cookbook_version'
      end

      banner "knife cookbook show COOKBOOK [VERSION] [PART] [FILENAME] (options)"

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

      option :with_uri,
        :short => "-w",
        :long => "--with-uri",
        :description => "Show corresponding URIs"

      def run 
        case @name_args.length
        when 4 # We are showing a specific file
          node = Hash.new
          node[:fqdn] = config[:fqdn] if config.has_key?(:fqdn)
          node[:platform] = config[:platform] if config.has_key?(:platform)
          node[:platform_version] = config[:platform_version] if config.has_key?(:platform_version)

          class << node
            def attribute?(name)
              has_key?(name)
            end
          end

          cookbook_name, segment, filename = @name_args[0], @name_args[2], @name_args[3]
          cookbook_version = @name_args[1] == 'latest' ? '_latest' : @name_args[1]

          cookbook = rest.get_rest("cookbooks/#{cookbook_name}/#{cookbook_version}")
          manifest_entry = cookbook.preferred_manifest_record(node, segment, filename)
          temp_file = rest.get_rest(manifest_entry[:url], true)

          # the temp file is cleaned up elsewhere
          temp_file.open if temp_file.closed?
          pretty_print(temp_file.read)

        when 3 # We are showing a specific part of the cookbook
          cookbook_version = @name_args[1] == 'latest' ? '_latest' : @name_args[1]
          result = rest.get_rest("cookbooks/#{@name_args[0]}/#{cookbook_version}")
          output(result.manifest[@name_args[2]])
        when 2 # We are showing the whole cookbook data
          cookbook_version = @name_args[1] == 'latest' ? '_latest' : @name_args[1]
          output(rest.get_rest("cookbooks/#{@name_args[0]}/#{cookbook_version}"))
        when 1 # We are showing the cookbook versions (all of them)
          cookbook_name = @name_args[0]
          env           = config[:environment]
          api_endpoint  = env ? "environments/#{env}/cookbooks/#{cookbook_name}" : "cookbooks/#{cookbook_name}"
          output(format_cookbook_list_for_display(rest.get_rest(api_endpoint)))
        when 0
          show_usage
          ui.fatal("You must specify a cookbook name")
          exit 1
        end
      end
    end
  end
end




