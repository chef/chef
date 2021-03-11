#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../knife"

class Chef
  class Knife
    class CookbookShow < Knife

      deps do
        require "chef/json_compat" unless defined?(Chef::JSONCompat)
        require "uri" unless defined?(URI)
        require "chef/cookbook_version" unless defined?(Chef::CookbookVersion)
      end

      banner "knife cookbook show COOKBOOK [VERSION] [PART] [FILENAME] (options)"

      option :fqdn,
        short: "-f FQDN",
        long: "--fqdn FQDN",
        description: "The FQDN of the host to see the file for."

      option :platform,
        short: "-p PLATFORM",
        long: "--platform PLATFORM",
        description: "The platform to see the file for."

      option :platform_version,
        short: "-V VERSION",
        long: "--platform-version VERSION",
        description: "The platform version to see the file for."

      option :with_uri,
        short: "-w",
        long: "--with-uri",
        description: "Show corresponding URIs."

      def run
        cookbook_name, cookbook_version, segment, filename = @name_args

        cookbook = Chef::CookbookVersion.load(cookbook_name, cookbook_version) unless cookbook_version.nil?

        case @name_args.length
        when 4 # We are showing a specific file
          node = {}
          node[:fqdn] = config[:fqdn] if config.key?(:fqdn)
          node[:platform] = config[:platform] if config.key?(:platform)
          node[:platform_version] = config[:platform_version] if config.key?(:platform_version)

          class << node
            def attribute?(name) # rubocop:disable Lint/NestedMethodDefinition
              key?(name)
            end
          end

          manifest_entry = cookbook.preferred_manifest_record(node, segment, filename)
          temp_file = rest.streaming_request(manifest_entry[:url])

          # the temp file is cleaned up elsewhere
          temp_file.open if temp_file.closed?
          pretty_print(temp_file.read)

        when 3 # We are showing a specific part of the cookbook
          if segment == "metadata"
            output(cookbook.metadata)
          else
            output(cookbook.files_for(segment))
          end
        when 2 # We are showing the whole cookbook
          output(cookbook.display)
        when 1 # We are showing the cookbook versions (all of them)
          env           = config[:environment]
          api_endpoint  = env ? "environments/#{env}/cookbooks/#{cookbook_name}" : "cookbooks/#{cookbook_name}"
          output(format_cookbook_list_for_display(rest.get(api_endpoint)))
        when 0
          show_usage
          ui.fatal("You must specify a cookbook name")
          exit 1
        end
      end
    end
  end
end
