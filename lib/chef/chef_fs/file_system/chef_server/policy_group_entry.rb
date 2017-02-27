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

require "chef/chef_fs/file_system/exceptions"

class Chef
  module ChefFS
    module FileSystem
      module ChefServer
        # Represents an entire policy group.
        # Server path: /organizations/ORG/policy_groups/GROUP
        # Repository path: policy_groups\GROUP.json
        # Format:
        # {
        #   "policies": {
        #     "a": { "revision_id": "1.0.0" }
        #   }
        # }
        class PolicyGroupEntry < RestListEntry
          # delete is handled normally:
          # DELETE /organizations/ORG/policy_groups/GROUP

          # read is handled normally:
          # GET /organizations/ORG/policy_groups/GROUP

          # write is different.
          # For each policy:
          # - PUT /organizations/ORG/policy_groups/GROUP/policies/POLICY
          # For each policy on the server but not the client:
          # - DELETE /organizations/ORG/policy_groups/GROUP/policies/POLICY
          # If the server has associations for a, b and c,
          # And the client wants associations for a, x and y,
          # We must PUT a, x and y
          # And DELETE b and c
          def write(file_contents)
            # Parse the contents to ensure they are valid JSON
            begin
              object = Chef::JSONCompat.parse(file_contents)
            rescue Chef::Exceptions::JSON::ParseError => e
              raise Chef::ChefFS::FileSystem::OperationFailedError.new(:create_child, self, e, "Parse error reading JSON creating child '#{name}': #{e}")
            end

            if data_handler
              object = data_handler.normalize_for_put(object, self)
              data_handler.verify_integrity(object, self) do |error|
                raise Chef::ChefFS::FileSystem::OperationFailedError.new(:create_child, self, nil, "Error creating '#{name}': #{error}")
              end
            end

            begin

              # this should all get carted to PolicyGroupEntry#write.

              # the server demands the full policy data, but we want users' local policy_group documents to just
              # have the data you'd get from GET /policy_groups/POLICY_GROUP. so we try to fetch that.

              # ordinarily this would be POST to the normal URL, but we do PUT to
              # /organizations/{organization}/policy_groups/{policy_group}/policies/{policy_name} with the full
              # policy data, for each individual policy.
              policy_datas = {}

              object["policies"].each do |policy_name, policy_data|
                policy_path = "/policies/#{policy_name}/revisions/#{policy_data["revision_id"]}"

                get_data = begin
                  rest.get(policy_path)
                rescue Net::HTTPServerException => e
                  raise "Could not find policy '#{policy_name}'' with revision '#{policy_data["revision_id"]}'' on the server"
                end

                # GET policy data
                server_policy_data = Chef::JSONCompat.parse(get_data)

                # if it comes back 404, raise an Exception with "Policy file X does not exist with revision Y on the server"

                # otherwise, add it to the list of policyfile datas.
                policy_datas[policy_name] = server_policy_data
              end

              begin
                existing_group = Chef::JSONCompat.parse(read)
              rescue NotFoundError
                # It's OK if the group doesn't already exist, just means no existing policies
              end

              # now we have the fullpolicy data for each policies, which is what the PUT endpoint demands.
              policy_datas.each do |policy_name, policy_data|
                # PUT /organizations/ORG/policy_groups/GROUP/policies/NAME
                rest.put("#{api_path}/policies/#{policy_name}", policy_data)
              end

              # Now we need to remove any policies that are *not* in our current group.
              if existing_group && existing_group["policies"]
                (existing_group["policies"].keys - policy_datas.keys).each do |policy_name|
                  rest.delete("#{api_path}/policies/#{policy_name}")
                end
              end

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

            self
          end
        end
      end
    end
  end
end
