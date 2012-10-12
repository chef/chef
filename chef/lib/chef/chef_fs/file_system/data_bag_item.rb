#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'chef/chef_fs/file_system/rest_list_entry'

class Chef
  module ChefFS
    module FileSystem
      class DataBagItem < RestListEntry
        def initialize(name, parent, exists = nil)
          super(name, parent, exists)
        end

        def write(file_contents)
          # Write is just a little tiny bit different for data bags:
          # you set raw_data in the JSON instead of putting the items
          # in the top level.
          json = Chef::JSONCompat.from_json(file_contents).to_hash
          id = name[0,name.length-5]  # Strip off the .json from the end
          if json['id'] != id
            raise "Id in #{path_for_printing}/#{name} must be '#{id}' (is '#{json['id']}')"
          end
          begin
            data_bag = parent.name
            json = {
              "name" => "data_bag_item_#{data_bag}_#{id}",
              "json_class" => "Chef::DataBagItem",
              "chef_type" => "data_bag_item",
              "data_bag" => data_bag,
              "raw_data" => json
            }
            rest.put_rest(api_path, json)
          rescue Net::HTTPServerException
            if $!.response.code == "404"
              raise Chef::ChefFS::FileSystem::NotFoundError.new($!), "#{path_for_printing} not found"
            else
              raise
            end
          end
        end
      end
    end
  end
end
