#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Daniel DeLeo (<dan@chef.io>)
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
    class CookbookBulkDelete < Knife

      deps do
        require_relative "cookbook_delete"
        require "chef/cookbook_version" unless defined?(Chef::CookbookVersion)
      end

      option :purge, short: "-p", long: "--purge", boolean: true, description: "Permanently remove files from backing data store."

      banner "knife cookbook bulk delete REGEX (options)"

      def run
        unless regex_str = @name_args.first
          ui.fatal("You must supply a regular expression to match the results against")
          exit 42
        end

        regex = Regexp.new(regex_str)

        all_cookbooks = Chef::CookbookVersion.list
        cookbooks_names = all_cookbooks.keys.grep(regex)
        cookbooks_to_delete = cookbooks_names.inject({}) { |hash, name| hash[name] = all_cookbooks[name]; hash }
        ui.msg "All versions of the following cookbooks will be deleted:"
        ui.msg ""
        ui.msg ui.list(cookbooks_to_delete.keys.sort, :columns_down)
        ui.msg ""

        unless config[:yes]
          ui.confirm("Do you really want to delete these cookbooks")

          if config[:purge]
            ui.msg("Files that are common to multiple cookbooks are shared, so purging the files may break other cookbooks.")
            ui.confirm("Are you sure you want to purge files instead of just deleting the cookbooks")
          end
          ui.msg ""
        end

        cookbooks_names.each do |cookbook_name|
          versions = rest.get("cookbooks/#{cookbook_name}")[cookbook_name]["versions"].map { |v| v["version"] }.flatten
          versions.each do |version|
            rest.delete("cookbooks/#{cookbook_name}/#{version}#{config[:purge] ? "?purge=true" : ""}")
            ui.info("Deleted cookbook  #{cookbook_name.ljust(25)} [#{version}]")
          end
        end
      end
    end
  end
end
