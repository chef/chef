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

require "chef/chef_fs/file_system/chef_server/rest_list_dir"
require "chef/chef_fs/file_system/chef_server/policy_revision_entry"

class Chef
  module ChefFS
    module FileSystem
      module ChefServer
        #
        # Server API:
        # /policies - list of policies by name
        #   - /policies/NAME - represents a policy with all revisions
        #     - /policies/NAME/revisions - list of revisions for that policy
        #       - /policies/NAME/revisions/REVISION - actual policy-revision document
        #
        # Local Repository and ChefFS:
        # /policies - PoliciesDir - maps to server API /policies
        #   - /policies/NAME-REVISION.json - PolicyRevision - maps to /policies/NAME/revisions/REVISION
        #
        class PoliciesDir < RestListDir
          # Children: NAME-REVISION.json for all revisions of all policies
          #
          # /nodes: {
          #   "node1": "https://api.opscode.com/organizations/myorg/nodes/node1",
          #   "node2": "https://api.opscode.com/organizations/myorg/nodes/node2",
          # }
          #
          # /policies: {
          #   "foo": {}
          # }

          def make_child_entry(name, exists = nil)
            @children.find { |child| child.name == name } if @children
            PolicyRevisionEntry.new(name, self, exists)
          end

          # Children come from /policies in this format:
          # {
          #   "foo": {
          #     "uri": "https://api.opscode.com/organizations/essentials/policies/foo",
          #     "revisions": {
          #       "1.0.0": {
          #
          #       },
          #       "1.0.1": {
          #
          #       }
          #     }
          #   }
          # }
          def children
              # Grab the names of the children, append json, and make child entries
            @children ||= begin
              result = []
              data = root.get_json(api_path)
              data.keys.sort.each do |policy_name|
                data[policy_name]["revisions"].keys.each do |policy_revision|
                  filename = "#{policy_name}-#{policy_revision}.json"
                  result << make_child_entry(filename, true)
                end
              end
              result
            end
          rescue Timeout::Error => e
            raise Chef::ChefFS::FileSystem::OperationFailedError.new(:children, self, e, "Timeout retrieving children: #{e}")
          rescue Net::HTTPServerException => e
            # 404 = NotFoundError
            if $!.response.code == "404"
              # GET /organizations/ORG/policies returned 404, but that just might be because
              # we are talking to an older version of the server that doesn't support policies.
              # Do GET /orgqanizations/ORG to find out if the org exists at all.
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
              policy_name, policy_revision = data_handler.name_and_revision(name)
              rest.post("#{api_path}/#{policy_name}/revisions", object)
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

        end
      end
    end
  end
end
