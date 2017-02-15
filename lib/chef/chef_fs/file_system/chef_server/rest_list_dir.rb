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

require "chef/chef_fs/file_system/base_fs_dir"
require "chef/chef_fs/file_system/chef_server/rest_list_entry"
require "chef/chef_fs/file_system/exceptions"

class Chef
  module ChefFS
    module FileSystem
      module ChefServer
        class RestListDir < BaseFSDir
          def initialize(name, parent, api_path = nil, data_handler = nil)
            super(name, parent)
            @api_path = api_path || (parent.api_path == "" ? name : "#{parent.api_path}/#{name}")
            @data_handler = data_handler
          end

          attr_reader :api_path
          attr_reader :data_handler

          def can_have_child?(name, is_dir)
            !is_dir
          end

          #
          # When talking to a modern (12.0+) Chef server
          # knife list /
          # -> /nodes
          # -> /policies
          # -> /policy_groups
          # -> /roles
          #
          # 12.0 or 12.1 will fail when you do this:
          # knife list / --recursive
          # Because it thinks /policies exists, and when it tries to list its children
          # it gets a 404 (indicating it actually doesn't exist).
          #
          # With this change, knife list / --recursive will list /policies as a real, empty directory.
          #
          # Alternately, we could have done some sort of detection when we listed the top level
          # and determined which endpoints the server would support, and returned only those.
          # So you wouldn't see /policies in that case at all.
          # The issue with that is there's no efficient way to do it because we can't find out
          # the server version directly, and can't ask the server for a list of the endpoints it supports.
          #

          #
          # Does GET /<api_path>, assumes the result is of the format:
          #
          # {
          #   "foo": "<api_path>/foo",
          #   "bar": "<api_path>/bar",
          # }
          #
          # Children are foo.json and bar.json in this case.
          #
          def children
              # Grab the names of the children, append json, and make child entries
            @children ||= root.get_json(api_path).keys.sort.map do |key|
              make_child_entry(key, true)
            end
          rescue Timeout::Error => e
            raise Chef::ChefFS::FileSystem::OperationFailedError.new(:children, self, e, "Timeout retrieving children: #{e}")
          rescue Net::HTTPServerException => e
            # 404 = NotFoundError
            if $!.response.code == "404"

              if parent.is_a?(ChefServerRootDir)
                # GET /organizations/ORG/<container> returned 404, but that just might be because
                # we are talking to an older version of the server that doesn't support policies.
                # Do GET /organizations/ORG to find out if the org exists at all.
                # TODO use server API version instead of a second network request.
                begin
                  root.get_json(parent.api_path)
                  # Return empty list if the organization exists but /policies didn't work
                  []
                rescue Net::HTTPServerException => e
                  if e.response.code == "404"
                    raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
                  end
                  raise Chef::ChefFS::FileSystem::OperationFailedError.new(:children, self, e, "HTTP error retrieving children: #{e}")
                end
              else
                raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
              end

            # Anything else is unexpected (OperationFailedError)
            else
              raise Chef::ChefFS::FileSystem::OperationFailedError.new(:children, self, e, "HTTP error retrieving children: #{e}")
            end
          end

          #
          # Does POST <api_path> with file_contents
          #
          def create_child(name, file_contents)
            # Parse the contents to ensure they are valid JSON
            begin
              object = Chef::JSONCompat.parse(file_contents)
            rescue Chef::Exceptions::JSON::ParseError => e
              raise Chef::ChefFS::FileSystem::OperationFailedError.new(:create_child, self, e, "Parse error reading JSON creating child '#{name}': #{e}")
            end

            # Create the child entry that will be returned
            result = make_child_entry(name, true)

            # Normalize the file_contents before post (add defaults, etc.)
            if data_handler
              object = data_handler.normalize_for_post(object, result)
              data_handler.verify_integrity(object, result) do |error|
                raise Chef::ChefFS::FileSystem::OperationFailedError.new(:create_child, self, nil, "Error creating '#{name}': #{error}")
              end
            end

            # POST /api_path with the normalized file_contents
            begin
              rest.post(api_path, object)
            rescue Timeout::Error => e
              raise Chef::ChefFS::FileSystem::OperationFailedError.new(:create_child, self, e, "Timeout creating '#{name}': #{e}")
            rescue Net::HTTPServerException => e
              # 404 = NotFoundError
              if e.response.code == "404"
                raise Chef::ChefFS::FileSystem::NotFoundError.new(self, e)
              # 409 = AlreadyExistsError
              elsif $!.response.code == "409"
                raise Chef::ChefFS::FileSystem::AlreadyExistsError.new(:create_child, self, e, "Failure creating '#{name}': #{path}/#{name} already exists")
              # Anything else is unexpected (OperationFailedError)
              else
                raise Chef::ChefFS::FileSystem::OperationFailedError.new(:create_child, self, e, "Failure creating '#{name}': #{e.message}")
              end
            end

            # Clear the cache of children so that if someone asks for children
            # again, we will get it again
            @children = nil

            result
          end

          def org
            parent.org
          end

          def environment
            parent.environment
          end

          def rest
            parent.rest
          end

          def make_child_entry(name, exists = nil)
            @children.find { |child| child.name == name } if @children
            RestListEntry.new(name, self, exists)
          end
        end
      end
    end
  end
end
