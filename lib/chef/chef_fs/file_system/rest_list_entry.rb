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
require 'chef/chef_fs/file_system/operation_failed_error'
require 'chef/chef_fs/raw_request'
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

        def data_handler
          parent.data_handler
        end

        def api_child_name
          if name.length < 5 || name[-5,5] != ".json"
            raise "Invalid name #{path}: must end in .json"
          end
          name[0,name.length-5]
        end

        def api_path
          "#{parent.api_path}/#{api_child_name}"
        end

        def org
          parent.org
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
          rescue Timeout::Error => e
            raise Chef::ChefFS::FileSystem::OperationFailedError.new(:delete, self, e), "Timeout deleting: #{e}"
          rescue Net::HTTPServerException => e
            if e.response.code == "404"
              raise Chef::ChefFS::FileSystem::NotFoundError.new(self, e)
            else
              raise Chef::ChefFS::FileSystem::OperationFailedError.new(:delete, self, e), "Timeout deleting: #{e}"
            end
          end
        end

        def read
          Chef::JSONCompat.to_json_pretty(_read_hash)
        end

        def _read_hash
          begin
            json = Chef::ChefFS::RawRequest.raw_request(rest, api_path)
          rescue Timeout::Error => e
            raise Chef::ChefFS::FileSystem::OperationFailedError.new(:read, self, e), "Timeout reading: #{e}"
          rescue Net::HTTPServerException => e
            if $!.response.code == "404"
              raise Chef::ChefFS::FileSystem::NotFoundError.new(self, e)
            else
              raise Chef::ChefFS::FileSystem::OperationFailedError.new(:read, self, e), "HTTP error reading: #{e}"
            end
          end
          # Minimize the value (get rid of defaults) so the results don't look terrible
          minimize_value(JSON.parse(json, :create_additions => false))
        end

        def chef_object
          # REST will inflate the Chef object using json_class
          data_handler.json_class.json_create(read)
        end

        def minimize_value(value)
          data_handler.minimize(data_handler.normalize(value, self), self)
        end

        def compare_to(other)
          # TODO this pair of reads can be parallelized

          # Grab the other value
          begin
            other_value_json = other.read
          rescue Chef::ChefFS::FileSystem::NotFoundError
            return [ nil, nil, :none ]
          end

          # Grab this value
          begin
            value = _read_hash
          rescue Chef::ChefFS::FileSystem::NotFoundError
            return [ false, :none, other_value_json ]
          end

          # Minimize (and normalize) both values for easy and beautiful diffs
          value = minimize_value(value)
          value_json = Chef::JSONCompat.to_json_pretty(value)
          begin
            other_value = JSON.parse(other_value_json, :create_additions => false)
          rescue JSON::ParserError => e
            Chef::Log.warn("Parse error reading #{other.path_for_printing} as JSON: #{e}")
            return [ nil, value_json, other_value_json ]
          end
          other_value = minimize_value(other_value)
          other_value_json = Chef::JSONCompat.to_json_pretty(other_value)

          [ value == other_value, value_json, other_value_json ]
        end

        def rest
          parent.rest
        end

        def write(file_contents)
          begin
            object = JSON.parse(file_contents, :create_additions => false)
          rescue JSON::ParserError => e
            raise Chef::ChefFS::FileSystem::OperationFailedError.new(:write, self, e), "Parse error reading JSON: #{e}"
          end

          if data_handler
            object = data_handler.normalize_for_put(object, self)
            data_handler.verify_integrity(object, self) do |error|
              raise Chef::ChefFS::FileSystem::OperationFailedError.new(:write, self), "#{error}"
            end
          end

          begin
            rest.put_rest(api_path, object)
          rescue Timeout::Error => e
            raise Chef::ChefFS::FileSystem::OperationFailedError.new(:write, self, e), "Timeout writing: #{e}"
          rescue Net::HTTPServerException => e
            if e.response.code == "404"
              raise Chef::ChefFS::FileSystem::NotFoundError.new(self, e)
            else
              raise Chef::ChefFS::FileSystem::OperationFailedError.new(:write, self, e), "HTTP error writing: #{e}"
            end
          end
        end
      end
    end
  end
end
