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

require 'chef/chef_fs/file_system/base_fs_dir'
require 'chef/chef_fs/file_system/rest_list_entry'
require 'chef/chef_fs/file_system/not_found_error'

class Chef
  module ChefFS
    module FileSystem
      class RestListDir < BaseFSDir
        def initialize(name, parent, api_path = nil)
          super(name, parent)
          @api_path = api_path || (parent.api_path == "" ? name : "#{parent.api_path}/#{name}")
        end

        attr_reader :api_path

        def child(name)
          result = @children.select { |child| child.name == name }.first if @children
          result ||= can_have_child?(name, false) ?
                     _make_child_entry(name) : NonexistentFSObject.new(name, self)
        end

        def can_have_child?(name, is_dir)
          name =~ /\.json$/ && !is_dir
        end

        def children
          begin
            @children ||= rest.get_rest(api_path).keys.map do |key|
              _make_child_entry("#{key}.json", true)
            end
          rescue Net::HTTPServerException
            if $!.response.code == "404"
              raise Chef::ChefFS::FileSystem::NotFoundError.new($!), "#{path_for_printing} not found"
            else
              raise
            end
          end
        end

        # NOTE if you change this significantly, you will likely need to change
        # DataBagDir.create_child as well.
        def create_child(name, file_contents)
          json = Chef::JSONCompat.from_json(file_contents).to_hash
          base_name = name[0,name.length-5]
          if json.include?('name') && json['name'] != base_name
            raise "Name in #{path_for_printing}/#{name} must be '#{base_name}' (is '#{json['name']}')"
          end
          rest.post_rest(api_path, json)
          _make_child_entry(name, true)
        end

        def environment
          parent.environment
        end

        def rest
          parent.rest
        end

        def _make_child_entry(name, exists = nil)
          RestListEntry.new(name, self, exists)
        end
      end
    end
  end
end
