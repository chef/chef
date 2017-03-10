#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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

require "chef/chef_fs/file_system/base_fs_object"
require "chef/chef_fs/file_system/exceptions"
require "chef/role"
require "chef/node"
require "chef/json_compat"

class Chef
  module ChefFS
    module FileSystem
      module ChefServer
        class RestListEntry < BaseFSObject
          def initialize(name, parent, exists = nil)
            super(name, parent)
            @exists = exists
            @this_object_cache = nil
          end

          def data_handler
            parent.data_handler
          end

          def api_child_name
            if %w{ .rb .json }.include? File.extname(name)
              File.basename(name, ".*")
            else
              name
            end
          end

          def api_path
            "#{parent.api_path}/#{api_child_name}"
          end

          def display_path
            pth = api_path.start_with?("/") ? api_path : "/#{api_path}"
            File.extname(pth).empty? ? pth + ".json" : pth
          end
          alias_method :path_for_printing, :display_path

          def display_name
            File.basename(display_path)
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
                @this_object_cache = rest.get(api_path)
                @exists = true
              rescue Net::HTTPServerException => e
                if e.response.code == "404"
                  @exists = false
                else
                  raise
                end
              rescue Chef::ChefFS::FileSystem::NotFoundError
                @exists = false
              end
            end
            @exists
          end

          def delete(recurse)
            # free up cache - it will be hydrated on next check for exists?
            @this_object_cache = nil
            rest.delete(api_path)
          rescue Timeout::Error => e
            raise Chef::ChefFS::FileSystem::OperationFailedError.new(:delete, self, e, "Timeout deleting: #{e}")
          rescue Net::HTTPServerException => e
            if e.response.code == "404"
              raise Chef::ChefFS::FileSystem::NotFoundError.new(self, e)
            else
              raise Chef::ChefFS::FileSystem::OperationFailedError.new(:delete, self, e, "Timeout deleting: #{e}")
            end
          end

          def read
            # Minimize the value (get rid of defaults) so the results don't look terrible
            Chef::JSONCompat.to_json_pretty(minimize_value(_read_json))
          end

          def _read_json
            @this_object_cache ? JSON.parse(@this_object_cache) : root.get_json(api_path)
          rescue Timeout::Error => e
            raise Chef::ChefFS::FileSystem::OperationFailedError.new(:read, self, e, "Timeout reading: #{e}")
          rescue Net::HTTPServerException => e
            if $!.response.code == "404"
              raise Chef::ChefFS::FileSystem::NotFoundError.new(self, e)
            else
              raise Chef::ChefFS::FileSystem::OperationFailedError.new(:read, self, e, "HTTP error reading: #{e}")
            end
          end

          def chef_object
            # REST will inflate the Chef object using json_class
            data_handler.json_class.from_hash(read)
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
              value = _read_json
            rescue Chef::ChefFS::FileSystem::NotFoundError
              return [ false, :none, other_value_json ]
            end

            # Minimize (and normalize) both values for easy and beautiful diffs
            value = minimize_value(value)
            value_json = Chef::JSONCompat.to_json_pretty(value)
            begin
              other_value = Chef::JSONCompat.parse(other_value_json)
            rescue Chef::Exceptions::JSON::ParseError => e
              Chef::Log.warn("Parse error reading #{other.path_for_printing} as JSON: #{e}")
              return [ nil, value_json, other_value_json ]
            end
            other_value = minimize_value(other_value)
            other_value_json = Chef::JSONCompat.to_json_pretty(other_value)

            # free up cache - it will be hydrated on next check for exists?
            @this_object_cache = nil

            [ value == other_value, value_json, other_value_json ]
          end

          def rest
            parent.rest
          end

          def write(file_contents)
            # free up cache - it will be hydrated on next check for exists?
            @this_object_cache = nil

            begin
              object = Chef::JSONCompat.parse(file_contents)
            rescue Chef::Exceptions::JSON::ParseError => e
              raise Chef::ChefFS::FileSystem::OperationFailedError.new(:write, self, e, "Parse error reading JSON: #{e}")
            end

            if data_handler
              object = data_handler.normalize_for_put(object, self)
              data_handler.verify_integrity(object, self) do |error|
                raise Chef::ChefFS::FileSystem::OperationFailedError.new(:write, self, nil, "#{error}")
              end
            end

            begin
              rest.put(api_path, object)
            rescue Timeout::Error => e
              raise Chef::ChefFS::FileSystem::OperationFailedError.new(:write, self, e, "Timeout writing: #{e}")
            rescue Net::HTTPServerException => e
              if e.response.code == "404"
                raise Chef::ChefFS::FileSystem::NotFoundError.new(self, e)
              else
                raise Chef::ChefFS::FileSystem::OperationFailedError.new(:write, self, e, "HTTP error writing: #{e}")
              end
            end
          end

          def api_error_text(response)
            Chef::JSONCompat.parse(response.body)["error"].join("\n")
          rescue
            response.body
          end
        end

      end
    end
  end
end
