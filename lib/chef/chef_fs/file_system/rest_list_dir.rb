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
        def initialize(name, parent, api_path = nil, data_handler = nil)
          super(name, parent)
          @api_path = api_path || (parent.api_path == "" ? name : "#{parent.api_path}/#{name}")
          @data_handler = data_handler
        end

        attr_reader :api_path
        attr_reader :data_handler

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
            @children ||= chef_collection.keys.sort.map do |key|
              _make_child_entry("#{key}.json", true)
            end
          rescue Net::HTTPServerException => e
            if $!.response.code == "404"
              raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
            else
              raise Chef::ChefFS::FileSystem::OperationFailedError.new(:children, self, e)
            end
          end
        end

        def chef_collection
          rest.get_rest(api_path)
        end

        def identity_key
          'name'
        end

        # NOTE if you change this significantly, you will likely need to change
        # DataBagDir.create_child as well.
        def create_child(name, file_contents)
          begin
            object = JSON.parse(file_contents, :create_additions => false)
          rescue JSON::ParserError => e
            raise Chef::ChefFS::FileSystem::OperationFailedError.new(:create_child, self, e), "Parse error reading JSON creating child '#{name}': #{e}"
          end

          result = _make_child_entry(name, true)

          if data_handler
            object = data_handler.normalize(object, result)
          end

          base_name = name[0,name.length-5]
          if object[identity_key] != base_name
            raise Chef::ChefFS::FileSystem::OperationFailedError.new(:create_child, self), "Name in #{path_for_printing}/#{name} must be '#{base_name}' (is '#{object[identity_key]}')"
          end

          begin
            rest.post_rest(api_path, object)
          rescue Net::HTTPServerException => e
            if e.response.code == "404"
              raise Chef::ChefFS::FileSystem::NotFoundError.new(self, e)
            else
              raise Chef::ChefFS::FileSystem::OperationFailedError.new(:create_child, self, e), "Failure creating '#{name}': #{e.message}"
            end
          end

          result
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
