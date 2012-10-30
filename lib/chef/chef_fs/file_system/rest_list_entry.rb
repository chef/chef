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

require 'chef/chef_fs/file_system/base_fs_object'
require 'chef/chef_fs/file_system/not_found_error'
require 'chef/role'
require 'chef/node'

class Chef
  module ChefFS
    module FileSystem
      class RestListEntry < BaseFSObject
        def initialize(name, parent, exists = nil)
          super(name, parent)
          @exists = exists
        end

        def api_path
          if name.length < 5 || name[-5,5] != ".json"
            raise "Invalid name #{path}: must end in .json"
          end
          api_child_name = name[0,name.length-5]
          "#{parent.api_path}/#{api_child_name}"
        end

        def environment
          parent.environment
        end

        def exists?
          if @exists.nil?
            begin
              @exists = parent.children.any? { |child| child.name == name }
            rescue Chef::ChefFS::FileSystem::NotFoundError
              @exists = false
            end
          end
          @exists
        end

        def delete(recurse)
          begin
            rest.delete_rest(api_path)
          rescue Net::HTTPServerException
            if $!.response.code == "404"
              raise Chef::ChefFS::FileSystem::NotFoundError.new($!), "#{path_for_printing} not found"
            else
              raise
            end
          end
        end

        def read
          Chef::JSONCompat.to_json_pretty(chef_object.to_hash)
        end

        def chef_object
          begin
            # REST will inflate the Chef object using json_class
            rest.get_rest(api_path)
          rescue Net::HTTPServerException
            if $!.response.code == "404"
              raise Chef::ChefFS::FileSystem::NotFoundError.new($!), "#{path_for_printing} not found"
            else
              raise
            end
          end
        end

        def compare_to(other)
          begin
            other_value = other.read
          rescue Chef::ChefFS::FileSystem::NotFoundError
            return [ nil, nil, :none ]
          end
          begin
            value = chef_object.to_hash
          rescue Chef::ChefFS::FileSystem::NotFoundError
            return [ false, :none, other_value ]
          end
          are_same = (value == Chef::JSONCompat.from_json(other_value, :create_additions => false))
          [ are_same, Chef::JSONCompat.to_json_pretty(value), other_value ]
        end

        def rest
          parent.rest
        end

        def write(file_contents)
          json = Chef::JSONCompat.from_json(file_contents).to_hash
          base_name = name[0,name.length-5]
          if json['name'] != base_name
            raise "Name in #{path_for_printing}/#{name} must be '#{base_name}' (is '#{json['name']}')"
          end
          begin
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
