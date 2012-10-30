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

require 'chef/chef_fs/file_system/rest_list_dir'
require 'chef/chef_fs/file_system/data_bag_item'
require 'chef/chef_fs/file_system/not_found_error'
require 'chef/chef_fs/file_system/must_delete_recursively_error'

class Chef
  module ChefFS
    module FileSystem
      class DataBagDir < RestListDir
        def initialize(name, parent, exists = nil)
          super(name, parent)
          @exists = nil
        end

        def dir?
          exists?
        end

        def read
          # This will only be called if dir? is false, which means exists? is false.
          raise Chef::ChefFS::FileSystem::NotFoundError, "#{path_for_printing} not found"
        end

        def exists?
          if @exists.nil?
            @exists = parent.children.any? { |child| child.name == name }
          end
          @exists
        end

        def create_child(name, file_contents)
          json = Chef::JSONCompat.from_json(file_contents).to_hash
          id = name[0,name.length-5]
          if json.include?('id') && json['id'] != id
            raise "ID in #{path_for_printing}/#{name} must be '#{id}' (is '#{json['id']}')"
          end
          rest.post_rest(api_path, json)
          _make_child_entry(name, true)
        end

        def _make_child_entry(name, exists = nil)
          DataBagItem.new(name, self, exists)
        end

        def delete(recurse)
          if !recurse
            raise Chef::ChefFS::FileSystem::MustDeleteRecursivelyError.new, "#{path_for_printing} must be deleted recursively"
          end
          begin
            rest.delete_rest(api_path)
          rescue Net::HTTPServerException
            if $!.response.code == "404"
              raise Chef::ChefFS::FileSystem::NotFoundError.new($!), "#{path_for_printing} not found"
            end
          end
        end
      end
    end
  end
end
